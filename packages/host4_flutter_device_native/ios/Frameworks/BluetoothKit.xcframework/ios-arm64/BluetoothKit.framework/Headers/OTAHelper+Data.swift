//
//  BluetoothHelper+OTA.swift
//  LED
//
//  Created by hukaiyin on 2021/4/13.
//  Copyright © 2021 sunday. All rights reserved.
//

import Foundation

public
extension OTAHelper {
    
    /// 查询ble设备OTA是否准备就绪，并附带CRC-CCITT标准校验值，和数据长度信息
    static func dfuReadyCheak(_ d: Data) {
        OTAHelper.shared.otaData = d
        
        var data = OTAProtocolID.dfuReady.data

        let crc: Int = Int(d.crc16ccitt_xmodem())
        let crcData = Data.from(crc, count: 2)
        data.append(crcData)

        let lengthData = Data.from(d.count, count: 3)
        data.append(lengthData)

        if writeOTACommand(data) == true {
            OTAHelper.shared.updating = true
        }
    }
    
    /// 获取单次发送字节数
    static func askOTAByteCount() {
        let data = OTAProtocolID.askBytes.data
        let _ = writeOTACommand(data)
    }
    

    /// 查询ble设备OTA是否完成
    static func checkOTA() {
        let data = OTAProtocolID.checkOTA.data
        let _ = writeOTACommand(data)
    }
}

public
extension OTAHelper {
    static func parse(protocolId: OTAProtocolID, otherData: Data) {
        switch protocolId {
        case .dfuReady:
            askOTAByteCount()
        case .askBytes:
            let byteCount: Int = otherData.toInt()
            
            Device.current.otaByteCount = byteCount
            print("OTA 单次下发字节数\(byteCount)")
            shared.otaReadyClosure?()
        case .sendedBytes:
            let error: Int = otherData.subdata(in: Range(NSRange(location: 0, length: 1))!).toInt()
            if error != 0 {
                shared.otaFailed(error)
            } else {
                let lenData = otherData.subdata(in: Range(NSRange(location: otherData.count - 4, length: 4))!)
                let index = lenData.toInt()
//                print("继续数据发送 index \(index)")
                
                guard let data = OTAHelper.shared.otaData else {
//                    print("BluetoothHelper.sendingOTAData nil")
                    return
                }
                
                let progress: CGFloat = CGFloat(index) / CGFloat(data.count)
//                print("\nota 升级进度\(progress)")

//                NotificationCenter.default.post(name: .otaProgress, object: progress)
                shared.ota(progress: progress)
                sendOTAData(with: data, index: index)
            }
        case .checkOTA:
            let result: Int = otherData.toInt()
            if result == 0 {
                shared.otaEnded()
            }
            break
        case .error:
            break
        }
    }
}

public
extension OTAHelper {
    
    /// 写OTA指令数据
    static func writeOTACommand(_ data: Data, finish:(()->())? = nil) -> Bool {
        let uuidString =  BluetoothKitConstant.otaCommandCharacteristic
        
        var data = data
        
        // 1Byte 长度
        let len: Int = data.count + 1
        let lengthData = Data.from(len, count: 1)
        data = lengthData + data
        
        let finish = finish ?? {}
        BaseBluetooth.shared.writeValue(data, to: uuidString, type: .withoutResponse, completion: finish)
        return true
    }
    
    /// 写 OTA 数据(单次，多少 Byte 看设备）
    static func writeOTAData(onceData: Data, finish:(()->())? = nil) {
        
        let uuidString = BluetoothKitConstant.otaDataCharacteristic
             
        let finish = finish ?? {}
        BaseBluetooth.shared.writeValue(onceData, to: uuidString, type: .withoutResponse, completion: finish)
    }
        
    /// 写 OTA 数据（总数据，在这里计算单次发送哪些数据）
    static func sendOTAData(with otaData: Data, index: Int = 0) {
        let sendingData = otaData
        
        if sendingData.count <= index {
            return
        }
        
        var onceData = sendingData
        var last = true

        // 如果有单次发送数据长度，就截取 单次发送的 数据
        let device = Device.current
        if device.otaByteCount != 0 {
            var onceLength = device.otaByteCount // 单次发送的 Byte 数从设备获取
            
            if  sendingData.count <= index + device.otaByteCount {
                onceLength = sendingData.count - index // 最后一次发送的 Byte 数可能小于 device.byteCount
                last = true
            } else {
                last = false
            }
//            print("sendingData.count \(sendingData.count)")
            onceData = sendingData.subdata(in: Range(NSRange(location: index, length: onceLength))!)
        }

        // 写入单次发送的数据
        writeOTAData(onceData: onceData) {
            if last {
                OTAHelper.shared.otaData = nil
                OTAHelper.checkOTA()
            }
        }
    }
}

extension OTAHelper {
    @objc func ota(progress: CGFloat) {
        guard let delegate = delegate else {
            return
        }
        delegate.ota(progress: progress)
    }
    
    @objc func otaEnded() {
        self.updating = false
        guard let delegate = delegate else {
            return
        }
        delegate.otaDidSucceed()
    }
    
    
    @objc func otaFailed(_ code: Int) {
        self.updating = false
        guard let delegate = delegate else {
            return
        }
        delegate.otaDidFail(withCode: code)
    }
}

