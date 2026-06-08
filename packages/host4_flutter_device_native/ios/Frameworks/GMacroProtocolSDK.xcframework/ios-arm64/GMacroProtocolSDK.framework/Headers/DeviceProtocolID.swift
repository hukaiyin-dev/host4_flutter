//
//  GMacroProtocolID.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/15.
//

import Foundation

enum GMacroProtocolID: UInt8 {

    // 设备 -> APP
    case page               = 0x0B // 设备请求工作模式切换 (iOS 不支持
    case currentPage        = 0x0E // 查询当前默认页号
    case diOSMode           = 0x1B // 设备目前在哪个 iOS 模式

    // 手柄
    case gpkeys             = 0x03 // 按键信息—>配置页面用（手柄
    case gptest             = 0x07 // 按键测试->测试页面用（手柄
    case gpDeviceKeysState  = 0x74 // 按键上报->（手柄
    // 键鼠
    case kbkeys             = 0x13 // 按键信息—>配置页面用（键鼠
    case kbtest             = 0x17 // 按键测试->测试页面用（键鼠
    
    // APP -> 设备
    case mode               = 0x01 // 手柄工作模式切换
    case screen             = 0x02 // 屏幕尺寸信息
    case keys1              = 0x04 // 按键位置（协议版本 010000
    case keys2              = 0x0D // 按键位置（协议版本 020000
    case keysEnd            = 0x1D // 按键设置结束指令
    case reset              = 0x05 // 恢复出厂设置
    case dfu                = 0x06 // 空升
    case deviceTest         = 0x08 // 蓝牙 host 状态查询 (iOS 写死 0x01
    case deviceMsg          = 0x09 // 获取设备项目编码、协议版本、固件版本
    case appMode            = 0x0A // 切换设备连接模式（iOS 写死 0x03
    case currentiOSMode     = 0x1A // 询问设备目前在哪个 iOS 模式
    case iOSMode            = 0x1C // iOS 模式切换
    case special            = 0x1E // 特殊配置（根据每个游戏不同
    case macro              = 0x2D // 宏按键
    case macroTouch         = 0x2E // 宏按键触发方式
    case macroEnd           = 0x2F // 宏按键终止
    
    // 宏 APP -> 设备
    case startMacro         = 0x36 // 开始宏配置
    case endMaco            = 0x34 // 结束配置
    case devicePlatform     = 0x30 // 设备类型及当前平台
    case electricity        = 0x31 // 查询电量
    case sleep              = 0x32 // 查询睡眠时间
    case setSleep           = 0x33 // 设置睡眠时间
    case setVibrate         = 0x35 // 设置振动级别
    case setTurbo           = 0x37 // 设置连发速率
//    case trigger         = 0x38 // 查询扳机
    case setTrigger         = 0x39 // 设置扳机
    case keyMacro           = 0x3A // 设置宏定义子按键
    case keyMacroEnd        = 0x3B // 查询宏定义默认映射键
    case setKeyMacroEnd     = 0x3C // 设置宏定义默认映射键
    
    case keyMap             = 0x3D // 键值映射
    case mouseKeyMap        = 0x5E // 键值映射(映射鼠标)
    case keyboardKeyMap     = 0x5F // 键值映射(映射键盘)
    case currentMapping     = 0x50 // 查询按键映射当前配置

    case rocker             = 0x3E // 摇杆线性设置
    case rocker3D           = 0x3F // 摇杆 3D 设置（支持subid）
    case rockerAdditional = 0x59 // 摇杆附加功能设置
    case beginCheck         = 0x41 // 陀螺仪开启自校
    case stopCheck          = 0x42 // 陀螺仪结束自校
    case beginCalibration   = 0x55 //摇杆(subId 02) 扳机(subId 03)开始校准
    case stopCalibration     = 0x56 //摇杆(subId 02) 扳机(subId 03)结束校准
    
    case printingType       = 0x44 // 实物外观
    case testMontor         = 0x45 // 测试振动力
    case startRecord        = 0x46 // 开始录制宏子按键
    case endRecord          = 0x47 // 结束录制宏子按键
    case switchLayout       = 0x58 // ABXY 按键 Switch 布局开关
    
    
    case isAllowColor       = 0x4C // 查询设备支持设置颜色（可支持可不支持）
    case colorDevice        = 0x4D // 查询支持宏的按键
    case setLightColor      = 0x4E // 设置灯组颜色（支持subid）
    case setLightEffect     = 0x4F // 设置灯组灯效（支持subid）
    case light              = 0x82 // 查询设备支持灯效及当前灯效（支持subid）
    case lightGroup         = 0x4A // 查询设备支持灯效及当前灯效
    case getLightConfig     =
        0x71 //查询设备当前灯效（支持subid）
    case setLightConfig     =
        0x72 //设置当前灯效配置（支持subid）
    case channelLight       = 0x70 // 通道灯亮度（支持subid）
    
    // 宏 设备 -> APP
    case finishCheck        = 0x43 // 陀螺仪完成自校
    case finishCalibration  = 0x57  // 摇杆(subId:02) 扳机(subId:03)完成自校
    case keyValue           = 0x40 // 按键上报
    case recordValue        = 0x48 // 上报录制的宏子按键
    case endRecordValue     = 0x49 // 结束上报录制的宏子按键
    
    case deviceVersion      = 0x84 // 获取设备版本信息
    case deviceInfo         = 0x77 // 获取设备版本信息（支持subid）
    
    case currentMacro       = 0x79 // 查询宏定义当前配置（分包发送）（支持subid）
//    case currentMacro       = 0x52 // 查询宏定义当前配置
    case macroInterval      = 0x80 // 设置宏定义循环间隔（支持subid）
    case trigger3D          = 0x85 // 扳机曲线
    case supportKey         = 0x86 // 支持的按键
    
    
    case motion             = 0x5B // 体感设置二
    
    case handleMode         = 0x69 // 手柄工作模式
    
    case vibration          = 0x67 // 振动状态
    
    case handleProfile      = 0x81 // 手柄配置页
    case handleFunction     = 0x83 // 开关手柄功能以及回调
    case gyro               = 0x6A // 陀螺仪
    case mapping            = 0x6C // 手柄按键映射
    case error              = 0x00 // 错误值
    
    case iap2ConnectState = 0x75 // iap2设备连接状态
}

enum GamepadMode: Int {
    //备注：flutter专用0x04
    case normal     = 0x04
    case config     = 0x01
    case test       = 0x02
    case macro      = 0x10
}

enum iOSMode: Int {
    case normal     = 0
    case bleMouse   = 1
}


enum GMacroDeviceType: UInt8 {
    case normal     = 0x00 // 默认设备
    case gamepad    = 0x01 // 手柄
    case dongle     = 0x02 // Dongle
    var description: String {
        switch self {
        case .normal:
            return "默认设备"
        case .gamepad:
            return "手柄"
        case .dongle:
            return "Dongle"
        }
    }
}

//2026.5.28新增 判断当前协议 ID 是否包含子 ID（SubID）
extension GMacroProtocolID {
    /// 判断当前协议 ID 是否包含子 ID（SubID）
    static func hasSubID(_ pid: GMacroProtocolID) -> Bool {
        switch pid {
        case .deviceVersion,      // 0x84
             .deviceInfo,         // 0x77
             .rocker3D,           // 0x3F
             .trigger3D,          // 0x85
             .supportKey,         // 0x86
             .handleMode,         // 0x69
             .handleProfile,      // 0x81
             .handleFunction,     // 0x83
             .gyro,               // 0x6A
             .mapping,            // 0x6C
             .light,              // 0x82
             .channelLight,       // 0x70
             .vibration,          // 0x67
             .beginCalibration,   // 0x55
             .stopCalibration,    // 0x56
             .gpDeviceKeysState:  // 0x74
            return true
        default:
            return false
        }
    }

    /// 便捷实例写法：pid.hasSubID
    var hasSubID: Bool {
        return Self.hasSubID(self)
    }
}
