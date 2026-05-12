//
//  LightPosition.swift
//  BluetoothKitDemo
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation

/// 灯光位置
@objc public 
enum LightPosition: UInt8, Sendable {
    case leftStickRing    = 0x00 // 左摇杆光圈
    case rightStickRing   = 0x01 // 右摇杆光圈
    case leftAmbient      = 0x02 // 左氛围灯
    case rightAmbient     = 0x03 // 右氛围灯
    case homeButton       = 0x04 // HOME 键灯(logo灯)
    case backlight        = 0x05 // 背光灯
    case chargingDock     = 0x06 // 充电底座灯

   public var description: String {
        switch self {
        case .leftStickRing:
            return "左摇杆光圈"
        case .rightStickRing:
            return "右摇杆光圈"
        case .leftAmbient:
            return "左氛围灯"
        case .rightAmbient:
            return "右氛围灯"
        case .homeButton:
            return "HOME 灯(LOGO 灯)"
        case .backlight:
            return "背光灯"
        case .chargingDock:
            return "充电底座灯"
        }
    }
}
