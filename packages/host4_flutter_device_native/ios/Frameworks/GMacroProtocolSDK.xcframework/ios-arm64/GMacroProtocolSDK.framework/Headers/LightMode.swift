//
//  LightMode.swift
//  BluetoothKitDemo
//
//  Created by hukaiyin on 2025/3/18.
//
import Foundation

/// 灯光大模式
@objc public
enum LightMajorMode: UInt8, Sendable {
    case constant      = 0x00 // 常亮
    case breathing     = 0x01 // 呼吸
    case gradient      = 0x02 // 七彩渐变
    case wave          = 0x03 // 幻彩跑马
    case singleWave    = 0x04 // 单色跑马

   public var description: String {
        switch self {
        case .constant: return"常亮"
        case .breathing: return"呼吸"
        case .gradient: return"七彩渐变"
        case .wave: return"幻彩跑马"
        case .singleWave: return"单色跑马"
        }
    }

    /// 获取小模式对应的 `UInt8` 值
    func subModeValue(subMode: LightSubMode) -> UInt8? {
        switch self {
        case .constant:
            switch subMode {
            case .fixedColor: return 0x00
            case .sequential: return 0x01
            case .random: return 0x02
            default: return nil
            }
            
        case .breathing:
            switch subMode {
            case .breathingFixedColor: return 0x00
            case .breathingSequential: return 0x01
            default: return nil
            }
            
        case .gradient:
            switch subMode {
            case .allLights: return 0x00
            case .centerLight: return 0x01
            default: return nil
            }

        case .wave:
            switch subMode {
            case .outward: return 0x00
            case .inward: return 0x01
            case .leftToRight: return 0x02
            case .clockwise: return 0x03
            case .counterClockwise: return 0x04
            default: return nil
            }

        case .singleWave:
            switch subMode {
            case .bounceLeftRight: return 0x00
            case .bounceCenter: return 0x01
            default: return nil
            }
        }
    }
}

/// 灯光小模式
@objc public
enum LightSubMode: Int, Sendable {

    case fixedColor         // 固定颜色
    case sequential         // 顺序切换
    case random             // 随机点亮

    case breathingFixedColor  // 固定颜色
    case breathingSequential  // 顺序切换

    case allLights          // 全灯点亮
    case centerLight        // 中间点亮

    case outward            // 两边往中间
    case inward             // 中间往两边
    case leftToRight        // 左边往右边
//    case rightToLeft        // 右边往左边
    case clockwise          // 顺时针
    case counterClockwise   // 逆时针

    case bounceLeftRight    // 左右两边来回
    case bounceCenter       // 中间两边来回

   public var description: String {
        switch self {
        case .fixedColor: return "固定颜色"
        case .sequential: return "顺序切换"
        case .random: return "随机点亮"
        case .breathingFixedColor: return "固定颜色"
        case .breathingSequential: return"顺序切换"
        case .allLights: return "全灯点亮"
        case .centerLight: return "中间点亮"
        case .outward: return "两边往中间"
        case .inward: return "中间往两边"
        case .leftToRight: return "左边往右边"
//        case .rightToLeft: return "右边往左边"
        case .clockwise: return "顺时针"
        case .counterClockwise: return "逆时针"
        case .bounceLeftRight: return "左右两边来回"
        case .bounceCenter: return "中间两边来回"
        }
    }
}
