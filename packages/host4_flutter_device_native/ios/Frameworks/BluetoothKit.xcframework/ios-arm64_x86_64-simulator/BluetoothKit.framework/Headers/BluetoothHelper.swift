//
//  LEDBluetoothHelper.swift
//  LED
//
//  Created by hukaiyin on 2021/3/31.
//  Copyright © 2021 sunday. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc
public protocol BluetoothDelegate: Sendable {
    
    /// 订阅特征后发送第一条消息
    @objc func startCommunication()
    
    /// 处理接收到的上报消息
    @objc func parse(data: Data, uuidString: String)
    
    /// 蓝牙状态改变
    @objc func bluetoothStateDidChange(to state: CBManagerState)
    
    /// 设备连接状态变化
    @objc func deviceConnectionDidChange(status: DeviceConnectionStatus, peripheral: CBPeripheral)
    
    /// 扫描状态变化
    @objc func bluetoothScanStatusDidChange(to status: BluetoothScanStatus)
}

public class BluetoothHelper: NSObject, @unchecked Sendable {
    
    public static let shared: BluetoothHelper = BluetoothHelper()
    
    var uuidDic: Dictionary<CBUUID, CBCharacteristic>? = nil
    
    var delegate: BluetoothDelegate?
    
    /// 发起连接
    public static func connect(peripheral: CBPeripheral) {
        print("🎃 发起连接")
        BaseBluetooth.shared.connectPeripheral(peripheral)
        BaseBluetooth.shared.stopScan(notif: false)
    }
    
    static func start() {
        let _ = self.shared
        shared.checkConnect()
        BaseBluetooth.shared.start()
    }
    
    override init() {
        super.init()
    }
    
    deinit {
        print("BluetoothHelper deinit")
    }
    
//    @objc func writeValue(_ data: Data, to characteristic: CBCharacteristic, type: CBCharacteristicWriteType, sleepTime: TimeInterval = 0, completion: (() -> Void)? = nil) {
//
//        BaseBluetooth.shared.writeValue(data, to: characteristic, type: type, sleepTime: sleepTime, completion: completion)
//    }
    
    @objc func sendOTA()  {
        guard let data = OTAHelper.shared.otaData else {
            print("OTA 空数据")
            return
        }
        OTAHelper.sendOTAData(with: data)
    }
    
    // 发现特征后调用，拿到所有订阅的特征
    func didDiscover(characteristics: [CBCharacteristic])  {
        let uuids = characteristics.map { $0.uuid.uuidString }.joined(separator: ", ")
        print("发现特征: \(uuids)")
        startCommunication(with: characteristics)
    }
    
    func didNotify(characteristic: CBCharacteristic) {
        print("成功订阅特征: \(characteristic.uuid)")
    }
    
    
    @objc func refreshPolling(_ notification: Notification)  {
        if isConnect { isConnect = false }
    }
    
    /// 检查蓝牙连接状况
    func checkConnect(closure: @escaping @Sendable (Bool) -> Void) {
        
        DispatchQueue.global().asyncAfter(deadline: .now()) {
            let c = BluetoothManager.shared.retrieveConnected(peripheralNames: BluetoothKitConstant.deviceNames, serviceUUIDStrs: BluetoothKitConstant.service)
            
            if !c {
                DispatchQueue.global().async {
                    closure(false)
                }
            }
        }
 
        BluetoothManager.shared.onStateChanged = { [unowned self] state in
            DispatchQueue.global().async {
                self.delegate?.bluetoothStateDidChange(to: state)
            }
            print("onStateChanged \(state)")
            if state != .poweredOn {
                DispatchQueue.global().async {
                    closure(false)
                }
            }
        }
        
        BluetoothManager.shared.onConnectionStatusChanged = { [unowned self] (status, peripheral) in
            var isConnect = false
            switch status {
            case .connected:
                isConnect = true
                self.configBBluetooth()
            case .failed:
                break
            case .disconnected:
                break
            }
            
            if status != .disconnected {
                DispatchQueue.global().async {
                    closure(isConnect)
                }
            }
            
            self.delegate?.deviceConnectionDidChange(status: status, peripheral: peripheral)
        }
        
        BluetoothManager.shared.onScanStatusChanged = { [unowned self] status in
            self.delegate?.bluetoothScanStatusDidChange(to: status)
        }
    }
    
    /// 配置蓝牙库回调
    func configBBluetooth() {
        
        BaseBluetooth.shared.peripheralManager?.didDiscoverWriteCharacteristic = self.didDiscover(characteristics:)
        BaseBluetooth.shared.peripheralManager?.didSubscribeNotifyCharacteristic = self.didNotify(characteristic:)
        
        OTAHelper.shared.otaReadyClosure = self.sendOTA
        
        // 收到外设上报的协议信息
        BaseBluetooth.shared.onMessage { (data, characteristic) in
            BluetoothHelper.shared.parse(data, characteristic: characteristic)
        }
    }
    
    // MARK: - Timer
    
    var timer: DispatchSourceTimer?
    var polling: Bool = false
    public private(set) var isConnect: Bool = false {
        didSet {
            if !isConnect {
                startPolling()
            } else {
                endPolling()
            }
        }
    }
    var dontCheck = false
    
    var sending = false
    var sn: Int = 1
    var bluetoothSN: Int = 1
}

extension BluetoothHelper {
    func update(connect: Bool) {
        isConnect = connect
    }
}

extension BluetoothHelper {
    
    /// 处理接收到的数据
    /// OTA 的自动处理，其它的等造 Protocol xcframework 后再看怎么用
    func parse(_ data: Data, characteristic: CBCharacteristic) {
        print("收到外设上报的协议信息 \(characteristic.uuid.uuidString) \(data.nsDescription())")
        
        
        let uuidString = characteristic.uuid.uuidString
        
        if !BluetoothKitConstant.availableCharacteristics.contains(uuidString) {
            print("⚠️ 未知特征: \(uuidString)")
            return
        }
        
        let isOTA = BluetoothKitConstant.otaCharacteristics.contains(uuidString)
        
        if isOTA {
            // 命令 ID
            let otaPIdData = data.subdata(in: Range(NSRange(location: 1, length: 2))!)
            
            let otaPIdInt: Int = otaPIdData.toInt()
            let pId: OTAProtocolID = OTAProtocolID(rawValue: otaPIdInt)!
            let otherData = data.subdata(in: Range(NSRange(location: 3, length: data.count - 3))!)
            OTAHelper.parse(protocolId: pId, otherData: otherData)
        } else {
            if data.count < 2 {
                print("长度错误")
                return;
            }
//            let l = data.subdata(in: Range(NSRange(location: 0, length: 1))!)
//            if l.toInt() != data.count {
//                print("长度错误")
//                return;
//            }
            
            delegate?.parse(data: data, uuidString: characteristic.uuid.uuidString)
        }
    }
}

extension BluetoothHelper {
    
    @objc
    public func testBluetoothKit() {
        print("能调用到 BluetoothKit")
    }
    
    @objc
    public func start(with delegate: BluetoothDelegate,
                      otaDelegate: OTADelegate) {
        
        
        self.delegate = delegate
        OTAHelper.shared.delegate = otaDelegate
        BluetoothHelper.start()
    }
    
    @objc
    public func updateUUIDs(with deviceNames: [String],
                            service: String,
                            commandCharacteristic: String,
                            dataCharacteristic: String,
                            otaService: String,
                            otaCommandCharacteristic: String,
                            otaDataCharacteristic: String) {
        
        let deviceNames = deviceNames + [BluetoothKitConstant.simulateDeviceName]
        BluetoothKitConstant.deviceNames = deviceNames
        
        BluetoothKitConstant.service.appendIfNotContains(service)
        BluetoothKitConstant.commandCharacteristic = commandCharacteristic
        BluetoothKitConstant.dataCharacteristic = dataCharacteristic
        
        let serviceUUID = CBUUID(string: service)
        let characteristicUUID = CBUUID(string: commandCharacteristic)
        BaseBluetooth.shared.peripheralManager?.setNotify(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        
       
        if let characteristicDic = BaseBluetooth.shared.peripheralManager?.characteristicDic {
            let keys = [commandCharacteristic, dataCharacteristic]
            let characteristics = keys.compactMap { characteristicDic[$0] }
            BluetoothHelper.shared.startCommunication(with: characteristics)
        }
        
        
//        BluetoothKitConstant.service = [otaService]
        BluetoothKitConstant.service.appendIfNotContains(otaService)
        BluetoothKitConstant.otaService = otaService
        BluetoothKitConstant.otaCommandCharacteristic = otaCommandCharacteristic
        BluetoothKitConstant.otaDataCharacteristic = otaDataCharacteristic
    }
    
    /// SDK 开发者调试用，使用者勿调
    public func updateDebugger(_ handler: @escaping (_ items: [Any], _ separator: String, _ terminator: String) -> Void) {
        BluetoothKitConstant.logHandler = handler
    }
    
    @objc
    public func scan(closure: @escaping (CBPeripheral, String, Data, NSNumber)->()) {
        
        stopScan()
        BaseBluetooth.shared.scan()

        BluetoothHelper.shared.startPolling()
                
        BluetoothManager.shared.discoveryHandler = { (manager, peripheral, cName, manufacturerData, RSSI) in
            guard let name = peripheral.name else { return }
            for deName in BluetoothKitConstant.deviceNames {
                if name.contains(deName) || cName.contains(deName)  {
                    let displayName = cName
                    closure(peripheral, displayName, manufacturerData, RSSI)
                }
            }
        }
    }
    
    @objc
    public func stopScan() {
        BaseBluetooth.shared.stopScan(notif: true)
    }
    
    @objc
    public func writeValue(_ data: Data,
                           to uuidString: String,
                           type: CBCharacteristicWriteType,
                           sleepTime: TimeInterval = 0,
                           progress: ((Int, Int) -> Void)? = nil,
                           completion: (() -> Void)? = nil) {
        BaseBluetooth.shared.writeValue(data, to: uuidString, type: type, sleepTime: sleepTime, progress: progress, completion: completion)
    }
}
