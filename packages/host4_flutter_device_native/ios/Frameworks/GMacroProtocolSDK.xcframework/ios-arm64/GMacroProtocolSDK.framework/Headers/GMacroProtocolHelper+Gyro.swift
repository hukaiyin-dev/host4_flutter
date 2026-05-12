//
//  BluetoothKitManager+Gyro.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/19.
//

import Foundation
import BluetoothKit

// MARK: - 体感
extension GMacroProtocolSession {
    
    /// 查询支持体感触发的按键
    public func queryGyroTriggerKeys(profile: Int,
                                     response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.queryGyroTriggerKeys(profile: profile, response: response)
    }
    
    /// 查询支持体感映射的模式
    public func queryGyroMappingModes(profile: Int,
                                      response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.queryGyroMappingModes(profile: profile, response: response)
    }
    
    /// 设置体感参数
    /// - Parameters:
    ///   - motionEnabled: 是否启用体感
    ///   - mappingEnabled: 是否启用体感映射（仅在非 Switch 模式有用）
    ///   - triggerMode: 体感触发方式
    ///   - triggerKey: 体感触发按键
    ///   - deadZone: 体感死区（0-100）
    ///   - sensitivity: 体感灵敏度（0-1000）
    ///   - mappingMode: 体感映射模式
    public func setMotion(motionEnabled: Bool,
                          mappingEnabled: Bool,
                          triggerMode: MotionTriggerMode,
                          triggerKey: GamepadKey,
                          deadZone: Int,
                          sensitivity: Int,
                          mappingMode: MotionMappingMode,
                          response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let info = MotionInfo(
            motionEnabled: motionEnabled,
            mappingEnabled: mappingEnabled,
            triggerMode: triggerMode,
            triggerKey: triggerKey,
            deadZone: deadZone,
            sensitivity: sensitivity,
            mappingMode: mappingMode
        )
        
        // 校验数据合法性
        guard info.isValid() else {
            response(.failure(BluetoothError.invalidInput))
            return
        }
        
        dataHelper.setMotion(info: info, response: response)
    }
    
    /// 设置体感二级灵敏度（FPS模式）
    /// - Parameters:
    ///   - isOn: 开关
    ///   - triggerMode: 触发模式（单击/按下）
    ///   - triggerKey: 触发按键
    ///   - sensitivity: 灵敏度 0-1000，默认 100；主要用于 FPS 类游戏，开镜前后使用不同灵敏度
    public func setMotionSecondary(isOn: Bool,
                                   triggerMode: MotionTriggerMode,
                                   triggerKey: GamepadKey,
                                   sensitivity: Int,
                                   response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.setMotionSecondary(isOn: isOn, triggerMode: triggerMode, triggerKey: triggerKey, sensitivity: sensitivity, response: response)
    }
    
   
    
    
    /// 设置体感水平方向使用的轴
    /// - Parameters:
    ///   - axis: 体感水平方向的轴
    public func setMotionHorizontalAxis(axis: GyroAxis,
                                        response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.setMotionHorizontalAxis(axis: axis, response: response)
    }
    
    /// 查询体感水平方向轴向
    public func fetchMotionHorizontalAxis(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
      
        dataHelper.fetchMotionHorizontalAxis(response: response)
    }
    
     /// 查询陀螺仪死区补偿（仅适用于陀螺仪模拟摇杆）
    public func fetchGyroDeadZoneComp(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchGyroDeadZoneComp(response: response)
    }
    
    /// 查询陀螺仪灵敏度曲线
    public func fetchGyroSensitivityCurve(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchGyroSensitivityCurve(response: response)
    }
    
    /// 查询陀螺仪灵敏度曲线
    public func fetchGyroSensitivity2(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchGyroSensitivity2(response: response)
    }
    
    /// 设置陀螺仪 X/Y 轴反转
    /// - Parameters:
    ///   - xOn: X 轴反转
    ///   - yOn: Y 轴反转
    public func setGyroXYInvert(xOn: Bool,
                                yOn: Bool,
                                response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.setGyroXYInvert(xOn: xOn, yOn: yOn, response: response)
    }
    
    
    /// 查询陀螺仪 XY 轴反转信息
    public func fetchGyroXYInvert(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchGyroXYInvert(response: response)
    }
    
    
    /// 设置陀螺仪死区补偿
    /// - Parameters:
    ///   - compensate: 补偿值（0-100）
    public func setGyroDeadZone(compensate: Int,
                                response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.setGyroDeadZone(compensate: compensate, response: response)
    }
}

extension GMacroProtocolSession {
    /// 设置陀螺仪灵敏度曲线
    /// - Parameters:
    ///   - x1/y1: 曲线点1
    ///   - x2/y2: 曲线点2
    ///   - x3/y3: 曲线点3
    public func setGyroSensitivityCurve(x1: Int, y1: Int,
                                        x2: Int, y2: Int,
                                        x3: Int, y3: Int,
                                        response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {

        let p1 = Point(x: x1, y: y1)
        let p2 = Point(x: x2, y: y2)
        let p3 = Point(x: x3, y: y3)
        
        dataHelper.setGyroSensitivityCurve(p1: p1, p2: p2, p3: p3, response: response)
    }
}


extension GMacroProtocolSession {
    /// 设置陀螺仪外圈死区
    /// - Parameters:
    ///   - gyroOuterDeadZone: 死区 0-100
    public func update(gyroOuterDeadZone: Int,
                       response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        
        dataHelper.update(gyroOuterDead: gyroOuterDeadZone, response: response)
    }
    
    /// 查询陀螺仪外圈死区
    public func fetchGyroOuterDeadZone(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchGyroOuterDeadZone(response: response)
    }
}

extension GMacroProtocolSession {
    // MARK: - 陀螺仪校准
    public func startGyroCalibration(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.startGyroCalibration(response: response)
    }
    
    public func endGyroCalibration(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.endGyroCalibration(response: response)
    }
    
    public func setMotionParam(mappingSwitch: Bool, mappingKey: Int, triggerMode: Int, triggerKey: Int, inputType: Int, inputMode: Int, rollReversal: Bool , pitchReversal: Bool, yawReversal: Bool, sensitivity: Int, deadZoneCompensation: Int, curveType: Int, curvature: Int, ratio: Int, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let info = MotionParam(
            mappingSwitch: mappingSwitch,
            mappingKey: GamepadKey(rawValue: mappingKey) ?? .none,
            triggerMode: triggerMode,
            triggerKey: triggerKey,
            inputType: inputType,
            inputMode: inputMode,
            rollReversal: rollReversal,
            pitchReversal: pitchReversal,
            yawReversal: yawReversal,
            deadZoneCompensation: deadZoneCompensation,
            curveType: curveType,
            curvature: curvature,
            ratio: ratio
        )
        
        dataHelper.setMotionParam(info: info, response: response)
    }
}
