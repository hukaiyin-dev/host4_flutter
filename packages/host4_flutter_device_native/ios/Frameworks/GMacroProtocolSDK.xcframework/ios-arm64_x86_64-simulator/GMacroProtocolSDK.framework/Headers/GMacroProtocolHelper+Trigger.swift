//
//  GMacroProtocolHelper+Trigger.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/19.
//

import Foundation

// MARK: - 扳机
extension GMacroProtocolSession {
    
    /// 设置扳机死区和余量
    public func trigger(leftMin: Int,
                 leftMax: Int,
                 rightMin: Int,
                 rightMax: Int,
                 finish:(()->())? = nil,
                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.trigger(leftMin: leftMin,
                           leftMax: leftMax,
                           rightMin: rightMin,
                           rightMax: rightMax,
                           finish: finish,
                           response: response)
    }
    
    /// 左扳机曲线设置
    /// - Parameters:
    ///   - cgPoints: 曲线点， X/Y 轴坐标: 实际的摇杆行程百分比（0-100）
    public func leftTriggerCurve(cgPoints:[CGPoint],
              response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        dataHelper.triggerCurve(cgPoints: cgPoints, subID: .leftCurve, response: response)
    }
    
    /// 右扳机曲线设置
    /// - Parameters:
    ///   - cgPoints: 曲线点， X/Y 轴坐标: 实际的摇杆行程百分比（0-100）
    public func rightTriggerCurve(cgPoints:[CGPoint],
              response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        dataHelper.triggerCurve(cgPoints: cgPoints, subID: .rightCurve, response: response)
    }
    
    
    /// 设置快速扳机开关
    /// - Parameters:
    ///   - leftOn: 左扳机
    ///   - rightOn: 右扳机
    public func triggerQuickSwitch(leftOn: Bool,
                            rightOn: Bool,
                            finish:(()->())? = nil,
                            response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.triggerQuickSwitch(leftOn: leftOn, rightOn: rightOn, response: response)
    }
    
    /// 获取快速扳机开关
    public func getTriggerQuickSwitch(
                            finish:(()->())? = nil,
                            response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
                                
        dataHelper.getTriggerQuickSwitch(response: response)
    }
}


extension GMacroProtocolSession {
    // MARK: - 扳机校准
    public func startTriggerCalibration(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.startTriggerCalibration(response: response)
    }
    
    public func endTriggerCalibration(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.endTriggerCalibration(response: response)
    }
}


extension GMacroProtocolSession {
    // MARK: - 设置左右扳机线性输出 85 07
    
    /// - Parameters:
    ///   leftMode: 1：线性输出 2：非线性输出
    ///   leftThreshold: 阈值：1-255（仅非线性输出使用）
    public func triggerLinearOutput(leftMode: Int, leftThreshold: Int, rightMode: Int, rightThreshold: Int, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        dataHelper.triggerLinearOutput(leftMode: leftMode, leftThreshold: leftThreshold, rightMode: rightMode, rightThreshold: rightThreshold, response: response)
    }
}
