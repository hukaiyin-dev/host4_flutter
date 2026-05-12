//
//  BluetoothKitManager+Macro.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/19.
//

import Foundation

// MARK: - 宏设置
extension GMacroProtocolSession {
    
    /// 查询宏定义当前配置
    public func queryCurrentMacro(profile: Int, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.currentMacro(profile: profile, response: response)
    }
    
    /// 查询支持宏的按键
    public func queryMacroKeys(profile: Int, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.queryMacroKeys(profile: profile, response: response)
    }
    
    /// 查询支持宏录制的按键
    public func queryMacroRecordableKeys(profile: Int, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.queryMacroRecordableKeys(profile: profile, response: response)
    }
    
    /// 查询宏录制时间参数范围
    public func queryMacroTimeRange(profile: Int, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.queryMacroTimeRange(profile: profile, response: response)
    }
    
    /// 查询宏录制最大支持组数
    public func queryMacroMaxGroups(profile: Int, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.queryMacroMaxGroups(profile: profile, response: response)
    }
    
    /// 设置宏定义子按键
    /// - Parameters:
    ///   - macroKey: 宏按键数据
    public func setMacroKeys(_ macroKey: MacroKey, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.comKeysDatas(macroKey: macroKey, response: response)
    }
    
    /// 设置宏定义循环间隔
    /// - Parameters:
    ///   - key: 宏按键 M1、M2、M3、M4 的键值
    ///   - intervalTime: 循环间隔 0-0xFFFFFFFF 单位 ms
    public func setMacroInterval(profile: Int, key: GamepadKey, intervalTime: Int, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.macroInterval(profile: profile, key: key, intervalTime: intervalTime, response: response)
    }
}

extension GMacroProtocolSession {
    public func startRecord(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.startRecord(response: response)
    }
    
    public func endRecord(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.resetDevice(response: response)
    }
}
