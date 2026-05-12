//
//  GMacroProtocolHelper+Rocker.swift.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/19.
//

import Foundation

// MARK: -  摇杆
extension GMacroProtocolSession {
    /// 摇杆线性设置 3e
    /// - Parameters:
    ///   - leftMin: 左摇杆起始值(0-100)  默认值 10
    ///   - leftMax: 左摇杆终止值(0-100)  默认值 80，终止值 - 起始值 >= 10
    ///   - leftXFlip: 左摇杆反转 X  0 == 不反转, 1 == 反转
    ///   - leftYFlip: 左摇杆反转 Y
    ///   - rightMin: 右摇杆起始值
    ///   - rightMax: 右摇杆终止值
    ///   - rightXFlip: 右摇杆反转 X
    ///   - rightYFlip: 右摇杆反转 Y
    public func updateRockerLinear(leftMin: Int, leftMax: Int, leftXFlip: Bool, leftYFlip: Bool, rightMin: Int, rightMax: Int, rightXFlip: Bool, rightYFlip: Bool, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let info = LinearInfo(
            leftMin: leftMin, leftMax: leftMax, leftXFlip: leftXFlip, leftYFlip: leftYFlip,
            rightMin: rightMin, rightMax: rightMax, rightXFlip: rightXFlip, rightYFlip: rightYFlip
        )
        
        dataHelper.rockerLinear(info: info, response: response)
    }
    
    /// 左摇杆曲线设置
    /// - Parameters:
    ///   - cgPoints: 曲线点， X/Y 轴坐标: 实际的摇杆行程百分比（0-100）
    public func updateLeftRocker3DCurve(cgPoints:[CGPoint], response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        dataHelper.rocker3DCurve(cgPoints: cgPoints, subID: .leftCurve, response: response)
    }
    
    /// 右摇杆曲线设置
    /// - Parameters:
    ///   - cgPoints: 曲线点， X/Y 轴坐标: 实际的摇杆行程百分比（0-100）
    public func updateRightRocker3DCurve(cgPoints:[CGPoint],
                                         response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        dataHelper.rocker3DCurve(cgPoints: cgPoints, subID: .rightCurve, response: response)
    }
    
    /// 设置摇杆死区回归补偿
    /// - Parameters:
    ///   - left: 左摇杆（0-65535）
    ///   - right: 右摇杆
    public func rockerDeadZoneCompensation(left: Int,
                                           right: Int,
                                           response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.rockerDeadZone(left: left, right: right, subID: .deadZoneCompensation, response: response)
    }
    
    /// 设置摇杆死区补偿
    /// - Parameters:
    ///   - left: 左摇杆（0-65535）
    ///   - right: 右摇杆
    public func rockerDeadZoneRegressionComp(left: Int,
                                             right: Int,
                                             response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        dataHelper.rockerDeadZone(left: left, right: right, subID: .deadZoneRegressionComp, response: response)
        
    }
    
    
    /// 设置摇杆曲线触发方式以及触发按键
    /// - Parameters:
    ///   - leftRigger: 曲线触发方式 0：持续，1：单击，2：按住
    ///   - leftGamepadKey: 曲线触发按键
    ///   - rightRigger: 曲线触发方式
    ///   - rightGamepadKey: 曲线触发按键
    public func rockerTriggerType(leftRigger: CurveTriggerMode,
                                  leftGamepadKey: GamepadKey,
                                  rightRigger: CurveTriggerMode,
                                  rightGamepadKey: GamepadKey,
                                  response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.rockerTriggerType(leftRigger: leftRigger, leftGamepadKey: leftGamepadKey, rightRigger: rightRigger, rightGamepadKey: rightGamepadKey, response: response)
    }
    
    
    
    /// 设置摇杆输出轨迹
    /// - Parameters:
    ///   - left: 左摇杆 0：圆形，1：方形，2：椭圆（圆角矩形）
    ///   - right: 右摇杆
    public func rockerOutputGraphics(left: OutputGraphics,
                                     right:OutputGraphics,
                                     response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.rockerOutputGraphics(left: left, right: right, response: response)
    }
}


extension GMacroProtocolSession {
    
    /// 设置触发器测试握把振动开关
    public func updateTriggerTestVibrationSwitch(triggerTestVibration: Bool,
                                                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.update(triggerTestVibration: triggerTestVibration, response: response)
    }

    /// 查询触发器测试握把振动开关
    public func fetchTriggerTestVibrationSwitch(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchTriggerTestVibration(response: response)
    }

    /// 设置扳机振动开关
    public func updateTriggerVibration(triggerVibration: Bool,
                                             response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.update(triggerVibration: triggerVibration, response: response)
    }

    /// 查询扳机振动开关
    public func fetchTriggerVibration(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchTriggerVibration(response: response)
    }

    /// 设置陀螺仪X/Y轴比例
    /// - Parameters:
    ///   - gyroXYRatio: 比例 1-100
    public func updategyroXYRatio(gyroXYRatio: Int,
                                       response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.update(gyroXYRatio: gyroXYRatio, response: response)
    }

    /// 查询陀螺仪X/Y轴比例
    public func fetchgyroXYRatio(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchgyroXYRatio(response: response)
    }

    /// 设置陀螺仪映射类型
    public func updateGyroMappingType(gyroMappingType: GyroMappingType,
                                           response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.update(gyroMappingType: gyroMappingType, response: response)
    }

    /// 查询陀螺仪映射类型
    public func fetchGyroMappingType(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchGyroMappingType(response: response)
    }

    /// 设置充电底座启停开关
    public func updateChargingDock(isOn: Bool,
                                   response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.updateChargingDock(isOn, response: response)
    }

    /// 查询充电底座启停开关
    public func fetchChargingDock(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchChargingDock(response: response)
    }
}

extension GMacroProtocolSession {
    // MARK: - 摇杆校准
    public func startRockerCalibration(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.startRockerCalibration(response: response)
    }
    
    public func endRockerCalibration(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.endRockerCalibration(response: response)
    }
}


extension GMacroProtocolSession {
    // MARK: - 摇杆附加功能设置
    
    /// - Parameters:
    ///   - leftDeadZone: 外形死区:0：圆形，1：方形，2：椭圆（圆角矩形）
    ///   - leftOutMax: 输出最大值：0-100（0%-100%）
    ///   - leftCurveApply: 曲线应用：0：持续，1：单击，2：按住
    ///   - leftCurveApplyKey: 曲线应用按键：持续模式为 0，单击模式和按住模式设定按键（附表键值）
    ///   - leftLineCorrection: 直线修正：0：关（圆形内死区），1：开（方形内死区）
    public func updateRockerAdditional(leftDeadZone: Int, leftOutMax: Int, leftCurveApply: Int, leftCurveApplyKey: Int, leftLineCorrection: Int, rightDeadZone: Int, rightOutMax: Int, rightCurveApply: Int, rightCurveApplyKey: Int, rightLineCorrection: Int, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let info = RockerAdditionalInfo(
            leftDeadZone: leftDeadZone,
            leftOutMax: leftOutMax,
            leftCurveApply : leftCurveApply,
            leftCurveApplyKey : GamepadKey(rawValue: leftCurveApplyKey) ?? .none,
            leftLineCorrection: leftLineCorrection,
            
            rightDeadZone: rightDeadZone,
            rightOutMax: rightOutMax,
            rightCurveApply : rightCurveApply,
            rightCurveApplyKey : GamepadKey(rawValue: rightCurveApplyKey) ?? .none,
            rightLineCorrection: rightLineCorrection
        )
        
        dataHelper.rockerAdditional(info: info, response: response)
    }
}
