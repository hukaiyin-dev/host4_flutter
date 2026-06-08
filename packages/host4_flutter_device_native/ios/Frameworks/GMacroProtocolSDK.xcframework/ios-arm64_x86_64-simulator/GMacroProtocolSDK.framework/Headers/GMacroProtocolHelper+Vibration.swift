//
//  BluetoothKitManager+Vibration.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/19.
//

import Foundation

// MARK: - 振动
extension GMacroProtocolSession {
    
    /// 设置振动级别
    /// - Parameters:
    ///   - left: 左侧振动力（0-100）
    ///   - right: 右侧振动力（0-100）
    public func setVibrationLevel(left: Int,
                           right: Int,
                           response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.setVibrationLevel(left: left, right: right, response: response)
    }
    
    /// 测试振动力
    /// - Parameters:
    ///   - left: 左侧振动力（0-255）
    ///   - right: 右侧振动力（0-255）
    ///   - position: 振动位置
    public func testVibration(left: Int,
                       right: Int,
                       position: VibrationPosition,
                       response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.testVibration(left: left, right: right, position: position, response: response)
    }
}

// MARK: - 马达开关状态
extension GMacroProtocolSession {
    
    /// 获取马达开关状态 6709
    public func fetchMotorSwitchState(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchMotorSwitchState(response: response)
    }
    
    /// 设置马达开关状态 670A
    public func updateMotorSwitchState(isOn: Bool,
                                       response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.setMotorSwitchState(isOn: isOn, response: response)
    }
}
