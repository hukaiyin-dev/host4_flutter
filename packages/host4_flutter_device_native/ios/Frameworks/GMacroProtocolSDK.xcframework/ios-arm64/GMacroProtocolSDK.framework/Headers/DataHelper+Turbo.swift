//
//  DataHelper+Turbo.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation

// MARK: - 连发
extension DataHelper {
    /// 设置连发速率 0x37
    func turboDatas(keyTurbos: [KeyTurbo],
                    finish: (() -> Void)? = nil,
                    response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let protocolID = GMacroProtocolID.setTurbo
        
        var datas = [Data]()
        
        
        for keyTurbo in keyTurbos {
            var payload = Data()
            
            let keyCode = keyTurbo.key.gamepadOneByteKeyCode
            
            payload.append(Data.from(keyCode, count: 1)) // 按键
            payload.append(Data.from(Int(keyTurbo.turbo.rawValue), count: 1)) // 连发模式
            payload.append(Data.from(keyTurbo.speed, count: 1)) // 速率
            
            let data = dataFrom(protocolID: protocolID, payload: payload)
            datas.append(data)
        }
        
        self.write(protocolID: protocolID, datas: datas, finish: finish, response: response)
    }
    
    
    /// 查询支持连发的按键 0x86 0x01
    func querySupportedTurboKeys(profile: Int,
                                 finish: (() -> Void)? = nil,
                                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {

        let subID = SupportKeySubID.queryTurboKeys
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1))
        payload.append(Data.from(profile, count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
}

