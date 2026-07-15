////
////  IAP2Manager.swift
////  MFiKit
////
////  Created by hukaiyin on 2025/11/5.
////
//
//import Foundation
//import ExternalAccessory
//
//final class IAP2Manager: NSObject {
//
//    private var inputOpened = false
//    private var outputWritable = false
//    private var session: EASession?
//    private var inStream: InputStream?
//    private var outStream: OutputStream?
//
//    public var onTx: ((Data) -> Void)?
//    public var onRx: ((Data) -> Void)?
//    public var onErrorOccurred: ((Error) -> Void)?
//    public var onDeviceConnected: (() -> Void)?
//    public var onDeviceDisconnected: (() -> Void)?
//    public var onDeviceConnectionFailed: (() -> Void)?
//
//    private var protocolString: String?
//    private var isPendingConnect = false
//
//    override init() {
//        super.init()
//        EAAccessoryManager.shared().registerForLocalNotifications()
//        NotificationCenter.default.addObserver(self, selector: #selector(accessoryDidConnect(_:)), name: .EAAccessoryDidConnect, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(accessoryDidDisconnect(_:)), name: .EAAccessoryDidDisconnect, object: nil)
//    }
//
//    deinit {
//        NotificationCenter.default.removeObserver(self)
//    }
//
//    public func updateProtocol(protocolString: String) {
//        self.protocolString = protocolString
//    }
//
//    public func connect() {
//        guard let protocolString = protocolString else {
//            let error = NSError(domain: "IAP2Manager", code: -1, userInfo: [NSLocalizedDescriptionKey: "协议字符串为空"])
//            onErrorOccurred?(error)
//            onDeviceConnectionFailed?()
//            return
//        }
//
//        let accessories = EAAccessoryManager.shared().connectedAccessories
//        if let accessory = accessories.first(where: { $0.protocolStrings.contains(protocolString) }) {
//            isPendingConnect = false
//            openSession(with: accessory, protocolString: protocolString)
//            return
//        }
//
//        isPendingConnect = true
//        let error = NSError(domain: "IAP2Manager", code: -1, userInfo: [NSLocalizedDescriptionKey: "未找到设备，等待设备连接"])
//        onErrorOccurred?(error)
//        onDeviceConnectionFailed?()
//    }
//
//    private func openSession(with accessory: EAAccessory, protocolString: String) {
//        guard let session = EASession(accessory: accessory, forProtocol: protocolString) else {
//            let error = NSError(domain: "IAP2Manager", code: -1, userInfo: [NSLocalizedDescriptionKey: "EASession 创建失败"])
//            onErrorOccurred?(error)
//            onDeviceConnectionFailed?()
//            return
//        }
//
//        self.session = session
//        self.inStream = session.inputStream
//        self.outStream = session.outputStream
//        setupStreams()
//    }
//
//    private func setupStreams() {
//        guard let inStream = inStream, let outStream = outStream else {
//            let error = NSError(domain: "IAP2Manager", code: -1, userInfo: [NSLocalizedDescriptionKey: "输入或输出流未初始化"])
//            onErrorOccurred?(error)
//            onDeviceConnectionFailed?()
//            return
//        }
//
//        inStream.delegate = self
//        outStream.delegate = self
//        inStream.schedule(in: .main, forMode: .common)
//        outStream.schedule(in: .main, forMode: .common)
//        inStream.open()
//        outStream.open()
//        onDeviceConnected?()
//    }
//
//    func sendData(_ data: Data) -> String {
//        guard let outStream = outStream else { return "尚未连接" }
//        let bytesWritten = data.withUnsafeBytes {
//            outStream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
//        }
//        if bytesWritten < 0 {
//            let error = outStream.streamError ?? NSError(domain: "IAP2Manager", code: -1, userInfo: [NSLocalizedDescriptionKey: "发送失败"])
//            onErrorOccurred?(error)
//            return "发送失败"
//        } else {
//            onTx?(data)
//            return "已发送 \(bytesWritten)/\(data.count) 字节"
//        }
//    }
//
//    func disconnect() {
//        isPendingConnect = false
//        guard let inStream = inStream, let outStream = outStream else { return }
//        inStream.close()
//        outStream.close()
//        session = nil
//        self.inStream = nil
//        self.outStream = nil
//        onDeviceDisconnected?()
//    }
//
//    @objc private func accessoryDidConnect(_ notification: Notification) {
//        guard let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory else { return }
//        guard isPendingConnect, let protocolString = protocolString else { return }
//        guard accessory.protocolStrings.contains(protocolString) else { return }
//        isPendingConnect = false
//        openSession(with: accessory, protocolString: protocolString)
//    }
//
//    @objc private func accessoryDidDisconnect(_ notification: Notification) {
//        guard let _ = notification.userInfo?[EAAccessoryKey] as? EAAccessory else { return }
//    }
//}
//
//extension IAP2Manager: StreamDelegate {
//    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
//        if eventCode.contains(.openCompleted) {
//            if aStream == inStream { inputOpened = true }
//            if aStream == outStream { outputWritable = true }
//        }
//        if eventCode.contains(.hasSpaceAvailable), aStream == outStream {
//            outputWritable = true
//        }
//        if eventCode.contains(.hasBytesAvailable), aStream == inStream {
//            var buffer = [UInt8](repeating: 0, count: 1024)
//            if let count = inStream?.read(&buffer, maxLength: buffer.count), count > 0 {
//                let data = Data(buffer.prefix(count))
//                onRx?(data)
//            }
//        }
//        if eventCode.contains(.errorOccurred) {
//            let error = aStream.streamError ?? NSError(domain: "IAP2Manager", code: -1, userInfo: [NSLocalizedDescriptionKey: "流错误"])
//            onErrorOccurred?(error)
//        }
//        if eventCode.contains(.endEncountered) {
//            disconnect()
//        }
//    }
//}


import Foundation
import ExternalAccessory

final class IAP2Manager: NSObject {
    
    // 连接状态
    private var inputOpened = false
    private var outputWritable = false
    
    private var session: EASession?
    private var inStream: InputStream?
    private var outStream: OutputStream?
    private var outputReadyNotified = false
    
    // 回调
    public var onTx: ((Data) -> Void)?
    public var onRx: ((Data) -> Void)?
    public var onErrorOccurred: ((Error) -> Void)?
    public var onDeviceConnected: (() -> Void)?
    public var onDeviceDisconnected: (() -> Void)?
    public var onDeviceConnectionFailed: (() -> Void)?
    public var onOutputReady: (() -> Void)?

    /// IAP2 握手完成标志，由外部（MFiKitHelper / MFiTransportSession）设置
    public var isCompleted: Bool = false

    /// 已有活跃会话时复用，由外部注入替代 MFiKitHelper.shared 调用
    public var onReuseSession: (() -> Void)?

    // 协议字符串
    private var protocolString: String?
    
    // 是否在等待设备插入（用户已经点击“连接”，但暂时没找到设备）
    private var isPendingConnect = false
    // 主动断开时不等待自动重连；固件升级完成后设备重启导致的被动断开需要等待重连。
    private var isClosingIntentionally = false
    
    // MARK: - 生命周期
    
    override init() {
        super.init()
        print("[IAP2] init IAP2Manager")
        
        EAAccessoryManager.shared().registerForLocalNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessoryDidConnect(_:)),
            name: .EAAccessoryDidConnect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessoryDidDisconnect(_:)),
            name: .EAAccessoryDidDisconnect,
            object: nil
        )
        
        // 启动时打印一下当前已连接的配件情况
        let accessories = EAAccessoryManager.shared().connectedAccessories
        print("[IAP2] init: 当前已连接配件数量: \(accessories.count)")
        for acc in accessories {
            print("[IAP2]  - \(acc.name), protocols: \(acc.protocolStrings)")
        }
    }
    
    deinit {
        print("[IAP2] deinit IAP2Manager")
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 协议配置
    
    public func updateProtocol(protocolString: String) {
        self.protocolString = protocolString
        print("[IAP2] updateProtocol: \(protocolString)")
    }
    
    // 当前是否已有有效的会话与流
    private func isSessionActive() -> Bool {
        return session != nil &&
               inStream != nil &&
               outStream != nil &&
               (inputOpened || outputWritable)
    }
    
    // MARK: - 连接设备
    
    public func connect() {
        print("[IAP2] connect() called, isPendingConnect = \(isPendingConnect)")
        // 每次主动发起连接时清掉历史主动断开标记，避免后续固件重启造成的 endEncountered 被误判为主动断开。
        isClosingIntentionally = false
        
        guard let protocolString = protocolString else {
            let error = NSError(
                domain: "IAP2Manager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "协议字符串为空"]
            )
            print("[IAP2] connect: 协议字符串为空")
            onErrorOccurred?(error)
            return
        }
        
        // 避免重复创建会话：如果已经有有效的会话与流，直接返回
        if isSessionActive() {
            print("[IAP2] connect: 已存在有效会话与流，跳过重复连接")
            isPendingConnect = false
            if isCompleted {
                print("[IAP2] connect: 复用会话，自动推送连接成功")
                onReuseSession?()
            }
            return
        }
        
        let accessories = EAAccessoryManager.shared().connectedAccessories
        print("[IAP2] connect: 当前已连接配件数量: \(accessories.count)")
        for acc in accessories {
            print("[IAP2]  - \(acc.name), protocols: \(acc.protocolStrings)")
        }
        
        // 1. 先看看当前是否已经有匹配的 accessory
        if let accessory = accessories.first(where: { $0.protocolStrings.contains(protocolString) }) {
            print("[IAP2] connect: 找到已连接的设备: \(accessory.name)，准备创建 session")
            isPendingConnect = false
            openSession(with: accessory, protocolString: protocolString)
            return
        }
        
        // 2. 当前没找到设备：进入“等待设备连接”的状态
        print("[IAP2] connect: 未找到支持协议 \(protocolString) 的设备，进入等待设备连接状态")
        isPendingConnect = true
        
        let error = NSError(
            domain: "IAP2Manager",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "未找到设备，等待设备连接"]
        )
        onErrorOccurred?(error)
    }
    
    // 真正创建 EASession 的逻辑单独抽出来
    private func openSession(with accessory: EAAccessory, protocolString: String) {
        print("[IAP2] openSession: accessory = \(accessory.name), protocol = \(protocolString)")
        // 新 session 已经开始建立，后续流结束应按当前连接状态重新判断，不能沿用旧的主动断开标记。
        isClosingIntentionally = false
        
        // 如果已经有活跃会话，直接复用，不再创建新的
        if isSessionActive() {
            print("[IAP2] openSession: 已有活跃会话，跳过创建")
            return
        }
        
        guard let session = EASession(accessory: accessory, forProtocol: protocolString) else {
            let error = NSError(
                domain: "IAP2Manager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "EASession 创建失败"]
            )
            print("[IAP2] openSession: EASession 创建失败")
            onErrorOccurred?(error)
            onDeviceConnectionFailed?()
            return
        }
        
        self.session = session
        self.inStream = session.inputStream
        self.outStream = session.outputStream
        
        print("[IAP2] openSession: session 创建成功，准备设置流")
        setupStreams()
    }
    
    // 设置流
    private func setupStreams() {
        print("[IAP2] setupStreams called")
        
        guard let inStream = inStream, let outStream = outStream else {
            let error = NSError(
                domain: "IAP2Manager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "输入或输出流未初始化"]
            )
            print("[IAP2] setupStreams: 输入或输出流未初始化")
            onErrorOccurred?(error)
            onDeviceConnectionFailed?()
            return
        }
        
        inStream.delegate = self
        outStream.delegate = self
        
        inStream.schedule(in: .main, forMode: .common)
        outStream.schedule(in: .main, forMode: .common)
        
        outputReadyNotified = false
        
        print("[IAP2] setupStreams: 打开输入输出流")
        inStream.open()
        outStream.open()
        
        print("[IAP2] IAP2 设备已连接，开始通信（流已打开）")
        onDeviceConnected?()
    }
    
    //发送数据
    func sendData(_ data: Data) throws -> String {
        guard let outStream = outStream else {
            print("[IAP2] sendData: 尚未连接")
            throw NSError(
                domain: "IAP2Manager",
                code: -10,
                userInfo: [NSLocalizedDescriptionKey: "尚未连接"]
            )
        }
        
        if !isCompleted {
            print("[IAP2] sendData: IAP2 尚未完成握手，无法发送数据")
            throw NSError(
                domain: "IAP2Manager",
                code: -11,
                userInfo: [NSLocalizedDescriptionKey: "IAP2 尚未完成握手，无法发送数据"]
            )
        }
        
        if !Thread.isMainThread {
            var result: Result<String, Error>!
            DispatchQueue.main.sync {
                result = Result { try self.performWrite(data) }
            }
            return try result.get()
        }
        return try performWrite(data)
    }

    private func performWrite(_ data: Data) throws -> String {
        guard let outStream = outStream else {
            print("[IAP2] performWrite: 流已释放")
            throw NSError(
                domain: "IAP2Manager",
                code: -12,
                userInfo: [NSLocalizedDescriptionKey: "流已释放"]
            )
        }

        let bytesWritten = try data.withUnsafeBytes { rawBuffer -> Int in
            guard let baseAddress = rawBuffer.bindMemory(to: UInt8.self).baseAddress else {
                return 0
            }

            var totalWritten = 0
            while totalWritten < data.count {
                let count = outStream.write(baseAddress.advanced(by: totalWritten),
                                            maxLength: data.count - totalWritten)
                if count < 0 {
                    let error = outStream.streamError ?? NSError(
                        domain: "IAP2Manager",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "发送失败"]
                    )
                    print("[IAP2] sendData: 发送失败，error = \(String(describing: outStream.streamError))")
                    onErrorOccurred?(error)
                    throw error
                }
                if count == 0 {
                    let error = NSError(
                        domain: "IAP2Manager",
                        code: -13,
                        userInfo: [NSLocalizedDescriptionKey: "发送失败：输出流未写入数据"]
                    )
                    print("[IAP2] sendData: 发送失败，write 返回 0")
                    onErrorOccurred?(error)
                    throw error
                }
                totalWritten += count
            }
            return totalWritten
        }

        print("[IAP2] sendData: 发送 \(data.count) 字节: \(data.map { String(format: "%02X", $0) }.joined())")
        print("[IAP2] sendData: 已发送 \(bytesWritten)/\(data.count) 字节")
        onTx?(data)
        return "已发送 \(bytesWritten)/\(data.count) 字节"
    }
    
    //发送连接测试数据
    func sendDataWithConnect(_ data: Data) -> String {
        guard let outStream = outStream else {
            print("[IAP2] sendData: 尚未连接")
            return "尚未连接"
        }
        
        let bytesWritten = data.withUnsafeBytes {
            outStream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
        }
        
        if bytesWritten < 0 {
            let error = outStream.streamError ?? NSError(
                domain: "IAP2Manager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "发送失败"]
            )
            print("[IAP2] sendData: 发送失败，error = \(String(describing: outStream.streamError))")
            onErrorOccurred?(error)
            return "发送失败"
        } else {
            
            print("[IAP2] sendData: 已发送 \(bytesWritten)/\(data.count) 字节")
            onTx?(data)
            return "已发送 \(bytesWritten)/\(data.count) 字节"
        }
    }
    
    // 断开连接
    func disconnect(keepPendingConnect: Bool = false) {
        print("[IAP2] disconnect called")
        isPendingConnect = keepPendingConnect
        if !keepPendingConnect {
            isClosingIntentionally = true
        }
        
//        MFiKitHelper.shared.isIap2Completed = false
//        MFiKitHelper.shared.iap2SendCount = 0
        
        guard let inStream = inStream, let outStream = outStream else {
            print("[IAP2] disconnect: 流已为空，无需处理")
            return
        }
        
        inStream.close()
        outStream.close()
        
        session = nil
        self.inStream = nil
        self.outStream = nil
        outputReadyNotified = false
        inputOpened = false
        outputWritable = false
        
        
        print("[IAP2] disconnect: 已关闭流并清理 session")
        
        onDeviceDisconnected?()
    }
    
    // MARK: - MFi 设备插拔通知处理
    
    @objc private func accessoryDidConnect(_ notification: Notification) {
        guard let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory else {
            print("[IAP2] accessoryDidConnect: 无 EAAccessoryKey")
            return
        }
        print("[IAP2] accessoryDidConnect: \(accessory.name), protocols = \(accessory.protocolStrings), isPendingConnect = \(isPendingConnect)")
        
        // 如果会话已活跃，忽略重复创建
        if isSessionActive() {
            print("[IAP2] accessoryDidConnect: 已有活跃会话，忽略")
            return
        }
        
        guard isPendingConnect, let protocolString = protocolString else {
            print("[IAP2] accessoryDidConnect: 非等待状态或协议为空，忽略本次连接")
            return
        }
        
        guard accessory.protocolStrings.contains(protocolString) else {
            print("[IAP2] accessoryDidConnect: 该设备不支持当前协议 \(protocolString)，忽略")
            return
        }
        
        print("[IAP2] accessoryDidConnect: 检测到匹配协议的设备，自动创建 session")
        isPendingConnect = false
        openSession(with: accessory, protocolString: protocolString)
    }
    
    @objc private func accessoryDidDisconnect(_ notification: Notification) {
        guard let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory else {
            print("[IAP2] accessoryDidDisconnect: 无 EAAccessoryKey")
            return
        }
        
        print("[IAP2] accessoryDidDisconnect: \(accessory.name)")
        // 当前断开逻辑在 stream 的 endEncountered / disconnect() 里处理
    }
}

extension IAP2Manager: StreamDelegate {

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        let streamDesc: String
        if aStream == inStream {
            streamDesc = "InputStream"
        } else if aStream == outStream {
            streamDesc = "OutputStream"
        } else {
            streamDesc = "UnknownStream"
        }
        
        print("[IAP2] stream event: \(streamDesc), eventCode = \(eventCode)")
        
        // 当流打开完成时
        if eventCode.contains(.openCompleted) {
            print("[IAP2] stream: \(streamDesc) openCompleted")
            if aStream == inStream { inputOpened = true }
            if aStream == outStream { outputWritable = true }
            
            if aStream == outStream {
                outputWritable = true
                if !outputReadyNotified {
                    outputReadyNotified = true
                
                    print("[IAP2] stream: OutputStream ready (openCompleted), firing onOutputReady")
                        
                    onOutputReady?()
                }
            }
        }

        // 输出流有空间可写
        if eventCode.contains(.hasSpaceAvailable), aStream == outStream {
            print("[IAP2] stream: OutputStream hasSpaceAvailable")
            outputWritable = true
            
            if !outputReadyNotified {
                outputReadyNotified = true
                
                print("[IAP2] stream: OutputStream ready (hasSpaceAvailable), firing onOutputReady")
                onOutputReady?()
            }
        }

        // 输入流有数据可读
        if eventCode.contains(.hasBytesAvailable), aStream == inStream {
            print("[IAP2] stream: InputStream hasBytesAvailable")
            var buffer = [UInt8](repeating: 0, count: 1024)
            if let count = inStream?.read(&buffer, maxLength: buffer.count), count > 0 {
                let data = Data(buffer.prefix(count))
                print("[IAP2] stream: 读取到 \(count) 字节数据")
                onRx?(data)
            } else {
                print("[IAP2] stream: read 返回 <= 0")
            }
        }

        // 发生错误
        if eventCode.contains(.errorOccurred) {
            let error = aStream.streamError ?? NSError(
                domain: "IAP2Manager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "流错误"]
            )
            print("[IAP2] stream: \(streamDesc) errorOccurred: \(String(describing: aStream.streamError))")
            onErrorOccurred?(error)
        }

        // 流结束
        if eventCode.contains(.endEncountered) {
            let shouldWaitForReconnect = !isClosingIntentionally
            if shouldWaitForReconnect {
                print("[IAP2] stream: \(streamDesc) endEncountered，准备断开连接并等待设备重新建立 MFi session")
            } else {
                print("[IAP2] stream: \(streamDesc) endEncountered，主动断开流程，不等待重连")
            }
            disconnect(keepPendingConnect: shouldWaitForReconnect)
            if !shouldWaitForReconnect {
                isClosingIntentionally = false
            }
        }
    }
}
