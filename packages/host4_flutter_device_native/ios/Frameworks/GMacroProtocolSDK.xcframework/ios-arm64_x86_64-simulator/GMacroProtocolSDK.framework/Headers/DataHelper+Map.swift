//
//  DataHelper+Map.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation
import BluetoothKit

// MARK: - 映射
extension DataHelper {
    
    /// 查询支持映射的按键 0x86 0x02
    func queryMappableKeys(profile: Int,
                           finish: (() -> Void)? = nil,
                           response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {

        let subID = SupportKeySubID.queryMappableKeys
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1))
        payload.append(Data.from(profile, count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    /// 查询支持映射为手柄的按键 0x86 0x04
    func queryMappableGamepadKeys(profile: Int,
                                  finish: (() -> Void)? = nil,
                                  response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = SupportKeySubID.queryMappableGamepadKeys
        
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1))
        payload.append(Data.from(profile, count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    /// 键值映射 0x3D
    func keyMappingDatas(keyMappings: [GamepadKeyMapping],
                         finish: (() -> Void)? = nil,
                         response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.keyMap
        
        var datas = [Data]()
        
        for keyMapping in keyMappings {
            var payload = Data()
            
            payload.append(Data.from(keyMapping.original.gamepadOneByteKeyCode, count: 1)) // 原始按键
            payload.append(Data.from(keyMapping.mapped.gamepadOneByteKeyCode, count: 1))   // 映射按键
            let data = dataFrom(protocolID: protocolID, payload: payload)
            datas.append(data)
        }
        
        self.write(protocolID: protocolID, datas: datas, finish: finish, response: response)
    }
    
    
    /// 键值映射（映射鼠标) 0x5E
    func mouseKeyMappingDatas(keyMappings: [MouseKeyMapping],
                              finish: (() -> Void)? = nil,
                              response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.mouseKeyMap
        
        var datas = [Data]()
        
        for keyMapping in keyMappings {
            var payload = Data()
            
            payload.append(Data.from(keyMapping.original.gamepadOneByteKeyCode, count: 1)) // 原始按键
            payload.append(Data.from(Int(keyMapping.mapped.rawValue), count: 1))   // 映射按键
            let data = dataFrom(protocolID: protocolID, payload: payload)
            datas.append(data)
        }
        
        self.write(protocolID: protocolID, datas: datas, finish: finish, response: response)
    }
    
    /// 键值映射（映射键盘) 0x5F
    func keyboardKeyMappingDatas(keyMappings: [KeyboardKeyMapping],
                                 finish: (() -> Void)? = nil,
                                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.keyboardKeyMap
        
        var datas = [Data]()
        
        for keyMapping in keyMappings {
            var payload = Data()
            
            payload.append(Data.from(keyMapping.original.gamepadOneByteKeyCode, count: 1)) // 原始按键
            payload.append(Data.from(Int(keyMapping.mapped.rawValue), count: 1))   // 映射按键
            let data = dataFrom(protocolID: protocolID, payload: payload)
            datas.append(data)
        }
        
        self.write(protocolID: protocolID, datas: datas, finish: finish, response: response)
    }
    
    /// 查询按键映射当前配置 0x50
    func currentMapping(profile: Int,
                        finish:(()->())? = nil,
                        response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.currentMapping
        
        var payload = Data()
        
        // profile
        payload.append(Data.from(UInt8(profile)))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
}



extension DataHelper {
    
    /// 查询手柄所有按键映射（支持同时映射多种类型键值） 6C11
    func currentMultiMapping(finish:(()->())? = nil,
                             response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = MappingSubID.fetchAllMappings
        let protocolID = subID.proID
        
        var payload = Data()
        
        payload.append(Data.from(Int(subID.rawValue), count: 1))
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))

        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    
    /// 查询获取手柄按键映射（支持同时映射多种类型键值） 6C12
    /// - Parameters:
    ///   - original: 原始按键
    func currentMultiMapping(original: GamepadKey,
                             finish:(()->())? = nil,
                             response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = MappingSubID.fetchOneMapping
        let protocolID = subID.proID
        
        var payload = Data()
        
        payload.append(Data.from(Int(subID.rawValue), count: 1))
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))
        
        payload.append(Data.from(original.gamepadOneByteKeyCode, count: 1)) // 原始按键

        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    
    /// 设置手柄按键映射（支持同时映射多种类型键值）6C10
    /// 类型 ≤ 3，每种类型的键值数量 ≤ 5，总键值数 ≤ 5
    /// - Parameters:
    ///   - original: 原始按键 rawValue
    ///   - mappedArray: 映射目标数组，每个包含 type（0:手柄，1:鼠标，2:键盘）
    func multiKeyMapping(original: GamepadKey,
                         mappedKeys: [MappedKey],
                         finish: (() -> Void)? = nil,
                         response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        guard !mappedKeys.isEmpty else {
            response(.failure(BluetoothError.invalidInput))
            return
        }
        
        
        let mapping = MultiKeyMapping(original: original, mapped: mappedKeys)
        
        // 原始按键键值
        print("原始按键键值：\(mapping.original.gamepadOneByteKeyCode)")
        
        // 映射类型集合（去重）
        let types = Set(mapping.mapped.map { $0.type.rawValue })
        print("映射按键类型数量：\(types.count)")
        print("映射按键类型：\(types.sorted())")
        
        // 映射键值总数量
        let totalValueCount = mapping.mapped.reduce(0) { $0 + $1.values.count }
        print("映射按键键值数量：\(totalValueCount)")
        
        // 映射键值数组（展开所有 values）
        let allValues = mapping.mapped.flatMap { $0.values }
        print("映射键值数组：\(allValues)")
        
        
        // 校验规则：类型 ≤ 3，每种类型的键值数量 ≤ 5，总键值数 ≤ 5
        let isTypeCountValid = types.count <= 3
        let isTotalCountValid = totalValueCount <= 5
        
        let isEachTypeCountValid = Dictionary(grouping: mapping.mapped, by: \.type)
            .allSatisfy { (_, group) in
                group.reduce(0) { $0 + $1.values.count } <= 5
            }
        
        guard isTypeCountValid, isTotalCountValid, isEachTypeCountValid else {
            response(.failure(BluetoothError.invalidInput))
            return
        }
        
        
        let subID = MappingSubID.setMapping
        let protocolID = subID.proID
        
        var payload = Data()
        
        payload.append(Data.from(Int(subID.rawValue), count: 1))
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))
        
        payload.append(Data.from(mapping.original.gamepadOneByteKeyCode, count: 1)) // 原始按键
        payload.append(Data.from(types.count, count: 1)) // 映射按键类型数量
        
        for mapped in mapping.mapped {
            let type = mapped.type.rawValue
            let keyValues = mapped.values
            let keyCount = keyValues.count
            
            payload.append(Data.from(type, count: 1)) // 映射键值类型
            payload.append(Data.from(keyCount, count: 1)) // 映射键值数量
            // 键值数组（每个 1 byte）
            for value in keyValues {
                payload.append(Data.from(value, count: 1))
            }
        }
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
}


extension DataHelper {
    
    func analyzeMapping(_ data: Data, _ subID: UInt8, _ sn: UInt8) -> [String: Any] {
        let subID = MappingSubID(rawValue: subID)
        switch subID {
        case .fetchAllMappings:
            return analyzeAllMappings(data)
//        case .fetchOneMapping:
//            return analyzeCurrentLightEffect(data)
        default:
            print("未处理的 MappingSubID 0x\(String(format: "%02X", subID!.rawValue))")
            return [:]
        }
    }
    
    // 查询手柄按键映射（支持同时映射多种类型键值）
    func analyzeMappings(_ data: Data) -> [String: Any] {
        print("analyzeMappings data \(data.nsDescription())")
        // <A2  03 010101  0202040C  0001  >
        
        var dic: [String: Any] = [:]
        var mappingList: [MultiKeyMappingBridge] = []
        var parser = DataParser(data)
        parser.skip(2)
        
        
        // 解析内容
        while parser.remaining >= 2 {
            let originalCode = parser.next(1).toInt()
            guard let original = GamepadKey.from(oneByteKeyCode: originalCode) else { continue }
            
            print("\n🔹 原始按键：\(original.gamepadKeyString) [\(originalCode)]")
            
            let typeCount = parser.next(1).toInt()
            print("📌 映射类型数量：\(typeCount)")
            
            var mappedBridges: [MappedKeyBridge] = []
            
            for _ in 0..<typeCount {
                if parser.remaining < 2 {
                    print("❌ 剩余不足以读取类型和数量")
                    break
                }
                
                let type = parser.next(1).toInt()
                let count = parser.next(1).toInt()
                
                guard parser.remaining >= count else {
                    print("❌ 映射键值不足，剩余 \(parser.remaining)，需要 \(count)")
                    break
                }
                
                var values: [Int] = []
                for _ in 0..<count {
                    values.append(parser.next(1).toInt())
                }
                
                print("  ▸ 类型：\(type)，数量：\(count)，键值：\(values)")
                
                switch type {
                case MappedKeyType.gamepad.rawValue:
                    let keys = values.compactMap { GamepadKey.from(oneByteKeyCode: $0) }
                    if !keys.isEmpty {
                        mappedBridges.append(MappedKeyBridge(mappedKey: .gamepad(keys)))
                    }
                    
                case MappedKeyType.mouse.rawValue:
                    let keys = values.compactMap { MouseKey(rawValue: UInt8($0)) }
                    if !keys.isEmpty {
                        mappedBridges.append(MappedKeyBridge(mappedKey: .mouse(keys)))
                    }
                    
                case MappedKeyType.keyboard.rawValue:
                    let keys = values.compactMap { KeyboardKey(rawValue: UInt8($0)) }
                    if !keys.isEmpty {
                        mappedBridges.append(MappedKeyBridge(mappedKey: .keyboard(keys)))
                    }
                    
                default:
                    print("❌ 未知映射类型：\(type)")
                }
            }
            
            let mapping = MultiKeyMappingBridge(original: original, mapped: mappedBridges)
            mappingList.append(mapping)
        }
        
        dic["mappings"] = mappingList
        print("dic \(dic)")
        return dic
    }
    
    // 查询手柄所有按键映射（支持同时映射多种类型键值）
    func analyzeAllMappings(_ data: Data) -> [String: Any] {
        print("analyzeAllMappings data \(data.nsDescription())")
        
        /**
         分析 data
         第一个 byte 为总长度，输出一下
         后面是
         [1 byte] 原始按键
         [1 byte] 类型数量
         {
             [1 byte] 类型
             [1 byte] 键值数量解析为 n
             [n byte] 键值数组
         } * 类型数量
         
         [下一个原始按键] ...
         
         组装一个 dic，
         {
             "mappings": [
                 {
                     "original": "填入原始按键的original.gamepadOneByteKeyCode",
                     "mapped": {type 和 values}
                 }
             ]
         }
         mappings 在外部要能解析成 MultiKeyMappingBridge，最终转换成 MultiKeyMapping
         */
        
        var dic: [String: Any] = [:]
        var mappingList: [MultiKeyMappingBridge] = []
        var parser = DataParser(data)
        
        // 1. 读取第一个字节作为总长度
        let totalLength = parser.next(1).toInt()
        print("📦 总长度（第一个 byte）：\(totalLength)")
        
        // 2. 解析内容
        while parser.remaining >= 2 {
            let originalCode = parser.next(1).toInt()
            guard let original = GamepadKey.from(oneByteKeyCode: originalCode) else { continue }
            
            print("\n🔹 原始按键：\(original.gamepadKeyString) [\(originalCode)]")
            
            let typeCount = parser.next(1).toInt()
            print("📌 映射类型数量：\(typeCount)")
            
            var mappedBridges: [MappedKeyBridge] = []
            
            for _ in 0..<typeCount {
                if parser.remaining < 2 {
                    print("❌ 剩余不足以读取类型和数量")
                    break
                }
                
                let type = parser.next(1).toInt()
                let count = parser.next(1).toInt()
                
                guard parser.remaining >= count else {
                    print("❌ 映射键值不足，剩余 \(parser.remaining)，需要 \(count)")
                    break
                }
                
                var values: [Int] = []
                for _ in 0..<count {
                    values.append(parser.next(1).toInt())
                }
                
                print("  ▸ 类型：\(type)，数量：\(count)，键值：\(values)")
                
                switch type {
                case MappedKeyType.gamepad.rawValue:
                    let keys = values.compactMap { GamepadKey.from(oneByteKeyCode: $0) }
                    if !keys.isEmpty {
                        mappedBridges.append(MappedKeyBridge(mappedKey: .gamepad(keys)))
                    }
                    
                case MappedKeyType.mouse.rawValue:
                    let keys = values.compactMap { MouseKey(rawValue: UInt8($0)) }
                    if !keys.isEmpty {
                        mappedBridges.append(MappedKeyBridge(mappedKey: .mouse(keys)))
                    }
                    
                case MappedKeyType.keyboard.rawValue:
                    let keys = values.compactMap { KeyboardKey(rawValue: UInt8($0)) }
                    if !keys.isEmpty {
                        mappedBridges.append(MappedKeyBridge(mappedKey: .keyboard(keys)))
                    }
                    
                default:
                    print("❌ 未知映射类型：\(type)")
                }
            }
            
            let mapping = MultiKeyMappingBridge(original: original, mapped: mappedBridges)
            mappingList.append(mapping)
        }
        
        dic["mappings"] = mappingList
        print("dic \(dic)")
        return dic
    }
    
}
