//
//  DataHelper+Trigger.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation
import BluetoothKit

// MARK: - 扳机
extension DataHelper {
    
    /// 设置扳机死区和余量 0x39
    func trigger(leftMin: Int,
                 leftMax: Int,
                 rightMin: Int,
                 rightMax: Int,
                 finish:(()->())? = nil,
                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        
        if !(0...100).contains(leftMin) || !(0...100).contains(leftMax)
            || !(0...100).contains(rightMin) || !(0...100).contains(rightMax) {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        
        let protocolID = GMacroProtocolID.setTrigger
        
        var payload = Data()
        
        payload.append(Data.from(leftMin, count: 1)) // 左扳机起始
        payload.append(Data.from(leftMax, count: 1)) // 左扳机终止
        
        payload.append(Data.from(rightMin, count: 1)) // 右扳机起始
        payload.append(Data.from(rightMax, count: 1)) // 右扳机终止
        
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    /// 设置扳机曲线 0x85 0x03/0x04
    func triggerCurve(cgPoints: [CGPoint],
                      subID:TriggerSubID,
                      finish:(()->())? = nil,
                      response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        if subID != .leftCurve && subID != .rightCurve {
            print("传入错误的 subID，请检查")
            return
        }
        let protocolID = subID.proID

        guard let points = convertAndValidatePoints(cgPoints: cgPoints, response: response) else { return }
        let datas = pointDatas(protocolID: protocolID, subID: subID.rawValue, points: points)
        self.write(protocolID: protocolID, datas: datas, finish: finish, response: response)
        
    }
    
    /// 设置快速扳机开关 0x85 0x08
    func triggerQuickSwitch(leftOn: Bool,
                            rightOn: Bool,
                            finish:(()->())? = nil,
                            response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = TriggerSubID.quickSwitch
        let protocolID = subID.proID

        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05
        
        // 快速扳机开关：1：开启；2：关闭
        let left = leftOn ? 1 : 2
        let right = rightOn ? 1 : 2
        payload.append(Data.from(left, count: 1))
        payload.append(Data.from(right, count: 1))
        
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    ///获取快速扳机开关 0x85 0x11
    func getTriggerQuickSwitch(
                            finish:(()->())? = nil,
                            response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = TriggerSubID.getQuickSwitch
        let protocolID = subID.proID

        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
}

extension DataHelper {
    // MARK: - 0x55 subID:03 开始扳机校准
    func startTriggerCalibration(finish:(()->())? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.beginCalibration
        
        var payload = Data()
        
        // subID
        let subID = 0x03
        
        payload.append(Data.from(UInt8(subID)))
        
        // dev 固定值0x00
        payload.append(Data.from(0x00))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // MARK: - 0x56 subID:03 结束扳机校准
    func endTriggerCalibration(finish:(()->())? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.stopCalibration
        
        var payload = Data()
        
        // subID
        let subID = 0x03
        
        payload.append(Data.from(UInt8(subID)))
        
        // dev 固定值0x00
        payload.append(Data.from(0x00))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
}

extension DataHelper {
    // MARK: - 0x85 subID:07 设置左右扳机线性输出
    /// 设置左右扳机线性输出
    func triggerLinearOutput(leftMode: Int, leftThreshold: Int, rightMode: Int, rightThreshold: Int,
                 finish:(()->())? = nil,
                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        
        if !(1...2).contains(leftMode) || !(1...2).contains(rightMode)
            || !(1...0xFF).contains(leftThreshold) || !(1...0xFF).contains(rightThreshold) {
            
            response(.failure(BluetoothError.outOfRange))
            
            return
        }
        
        let protocolID = GMacroProtocolID.trigger3D
        
        var payload = Data()
        
        //subId
        payload.append(Data.from(0x07))
        
        //dev
        payload.append(Data.from(0x00))
        
        payload.append(Data.from(leftMode, count: 1)) // 左扳机线性
        payload.append(Data.from(leftThreshold, count: 1)) // 左扳机阈值
        
        payload.append(Data.from(rightMode, count: 1)) // 右扳机线性
        payload.append(Data.from(rightThreshold, count: 1)) // 右扳机阈值
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    func analyzeQuickTrigger(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)
        
        // subID
        _ = parser.next(1)
        // Dev
        _ = parser.next(1)
        
        
        // 左扳机开关
        let leftOn = parser.next(1).toInt()
        dic["leftOn"] = leftOn
        
        // 右扳机开关
        let rightOn = parser.next(1).toInt()
        dic["rightOn"] = rightOn

        return dic
    }
}
