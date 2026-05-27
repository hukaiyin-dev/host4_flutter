//
//  BluetoothManager.swift
//  LED
//
//  Created by hukaiyin on 2023/8/24.
//

import CoreBluetooth
import Foundation

public
final class BluetoothManager: NSObject , @unchecked Sendable {
    
    static let shared = BluetoothManager()
    
    var centralManager: CBCentralManager!
    
    var peripheralManager: PeripheralManager? {
        return _peripheralManager
    }
    private var _peripheralManager: PeripheralManager?
    
    public private(set) var currentState: CBManagerState = .unknown

    // 发现外设时
    var discoveryHandler: ((CBCentralManager, CBPeripheral, String, Data, NSNumber) -> Void)?
    var onStateChanged: ((CBManagerState) -> Void)?
    var onConnectionStatusChanged: ((DeviceConnectionStatus, CBPeripheral) -> Void)?
    var onScanStatusChanged: ((BluetoothScanStatus) -> Void)?

    private var stopScanAfterConnect = false
    
    private var connectingPeripheral: CBPeripheral?
    
    private override init() {
        super.init()
        
        print("CBCentralManagerDelegate")
        
        let queue = DispatchQueue(label: "centralQueue")
        
        centralManager = CBCentralManager(delegate: self, queue: queue, options: [
            CBCentralManagerOptionShowPowerAlertKey: false
        ])
    }
    
    func scan() {
        scanPeripherals(seconds: 6000)
    }
    
    
    func connectPeripheral(_ peripheral: CBPeripheral, options: [String: Any]? = nil) {
        _peripheralManager = PeripheralManager(peripheral: peripheral)

        connectingPeripheral = peripheral
        centralManager.connect(peripheral, options: options)
    }
    
    func stopScan(notif: Bool ) {
        centralManager.stopScan()
        if notif {
            onScanStatusChanged?(.stopped)
        }
    }
    
    func cancelPeripheralConnection(_ peripheral: CBPeripheral) {
        stopScan(notif: true)
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    private func scanPeripherals(seconds: Int) {
        onScanStatusChanged?(.scanning)
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false,
            CBCentralManagerOptionShowPowerAlertKey: true
        ])
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds)) {
            self.stopScan(notif: true)
        }
    }
    
    func retrieveConnected(peripheralNames: [String], serviceUUIDStrs: [String]) -> Bool {
        let serviceUUIDs = serviceUUIDStrs.map { CBUUID(string: $0) }
        let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs)
        
        for peripheral in connectedPeripherals {
            guard let name = peripheral.name else { continue }
//            print("已连接 peripheral.name \(name) \(peripheralNames)")
            if peripheralNames.contains(where: { name.contains($0) }) {
                return true
            }
        }
        return false
    }
    
    //2026.5.22 适配系统已连接的设备，直接使用系统的 CBPeripheral 对象进行通信，避免重复连接导致的断连问题
    func adoptConnectedPeripheralFromSystem(_ peripheral: CBPeripheral) {
        print("复用系统已连接设备: \(peripheral.name ?? "unknown"), state: \(peripheral.state.rawValue)")

        if peripheral.state != .connected {
            print("系统返回了设备，但当前 central 尚未处于 connected，改为发起 connect")
            connectPeripheral(peripheral)
            return
        }

        _peripheralManager = PeripheralManager(peripheral: peripheral)
        connectingPeripheral = nil

        var didReportConnected = false
        _peripheralManager?.didDiscoverWriteCharacteristic = { [weak self] _ in
            guard didReportConnected == false else { return }
            didReportConnected = true
            self?.onConnectionStatusChanged?(.connected, peripheral)
        }

        _peripheralManager?.peripheral.discoverServices(nil)
    }
    
    private func serviceUUIDs(from strings: [String]) -> [CBUUID] {
        return strings.map { CBUUID(string: $0) }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        currentState = central.state

        onStateChanged?(central.state)
    }
    
    public func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advName ?? peripheral.name ?? ""
        if name.count == 0 {
            return
        }
        
        print("发现设备 name: \(name) \(String(describing: advName))")
       
        var manufacturerData = Data()
        
        let matched = BluetoothKitConstant.deviceNames.contains { name.contains($0) }

//        print("Data.from(0x0300, count: 6) \(Data.from(0x0300, count: 6))")

        if matched {
//            for (key, value) in advertisementData {
//                print("📦 广播字段 key: \(key), value: \(value)")
//            }
            
            // 获取固件自定义广播内容
             if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                 manufacturerData = data
//                 print("🔍 广播 Manufacturer Data: \(manufacturerData.nsDescription())")
             }
        }
#if DEBUG
        if name == BluetoothKitConstant.simulateDeviceName {
            // 模拟 3.0 的设备广播
            manufacturerData =  Data.from(0x0300, count: 6)
            print("模拟 3.0 的设备广播")
        }
#endif
//        print("manufacturerData.count \(manufacturerData.count)")

        discoveryHandler?(central, peripheral, name, manufacturerData, RSSI)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("设备已连接")
        _peripheralManager = PeripheralManager(peripheral: peripheral)
        _peripheralManager?.peripheral.discoverServices(nil)
        
        connectingPeripheral = nil
        
        onConnectionStatusChanged?(.connected, peripheral)
        if stopScanAfterConnect {
            self.stopScan(notif: true)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectingPeripheral = nil
        print("🔴 error \(String(describing: error))")
        onConnectionStatusChanged?(.failed, peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == _peripheralManager?.peripheral {
            _peripheralManager = nil
        }
        connectingPeripheral = nil
        
        if BluetoothHelper.shared.isConnect == true {
            print("centralManager 断连")
            // 已经断连（可能是主动触发）不再循环检测是否连接，需下次发起扫描连接再开始检测
            BluetoothHelper.shared.dontCheck = true
            onConnectionStatusChanged?(.disconnected, peripheral)
        }
    }
    
}

public
extension BluetoothHelper {
    @objc
    func currentStatusKey() -> String {
        let state = BluetoothManager.shared.currentState
        switch state {
        case .poweredOn:
            return "poweredOn"
        case .poweredOff:
            return "poweredOff"
        case .unauthorized:
            return "unauthorized"
        default:
            return "unknown"
        }
    }
}
