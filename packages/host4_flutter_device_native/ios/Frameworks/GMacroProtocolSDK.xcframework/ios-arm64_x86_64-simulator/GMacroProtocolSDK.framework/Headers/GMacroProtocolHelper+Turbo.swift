//
//  BluetoothKitManager+Turbo.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/19.
//

import Foundation

// MARK: - 连发
extension GMacroProtocolSession {
    
    /// 设置连发速率
    /// - Parameters:
    ///   - values: 按键、连发、速率
    ///   - deviceType: 设备类型
    public func updateKeyTurbo(_ values: [(GamepadKey, TurboMode, Int)],
                        response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        // 将元组转换为 KeyTurbo 数组
        let keyTurbos = values.map {KeyTurbo(key: $0.0, turbo: $0.1, speed: $0.2) }
        
        dataHelper.turboDatas(keyTurbos: keyTurbos, response: response)
    }

    /// 查询支持连发的按键
    public func querySupportedTurboKeys(profile: Int,
                                        response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.querySupportedTurboKeys(profile: profile, response: response)
    }
}

