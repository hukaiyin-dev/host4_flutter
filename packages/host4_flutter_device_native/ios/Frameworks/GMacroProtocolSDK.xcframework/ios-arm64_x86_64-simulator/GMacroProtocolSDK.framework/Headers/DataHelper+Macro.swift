//
//  DataHelper+Macro.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation

// MARK: - 宏设置
extension DataHelper {
    
    // MARK: - 7901
    // 查询宏定义当前配置（分包发送  7901
    func currentMacro(profile: Int,
                      finish:(()->())? = nil,
                      response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.currentMacro
        
        var payload = Data()
        
        // subID
        let subID = 0x01
        payload.append(Data.from(UInt8(subID)))
        
        // profile
        payload.append(Data.from(UInt8(profile)))
        
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // MARK: - 8603
    /// 查询支持宏的按键 8603
    func queryMacroKeys(profile: Int,
                        finish: (() -> Void)? = nil,
                        response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = SupportKeySubID.queryMacroKeys
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1))
        payload.append(Data.from(profile, count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 8605
    /// 查询支持宏录制的按键 8605
    func queryMacroRecordableKeys(profile: Int,
                                  finish: (() -> Void)? = nil,
                                  response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = SupportKeySubID.queryMacroRecordableKeys
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1))
        payload.append(Data.from(profile, count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 8606
    /// 查询宏录制时间参数范围 8606
    func queryMacroTimeRange(profile: Int,
                             finish: (() -> Void)? = nil,
                             response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = SupportKeySubID.queryMacroTimeRange
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1))
        payload.append(Data.from(profile, count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 8607
    /// 查询宏录制最大支持组数 8607
    func queryMacroMaxGroups(profile: Int,
                             finish: (() -> Void)? = nil,
                             response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = SupportKeySubID.queryMacroMaxGroups
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1))
        payload.append(Data.from(profile, count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 3A
    /// 设置宏定义子按键 3A
    func comKeysDatas(macroKey: MacroKey,
                      finish: (() -> Void)? = nil,
                      response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let comKeys = macroKey.comKeys
        let keyCode = macroKey.value.gamepadOneByteKeyCode
        let protocolID = GMacroProtocolID.keyMacro
        
        var datas = [Data]()
        
        for (index, comKey) in comKeys.enumerated() {
            
            var payload = Data()
            
            payload.append(Data.from(keyCode, count: 1))  // 宏按键
            payload.append(Data.from(macroKey.cycle.rawValue))
            
            payload.append(Data.from(index, count: 1)) // index 从 1 开始
            payload.append(Data.from(comKey.keepTime, count: 2)) // 持续时间
            payload.append(Data.from(comKey.intervalTime, count: 2)) // 间隔时间
            
            for key in comKey.keys {
                payload.append(Data.from(key.gamepadOneByteKeyCode, count: 1))
            }
            
            let data = dataFrom(protocolID: protocolID, payload: payload)
            
            datas.append(data)
        }
        self.write(protocolID: protocolID, datas: datas, finish: finish, response: response)
    }
    
    // MARK: - 8001
    
    /// 设置宏定义循环间隔 8001
    func macroInterval(profile: Int, key: GamepadKey, intervalTime: Int, finish: (() -> Void)? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let protocolID = GMacroProtocolID.macroInterval
        
        var payload = Data()
        
        // subID
        let subID = 0x01
        payload.append(Data.from(UInt8(subID)))
        
        // profile
        payload.append(Data.from(profile, count: 1))
        
        
        payload.append(Data.from(key.gamepadOneByteKeyCode, count: 1))
        payload.append(Data.from(intervalTime, count: 4))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 5C 查询手柄当前配置页
    func fetchCurrentProfile(finish: (() -> Void)? = nil,
                              response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let protocolID = GMacroProtocolID.fetchProfile
        
        let all = dataFrom(protocolID: protocolID, payload: nil)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
}


extension DataHelper {
  
    // 查询宏定义当前配置（分包发送）
    func analyzeCurrentMacro(_ data: Data, _ subID: UInt8, _ sn: UInt8) -> [String: Any] {
        print("📥 查询宏定义当前配置: \(data.nsDescription())\n")

        var dic: [String: Any] = [:]
        var parser = DataParser(data)
        var macros: [MacroKey] = []
        var macroIndex = 0

        while parser.remaining > 0 {
            macroIndex += 1
            print("➡️ 开始解析第 \(macroIndex) 条宏，剩余字节: \(parser.remaining)")

            let mainKeyCode = parser.next(1).toInt()
            guard let mainKey = GamepadKey.from(oneByteKeyCode: mainKeyCode) else {
                continue
            }
            
            print("  🎮 宏主键: \(mainKey.gamepadKeyString) mainKeyCode (\(mainKeyCode))")

            let cycleModeRaw = parser.next(1).toInt()
            let cycleMode = CycleMode(rawValue: UInt8(cycleModeRaw)) ?? .loop
            print("  🔁 循环模式: \(cycleMode) (\(cycleModeRaw))")

            let interval = parser.next(4).toInt()
            print("  ⏱️ 间隔时间: \(interval) ms")

            let totalCount = parser.next(1).toInt()
            print("  🔧 子按键数量: \(totalCount)")

            var comKeys: [MacroComkey] = []
                
            for _ in 0..<totalCount {
//                print("    👉 第 \(i + 1) 个子按键，剩余: \(parser.remaining)")

                let _ = parser.next(1).toInt() // index（可选保留）

                let duration = parser.next(2).toInt()
                print("      ⏲️ 持续时间: \(duration) ms")

                let delay = parser.next(2).toInt()
                print("      🕓 间隔时间: \(delay) ms")

                if parser.remaining <= 0 {
                    break
                }
                let comboCount = parser.next(1).toInt()
                print("      🎯 组合键数量: \(comboCount)")

                var comboKeys: [GamepadKey] = []
                for _ in 0..<comboCount {
                    
                    // 这里有问题...不应该用 parser.remaining 判定
                    if parser.remaining <= 0 {
                        break
                    }
                    let comboKeyCode = parser.next(1).toInt()
                    if let comboKey = GamepadKey.from(oneByteKeyCode: comboKeyCode) {
                        comboKeys.append(comboKey)
                    }
//                    print("        ⌨️ combo[\(j)]: \(comboKey) (\(comboKeyCode))")
                }

                let comKey = MacroComkey(
                    keys: comboKeys,
                    keepTime: duration,
                    intervalTime: delay
                )
                comKeys.append(comKey)
            }

            let macroKey = MacroKey(
                value: mainKey,
                cycle: cycleMode,
                intervalTime: interval,
                comKeys: comKeys
            )
            macros.append(macroKey)

            print("✅ 完成第 \(macroIndex) 条宏解析，剩余: \(parser.remaining)\n")
        }

//        let validMacros = macros.filter {
//            !$0.comKeys.contains { $0.keys.isEmpty }
//        }
//        
        dic["macros"] = macros
        return dic
    }
        
    func splitMacros(from data: Data) -> [Data] {
        var macros: [Data] = []
        var parser = DataParser(data)

        while parser.remaining >= 7 {
            let startOffset = parser.offset

            _ = parser.next(1) // 宏键
            _ = parser.next(1) // 循环
            _ = parser.next(4) // 间隔
            let totalCount = parser.next(1).toInt()

            for _ in 0..<totalCount {
                guard parser.remaining >= 6 else { break }
                _ = parser.next(1) // index
                _ = parser.next(2) // 持续
                _ = parser.next(2) // 间隔
                let comboCount = parser.next(1).toInt()
                guard parser.remaining >= comboCount else { break }
                _ = parser.next(comboCount)
            }

            let endOffset = parser.offset
            let macroData = data.subdata(in: startOffset..<endOffset)
            macros.append(macroData)
        }

        return macros
    }
    
    // MARK: - 0x5C 查询手柄当前配置页解析
    func analyzeProfile(_ data: Data) -> [String: Any] {
        let profile = data.toInt()
        return ["profile": profile]
    }
}


extension DataHelper {
    // MARK: - 0x46 开始录制宏子按键
    func startRecord(finish:(()->())? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.startRecord
        
        let all = dataFrom(protocolID: protocolID, payload: nil)
        
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // MARK: - 0x36 平台设置
    func startMacroPlatform(profile: Int,
                             finish: (() -> Void)? = nil,
                             response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let protocolID = GMacroProtocolID.startMacro
        
        var payload = Data()
        payload.append(Data.from(UInt8(profile)))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // MARK: - 0x34 结束配置
    func endMacroConfig(finish: (() -> Void)? = nil,
                        response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let protocolID = GMacroProtocolID.endMaco
        let all = dataFrom(protocolID: protocolID, payload: nil)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // MARK: - 0x47 结束录制宏子按键
    func endRecord(finish:(()->())? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let protocolID = GMacroProtocolID.endRecord
        let all = dataFrom(protocolID: protocolID, payload: nil)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
}
