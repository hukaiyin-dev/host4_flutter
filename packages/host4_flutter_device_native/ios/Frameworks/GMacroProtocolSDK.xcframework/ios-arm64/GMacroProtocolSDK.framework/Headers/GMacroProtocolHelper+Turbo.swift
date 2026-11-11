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

    /// 0x37 0x80：设置 16 位连发速率，旧 0x37 接口保持不变。
    public func updateKeyTurbo16(_ values: [(GamepadKey, TurboMode, Int)],
                                 pressDuration: Int = 1,
                                 device: Int = 0,
                                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let keyTurbos = values.map { KeyTurbo(key: $0.0, turbo: $0.1, speed: $0.2, pressDuration: pressDuration) }
        dataHelper.turboDatas16(keyTurbos: keyTurbos, device: device, response: response)
    }

    /// 0x37 0x80：每个按键分别指定按压时间和连发间隔，单位均为 10ms。
    public func updateKeyTurboTiming(_ values: [(key: GamepadKey, turbo: TurboMode, pressDuration: Int, interval: Int)],
                                 device: Int = 0,
                                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let keyTurbos = values.map { KeyTurbo(key: $0.key, turbo: $0.turbo, speed: $0.interval, pressDuration: $0.pressDuration) }
        dataHelper.turboDatas16(keyTurbos: keyTurbos, device: device, response: response)
    }

    /// 0x37 0x81：查询单个按键的连发配置。
    public func queryKeyTurbo16(_ key: GamepadKey,
                                device: Int = 0,
                                response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.queryKeyTurbo16(key: key, device: device, response: response)
    }

    /// 0x37 0x82：查询所有按键的连发配置，响应以 0x83 多包返回。
    public func queryAllKeyTurbo16(device: Int = 0,
                                   response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.queryAllKeyTurbo16(device: device, response: response)
    }

    /// 查询支持连发的按键
    public func querySupportedTurboKeys(profile: Int,
                                        response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.querySupportedTurboKeys(profile: profile, response: response)
    }
}
