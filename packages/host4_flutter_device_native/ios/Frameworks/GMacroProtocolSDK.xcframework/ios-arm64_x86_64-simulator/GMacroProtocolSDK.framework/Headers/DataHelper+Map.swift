//
//  DataHelper+Map.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation
import BluetoothKit

// MARK: - 键值映射
extension DataHelper {

    /// 查询支持映射的按键 0x86 0x02
    func queryMappableKeys(profile: Int,
                            finish:(()->())? = nil,
                            response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = SupportKeySubID.queryMappableKeys
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1))
        payload.append(Data.from(profile, count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    /// 查询支持映射为手柄的按键 0x86 0x04
    func queryMappableGamepadKeys(profile: Int,
                            finish:(()->())? = nil,
                            response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = SupportKeySubID.queryMappableGamepadKeys
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1))
        payload.append(Data.from(profile, count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
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
    
    // MARK: - 6C0D 设置手柄按键映射（单映射）
    /// - Parameters:
    ///   - original: 原始按键
    ///   - mapped: 映射按键
    func setHandleKeyMapping(original: GamepadKey,
                              mapped: GamepadKey,
                              finish: (() -> Void)? = nil,
                              response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = MappingSubID.setHandleMapping
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID 0x0D
        payload.append(Data.from(0x00, count: 1))               // Dev 固定 0
        payload.append(Data.from(original.gamepadOneByteKeyCode, count: 1)) // 原始按键
        payload.append(Data.from(0, count: 1))                  // 映射键值类型 0=手柄
        payload.append(Data.from(1, count: 1))                  // 映射键值数量 固定1
        payload.append(Data.from(mapped.gamepadOneByteKeyCode, count: 1))   // 映射按键
        
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
        
        // 映射类型数量
        _ = types.count
        
        // 总键值数
        let totalValueCount = mapping.mapped.reduce(0) { $0 + $1.values.count }
        print("总映射键值数量：\(totalValueCount)")
        
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
        
        while parser.remaining > 0 {
            guard parser.remaining >= 5 else {
                print("⚠️ 数据不足，无法解析完整映射条目")
                break
            }
            
            let original = parser.next(1).toInt()
            _ = parser.next(1).toInt() // typeCount
            
            var mappedArray: [MappedKeyBridge] = []
            
            while parser.remaining >= 2 {
                let type = parser.next(1).toInt()
                let count = parser.next(1).toInt()
                
                guard parser.remaining >= count else {
                    print("⚠️ 数据不足，无法读取 \(count) 个键值")
                    break
                }
                
                var values: [Int] = []
                for _ in 0..<count {
                    let value = parser.next(1).toInt()
                    values.append(value)
                }
                mappedArray.append(MappedKeyBridge(type: type, values: values))
            }
            
            let originalKey = GamepadKey(rawValue: original) ?? .none
            let bridge = MultiKeyMappingBridge(original: originalKey, mapped: mappedArray)
            mappingList.append(bridge)
        }
        
        dic["mappings"] = mappingList
        return dic
    }
    
    /// 解析手柄所有按键映射（多包数据）
    func analyzeAllMappings(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        var mappingList: [MultiKeyMappingBridge] = []
        var parser = DataParser(data)
        
        while parser.remaining > 7 {
            let original = parser.next(1).toInt()
            let typeCount = parser.next(1).toInt()
            
            var mappedArray: [MappedKeyBridge] = []
            
            for _ in 0..<typeCount {
                guard parser.remaining >= 2 else { break }
                let type = parser.next(1).toInt()
                let count = parser.next(1).toInt()
                guard parser.remaining >= count else { break }
                var values: [Int] = []
                for _ in 0..<count {
                    let value = parser.next(1).toInt()
                    values.append(value)
                }
                mappedArray.append(MappedKeyBridge(type: type, values: values))
            }
            
            let originalKey = GamepadKey(rawValue: original) ?? .none
            let bridge = MultiKeyMappingBridge(original: originalKey, mapped: mappedArray)
            mappingList.append(bridge)
        }
        
        dic["mappings"] = mappingList
        return dic
    }
}
