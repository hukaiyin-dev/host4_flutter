//
//  BluetoothKitManager+Device.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/19.
//

import Foundation
import BluetoothKit

// MARK: - Device
extension GMacroProtocolSession {

    /// 设备版本信息
    public func fetchDeviceVersion(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.deviceVersion(response: response)
    }
    
    /// 设备信息（魔派）
    public func fetchMobapadDeviceInfo(profile: Int, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.deviceInfo(profile: profile, response: response)
    }
    
    /// 恢复出厂设置
    public func resetDevice(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.resetDevice(response: response)
    }
}


// MARK: - 模式切换
extension GMacroProtocolSession {
    public func switchToNormalMode(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.switchToNormalMode(response: response)
    }
    
    public func switchToTestMode(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.switchToTestMode(response: response)
    }
    
    
    public func switchToConfigMode(_ response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.switchToConfigMode(response: response)
    }
}

// MARK: - 回报率
extension GMacroProtocolSession {
    
    /// 设置回报率
    /// - Parameters:
    ///   - rate: 回报率（0-65535）（常规：125-1000）
    public func updateReportRate(_ rate: Int,
                                 finish: (() -> Void)? = nil,
                                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.updateReportRate(rate, response: response)
    }
    
    /// 查询回报率
    public func fetchReportRate(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchReportRate(response: response)
    }
}

extension DataHelper {
    
    /// 查询回报率 8409
    func fetchReportRate(finish: (() -> Void)? = nil,
                         response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        var payload = Data()
        
        // subID
        let subID = DeviceVersionSubID.fetchReportRate
        payload.append(Data.from(subID.rawValue))
        
        // device
        let device = GMacroDeviceType.gamepad
        payload.append(Data.from(device.rawValue))
        
        let protocolID = subID.proID
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    
    /// 设置 回报率 8408
    func updateReportRate(_ rate: Int,
                          finish: (() -> Void)? = nil,
                          response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        guard (0...0xFFFF).contains(rate) else {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        
        var payload = Data()
        
        // subID
        let subID = DeviceVersionSubID.setReportRate
        payload.append(Data.from(subID.rawValue))
        
        // device
        let device = GMacroDeviceType.gamepad.rawValue
        payload.append(Data.from(device))
        
        payload.append(Data.from(rate, count: 2))

        
        let protocolID = subID.proID

        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
}

// MARK: - 查询校准的模块
extension GMacroProtocolSession {
    /// 查询支持校准的模块
    public func fetchSupportCalibration(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchSupportCalibration(response: response)
    }
    
    /// 查询校准退出按键
    public func fetchCalibrationKey(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchCalibrationKey(response: response)
    }
    
    /// ABXY 按键 Switch 布局开关
    /// - Parameters:
    ///   - isOpen: 开关 0 是关，1 是开，开关快速切换 ABXY 按键布局，修改会清除 ABXY 按键的设置
    ///   - locking：十字键斜向锁：0：关（8 向），1：开（4 向）
    ///   - locking：左摇杆十字键互换：0：关，1：开
    public func updateSwitchLayout(isOpen : Bool, locking : Bool, exchange : Bool, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        dataHelper.updateSwitchLayout(isOpen: isOpen, locking: locking, exchange: exchange, response: response)
    }
}

// MARK: - 手柄工作模式
extension GMacroProtocolSession {
    
    /// 获取手柄工作模式 6901
    /// mode: 0=关闭, 1=XBOX, 2=Nintendo, 3=XBOX ONE
    public func fetchHandleWorkMode(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchHandleWorkMode(response: response)
    }
    
    /// 设置手柄工作模式 6902
    /// mode: 0=关闭, 1=XBOX, 2=Nintendo, 3=XBOX ONE
    public func updateHandleWorkMode(mode: Int,
                                     response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.setHandleWorkMode(mode: mode, response: response)
    }
    
    /// 获取当前手柄模式 6907
    /// mode: 1=XINPUT, 2=DINPUT, 3=Switch
    public func fetchCurrentHandleMode(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.fetchCurrentHandleMode(response: response)
    }
    
    /// 设置当前手柄模式 6908
    /// mode: 1=XINPUT, 2=DINPUT, 3=Switch
    public func updateCurrentHandleMode(mode: Int,
                                        response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.setCurrentHandleMode(mode: mode, response: response)
    }
}

// MARK: - 手柄配置页
extension GMacroProtocolSession {
    
    /// 切换手柄配置页 8101
    /// profile: 配置页编号
    public func switchToProfile(profile: Int,
                                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.switchToProfile(profile: profile, response: response)
    }
    
    /// 测试模式切换配置页 8102
    /// profile: 配置页编号
    public func switchToTestProfile(profile: Int,
                                     response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.switchToTestProfile(profile: profile, response: response)
    }
}

// MARK: - 开关手柄功能以及回调
extension GMacroProtocolSession {
    
    /// 开关手柄功能以及回调 8302
    /// - Parameters:
    ///   - handleOn: Bit0 手柄功能开关
    ///   - ep3CallbackOn: Bit1 EP3 回调开关
    public func updateHandleFunction(handleOn: Bool,
                                      ep3CallbackOn: Bool,
                                      response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        dataHelper.updateHandleFunction(handleOn: handleOn, ep3CallbackOn: ep3CallbackOn, response: response)
    }
}

extension DataHelper {
    
    /// 查询支持校准的模块
    func fetchSupportCalibration(finish: (() -> Void)? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        var payload = Data()
        
        let protocolID = GMacroProtocolID.beginCalibration
        
        // subID
        payload.append(Data.from(UInt8(0x05)))
        
        // device
        payload.append(Data.from(UInt8(0x00)))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    /// 查询校准退出按键
    func fetchCalibrationKey(finish: (() -> Void)? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        var payload = Data()
        
        let protocolID = GMacroProtocolID.beginCalibration
        
        // subID
        payload.append(Data.from(UInt8(0x04)))
        
        // device
        payload.append(Data.from(UInt8(0x00)))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
}
