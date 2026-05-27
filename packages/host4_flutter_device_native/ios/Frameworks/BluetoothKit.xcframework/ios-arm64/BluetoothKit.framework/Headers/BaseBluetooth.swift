//
//  BaseBluetooth.swift
//  LED
//
//  Created by hukaiyin on 2023/8/24.
//

import CoreBluetooth
import Foundation

final class BaseBluetooth {
    
    nonisolated(unsafe) static let shared = BaseBluetooth()
    
    var peripheralManager: PeripheralManager? {
        guard let peripheralManager = BluetoothManager.shared.peripheralManager else { return nil }
        return peripheralManager
    }
    
    private init() {}
    
    // MARK: - 中央管理
    
    func start() {
        print("🔧 Bluetooth Manager started")
    }
    
    func connectPeripheral(_ peripheral: CBPeripheral, options: [String: Any]? = nil) {

        BluetoothManager.shared.connectPeripheral(peripheral, options: options)
        
    }
    
//    func scanConnect(peripheralName: String, serviceUUIDStrs: [String], stopAfter seconds: Int) {
//        BluetoothManager.shared.scanConnect(peripheralName: peripheralName, serviceUUIDStrs: serviceUUIDStrs, stopAfter: seconds)
//    }
    
    func scan() {
        BluetoothManager.shared.scan()
    }
    
    func stopScan(notif: Bool) {
        BluetoothManager.shared.stopScan(notif: notif)
    }
    
    func cancelPeripheralConnection() {
        if let p = BluetoothManager.shared.peripheralManager?.peripheral {
            BluetoothManager.shared.cancelPeripheralConnection(p)
        }
    }
    
    // MARK: - Peripheral 操作
    
    func writeValue(_ data: Data,
                    to uuidString: String,
                    type: CBCharacteristicWriteType,
                    sleepTime: TimeInterval = 0,
                    progress: ((Int, Int) -> Void)? = nil,
                    completion: (() -> Void)? = nil) {
        peripheralManager?.writeValue(data, to: uuidString, type: type, sleep: sleepTime, progress: progress, completion: completion)
    }
    
    func stopWriting() {
        peripheralManager?.cancelSending()
    }
    
    func onMessage(_ handler: @escaping (Data, CBCharacteristic) -> Void) {
        peripheralManager?.onMessage = handler
    }

    
    // MARK: - 访问属性
    
    var centralManager: CBCentralManager {
        return BluetoothManager.shared.centralManager
    }
    
    var connectedPeripheral: CBPeripheral? {
        return BluetoothManager.shared.peripheralManager?.peripheral
    }
}

@objc
public enum DeviceConnectionStatus: Int {
    case connected      // 已经连上设备
    case disconnected   // 设备已断连
    case failed         // 连接失败
}

@objc
public enum BluetoothScanStatus: Int {
    case scanning   // 正在扫描
    case stopped    // 扫描停止
}
