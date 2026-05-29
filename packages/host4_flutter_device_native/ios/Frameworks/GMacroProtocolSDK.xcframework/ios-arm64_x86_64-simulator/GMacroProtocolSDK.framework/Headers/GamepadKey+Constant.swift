//
//  Key+Constant.swift
//  QMacro
//
//  Created by hukaiyin on 2020/3/13.
//  Copyright © 2020 sunday. All rights reserved.
//

import Foundation

extension GamepadKey {
    
    
    var gamepadOneByteKeyCode: Int {
        switch self {
        case .none:             return 0
        case .m1:               return 0x01
        case .m2:               return 0x02
        case .m3:               return 0x03
        case .m4:               return 0x04
        case .m5:               return 0x05
        case .m6:               return 0x06
        case .SL_L:             return 0x11
        case .SR_L:             return 0x12
        case .SL_R:             return 0x13
        case .SR_R:             return 0x14
        case .SET_L:            return 0x21
        case .SET_R:            return 0x22
        case .A:                return 0xA0
        case .B:                return 0xA1
        case .X:                return 0xA2
        case .Y:                return 0xA3
        case .L1:               return 0xA4
        case .L2:               return 0xA5
        case .L3:               return 0xA6
        case .R1:               return 0xA7
        case .R2:               return 0xA8
        case .R3:               return 0xA9
        case .Back:             return 0xAA
        case .Start:            return 0xAB
        case .Menu:             return 0xAC
        case .home:             return 0xAD
        case .key_i:                return 0xAE
            
        case .cross:            return 0xD0
        case .Left:             return 0xD1
        case .Right:            return 0xD2
        case .Up:               return 0xD3
        case .Down:             return 0xD4
        case .LeftUp:           return 0xD5
        case .RightUp:          return 0xD6
        case .LeftDown:         return 0xD7
        case .RightDown:        return 0xD8
            
        case .J1:               return 0xE0
        case .lrLeft:           return 0xE1
        case .lrRight:          return 0xE2
        case .lrUp:             return 0xE3
        case .lrDown:           return 0xE4
        case .lrLeftUp:         return 0xE5
        case .lrRightUp:        return 0xE6
        case .lrLeftDown:       return 0xE7
        case .lrRightDown:      return 0xE8
            
            
        case .J2:               return 0xF0
        case .rrLeft:           return 0xF1
        case .rrRight:          return 0xF2
        case .rrUp:             return 0xF3
        case .rrDown:           return 0xF4
        case .rrLeftUp:         return 0xF5
        case .rrRightUp:        return 0xF6
        case .rrLeftDown:       return 0xF7
        case .rrRightDown:      return 0xF8
            
        case .select:           return 0xAF
        }
    }
    
    var bitKeyCode: Int {
        switch self {
        case .A:                return 1 << 0
        case .B:                return 1 << 1
        case .X:                return 1 << 2
        case .Y:                return 1 << 3
        case .Left:             return 1 << 6
        case .Right:            return 1 << 7
        case .Up:               return 1 << 8
        case .Down:             return 1 << 9
        case .select:           return 1 << 10
        case .Start:            return 1 << 11
        case .L1:               return 1 << 12
        case .L2:               return 1 << 13
        case .L3:               return 1 << 14
        case .R1:               return 1 << 15
        case .R2:               return 1 << 16
        case .R3:               return 1 << 17
        case .J1:               return 1 << 18
        case .J2:               return 1 << 19
        case .Back:             return 1 << 20
        case .Menu:             return 1 << 21
        case .key_i:            return 1 << 22
        case .home:             return 1 << 23
        case .m1:               return 1 << 24
        case .m2:               return 1 << 25
        case .m3:               return 1 << 26
        case .m4:               return 1 << 27
        default:                return 0
        }
    }

    var bitKeyCodeWithState: Int {
        switch self {
        case .m1:               return 1 << 0
        case .m2:               return 1 << 1
        case .Back:             return 1 << 2
        case .Start:            return 1 << 3
        case .A:                return 1 << 4
        case .B:                return 1 << 5
        case .X:                return 1 << 6
        case .Y:                return 1 << 7
        case .L1:               return 1 << 8
        case .R1:               return 1 << 9
        case .L2:               return 1 << 10
        case .R2:               return 1 << 11
        case .L3:               return 1 << 12
        case .R3:               return 1 << 13
        case .Up:               return 1 << 14
        case .Down:             return 1 << 15
        case .Left:             return 1 << 16
        case .Right:            return 1 << 17
        case .m3:               return 1 << 21
        case .home:             return 1 << 22
        case .key_i:            return 1 << 23
        case .SET_L:            return 1 << 24
        case .m4:               return 1 << 25
        case .Menu:             return 1 << 26
        default:                return 0
        }
    }
    
    public var gamepadKeyString: String {
        switch self {
        case .none:             return "None"
        case .A:                return "A"
        case .B:                return "B"
        case .X:                return "X"
        case .Y:                return "Y"
            //        case .L:                return "L"
            //        case .R:                return "R"
        case .Right:            return "right"
        case .Left:             return "left"
        case .Down:             return "down"
        case .Up:               return "up"
        case .select:           return "Select"
        case .Start:            return "Start"
        case .L1:               return "L1"
        case .L2:               return "L2"
        case .L3:               return "L3"
        case .R1:               return "R1"
        case .R2:               return "R2"
        case .R3:               return "R3"
        case .J1:               return "J1"
        case .J2:               return "J2"
        case .Back:             return "Back"
        case .Menu:             return "〇"
        case .key_i:                return "i"
        case .m1:               return "M1"
        case .m2:               return "M2"
        case .m3:               return "M3"
        case .m4:               return "M4"
        case .SL_L:             return "SL_L"
        case .SR_L:             return "SR_L"
        case .SL_R:             return "SL_R"
        case .SR_R:             return "SR_R"
        case .SET_L:            return "SET_L"
        case .SET_R:            return "SET_R"
        case .home:             return "Home"
        case .cross:            return "cross"
        case .LeftUp:           return "LU"
        case .RightUp:          return "RU"
        case .LeftDown:         return "LD"
        case .RightDown:        return "RD"
            
        case .lrLeft:           return "lrL"
        case .lrRight:          return "lrR"
        case .lrUp:             return "lrU"
        case .lrDown:           return "lrD"
        case .lrLeftUp:         return "lrLU"
        case .lrRightUp:        return "lrRU"
        case .lrLeftDown:       return "lrLD"
        case .lrRightDown:      return "lrRD"
            
        case .rrLeft:           return "rrL"
        case .rrRight:          return "rrR"
        case .rrUp:             return "rrU"
        case .rrDown:           return "rrD"
        case .rrLeftUp:         return "rrLU"
        case .rrRightUp:        return "rrRU"
        case .rrLeftDown:       return "rrLD"
        case .rrRightDown:      return "rrRD"
        default:                return "未定义"
        }
        
    }
}
