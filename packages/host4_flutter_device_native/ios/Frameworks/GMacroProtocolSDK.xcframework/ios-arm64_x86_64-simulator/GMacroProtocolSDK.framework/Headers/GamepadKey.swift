//
//  GamepadKey.swift
//  BluetoothKitDemo
//
//  Created by hukaiyin on 2025/3/17.
//

import Foundation
import BluetoothKit

@objc public
enum GamepadKey: Int, CaseIterable, Sendable {
    
    case none = 0
    
    case m1 = 0x01, m2 = 0x02, m3 = 0x03, m4 = 0x04, m5 = 0x05, m6 = 0x06

    case SL_L = 0x11, SR_L = 0x12, SL_R = 0x13, SR_R = 0x14
    case SET_L = 0x21, SET_R = 0x22

    case A = 0xA0, B = 0xA1, X = 0xA2, Y = 0xA3
    case L1 = 0xA4, L2 = 0xA5, L3 = 0xA6
    case R1 = 0xA7, R2 = 0xA8, R3 = 0xA9
    case Back = 0xAA, Start = 0xAB, Menu = 0xAC, home = 0xAD, key_i = 0xAE
    case select = 0xAF

    case cross = 0xD0, Left = 0xD1, Right = 0xD2, Up = 0xD3, Down = 0xD4
    case LeftUp = 0xD5, RightUp = 0xD6, LeftDown = 0xD7, RightDown = 0xD8

    case J1 = 0xE0, lrLeft = 0xE1, lrRight = 0xE2, lrUp = 0xE3, lrDown = 0xE4
    case lrLeftUp = 0xE5, lrRightUp = 0xE6, lrLeftDown = 0xE7, lrRightDown = 0xE8

    case J2 = 0xF0, rrLeft = 0xF1, rrRight = 0xF2, rrUp = 0xF3, rrDown = 0xF4
    case rrLeftUp = 0xF5, rrRightUp = 0xF6, rrLeftDown = 0xF7, rrRightDown = 0xF8
    
    public var rawValue: Int {
        return gamepadOneByteKeyCode
    }
}

extension DataHelper {
    func analyzeGamePadBitKeys(_ data: Data) -> [String: Any] {
        
        var dic: [String: Any] = [:]
        var keys: [GamepadKey] = []
        
        var parser = DataParser(data)
        let keysData = parser.next(3)  // 3Byte keycode
//        keysData.byteSwapped() // 高低位转换
        keys.append(contentsOf: GamepadKey.keys(keysData))
        
        dic = [
            "keys": keys
        ]
        
        var tip = ""
        
        if let keys = dic["keys"] as? [GamepadKey] {
            for key in keys {
                tip += "\n按下\(key.gamepadKeyString)"
            }
        }
//        print("\n---------------------------------")
//        print("🕹️ \(tip)")
//        print("---------------------------------\n")
        delegate?.receiveConfigKeys(keys)
        return dic
    }
    
    func analyzeGamePadTestKeys(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        var keys: [GamepadKey] = []

        var parser = DataParser(data)
        
        let J1X = parser.next(1).toInt()    // 左摇杆 X 轴 0-255，0X7F 中位表示不动
        let J1Y = parser.next(1).toInt()    // 左摇杆 Y 轴
        let J2X = parser.next(1).toInt()    // 右摇杆 X 轴
        let J2Y = parser.next(1).toInt()    // 右摇杆 Y 轴
        
        var keysData = parser.next(4) //用 bit 表示多个按键的按下/抬起状态
        keysData.byteSwapped() // 高低位转换
        keys.append(contentsOf: GamepadKey.keys(keysData))
        
        let L2 = parser.next(1).toInt()    // L2 0-255
        let R2 = parser.next(1).toInt()    // R2 0-255

        var funcKeysData = parser.next(1) //用 bit 表示多个特殊按键的按下/抬起状态
        funcKeysData.byteSwapped() // 高低位转换
        keys.append(contentsOf: GamepadKey.keys(funcKeysData))
        
        
//        // 摇杆值转四方向按键
//        if J1X < 128 {
//            keys.append(GamepadKey.lrLeft)
//        } else if J1X > 128 {
//            keys.append(GamepadKey.lrRight)
//        }
//
//        if J1Y < 128 {
//            keys.append(GamepadKey.lrUp)
//        } else if J1Y > 128 {
//            keys.append(GamepadKey.lrDown)
//        }
//        
//        if J2X < 128 {
//            keys.append(GamepadKey.rrLeft)
//        } else if J2X > 128 {
//            keys.append(GamepadKey.rrRight)
//        }
//        
//        if J2Y < 128 {
//            keys.append(GamepadKey.rrUp)
//        } else if J2Y > 128 {
//            keys.append(GamepadKey.rrDown)
//        }
        
        dic = [
            "keys": keys,
            "J1X": J1X,
            "J1Y": J1Y,
            "J2X": J2X,
            "J2Y": J2Y,
            "L2": L2,
            "R2": R2
        ]
        

        var tip = ""
        
        
        if let J1X = dic["J1X"] as? Int {
            tip += "J1X: \(J1X), "
        }
        if let J1Y = dic["J1Y"] as? Int {
            tip += "J1Y: \(J1Y), "
        }
        if let J2X = dic["J2X"] as? Int {
            tip += "J2X: \(J2X), "
            
        }
        if let J2Y = dic["J2Y"] as? Int {
            tip += "J2Y: \(J2Y), "
            
        }
        if let L2 = dic["L2"] as? Int {
            tip += "L2: \(L2), "
            
        }
        if let R2 = dic["R2"] as? Int {
            tip += "R2: \(R2), "
        }
        
        if let keys = dic["keys"] as? [GamepadKey] {
            for key in keys {
                tip += "\n按下\(key.gamepadKeyString)"
            }
        }
        delegate?.receiveTestKeys(keys, j1x: J1X, j1y: J1Y, j2x: J2X, j2y: J2Y, l2: L2, r2: R2)
//        print("\n---------------------------------")
//        print("🕹️ \(tip)")
//        print("---------------------------------\n")
        
        return dic
    }
    
    //0x74 06解析
    func analyzeGamePadKeysState(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        
        var keys: [GamepadKey] = []

        var parser = DataParser(data)
        
        _ = parser.next(4) //保留位，暂时没用
        
        //按键
        var keysData = parser.next(4) //用 bit 表示多个按键的按下/抬起状态
        keysData.byteSwapped() // 高低位转换
        keys.append(contentsOf: GamepadKey.keysState(keysData))
        
        //左摇杆
        let J1X = parser.next(1).toInt()    // 左摇杆 X 轴 0-255，0X80 中位表示不动
        let J1Y = parser.next(1).toInt()    // 左摇杆 Y 轴
        
        //右摇杆
        let J2X = parser.next(1).toInt()    // 右摇杆 X 轴
        let J2Y = parser.next(1).toInt()    // 右摇杆 Y 轴
        
        //扳机
        let L2 = parser.next(1).toInt()    // LT 0-255
        let R2 = parser.next(1).toInt()    // RT 0-255
        
        _ = parser.next(13) //保留位，暂时没用
        
        let J1X_O = parser.next(2).toInt() //左摇杆 X_O
        let J1Y_O = parser.next(2).toInt() //左摇杆 Y_O
        let J2X_O = parser.next(2).toInt() //右摇杆 X_L
        let J2Y_O = parser.next(2).toInt()
            //右摇杆 Y_L
        let L2_O = parser.next(2).toInt()
            //左扳机 L
        let R2_O = parser.next(2).toInt() //右扳机 L
        
        dic = [
            "keys": keys,
            "J1X": J1X,
            "J1X_O" : J1X_O,
            "J1Y": J1Y,
            "J1Y_O" : J1Y_O,
            "J2X": J2X,
            "J2X_O" : J2X_O,
            "J2Y": J2Y,
            "J2Y_O" : J2Y_O,
            "L2": L2,
            "L2_O" : L2_O,
            "R2": R2,
            "R2_O" : R2_O,
        ]
        
        var tip = ""
        
        if let J1X = dic["J1X"] as? Int {
            tip += "J1X: \(J1X), "
        }
        if let J1X_O = dic["J1X_O"] as? Int {
            tip += "J1X_O: \(J1X_O), "
        }
        if let J1Y = dic["J1Y"] as? Int {
            tip += "J1Y: \(J1Y), "
        }
        if let J1Y_O = dic["J1Y_O"] as? Int {
            tip += "J1Y_O: \(J1Y_O), "
        }
        if let J2X = dic["J2X"] as? Int {
            tip += "J2X: \(J2X), "
        }
        if let J2X_O = dic["J2X_O"] as? Int {
            tip += "J2X_O: \(J2X_O), "
        }
        if let J2Y = dic["J2Y"] as? Int {
            tip += "J2Y: \(J2Y), "
        }
        if let J2Y_O = dic["J2Y_O"] as? Int {
            tip += "J2Y_O: \(J2Y_O), "
        }
        if let L2 = dic["L2"] as? Int {
            tip += "L2: \(L2), "
        }
        if let L2_O = dic["L2_O"] as? Int {
            tip += "L2_O: \(L2_O), "
        }
        if let R2 = dic["R2"] as? Int {
            tip += "R2: \(R2), "
        }
        if let R2_O = dic["R2_O"] as? Int {
            tip += "R2_O: \(R2_O), "
        }
        
        if let keys = dic["keys"] as? [GamepadKey] {
            for key in keys {
                tip += "\n按下\(key.gamepadKeyString)"
            }
        }
        
        delegate?.receiveDevKeysState(keys, j1x: J1X, j1x_o: J1X_O, j1y: J1Y, j1y_o: J1Y_O, j2x: J2X, j2x_o: J2X_O, j2y: J2Y, j2y_o: J2Y_O, l2: L2, l2_o: L2_O, r2: R2, r2_o: R2_O)
        
        return dic
    }
}

extension GamepadKey {
    /// 0x07 data 值对应的 单键  Byte 6789+12
    static func keys(_ data: Data) -> [GamepadKey] {
        var keys: [GamepadKey] = []
        let receiveKeyInt = data.toInt()

        for key in GamepadKey.allGamepadKeys {
            // &，不为 0，表示 receiveKeyInt 包含这个 key
            if receiveKeyInt & key.bitKeyCode != 0 {
                keys.append(key)
            }
        }

        return keys
    }
    
    /// 0x74 06 data 值对应的 单键  Byte
    static func keysState(_ data: Data) -> [GamepadKey] {
        var keys: [GamepadKey] = []
        let receiveKeyInt = data.toInt()

        for key in GamepadKey.allGamepadKeys {
            // &，不为 0，表示 receiveKeyInt 包含这个 key
            if receiveKeyInt & key.bitKeyCodeWithState != 0 {
                keys.append(key)
            }
        }

        return keys
    }
}

extension GamepadKey {
    private static let codeToKeyMap: [Int: GamepadKey] = {
        var map = [Int: GamepadKey]()
        for key in GamepadKey.allCases {
            map[key.gamepadOneByteKeyCode] = key
        }
        return map
    }()
    
    private static let stringToKeyMap: [String: GamepadKey] = {
        var map = [String: GamepadKey]()
        for key in GamepadKey.allCases {
            map[key.gamepadKeyString] = key
        }
        return map
    }()
    
    static func from(oneByteKeyCode: Int) -> GamepadKey? {
        return codeToKeyMap[oneByteKeyCode]
    }
    
    static func from(keyString: String) -> GamepadKey? {
        return stringToKeyMap[keyString]
    }
}

extension GamepadKey{
    
    
    static var errorString: String {
        return "无"
    }

    
    static let allOneByteGamepadKeys: [GamepadKey] = {
        return [
            m1, m2, m3, m4,
            
            A, B, X, Y,
            L1, L2, L3,
            R1, R2, R3,
            
            Back, Start, home, Menu, key_i,
            
            cross, Left, Right, Up, Down, LeftUp, RightUp, LeftDown, RightDown,
            J1, lrLeft, lrRight, lrUp, lrDown, lrLeftUp, lrRightUp, lrLeftDown,lrRightDown,
            J2, rrLeft, rrRight, rrUp, rrDown, rrLeftUp, rrRightUp, rrLeftDown, rrRightDown,
        ]
    }()
    
    static let allGamepadKeys: [GamepadKey] = {
        return [
            A, B, X, Y,
//            L, R,
            Left, Right, Up, Down,
            select, Start,
            L1, L2, L3,
            R1, R2, R3,
            J1, J2,
            Back, Menu, key_i, home,
            m1, m2, m3, m4,
        ]
    }()
    
    static let rockers = [GamepadKey.J1.gamepadKeyString, GamepadKey.J2.gamepadKeyString,
//                          GamepadKey.J1.keyboardKeyString, GamepadKey.J2.keyboardKeyString
    
    ] // 会绑弹框方法的按钮(范围灵敏度设置）
}
