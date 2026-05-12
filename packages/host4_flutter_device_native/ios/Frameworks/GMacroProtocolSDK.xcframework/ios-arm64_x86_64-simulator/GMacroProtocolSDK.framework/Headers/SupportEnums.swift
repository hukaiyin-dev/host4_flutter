//
//  SupportEnums.swift
//  BluetoothKitDemo
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation

/// 输出轨迹
@objc public
enum OutputGraphics: UInt8, Sendable {
    case circle        = 0  // 圆形
    case square        = 1  // 方形
    case roundedRect   = 2  // 圆角矩形

   public var description: String {
        switch self {
        case .circle:
            return "圆形"
        case .square:
            return "方形"
        case .roundedRect:
            return "圆角矩形"
        }
    }
}

/// 曲线触发方式
@objc public
enum CurveTriggerMode: UInt8, Sendable {
    case continuous     = 0  // 持续
    case click          = 1  // 单击
    case hold           = 2  // 按住

   public var description: String {
        switch self {
        case .continuous:
            return "持续"
        case .click:
            return "单击"
        case .hold:
            return "按住"
        }
    }
}

/// 陀螺仪映射类型
@objc public
enum GyroMappingType: UInt8, Sendable {
    case instant    = 1  // 即时
    case continuous = 2  // 持续

   public var description: String {
        switch self {
        case .instant:
            return "即时"
        case .continuous:
            return "持续"
        }
    }
}

/// 振动位置
@objc public
enum VibrationPosition: UInt8, Sendable {
    case left      = 0x01  // 左
    case right     = 0x02  // 右
    case both      = 0x03  // 同时

   public var description: String {
        switch self {
        case .left:
            return "左侧振动"
        case .right:
            return "右侧振动"
        case .both:
            return "左右同时振动"
        }
    }
}

/// 体感触发方式
@objc public
enum MotionTriggerMode: UInt8, Sendable {
    case continuous  = 0 // 持续
    case click       = 1 // 单击
    case hold        = 2 // 按下

   public var description: String {
        switch self {
        case .continuous:
            return "持续"
        case .click:
            return "单击"
        case .hold:
            return "按下"
        }
    }
}

/// 体感映射模式
@objc public
enum MotionMappingMode: UInt8, Sendable {
    case dPad       = 0 // 十字键
    case leftStick  = 1 // 左摇杆
    case rightStick = 2 // 右摇杆
    case mouse      = 3 // 鼠标

   public var description: String {
        switch self {
        case .dPad:
            return "十字键"
        case .leftStick:
            return "左摇杆"
        case .rightStick:
            return "右摇杆"
        case .mouse:
            return "鼠标"
        }
    }
}

/// 体感轴向
@objc public
enum GyroAxis: UInt8, Sendable {
    case zAxis      = 1 // Z 轴
    case yAxis      = 2 // Y 轴
    case zAndYAxis  = 3 // Z 轴 Y 轴混合

   public var description: String {
        switch self {
        case .zAxis:
            return "Z 轴"
        case .yAxis:
            return "Y 轴"
        case .zAndYAxis:
            return "Z 轴 Y 轴混合"
        }
    }
}

/// 支持映射键值类型
@objc public
enum MappingType: UInt8, Sendable {
    case gamepad    = 1   // 手柄
    case mouse      = 2   // 鼠标
    case keyboard   = 4   // 键盘
    case multimedia = 8   // 多媒体

   public var description: String {
        switch self {
        case .gamepad:
            return "手柄"
        case .mouse:
            return "鼠标"
        case .keyboard:
            return "键盘"
        case .multimedia:
            return "多媒体"
        default:
            return "未知类型"
        }
    }
}

/// 循环模式
@objc public
enum CycleMode: UInt8, Sendable {
    case loop       = 0   // 无限循环，再次按下停止
    case once       = 1   // 执行一次
    case hold       = 2   // 按住循环

   public var description: String {
        switch self {
        case .loop:
            return "无限循环"
        case .once:
            return "执行一次"
        case .hold:
            return "按住循环"
        }
    }
}
