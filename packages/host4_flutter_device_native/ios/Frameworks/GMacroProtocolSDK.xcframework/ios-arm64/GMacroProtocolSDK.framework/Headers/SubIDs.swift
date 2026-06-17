//
//  SubIDs.swift
//  GameMacroSDKExample-ObjC
//
//  Created by hukaiyin on 2025/3/25.
//

import Foundation

/// 获取设备版本信息 84
enum DeviceVersionSubID: UInt8 {
    case version                = 0x01 // 获取设备版本信息
    case setReportRate          = 0x08 // 设置回报率
    case fetchReportRate        = 0x09 // 查询回报率
    case setChargingDock        = 0x0A // 设置充电底座启停开关
    case fetchChargingDock      = 0x0B // 查询充电底座启停开关

   var description: String {
        switch self {
        case .version:
            return "获取设备版本信息"
        case .setReportRate:
            return "设置回报率"
        case .fetchReportRate:
            return "查询回报率"
        case .setChargingDock:
            return "设置充电底座启停开关"
        case .fetchChargingDock:
            return "查询充电底座启停开关"
        }
    }

    var proID: GMacroProtocolID {
        return GMacroProtocolID.deviceVersion
    }
}

/// 获取设备版本信息 77
enum DeviceInfoSubID: UInt8 {
    case gameMacroDefault   = 0x04 // Game Macro 默认值（完整设备配置）
    case mobpad             = 0x08 // 魔派设备信息
    
   var description: String {
        switch self {
        case .gameMacroDefault:
            return "Game Macro 默认值"
        case .mobpad:
            return "魔派设备信息"
        }
    }

    var proID: GMacroProtocolID {
        return GMacroProtocolID.deviceInfo
    }
}

/// 摇杆 3D 设置 3F
enum RockerSubID: UInt8 {
    case leftCurve                  = 0x0D // 左摇杆曲线
    case rightCurve                 = 0x0E // 右摇杆曲线
    case deadZoneCompensation       = 0x12 // 设置摇杆死区补偿
    case deadZoneRegressionComp     = 0x13 // 设置摇杆死区回归补偿
    case triggerModeAndButton       = 0x14 // 设置摇杆曲线触发方式及触发按键
    case rockerOutputGraphics       = 0x15 // 设置摇杆输出轨迹
    case setAntiDeadZone            = 0x1D // 设置摇杆反死区
    case fetchAntiDeadZone          = 0x1E // 获取摇杆反死区
    
   var description: String {
        switch self {
        case .leftCurve:
            return "左摇杆曲线"
        case .rightCurve:
            return "右摇杆曲线"
        case .deadZoneCompensation:
            return "设置摇杆死区补偿"
        case .deadZoneRegressionComp:
            return "设置摇杆死区回归补偿"
        case .triggerModeAndButton:
            return "设置摇杆曲线触发方式及触发按键"
        case .rockerOutputGraphics:
            return "设置摇杆输出轨迹"
        case .setAntiDeadZone:
            return "设置摇杆反死区"
        case .fetchAntiDeadZone:
            return "获取摇杆反死区"
        }
    }
    
    var proID: GMacroProtocolID {
        return GMacroProtocolID.rocker3D
    }
}

/// 扳机曲线 85
enum TriggerSubID: UInt8 {
    case fetchLinearOutput          = 0x06 // 查询左右扳机线性输出
    case leftCurve                  = 0x03 // 左扳机曲线
    case rightCurve                 = 0x04 // 右扳机曲线
    case linearOutput               = 0x07 // 设置扳机线形输出
    case quickSwitch                = 0x08 // 设置快速扳机开关
    case getQuickSwitch             = 0x11 // 获取快速扳机开关
    
   var description: String {
        switch self {
        case .leftCurve:
            return "左扳机曲线"
        case .rightCurve:
            return "右扳机曲线"
        case .quickSwitch:
            return "设置快速扳机开关"
        case .getQuickSwitch:
            return "获取快速扳机开关"
        case .linearOutput:
            return "设置扳机线形输出"
        case .fetchLinearOutput:
            return "查询左右扳机线性输出"
        }
    }
    
    var proID: GMacroProtocolID {
        return GMacroProtocolID.trigger3D
    }
}

/// 支持按键查询子命令 ID 86
enum SupportKeySubID: UInt8 {
    case queryTurboKeys             = 0x01 // 查询支持连发的按键及参数
    case queryMappableKeys          = 0x02 // 查询支持映射的按键
    case queryMacroKeys             = 0x03 // 查询支持宏的按键
    case queryMappableGamepadKeys   = 0x04 // 查询支持映射为手柄的按键
    case queryMacroRecordableKeys   = 0x05 // 查询支持宏录制的按键
    case queryMacroTimeRange        = 0x06 // 查询宏录制时间参数范围
    case queryMacroMaxGroups        = 0x07 // 查询宏录制最大支持组数
    case queryGyroTriggerKeys       = 0x08 // 查询支持体感触发的按键
    case queryGyroMappingModes      = 0x09 // 查询支持体感映射的模式

   var description: String {
        switch self {
        case .queryTurboKeys:
            return "查询支持连发的按键及参数"
        case .queryMappableKeys:
            return "查询支持映射的按键"
        case .queryMacroKeys:
            return "查询支持宏的按键"
        case .queryMappableGamepadKeys:
            return "查询支持映射为手柄的按键"
        case .queryMacroRecordableKeys:
            return "查询支持宏录制的按键"
        case .queryMacroTimeRange:
            return "查询宏录制时间参数范围"
        case .queryMacroMaxGroups:
            return "查询宏录制最大支持组数"
        case .queryGyroTriggerKeys:
            return "查询支持体感触发的按键"
        case .queryGyroMappingModes:
            return "查询支持体感映射的模式"
        }
    }
    
    var proID: GMacroProtocolID {
        return GMacroProtocolID.supportKey
    }
}
    
/// 陀螺仪 SubID 6A
enum GyroSubID: UInt8 {
    case setGyroMappingType         = 0x09 // 设置陀螺仪映射类型
    case fetchGyroMappingType       = 0x0A // 查询陀螺仪映射类型
    case setHorizontalAxis          = 0x1A // 设置体感水平方向使用的轴（陀螺仪 Z 轴、Y 轴 或 Z+Y 混合）
    case fetchHorizontalAxis        = 0x1B // 查询体感水平方向轴向
    case setGyroSensitivityCurve    = 0x1C // 设置陀螺仪灵敏度曲线
    case fetchGyroSensitivityCurve  = 0x1D // 查询陀螺仪灵敏度曲线
    case setGyroXYInvert            = 0x0F // 设置陀螺仪 X 轴 Y 轴反转
    case fetchGyroXYInvert          = 0x10 // 查询陀螺仪 X 轴 Y 轴反转信息
    case setGyroDeadZoneComp        = 0x13 // 设置陀螺仪死区补偿（可用于抵消游戏内死区）
    case fetchGyroDeadZoneComp      = 0x14 // 查询陀螺仪死区补偿（仅适用于陀螺仪模拟摇杆）
    case setGyroSensitivity2        = 0x1E // 设置次级陀螺仪灵敏度（主要用于 FPS 游戏，开镜前/后不同）
    case fetchGyroSensitivity2      = 0x1F // 查询次级陀螺仪灵敏度（主要用于 FPS 游戏，开镜前/后不同）
    case setGyroXYRatio             = 0x22 // 设置陀螺仪XY轴比例
    case fetchGyroXYRatio           = 0x23 // 查询陀螺仪XY轴比例
    case setGyroOuterDeadZone       = 0x24 // 设置陀螺仪外圈死区
    case fetchGyroOuterDeadZone     = 0x25 // 查询陀螺仪外圈死区
    case setGyroAxisSwap            = 0x29 // 设置体感轴向交换
    case fetchGyroAxisSwap          = 0x2A // 获取体感轴向交换
    case setGyroParam     = 0x28 // 体感参数设置

    var description: String {
        switch self {
        case .setHorizontalAxis:
            return "设置体感水平方向使用的轴（陀螺仪 Z 轴、Y 轴 或 Z+Y 混合）"
        case .fetchHorizontalAxis:
            return "查询体感水平方向轴向"
        case .setGyroSensitivityCurve:
            return "设置陀螺仪灵敏度曲线"
        case .fetchGyroSensitivityCurve:
            return "查询陀螺仪灵敏度曲线"
        case .setGyroXYInvert:
            return "设置陀螺仪 X 轴 Y 轴反转"
        case .setGyroDeadZoneComp:
            return "设置陀螺仪死区补偿（可用于抵消游戏内死区）"
        case .setGyroSensitivity2:
            return "设置次级陀螺仪灵敏度（主要用于 FPS 游戏，开镜前和开镜后使用两套灵敏度）"
        case .fetchGyroSensitivity2:
            return "查询次级陀螺仪灵敏度（主要用于 FPS 游戏，开镜前和开镜后使用两套灵敏度）"
        case .setGyroXYRatio:
            return "设置陀螺仪XY轴比例"
        case .fetchGyroXYRatio:
            return "查询陀螺仪XY轴比例"
        case .setGyroMappingType:
            return "设置陀螺仪映射类型"
        case .fetchGyroMappingType:
            return "查询陀螺仪映射类型"
        case .setGyroOuterDeadZone:
            return "设置陀螺仪外圈死区"
        case .fetchGyroOuterDeadZone:
            return "查询陀螺仪外圈死区"
        case .setGyroAxisSwap:
            return "设置体感轴向交换"
        case .fetchGyroAxisSwap:
            return "获取体感轴向交换"
        case .fetchGyroDeadZoneComp:
            return "查询陀螺仪死区补偿（仅适用于陀螺仪模拟摇杆）"
        case .fetchGyroXYInvert:
            return "获取陀螺仪XY轴反转信息"
        case .setGyroParam:
            return "体感参数设置"
        }
    }

    var proID: GMacroProtocolID {
        return GMacroProtocolID.gyro
    }
}

enum MappingSubID: UInt8 {
    case setHandleMapping       = 0x0D // 设置手柄按键映射（单映射）
    case setMapping             = 0x10 // 设置手柄按键映射（多映射）
    case fetchAllMappings       = 0x11 // 查询手柄所有按键映射
    case fetchOneMapping        = 0x12 // 查询单个手柄按键映射
    
    var description: String {
        switch self {
        case .setHandleMapping:
            return "设置手柄按键映射(单)"
        case .setMapping:
            return "设置手柄按键映射(多)"
        case .fetchAllMappings:
            return "查询手柄所有按键映射"
        case .fetchOneMapping:
            return "查询单个手柄按键映射"
        }
    }
    
    var proID: GMacroProtocolID {
        return GMacroProtocolID.mapping
    }
}

/// 灯光 SubID 82
enum LightSubID: UInt8 {
    case fetchCurrent               = 0x01 // 查询设备支持灯效及当前灯效（支持模式固定，无小模式）ret
    case fetchLightPositionAndGroup = 0x04 // 查询灯光位置及组数
    case fetchSupportedLightEffects = 0x05 // 查询支持的灯效（灯位置）
    case fetchCurrentLightEffect    = 0x06 // 查询当前灯效（灯位置）

   var description: String {
        switch self {
        case .fetchLightPositionAndGroup:
            return "查询灯光位置及组数"
        case .fetchSupportedLightEffects:
            return "查询支持的灯效（灯位置）"
        case .fetchCurrentLightEffect:
            return "查询当前灯效（灯位置）"
        case .fetchCurrent:
            return "查询设备支持灯效及当前灯效（支持模式固定，无小模式）"
        }
    }
    
    var proID: GMacroProtocolID {
        return GMacroProtocolID.light
    }
}

/// 通道灯亮度 SubID 70
enum ChannelLightSubID: UInt8 {
    case setChannelSwitch        = 0x08 // 设置通道灯开关
    case fetchChannelSwitch      = 0x09 // 获取通道灯开关
    case setChannelBrightness    = 0x0A // 设置通道灯亮度
    case fetchChannelBrightness  = 0x0B // 获取通道灯亮度

   var description: String {
        switch self {
        case .setChannelSwitch:
            return "设置通道灯开关"
        case .fetchChannelSwitch:
            return "获取通道灯开关"
        case .setChannelBrightness:
            return "设置通道灯亮度"
        case .fetchChannelBrightness:
            return "获取通道灯亮度"
        }
    }
    
    var proID: GMacroProtocolID {
        return GMacroProtocolID.channelLight
    }
}


/// 陀螺仪 SubID 67
enum VibrationSubID: UInt8 {
    case fetchVibrationState                = 0x01 // 获取振动状态
    case setVibrationState                  = 0x02 // 设置振动状态
    case fetchVibrationTipState             = 0x03 // 获取振动提示状态
    case setVibrationTipState               = 0x04 // 设置振动提示状态
    case setAudioMotor                      = 0x05 // 设置音频马达开关
    case fetchAudioMotor                    = 0x06 // 获取音频马达开关
    case setMotorVibrationMode              = 0x07 // 设置马达振动模式
    case fetchMotorVibrationMode            = 0x08 // 获取马达振动模式
    case fetchMotorSwitchState              = 0x09 // 获取马达开关状态
    case setMotorSwitchState                = 0x0A // 设置马达开关状态
    case setTriggerTestGripVibration        = 0x0B // 设置扳机测试握把振动开关
    case fetchTriggerTestGripVibration      = 0x0C // 获取扳机测试握把振动开关
    case setTriggerVibration                = 0x0D // 设置扳机振动开关
    case fetchTriggerVibration              = 0x0E // 获取扳机振动开关

   var description: String {
        switch self {
        case .fetchVibrationState:
            return "获取振动状态"
        case .setVibrationState:
            return "设置振动状态"
        case .fetchVibrationTipState:
            return "获取振动提示状态"
        case .setVibrationTipState:
            return "设置振动提示状态"
        case .setAudioMotor:
            return "设置音频马达开关"
        case .fetchAudioMotor:
            return "获取音频马达开关"
        case .setMotorVibrationMode:
            return "设置马达振动模式"
        case .fetchMotorVibrationMode:
            return "获取马达振动模式"
        case .fetchMotorSwitchState:
            return "获取马达开关状态"
        case .setMotorSwitchState:
            return "设置马达开关状态"
        case .setTriggerTestGripVibration:
            return "设置扳机测试握把振动开关"
        case .fetchTriggerTestGripVibration:
            return "获取扳机测试握把振动开关"
        case .setTriggerVibration:
            return "设置扳机振动开关"
        case .fetchTriggerVibration:
            return "获取扳机振动开关"
        }
    }
    
    var proID: GMacroProtocolID {
        return GMacroProtocolID.vibration
    }
}

enum CalibrationStartSubID: UInt8 {
    case allCalibration             = 0x01 // 摇杆扳机校准
    case rockerCalibration          = 0x02 // 摇杆校准
    case triggerCalibration         = 0x03 // 扳机校准
    case quitCalibration          = 0x04 // 校准退出按键
    case supportCalibration         = 0x05 // 支持的校准
    
    var description: String {
        switch self {
        case .allCalibration:
            return "开始摇杆扳机校准"
        case .rockerCalibration:
            return "开启摇杆校准"
        case .triggerCalibration:
            return "开启扳机校准"
        case .quitCalibration:
            return "校准退出按键"
        case .supportCalibration:
            return "支持的校准"
        }
    }
    
    var proID: GMacroProtocolID {
        return GMacroProtocolID.beginCalibration
    }
}

enum CalibrationStopSubID: UInt8 {
    case allCalibration             = 0x01 // 摇杆扳机校准
    case rockerCalibration          = 0x02 // 摇杆校准
    case triggerCalibration         = 0x03 // 扳机校准
    
    var description: String {
        switch self {
        case .allCalibration:
            return "结束摇杆扳机校准"
        case .rockerCalibration:
            return "结束摇杆校准"
        case .triggerCalibration:
            return "结束扳机校准"
        }
    }
    
    var proID: GMacroProtocolID {
        return GMacroProtocolID.stopCalibration
    }
}

enum DeviceKeysStateSubID: UInt8 {
    case state_06             = 0x06 // 设备按键状态查询
    
    var description: String {
        switch self {
        case .state_06:
            return "设备按键状态查询"
        }
    }
    
    var proID: GMacroProtocolID {
        return GMacroProtocolID.gpDeviceKeysState
    }
}
