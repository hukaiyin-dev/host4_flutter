//
//  DataHelper+Vibration.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation
import BluetoothKit

// MARK: - 振动
extension DataHelper {
    
    /// 设置振动级别 0x35
    func setVibrationLevel(left: Int,
                           right: Int,
                           finish: (() -> Void)? = nil,
                           response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        guard (0...100).contains(left), (0...100).contains(right) else {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        
        let protocolID = GMacroProtocolID.setVibrate
        
        var payload = Data()
        payload.append(Data.from(left, count: 1))
        payload.append(Data.from(right, count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    /// 测试振动力 0x45
    func testVibration(left: Int,
                       right: Int,
                       position: VibrationPosition,
                       finish: (() -> Void)? = nil,
                       response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        // 确保振动力在 0-255 范围内
        guard (0...255).contains(left), (0...255).contains(right) else {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        
        let protocolID = GMacroProtocolID.testMontor
        
        var payload = Data()
        payload.append(Data.from(left, count: 1))  // 左振动力
        payload.append(Data.from(right, count: 1)) // 右振动力
        payload.append(Data.from(Int(position.rawValue), count: 1)) // 振动位置
        
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
}

extension DataHelper {
    
    func analyzeVibration(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)

        // subID
        let subIDData = parser.next(1)
        let subID = VibrationSubID(rawValue: UInt8(subIDData.toInt()))
        
        // Dev
        _ = parser.next(1)
        
        switch subID {
            
        case .fetchTriggerTestGripVibration, .fetchTriggerVibration:
            // Param：1 为开启，2 为关闭
            let param = parser.next(1).toInt()
            var isOn = true
            if param == 2 {
                isOn = false
            }
            dic["isOn"] = isOn
        default:
            print("未处理的 VibrationSubID 0x\(String(format: "%02X", subID!.rawValue))")
        }
        return dic
    }
}
