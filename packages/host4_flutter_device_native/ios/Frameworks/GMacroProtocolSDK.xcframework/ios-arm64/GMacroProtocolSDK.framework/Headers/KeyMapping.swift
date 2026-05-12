//
//  KeyMapping.swift
//  BluetoothKitDemo
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation

// 按键映射
public
struct GamepadKeyMapping: Sendable {
    public var original: GamepadKey  // 原始按键
    public var mapped: GamepadKey    // 映射按键
    
    public init(original: GamepadKey, mapped: GamepadKey) {
        self.original = original
        self.mapped = mapped
    }
    
    
}

// 键值映射（映射鼠标）
public
struct MouseKeyMapping: Sendable {
    public var original: GamepadKey    // 原始按键
    public var mapped: MouseKey        // 映射按键
    
    public init(original: GamepadKey, mapped: MouseKey) {
        self.original = original
        self.mapped = mapped
    }
}

// 键值映射（映射键盘）
public
struct KeyboardKeyMapping: Sendable {
    public var original: GamepadKey    // 原始按键
    public var mapped: KeyboardKey     // 映射按键
    
    public init(original: GamepadKey, mapped: KeyboardKey) {
        self.original = original
        self.mapped = mapped
    }
}

public enum MappedKeyType: Int, Sendable {
    case gamepad = 0
    case mouse = 1
    case keyboard = 2

    public var description: String {
        switch self {
        case .gamepad:
            return "手柄"
        case .mouse:
            return "鼠标"
        case .keyboard:
            return "键盘"
        }
    }
}

public enum MappedKey: Sendable {
    case gamepad([GamepadKey])
    case mouse([MouseKey])
    case keyboard([KeyboardKey])
    
    public var type: MappedKeyType {
        switch self {
        case .gamepad: return .gamepad
        case .mouse: return .mouse
        case .keyboard: return .keyboard
        }
    }

    public var values: [Int] {
        switch self {
        case .gamepad(let keys):
            return keys.map { $0.gamepadOneByteKeyCode }
        case .mouse(let keys):
            return keys.map { Int($0.rawValue) }
        case .keyboard(let keys):
            return keys.map { Int($0.rawValue) }
        }
    }
}

public struct MultiKeyMapping: Sendable {
    public var original: GamepadKey
    public var mapped: [MappedKey]

    public init(original: GamepadKey, mapped: [MappedKey]) {
        self.original = original
        self.mapped = mapped
    }
}



// MARK: - OC 兼容桥接类

@objcMembers
public class GamepadKeyMappingBridge: NSObject {
    public let original: Int
    public let mapped: Int

    public init(mapping: GamepadKeyMapping) {
        self.original = mapping.original.gamepadOneByteKeyCode
        self.mapped = mapping.mapped.gamepadOneByteKeyCode
    }
    
    @objc public init(original: Int, mapped: Int) {
        self.original = original
        self.mapped = mapped
    }
}

@objcMembers
public class MouseKeyMappingBridge: NSObject {
    public let original: Int
    public let mapped: Int

    public init(mapping: MouseKeyMapping) {
        self.original = mapping.original.gamepadOneByteKeyCode
        self.mapped = Int(mapping.mapped.rawValue)
    }
}

@objcMembers
public class KeyboardKeyMappingBridge: NSObject {
    public let original: Int
    public let mapped: Int

    public init(mapping: KeyboardKeyMapping) {
        self.original = mapping.original.gamepadOneByteKeyCode
        self.mapped = Int(mapping.mapped.rawValue)
    }
}

@objcMembers
public class MappedKeyBridge: NSObject {
    public let type: Int
    public let values: [Int]

    @objc public init(type: Int, values: [Int]) {
        self.type = type
        self.values = values
    }

    public init(mappedKey: MappedKey) {
        self.type = mappedKey.type.rawValue
        self.values = mappedKey.values
    }

    public func toMappedKey() -> MappedKey? {
        switch type {
        case MappedKeyType.gamepad.rawValue:
            let keys = values.compactMap { GamepadKey.from(oneByteKeyCode: $0) }
            return keys.isEmpty ? nil : .gamepad(keys)
        case MappedKeyType.mouse.rawValue:
            let keys = values.compactMap { MouseKey(rawValue: UInt8($0)) }
            return keys.isEmpty ? nil : .mouse(keys)

        case MappedKeyType.keyboard.rawValue:
            let keys = values.compactMap { KeyboardKey(rawValue: UInt8($0)) }
            return keys.isEmpty ? nil : .keyboard(keys)

        default:
            return nil
        }
    }
}

@objcMembers
public class MultiKeyMappingBridge: NSObject {
    public let original: GamepadKey
    public let mapped: [MappedKeyBridge]

    public init(original: GamepadKey, mapped: [MappedKeyBridge]) {
        self.original = original
        self.mapped = mapped
    }

    @objc public convenience init(originalCode: Int, mapped: [MappedKeyBridge]) {
        if let key = GamepadKey.from(oneByteKeyCode: originalCode) {
            self.init(original: key, mapped: mapped)
        } else {
            fatalError("无法创建 GamepadKey")
        }
    }

    public var originalCode: Int {
        return original.gamepadOneByteKeyCode
    }
}
