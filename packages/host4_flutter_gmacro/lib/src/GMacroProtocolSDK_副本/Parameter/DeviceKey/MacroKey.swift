//
//  MacroKey.swift
//  BluetoothKitDemo
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation

// 宏按键
public struct MacroKey: Sendable {
    
    public var value: GamepadKey
    public var cycle: CycleMode
    
    /// 单位 ms
    public var intervalTime: Int
    public var comKeys: [MacroComkey]
    
    public init(value: GamepadKey, cycle: CycleMode = .loop, intervalTime: Int, comKeys: [MacroComkey]) {
        self.value = value
        self.cycle = cycle
        self.intervalTime = intervalTime
        self.comKeys = comKeys
    }
    
    public var description: String {
        var desc = "宏主键 \(value.gamepadKeyString)"
        desc += ", \(cycle.description), 间隔 \(intervalTime) ms"
        
        for comKey in comKeys {
            desc += "\n\(comKey.description)"
        }
        
        return desc
    }
}

// 宏子按键组合键
public struct MacroComkey: Sendable  {
    public var keys: [GamepadKey]
    public var keepTime: Int
    
    /// 单位 ms
    public var intervalTime: Int

    public init(keys: [GamepadKey], keepTime: Int = 100, intervalTime: Int = 0) {
        self.keys = []
        for key in keys {
//            if key != .error {
                self.keys.append(key)
//            }
        }
        self.keepTime = keepTime
        self.intervalTime = intervalTime
    }
    
    public var description: String {
        var desc = "\n组合键: "
        for (index, key) in keys.enumerated() {
            desc += "\(key.gamepadKeyString)"
            if index < keys.count - 1 {
                desc += " + "
            }
        }
        desc += "\n持续\(keepTime) ms, 间隔 \(intervalTime) ms"

        return desc
    }
}

// MARK: - Objective-C 兼容

@objcMembers
public class MacroComkeyBridge: NSObject, @unchecked Sendable {
    public let keys: [NSNumber]
    public let keepTime: Int
    public let intervalTime: Int
    
    public init(comkey: MacroComkey) {
        self.keys = comkey.keys.map { NSNumber(value: $0.gamepadOneByteKeyCode) }
        self.keepTime = comkey.keepTime
        self.intervalTime = comkey.intervalTime
    }
}

@objcMembers
public class MacroKeyBridge: NSObject, @unchecked Sendable {
    public let value: NSNumber?
    public let cycle: CycleMode
    public let comKeys: [MacroComkeyBridge]?
    public let intervalTime: Int

    public init(macroKey: MacroKey) {
        self.value = NSNumber(value: macroKey.value.gamepadOneByteKeyCode)
        self.cycle = macroKey.cycle
        self.intervalTime = macroKey.intervalTime
        self.comKeys = macroKey.comKeys.map { MacroComkeyBridge(comkey: $0) }
    }
}

extension DataHelper {
    //宏录制的数据处理
    func analyzeRecordKeys(_ data: Data) -> [String: Any] {
        
        var dic: [String: Any] = [:]
        
        var comboKeys: [GamepadKey] = []
        
        var parser = DataParser(data)
        
        //持续时间
        let duration = parser.next(2).toInt()
        //间隔时间
        let delay = parser.next(2).toInt()
        //子按键
        let subCount = parser.remaining
        let subKeyData = parser.trimmed()
        
        for _ in 0..<subCount {
            let comboKeyCode = parser.next(1).toInt()
            
            if let comboKey = GamepadKey.from(oneByteKeyCode: comboKeyCode) {
                comboKeys.append(comboKey)
            }
        }
        
        let comKey = MacroComkey(
            keys: comboKeys,
            keepTime: duration,
            intervalTime: delay
        )
        
        let comkeyBridge = MacroComkeyBridge(comkey: comKey)
        
        dic = [
            "data" : comkeyBridge,
        ]
        
        var tip = ""
        
        for key in comboKeys {
            tip += "\n按下\(key.gamepadKeyString)"
        }
        
        delegate?.receiveRecordKeys(comkeyBridge)
        
        return dic
    }
    
    func analyzeEndReport(_ data: Data) -> [String: Any] {
        
        var dic: [String: Any] = [:]
        
        let result = data.toInt()
        
        dic = [
            "code" : result
        ]
        
        delegate?.endRecordKeys(result)
        
        return dic
    }
}
