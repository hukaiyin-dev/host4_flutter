//
//  PeripheralManager.swift
//  LED
//
//  Created by hukaiyin on 2023/8/24.
//

import CoreBluetooth
import Foundation

public
final class PeripheralManager: NSObject, CBPeripheralDelegate {
    
    private var sendingData: Data?
    private var sendingIndex: Int = 0
    private var sendingCharacteristic: CBCharacteristic?
    private var sendingType: CBCharacteristicWriteType = .withoutResponse
    private var sendingCompletion: (() -> Void)?
    private var sendingProgress: ((Int, Int) -> Void)?

    
    var peripheral: CBPeripheral {
        didSet {
            peripheral.delegate = self
        }
    }
    
    var characteristicDic: [String: CBCharacteristic] = [:]

    var onMessage: ((Data, CBCharacteristic) -> Void)?
    
    
    var didDiscoverWriteCharacteristic: (([CBCharacteristic]) -> Void)?
    var didSubscribeNotifyCharacteristic: ((CBCharacteristic) -> Void)?

    private var stopSending = false
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        self.peripheral.delegate = self
    }
    
    // MARK: - 通信
    func writeValue(_ data: Data,
                    to uuidString: String,
                    type: CBCharacteristicWriteType = .withoutResponse,
                    sleep: TimeInterval = 0,
                    progress: ((Int, Int) -> Void)? = nil,
                    completion: (() -> Void)? = nil) {
        
        guard let characteristic = characteristicDic[uuidString] else {
            print("没有对应的 characteristic")
            return
        }
        
        sendingProgress = progress
        
        guard characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) else {
            print("⚠️ Characteristic not writable: \(characteristic.uuid)")
            return
        }
        
        stopSending = false
        
        
        // 初始化发送状态
        sendingData = data
        sendingIndex = 0
        sendingCharacteristic = characteristic
        sendingType = type
        sendingCompletion = completion

        print("下发数据 \(uuidString) \(data.nsDescription())")

        // 开始首次发送
        sendChunk()
    }
    
    private func sendChunk() {
        guard let data = sendingData,
              let characteristic = sendingCharacteristic else { return }

        let mtu = peripheral.maximumWriteValueLength(for: sendingType)
        
//        print("mtu \(mtu)")
        let onceDataCount = mtu // 不能乘倍数
        
        while sendingIndex < data.count {
            let end = min(sendingIndex + onceDataCount, data.count)
            let chunk = data.subdata(in: sendingIndex..<end)
            peripheral.writeValue(chunk, for: characteristic, type: sendingType)
            sendingIndex = end

            
            // 回调原始字节数
            sendingProgress?(sendingIndex, data.count)
            
            // 对于 .withoutResponse 类型，可能触发缓冲区满，停止发送，等待回调
            if sendingType == .withoutResponse {
                break
            }
        }

        // 写完所有数据
        if sendingIndex >= data.count {
            sendingCompletion?()
            sendingData = nil
            sendingCharacteristic = nil
        }
    }
    
    
    func setNotify(serviceUUID: CBUUID, characteristicUUID: CBUUID) {
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }),
              let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID }) else {
            return
        }
        peripheral.setNotifyValue(true, for: characteristic)
    }
    
    func cancelSending() {
        stopSending = true
    }
    
    
    // MARK: - CBPeripheralDelegate
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
//            serviceDic[service.uuid] = BaseService(uuid: service.uuid)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("❌ 特征发现失败：\(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
//        print("🔍 发现 service \(service.uuid) 的特征: \(characteristics.map { $0.uuid.uuidString })")
        
        var mDic: [String: CBCharacteristic] = [:]
        
        for characteristic in characteristics {
            mDic[characteristic.uuid.uuidString] = characteristic
            if characteristic.properties.contains(.notify) {
//                print("订阅特征: \(characteristic.uuid)")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
        characteristicDic.merge(mDic) { _, new in new }
        didDiscoverWriteCharacteristic?(characteristics)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        
        if !BluetoothKitConstant.characteristics.contains(characteristic.uuid.uuidString) {
            return
        }
        
        if let error = error {
            print("❌ 特征订阅失败: \(characteristic.uuid.uuidString) \(error.localizedDescription)")
            return
        }
        if characteristic.isNotifying {
            didSubscribeNotifyCharacteristic?(characteristic)
        } else {
            print("❌ 取消订阅特征: \(characteristic.uuid.uuidString) \(characteristic.uuid)")
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else { return }
        
        let uuid = characteristic.uuid.uuidString
        let allowedUUIDs: [String] = ["FF21", "FF22", "FF10", "FF11", "FF12", "FF00", "FF01", "FF02", "00001530-1212-EFDE-1523-785FEABCD123"]
        
        guard allowedUUIDs.contains(uuid), value.count > 0 else {
//            print("📭 忽略无效或未注册特征数据 uuid: \(uuid)")
            return
        }
        
        onMessage?(value, characteristic)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error, (error as NSError).code != 241 {
            print("❌ 写入失败：\(error.localizedDescription)")
        } else {
            print("✅ 写入成功：\(characteristic.uuid)")
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ 描述符发现错误：\(error.localizedDescription)")
        } else {
//            print("🔍 发现描述符：\(characteristic.descriptors?.map { $0.uuid.uuidString } ?? [])")
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        if let error = error {
            print("❌ 描述符更新失败：\(error.localizedDescription)")
        } else {
            print("ℹ️ 描述符更新：\(descriptor.uuid.uuidString) = \(String(describing: descriptor.value))")
        }
    }
    
    
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
//        print("📬 缓冲区已释放，继续发送")
        sendChunk()
    }
}


