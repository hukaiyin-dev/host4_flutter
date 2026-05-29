//
//  BluetoothKitManager+Light.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/19.
//

import Foundation

// MARK: - 灯光
extension GMacroProtocolSession {
    
    /// 查询当前灯光状态
    public func fetchLight(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchLight(response: response)
    }
    
    /// 查询灯光位置及组数
    public func fetchLightPosition(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchLightPosition(response: response)
    }
    
    /// 查询支持的灯光特效
    public func fetchSupportedLightEffects(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchSupportedLightEffects(response: response)
    }
    
    /// 查询当前灯光特效
    public func fetchCurrentLightEffect(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchCurrentLightEffect(response: response)
    }
    
    /// 设置灯组颜色
    /// - Parameters:
    ///   - position: 灯光位置
    ///   - groupCount: 组数
    ///   - colors: 颜色数组（RGB）
    public func setLightColor(position: LightPosition,
                              groupCount: Int,
                              colors: [(red: UInt8, green: UInt8, blue: UInt8)],
                              response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.setLightColor(position: position, groupCount: groupCount, colors: colors, response: response)
    }
    
    /// 设置灯光效果
    /// - Parameters:
    ///   - position: 灯光位置
    ///   - groupCount: 组数
    ///   - isOn: 是否开启
    ///   - light: 亮度（0-100）
    ///   - speed: 速度（0-100）
    ///   - mode: 大模式
    ///   - subMode: 小模式
    ///   - colors: 颜色数组（RGB）
    public func setLightEffect(position: LightPosition,
                               groupCount: Int,
                               isOn: Bool,
                               light: Int,
                               speed: Int,
                               mode: LightMajorMode,
                               subMode: LightSubMode,
                               colors: [(red: UInt8, green: UInt8, blue: UInt8)],
                               response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.setLightEffect(position: position, groupCount: groupCount, isOn: isOn, light: light, speed: speed, mode: mode, subMode: subMode, colors: colors, response: response)
    }
}

// MARK: - 灯光
extension GMacroProtocolSession {
    /// 查询当前灯效配置
    public func fetchCurrentLightConfig(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchCurrentLightConfig(response: response)
    }
    
    /// 设置灯光效果
    /// - Parameters:
    ///   - effect:  1：单色；2：呼吸；3：色谱循环
    ///   - colors: 颜色数组（RGB）
    ///   - brightness: 亮度（0-100）
    ///   - speed: 速度（0-100）
    public func setLightConfig(effect: Int, colorR: UInt8, colorG: UInt8, colorB: UInt8, light: Int, speed: Int, profile: Int, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        dataHelper.setLightConfig(effect: effect, colorR: colorR, colorG: colorG, colorB: colorB, light: light, speed: speed, profile: profile, response: response)
    }

    /// 设置通道灯开关
    public func setChannelLightSwitch(isOn: Bool,
                                      response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.setChannelLightSwitch(isOn: isOn, response: response)
    }

    /// 查询通道灯开关
    public func fetchChannelLightSwitch(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchChannelLightSwitch(response: response)
    }

    /// 设置通道灯亮度
    /// - Parameter brightness: 亮度 0-100
    public func setChannelLightBrightness(brightness: Int,
                                          response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.setChannelLightBrightness(brightness: brightness, response: response)
    }

    /// 查询通道灯亮度
    public func fetchChannelLightBrightness(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchChannelLightBrightness(response: response)
    }
}
