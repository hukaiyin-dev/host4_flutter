//
//  BluetoothKitManager+Map.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/19.
//

import Foundation

// MARK: - 映射
extension GMacroProtocolSession {
    
    /// 查询支持映射的按键
    public func queryMappableKeys(profile: Int,
                                  response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.queryMappableKeys(profile: profile, response: response)
    }
    
    /// 查询支持映射为手柄的按键
    public func queryMappableGamepadKeys(profile: Int,
                                         response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.queryMappableGamepadKeys(profile: profile, response: response)
    }
    
    /// 设置按键映射为手柄
    /// - Parameters:
    ///   - keyMappings: 按键映射数组
    public func setKeyMappings(_ keyMappings: [GamepadKeyMapping],
                               response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.keyMappingDatas(keyMappings: keyMappings, response: response)
    }
    
    /// 设置手柄按键映射（单映射）6C0D
    /// - Parameters:
    ///   - original: 原始按键
    ///   - mapped: 映射按键
    public func setHandleKeyMapping(original: GamepadKey,
                                    mapped: GamepadKey,
                                    response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.setHandleKeyMapping(original: original, mapped: mapped, response: response)
    }
    
    /// 设置按键映射为鼠标
    /// - Parameters:
    ///   - keyMappings: 鼠标映射数组
    public func setMouseKeyMappings(_ keyMappings: [MouseKeyMapping],
                                    response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.mouseKeyMappingDatas(keyMappings: keyMappings, response: response)
    }
    
    /// 设置按键映射为键盘
    /// - Parameters:
    ///   - keyMappings: 键盘映射数组
    public func setKeyboardKeyMappings(_ keyMappings: [KeyboardKeyMapping],
                                       response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.keyboardKeyMappingDatas(keyMappings: keyMappings, response: response)
    }
    
    /// 查询当前按键映射配置
    public func queryCurrentMapping(profile: Int,
                                    response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.currentMapping(profile: profile, response: response)
    }
    
}

// MARK: - 多映射按键支持（手柄/鼠标/键盘组合）
extension GMacroProtocolSession {
    
    /// 设置手柄按键映射（支持同时映射多种类型键值）
    /// 类型数量 ≤ 3，每种类型键值数量 ≤ 5，总映射键值数量 ≤ 5
    /// - Parameters:
    ///   - original: 原始按键（GamepadKey）
    ///   - mappedKeys: 映射目标数组（MappedKey，支持 gamepad/mouse/keyboard
    public func setMultiKeyMapping(original: GamepadKey,
                                   mappedKeys: [MappedKey],
                                   finish: (() -> Void)? = nil,
                                   response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.multiKeyMapping(original: original,
                                          mappedKeys: mappedKeys,
                                          finish: finish,
                                          response: response)
    }
    
    /// 查询手柄所有按键映射（支持同时映射多种类型键值
    public func queryAllMultiMappings(finish: (() -> Void)? = nil,
                                      response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.currentMultiMapping(finish: finish, response: response)
    }
    
    /// 查询获取某个手柄按键映射（支持同时映射多种类型键值）
    /// - Parameters:
    ///   - original: 要查询的原始按键
    public func queryMultiMapping(for original: GamepadKey,
                                  finish: (() -> Void)? = nil,
                                  response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.currentMultiMapping(original: original,
                                              finish: finish,
                                              response: response)
    }
}
