import Foundation
import BluetoothKit
import ObjectiveC

/// GMacro protocol session 事件
public enum GMacroProtocolEvent: @unchecked Sendable {
    case progress(CGFloat)
    case success
    case failure(String)
    case testKeys([GamepadKey], j1x: Int, j1y: Int, j2x: Int, j2y: Int, l2: Int, r2: Int)
    case configKeys([GamepadKey])
    case testKeyboardMouse(modifierKeys: [ModifierKey], keyboardKeys: [KeyboardKey],
                           mouseCores: [MouseCoreButton], mouseWheels: [MouseWheelButton],
                           mouseX: Int8, mouseY: Int8, mediaKeys: [MediaKey])
    case recordKeys(MacroComkeyBridge)
    case endRecord(Int)
    case calibrationFinished(type: Int, subId: Int, result: Int, param1: [Int], param2: [Int])
    /// 手柄通过协议层上报 MFi 设备就绪（0x7402）；外层 NativeAdapterRuntime 负责映射到 Flutter ProtocolReady
    case deviceConnected
    case devKeysState([GamepadKey], j1x: Int, j1x_o: Int, j1y: Int, j1y_o: Int,
                      j2x: Int, j2x_o: Int, j2y: Int, j2y_o: Int,
                      l2: Int, l2_o: Int, r2: Int, r2_o: Int)
}

/// GMacro protocol session（session 化入口，替代 GMacroProtocolHelper.shared）。
///
/// - 每次 attach 操作创建一个独立实例，不再共享全局状态
/// - DataHelper 是 session 级实例，不使用 DataHelper.shared
/// - 不持有 disconnect 能力；transport 断连由外层 NativeAdapterRuntime 级联处理
public final class GMacroProtocolSession: NSObject, @unchecked Sendable {

    public let sessionId: String
    private let transport: ByteStreamTransport

    /// session 内专属 DataHelper，不使用 DataHelper.shared（internal 供同模块 extension 访问）
    let dataHelper: DataHelper

    /// 单次下发字节数上限，由外层（NativeAdapterRuntime）在 attach 时配置
    public var onceByteLimit: Int = 20

    /// protocol 事件回调
    public var onEvent: ((GMacroProtocolEvent) -> Void)?
    public typealias OTAWriteClosure = (_ data: Data, _ completion: (() -> Void)?) -> Void
    public var otaCommandWriter: OTAWriteClosure?
    public var otaDataWriter: OTAWriteClosure?

    public init(sessionId: String, transport: ByteStreamTransport) {
        self.sessionId = sessionId
        self.transport = transport
        self.dataHelper = DataHelper()
        super.init()
        dataHelper.setup(with: self)

        // 注入发送钩子：所有写操作经由 transport，不走 GMacroProtocolHelper.shared.delegate
        dataHelper.sendPacketHandler = { [weak self] data, _, _, _, _, finish, response in
            guard let self else { return }
            do {
                try self.transport.send(data)
                finish?()
                // 不在此处调用 response：设备回包由 pendingResponses 机制处理，
                // 调用 response?(nil, nil) 会触发 "Empty or invalid response" 误报。
            } catch {
                response?(nil, error as NSError)
            }
        }

        transport.onReceive { [weak self] data in
            self?.handleIncoming(data)
        }
    }

    public func close() {
        dataHelper.delegate = nil   // 断开循环引用
        onEvent = nil
    }
}

// MARK: - GMacroDataDelegate

extension GMacroProtocolSession: GMacroDataDelegate {

    public func onceByteCount() -> Int { onceByteLimit }

    public func progress(_ progress: CGFloat) {
        onEvent?(.progress(progress))
    }

    public func success() {
        onEvent?(.success)
    }

    public func error(_ message: String) {
        onEvent?(.failure(message))
    }

    public func receiveTestKeys(_ keys: [GamepadKey], j1x: Int, j1y: Int,
                                j2x: Int, j2y: Int, l2: Int, r2: Int) {
        onEvent?(.testKeys(keys, j1x: j1x, j1y: j1y, j2x: j2x, j2y: j2y, l2: l2, r2: r2))
    }

    public func receiveConfigKeys(_ keys: [GamepadKey]) {
        onEvent?(.configKeys(keys))
    }

    public func receiveTestKeyboardMouse(_ modifierKeys: [ModifierKey],
                                         keyboardKeys: [KeyboardKey],
                                         mouseCores: [MouseCoreButton],
                                         mouseWheels: [MouseWheelButton],
                                         mouseX: Int8, mouseY: Int8,
                                         mediaKeys: [MediaKey]) {
        onEvent?(.testKeyboardMouse(modifierKeys: modifierKeys, keyboardKeys: keyboardKeys,
                                    mouseCores: mouseCores, mouseWheels: mouseWheels,
                                    mouseX: mouseX, mouseY: mouseY, mediaKeys: mediaKeys))
    }

    public func receiveRecordKeys(_ value: MacroComkeyBridge) {
        onEvent?(.recordKeys(value))
    }

    public func endRecordKeys(_ code: Int) {
        onEvent?(.endRecord(code))
    }

    public func finishCalibration(_ type: Int, subId: Int, result: Int,
                                   param1: [Int], param2: [Int]) {
        onEvent?(.calibrationFinished(type: type, subId: subId, result: result,
                                      param1: param1, param2: param2))
    }

    /// 手柄上报协议层 MFi 就绪（0x7402）。
    /// 不再直接驱动 MFiKitHelper.shared；外层 NativeAdapterRuntime 监听 onEvent 决定如何处理。
    public func devConnectState(_ state: Int) {
        onEvent?(.deviceConnected)
    }

    public func receiveDevKeysState(_ keys: [GamepadKey],
                                     j1x: Int, j1x_o: Int, j1y: Int, j1y_o: Int,
                                     j2x: Int, j2x_o: Int, j2y: Int, j2y_o: Int,
                                     l2: Int, l2_o: Int, r2: Int, r2_o: Int) {
        onEvent?(.devKeysState(keys,
                               j1x: j1x, j1x_o: j1x_o,
                               j1y: j1y, j1y_o: j1y_o,
                               j2x: j2x, j2x_o: j2x_o,
                               j2y: j2y, j2y_o: j2y_o,
                               l2: l2, l2_o: l2_o,
                               r2: r2, r2_o: r2_o))
    }
}

private enum GMacroOTAProtocolID: Int {
    case dfuReady = 0x5000
    case askBytes = 0x5100
    case sendedBytes = 0x5200
    case checkDfu = 0x5300
}

private struct GMacroOTAState {
    let firmware: Data
    var byteCount: Int = 0
}

private final class GMacroOTAStateBox: NSObject {
    var state: GMacroOTAState

    init(state: GMacroOTAState) {
        self.state = state
    }
}

private var otaStateKey: UInt8 = 0

extension GMacroProtocolSession {
    public func startOTA(data: Data) {
        guard !data.isEmpty else {
            onEvent?(.failure("OTA 固件为空"))
            return
        }
        guard otaCommandWriter != nil, otaDataWriter != nil else {
            onEvent?(.failure("OTA 通道未配置"))
            return
        }

        otaState = GMacroOTAState(firmware: data)
        sendOTAReadyCheck(with: data)
    }

    func handleIncoming(_ data: Data) {
        if handleOTAResponseIfNeeded(data) {
            return
        }
        dataHelper.parse(data)
    }

    private func handleOTAResponseIfNeeded(_ data: Data) -> Bool {
        guard otaState != nil, data.count >= 3 else {
            return false
        }

        let protocolId = data.subdata(in: 1..<3).toInt()
        guard let otaProtocol = GMacroOTAProtocolID(rawValue: protocolId) else {
            return false
        }

        let otherData = data.subdata(in: 3..<data.count)

        switch otaProtocol {
        case .dfuReady:
            askOTAByteCount()

        case .askBytes:
            let byteCount = otherData.toInt()
            guard byteCount > 0 else {
                finishOTAWithFailure("设备返回的 OTA 单包长度无效: \(byteCount)")
                return true
            }
            otaState?.byteCount = byteCount
            sendNextOTAData(from: 0)

        case .sendedBytes:
            guard otherData.count >= 5 else {
                finishOTAWithFailure("设备返回的 OTA 进度数据长度异常")
                return true
            }

            let errorCode = otherData.subdata(in: 0..<1).toInt()
            guard errorCode == 0 else {
                finishOTAWithFailure("设备 OTA 失败，错误码 \(errorCode)")
                return true
            }

            guard let state = otaState else {
                finishOTAWithFailure("OTA 状态已丢失")
                return true
            }

            let indexData = otherData.subdata(in: (otherData.count - 4)..<otherData.count)
            let index = indexData.toInt()
            let progress = min(CGFloat(index) / CGFloat(state.firmware.count), 1)
            onEvent?(.progress(progress))

            if index < state.firmware.count {
                sendNextOTAData(from: index)
            }

        case .checkDfu:
            let result = otherData.toInt()
            if result == 0 {
                otaState = nil
                onEvent?(.progress(1))
                onEvent?(.success)
            } else {
                finishOTAWithFailure("设备 OTA 校验失败，错误码 \(result)")
            }
        }

        return true
    }

    private func sendOTAReadyCheck(with data: Data) {
        var payload = Data.from(GMacroOTAProtocolID.dfuReady.rawValue, count: 2)
        payload.append(Data.from(Int(data.crc16ccitt_xmodem()), count: 2))
        payload.append(Data.from(data.count, count: 3))
        writeOTACommand(payload)
    }

    private func askOTAByteCount() {
        writeOTACommand(Data.from(GMacroOTAProtocolID.askBytes.rawValue, count: 2))
    }

    private func checkOTAResult() {
        writeOTACommand(Data.from(GMacroOTAProtocolID.checkDfu.rawValue, count: 2))
    }

    private func sendNextOTAData(from index: Int) {
        guard let state = otaState else {
            finishOTAWithFailure("OTA 状态已丢失")
            return
        }
        guard state.byteCount > 0 else {
            finishOTAWithFailure("OTA 单包长度尚未就绪")
            return
        }
        guard index < state.firmware.count else {
            return
        }

        let end = min(index + state.byteCount, state.firmware.count)
        let chunk = state.firmware.subdata(in: index..<end)
        let isLast = end >= state.firmware.count

        otaDataWriter?(chunk) { [weak self] in
            if isLast {
                self?.checkOTAResult()
            }
        }
    }

    private func writeOTACommand(_ body: Data) {
        var packet = Data.from(body.count + 1, count: 1)
        packet.append(body)
        otaCommandWriter?(packet, nil)
    }

    private func finishOTAWithFailure(_ message: String) {
        otaState = nil
        onEvent?(.failure(message))
    }

    private var otaState: GMacroOTAState? {
        get { (objc_getAssociatedObject(self, &otaStateKey) as? GMacroOTAStateBox)?.state }
        set {
            let boxed = newValue.map { GMacroOTAStateBox(state: $0) }
            objc_setAssociatedObject(self, &otaStateKey, boxed, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
