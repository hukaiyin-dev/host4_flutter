//
//  MouseKey.swift
//  BluetoothKitDemo
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation

/// 鼠标按键
@objc public
enum MouseKey: UInt8, Sendable {
    case leftButton     = 0x01 // 鼠标左键
    case rightButton    = 0x02 // 鼠标右键
    case middleButton   = 0x03 // 鼠标中键
    case scrollUp       = 0x04 // 滚轮上
    case scrollDown     = 0x05 // 滚轮下
    case forward        = 0x06 // 前进
    case backward       = 0x07 // 后退

   public var description: String {
        switch self {
        case .leftButton:
            return "鼠标左键"
        case .rightButton:
            return "鼠标右键"
        case .middleButton:
            return "鼠标中键"
        case .scrollUp:
            return "滚轮上"
        case .scrollDown:
            return "滚轮下"
        case .forward:
            return "前进"
        case .backward:
            return "后退"
        }
    }
}
