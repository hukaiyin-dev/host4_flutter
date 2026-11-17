//
//  DataHelper+Turbo.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation
import BluetoothKit

// MARK: - 连发
extension DataHelper {
    /// 设置 16 位连发速率 0x37 0x80。
    func turboDatas16(keyTurbos: [KeyTurbo],
                      device: Int = 0,
                      finish: (() -> Void)? = nil,
                      response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        guard (0...0xFF).contains(device) else {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        guard keyTurbos.allSatisfy({ (1...0xFFFF).contains($0.speed) && (0...0xFFFF).contains($0.pressDuration) }) else {
            response(.failure(BluetoothError.invalidInput))
            return
        }
        let protocolID = GMacroProtocolID.setTurbo
        let datas = keyTurbos.map { item -> Data in
            var payload = Data([0x80, UInt8(device)])
            payload.append(Data.from(item.key.gamepadOneByteKeyCode, count: 1))
            payload.append(Data.from(Int(item.turbo.rawValue), count: 1))
            payload.append(Data.from(item.pressDuration, count: 2))
            payload.append(Data.from(item.speed, count: 2))
            return dataFrom(protocolID: protocolID, payload: payload)
        }
        write(protocolID: protocolID, datas: datas, finish: finish, response: response)
    }

    func queryKeyTurbo16(key: GamepadKey,
                         device: Int = 0,
                         response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        guard (0...0xFF).contains(device) else {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        let payload = Data([0x81, UInt8(device), UInt8(key.gamepadOneByteKeyCode)])
        write(protocolID: .setTurbo, data: dataFrom(protocolID: .setTurbo, payload: payload), response: response)
    }

    func queryAllKeyTurbo16(device: Int = 0,
                            response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        guard (0...0xFF).contains(device) else {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        write(protocolID: .setTurbo, data: dataFrom(protocolID: .setTurbo, payload: Data([0x82, UInt8(device)])), response: response)
    }

    func analyzeKeyTurbo16(_ payload: Data) -> [String: Any]? {
        guard payload.count == 8, payload[0] == 0x81 else { return nil }
        return turbo16Entry(payload, at: 2).map { ["device": Int(payload[1]), "config": $0] }
    }

    func analyzeAllKeyTurbo16(_ data: Data) -> [String: Any]? {
        var offset = 0
        var configs: [[String: Any]] = []
        while offset < data.count {
            let count = Int(data[offset])
            offset += 1
            guard count <= (data.count - offset) / 6 else { return nil }
            for _ in 0..<count {
                guard let entry = turbo16Entry(data, at: offset) else { return nil }
                configs.append(entry)
                offset += 6
            }
        }
        return ["configs": configs]
    }

    private func turbo16Entry(_ data: Data, at offset: Int) -> [String: Any]? {
        guard offset + 6 <= data.count else { return nil }
        let pressDuration = Int(data[offset + 2]) << 8 | Int(data[offset + 3])
        let interval = Int(data[offset + 4]) << 8 | Int(data[offset + 5])
        return ["key": Int(data[offset]), "turbo": Int(data[offset + 1]),
                "pressDuration": pressDuration, "interval": interval]
    }

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
