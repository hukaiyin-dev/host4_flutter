//
//  DataHelper.swift
//  LEDSDK
//
//  Created by hukaiyin on 2023/2/27.
//

import UIKit

public protocol GMacroDataDelegate: AnyObject {
    func progress(_ progress: CGFloat)
    func success()
    func error(_ message: String)
    func onceByteCount() -> Int
    //0x07按键上报
    func receiveTestKeys(_ keys: [GamepadKey], j1x: Int, j1y: Int, j2x: Int, j2y: Int, l2: Int, r2: Int)
    func receiveConfigKeys(_ keys: [GamepadKey])
    
    func receiveTestKeyboardMouse(_ modifierKeys: [ModifierKey], keyboardKeys: [KeyboardKey], mouseCores: [MouseCoreButton], mouseWheels: [MouseWheelButton], mouseX: Int8, mouseY: Int8, mediaKeys: [MediaKey])
    
    //宏录制接收的子按键数据0x48
    func receiveRecordKeys(_ value: MacroComkeyBridge)
    
    //宏录制接收到停止上报0x49
    func endRecordKeys(_ code: Int)
    
    //校准完成4301 5702 5703
    func finishCalibration(_ type: Int, subId : Int, result : Int, param1 : [Int], param2 : [Int])
    
    //连接状态0x74 02
    func devConnectState(_ state : Int)
    
    //按键状态上报 7406
    func receiveDevKeysState(_ keys: [GamepadKey], j1x: Int, j1x_o : Int, j1y: Int, j1y_o : Int, j2x: Int, j2x_o : Int, j2y: Int, j2y_o : Int,  l2: Int, l2_o: Int, r2: Int, r2_o: Int)
}

public class DataHelper: NSObject, @unchecked Sendable {

    var writeQueue = [(protocolID: GMacroProtocolID, datas: [Data], finish: (() -> Void)?, response: @Sendable (Result<[String: Any], Error>) -> Void)]()
    var isWriting = false
    
    var pendingResponses: [ResponseKey: (Result<[String: Any], Error>) -> Void] = [:]
//    var pendingResponses: [GMacroProtocolID: (Result<[String: Any], Error>) -> Void] = [:]
    let callbackQueue = DispatchQueue(label: "com.bluetooth.responseQueue", attributes: .concurrent)
    
    weak var delegate: GMacroDataDelegate?

    /// session 化发送钩子，由 GMacroProtocolSession 在 init 时注入。
    /// 必须在调用任何写操作前设置，否则触发 assertionFailure。
    public typealias SendPacketHandler = (
        _ data: Data,
        _ totalCount: Int,
        _ sentCount: Int,
        _ uuidString: String,
        _ silent: Bool,
        _ finish: (() -> Void)?,
        _ response: ((NSDictionary?, NSError?) -> Void)?
    ) -> Void
    var sendPacketHandler: SendPacketHandler?

    var sn: Int = 1
    var oneByteSN: Int = 1
    var bluetoothSN: Int = 1
    
    // 分包处理
    var keepReceive = false
    var receivingData = Data()
    var expectedPacketCount: Int = 0
    var receivedPacketCount: Int = 0
    var currentReceivingProtocolID: GMacroProtocolID?
    var currentReceivingSubID: UInt8 = 0 {
        didSet {
            print("currentReceivingSubId \(currentReceivingSubID)")
        }
    }
    var currentReceivingSN: UInt8 = 0
    
    override init() {
        super.init()
//        NotificationCenter.default.addObserver(self, selector: #selector(dataProgress(_ :)), name: .sendingDataProgress, object: nil);
//        NotificationCenter.default.addObserver(self, selector: #selector(dataEnd(_ :)), name: .endSendData, object: nil)
    }
    
    public func setup(with delegate: GMacroDataDelegate) {
        self.delegate = delegate
    }
    
    
    func resetData() {
//        sn = 1
//        oneByteSN = 1
////        shared.sendingDataDic.removeAll()
//        pendingResponses = [:]
//        OTAHelper.shared.otaData = nil
//        OTAHelper.shared.updating = false
    }
} 
struct ResponseKey: Hashable, CustomStringConvertible {
    let protocolID: GMacroProtocolID
    let sn: UInt8

    var description: String {
        return "(\(protocolID), sn: \(sn))"
    }
}
extension DataHelper {
    @objc func dataProgress(_ notification: Notification) {
        guard let progress: CGFloat = notification.object as? CGFloat else {
            return
        }
        if let delegate = delegate {
            delegate.progress(progress)
        }
    }
    
    @objc func dataEnd(_ notification: Notification) {
        if let delegate = delegate {
            delegate.success()
        }
    }
}


