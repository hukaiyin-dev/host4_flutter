//
//  BluetoothKitManager+Sleep.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/19.
//

import Foundation

// MARK: - 休眠时间
extension GMacroProtocolSession {
    
    /// 设置自动睡眠时间
    /// - Parameters:
    ///   - time: 休眠时间（0x00 - 0xFF）
    public func setSleepTime(time: Int,
                      response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchSleep(time: time, response: response)
    }

    /// 查询自动休眠时间
    public func getSleepTime(profile: Int,
                      response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchSleep(profile: profile, response: response)
    }
}
