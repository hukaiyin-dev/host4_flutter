//
//  SDKConstant.swift
//  LEDSDK
//
//  Created by hukaiyin on 2023/3/1.
//

import Foundation

struct BluetoothKitConstant {
    nonisolated(unsafe) static var deviceNames: [String] = [
        "LED", "Pixely", "macro",
    ]
    
    static let simulateDeviceName = "SHZJ"
    static let simulateService = "FFFF"
    // 数据服务与特征
    nonisolated(unsafe) static var service = ["FF00"]
    nonisolated(unsafe) static var commandCharacteristic = "FF01"
    nonisolated(unsafe) static var dataCharacteristic = "FF02"

    // OTA 服务与特征
    nonisolated(unsafe) static var otaService = "FF10"
    nonisolated(unsafe) static var otaCommandCharacteristic = "FF11"
    nonisolated(unsafe) static var otaDataCharacteristic = "FF12"
    
    // 可用特征
    nonisolated(unsafe) static var availableCharacteristics: [String] = [
        commandCharacteristic,
        dataCharacteristic,
        otaCommandCharacteristic,
        otaDataCharacteristic
    ]
    
    nonisolated(unsafe) static var characteristics: [String] = [
        commandCharacteristic,
        dataCharacteristic
    ]
    
    nonisolated(unsafe) static var otaCharacteristics: [String] = [
        otaCommandCharacteristic,
        otaDataCharacteristic
    ]
    
    nonisolated(unsafe) static var responseTimeout: TimeInterval = 5
    
    /// 多条消息之间的发送间隔
    nonisolated(unsafe) static var messageInterval: TimeInterval = 0.05
    
    
    nonisolated(unsafe) static var logHandler: ((_ items: [Any], _ separator: String, _ terminator: String) -> Void)?
}


public
enum BluetoothError: Error, LocalizedError {
    case timeout                            // 超时
    case deviceReportedError(code: Int)     // 设备上报错误
    case outOfRange                         // 越界
    case invalidInput                       // 非法输入

    public var errorDescription: String? {
        switch self {
        case .timeout:
            return "蓝牙设备响应超时"
        case .deviceReportedError(let code):
            return "设备上报错误码 \(code)"
        case .outOfRange:
            return "数据越界"
        case .invalidInput:
            return "非法输入"
        }
    }
}
