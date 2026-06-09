//
//  DataHelper+SupportKey.swift
//  GameMacroSDKExample-ObjC
//
//  Created by hukaiyin on 2025/3/22.
//

import Foundation

// MARK: - SupportKey
extension DataHelper {
    // 查询支持连发的按键及参数
    func analyzeTurboSupportKey(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)
        
        // 连发模式
        let modeRaw = parser.next(1).toInt()
        let mode = TurboMode(rawValue: UInt8(modeRaw)) ?? .disabled
        dic["mode"] = mode
        
        // 最大速率
        let maxSpeed = parser.next(1).toInt()
        dic["maxSpeed"] = maxSpeed
        
        // 最小速率
        let minSpeed = parser.next(1).toInt()
        dic["minSpeed"] = minSpeed
        
        // 按键列表
        var keys: [GamepadKey] = []
        while parser.remaining > 0 {
            let keyCode = parser.next(1).toInt()
            if let key = GamepadKey.from(oneByteKeyCode: keyCode) {
                keys.append(key)
            }
        }
        dic["keys"] = keys
        
        return dic
    }
    
    func analyzeSupportKey(_ data: Data, _ subID: UInt8, _ sn: UInt8) -> [String: Any] {
        let subID = SupportKeySubID(rawValue: subID)
        switch subID {
        case .queryTurboKeys:
            return analyzeTurboSupportKey(data)
        case .queryMappableKeys:
            return analyzeMappableKey(data)
        case .queryMappableGamepadKeys:
            return analyzeMappableGamepadKey(data)
        case .queryMacroKeys:
            return analyzeMacroKey(data)
        case .queryMacroRecordableKeys:
            return analyzeMacroRecordableKey(data)
        case .queryGyroTriggerKeys:
            return analyzeGyroTriggerKey(data)
        default:
            print("未处理的 SupportKeySubID  0x\(String(format: "%02X", subID!.rawValue))")
            return [:]
        }
    }
    
    //  查询支持体感触发的按键
    func analyzeGyroTriggerKey(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)

        // subID
        _ = parser.next(1)

        
        // 所有 byte 为支持宏录制的按键
        var keys: [GamepadKey] = []
        while parser.remaining > 0 {
            let keyCode = parser.next(1).toInt()
            if let key = GamepadKey.from(oneByteKeyCode: keyCode) {
                keys.append(key)
            }
        }
        dic["keys"] = keys
        
        return dic
    }
    
    
    
    // 查询支持体感映射的模式
    func analyzeGyroMappingModes(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)

        // subID
        _ = parser.next(1)

        // 读取 2 字节 bit
        let rawValue = parser.next(2).toInt()
        dic["raw"] = rawValue

        // bit 映射关系
        let modeMap: [(bit: Int, mode: MotionMappingMode)] = [
            (0, .dPad),
            (1, .leftStick),
            (2, .rightStick),
            (3, .mouse)
        ]

        // 提取支持的模式
        let supportedModes = modeMap.compactMap { (bit, mode) -> MotionMappingMode? in
            return (rawValue & (1 << bit)) != 0 ? mode : nil
        }

        dic["modes"] = supportedModes

        return dic
    }
    
    
    // 查询宏录制时间参数范围
    func analyzeMacroTimeRange(_ data: Data)  -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)
        
        guard parser.remaining >= 6 else {
            print("⚠️ 数据长度不足 6 字节")
            return dic
        }
        
        // subID
        let _ = parser.next(1)
        let keepTime = parser.next(2).toInt()
        let intervalTime = parser.next(2).toInt()
        let cycleInterval = parser.next(2).toInt()
        
        dic["keepTime"] = keepTime
        dic["intervalTime"] = intervalTime
        dic["cycleInterval"] = cycleInterval
        
        return dic
    }
    
    // 查询支持宏录制的按键
    func analyzeMacroRecordableKey(_ data: Data)  -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)
        
        // 所有 byte 为支持宏录制的按键
        var keys: [GamepadKey] = []
        while parser.remaining > 0 {
            let keyCode = parser.next(1).toInt()
            if let key = GamepadKey.from(oneByteKeyCode: keyCode) {
                keys.append(key)
            }
        }
        dic["keys"] = keys
        
        return dic
    }
    
    // 查询支持宏的按键
    func analyzeMacroKey(_ data: Data)  -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)
        
        // 第1个 byte 为是否支持宏
        let supported = parser.next(1).toInt()
        dic["supported"] = supported == 1
        
        // 后续每个 byte 为支持的宏按键
        var keys: [GamepadKey] = []
        while parser.remaining > 0 {
            let keyCode = parser.next(1).toInt()
            if let key = GamepadKey.from(oneByteKeyCode: keyCode) {
                keys.append(key)
            }
        }
        dic["keys"] = keys
        
        return dic
    }
    
    // 查询支持映射为手柄的按键
    func analyzeMappableGamepadKey(_ data: Data)  -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)
        
        // 所有 byte 为支持映射的按键
        var keys: [GamepadKey] = []
        while parser.remaining > 0 {
            let keyCode = parser.next(1).toInt()
            if let key = GamepadKey.from(oneByteKeyCode: keyCode) {
                keys.append(key)
            }
        }
        dic["keys"] = keys
        
        return dic
    }
    
    // 查询按键映射当前配置
    func analyzeCurrnetMapping(_ data: Data, _ sn: UInt8) -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)
        
        // 映射总长度
        let length = parser.next(1).toInt()
        guard length % 3 == 0 else {
            print("映射数据长度非法")
            return dic
        }
        
        // 初始化容器
        var gamepadMappings: [GamepadKeyMapping] = []
        var mouseMappings: [MouseKeyMapping] = []
        var keyboardMappings: [KeyboardKeyMapping] = []
        
        let count = length / 3
        for _ in 0..<count {
            let typeByte = parser.next(1).toInt()
            let originalTypeValue = (typeByte & 0xF0) >> 4  // b7-b4
            let mappedTypeValue = typeByte & 0x0F           // b3-b0
            
            let originalType = MappingType(rawValue: UInt8(1 << originalTypeValue))
            let mappedType = MappingType(rawValue: UInt8(1 << mappedTypeValue))
            
            guard let originalKey = GamepadKey.from(oneByteKeyCode: parser.next(1).toInt()) else {
                continue
            }
            let mappedRaw = parser.next(1).toInt()
            
            // 目前仅支持原始为手柄的映射
            guard originalType == .gamepad, let mappedType = mappedType else { continue }
            
            switch mappedType {
            case .gamepad:
                guard let mapped = GamepadKey.from(oneByteKeyCode: mappedRaw) else {
                    continue
                }
                gamepadMappings.append(GamepadKeyMapping(original: originalKey, mapped: mapped))
            case .mouse:
                let mapped: MouseKey = MouseKey(rawValue: UInt8(mappedRaw)) ?? .backward
                mouseMappings.append(MouseKeyMapping(original: originalKey, mapped: mapped))
            case .keyboard:
                let mapped: KeyboardKey = KeyboardKey(rawValue: UInt8(mappedRaw)) ?? .Reserved
                keyboardMappings.append(KeyboardKeyMapping(original: originalKey, mapped: mapped))
            default:
                continue
            }
        }
        
        dic["gamepadMappings"] = gamepadMappings
        dic["mouseMappings"] = mouseMappings
        dic["keyboardMappings"] = keyboardMappings
        
        return dic
    }
    
    
    // 查询支持映射的按键
    func analyzeMappableKey(_ data: Data)  -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)
        
        // 映射支持类型
        let mappingBits = parser.next(1).toInt()
        var supportedTypes: [MappingType] = []
        
        // 判断哪些 bit 被置位
        let allTypes: [MappingType] = [.gamepad, .mouse, .keyboard, .multimedia]
        for type in allTypes {
            if (mappingBits & Int(type.rawValue)) != 0 {
                supportedTypes.append(type)
            }
        }
        dic["types"] = supportedTypes
        
        // 后续所有 byte 为支持映射的按键
        var keys: [GamepadKey] = []
        while parser.remaining > 0 {
            let keyCode = parser.next(1).toInt()
            if let key = GamepadKey.from(oneByteKeyCode: keyCode) {
                keys.append(key)
            }
        }
        dic["keys"] = keys
        
        return dic
    }
}
