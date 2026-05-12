//
//  ModifierKey.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/8/6.
//

import Foundation

@objc public
enum ModifierKey: UInt8, CaseIterable {
    case none          = 0x00
    case leftControl   = 0x01  // bit(0)
    case leftShift     = 0x02  // bit(1)
    case leftAlt       = 0x04  // bit(2)
    case leftGUI       = 0x08  // bit(3)
    case rightControl  = 0x10  // bit(4)
    case rightShift    = 0x20  // bit(5)
    case rightAlt      = 0x40  // bit(6)
    case rightGUI      = 0x80  // bit(7)
}

extension ModifierKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none: return "None"
        case .leftControl: return "LeftControl"
        case .leftShift: return "LeftShift"
        case .leftAlt: return "LeftAlt"
        case .leftGUI: return "LeftGUI"
        case .rightControl: return "RightControl"
        case .rightShift: return "RightShift"
        case .rightAlt: return "RightAlt"
        case .rightGUI: return "RightGUI"
        }
    }
}

extension ModifierKey {
    /// 传入一个 byte，传出组合键
    static func buttons(from data: Data) -> [ModifierKey] {
        guard let bitmask = data.first else {
               return []
           }
        var result: [ModifierKey] = []
        for button in allCases {
            if button != .none && (bitmask & button.rawValue) != 0 {
                result.append(button)
            }
        }
        return result
    }
}

/** 和 KeyboardKey 不同
 
 let data = Data([0x12])
 let buttons = ModifierKey.buttons(from: data)
 print(buttons.map { $0.description }) // ["LeftShift", "RightControl"]
 
 */


import Foundation

@objc public
enum MouseCoreButton: UInt8, CaseIterable {
    case none           = 0x00
    case leftButton     = 0x01  // bit(0)
    case rightButton    = 0x02  // bit(1)
    case middleButton   = 0x04  // bit(2)
    case backButton     = 0x08  // bit(3)
    case forwardButton  = 0x10  // bit(4)
}


extension MouseCoreButton: CustomStringConvertible {
   public var description: String {
        switch self {
        case .none: return "None"
        case .leftButton: return "LeftButton"
        case .rightButton: return "RightButton"
        case .middleButton: return "MiddleButton"
        case .backButton: return "BackButton"
        case .forwardButton: return "ForwardButton"
        }
    }
}

extension MouseCoreButton {
    /// 传入一个 byte，传出组合键
    static func buttons(from data: Data) -> [MouseCoreButton] {
        guard let bitmask = data.first else {
            return []
        }
        var result: [MouseCoreButton] = []
        for button in allCases {
            if button != .none && (bitmask & button.rawValue) != 0 {
                result.append(button)
            }
        }
        return result
    }
}


import Foundation

@objc public
enum MouseWheelButton: UInt8, CaseIterable {
    case none            = 0x00
    case wheelUp         = 0x01  // bit(0)
    case wheelDown       = 0x02  // bit(1)
    case wheelLeft       = 0x04  // bit(2)
    case wheelRight      = 0x08  // bit(3)
    // bit(4)-bit(7) Reserved
}

extension MouseWheelButton: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none: return "None"
        case .wheelUp: return "WheelUp"
        case .wheelDown: return "WheelDown"
        case .wheelLeft: return "WheelLeft"
        case .wheelRight: return "WheelRight"
        }
    }
}

extension MouseWheelButton {
    /// 传入一个 byte，传出组合键
    static func buttons(from data: Data) -> [MouseWheelButton] {
        guard let bitmask = data.first else {
            return []
        }
        var result: [MouseWheelButton] = []
        for button in allCases {
            if button != .none && (bitmask & button.rawValue) != 0 {
                result.append(button)
            }
        }
        return result
    }
}

