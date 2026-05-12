//
//  DataHelper+Sleep.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation
import BluetoothKit

// MARK: - 休眠时间
extension DataHelper {
    
    /// 设置自动睡眠时间 0x33 0x01
    func fetchSleep(time: Int,
                    finish: (() -> Void)? = nil,
                    response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        if !(0...0xFF).contains(time) {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        
        let protocolID = GMacroProtocolID.setSleep
        
        var payload = Data()
        
        // subID
        let subID = 0x01
        payload.append(Data.from(UInt8(subID)))
        
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))
        
        // time
        payload.append(Data.from(time, count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    /// 查询自动休眠时间 0x32 0x01
    func fetchSleep(profile: Int,
                    finish: (() -> Void)? = nil,
                    response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let protocolID = GMacroProtocolID.sleep
        
        var payload = Data()
        
        // subID
        let subID = 0x01
        payload.append(Data.from(UInt8(subID)))
        
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
}

// MARK: - Parse
extension DataHelper {
    func analyzeSleep(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)
        
        // subID
        _ = parser.next(1)
        // Dev
        _ = parser.next(1)
        
        
        // 睡眠时间 0-255（分钟），0 == 不自动睡眠
        let sleepTime = parser.next(1).toInt()
        dic["sleep"] = sleepTime

        return dic
    }
}
