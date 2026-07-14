//
//  SDKConstant.swift
//  LEDSDK
//
//  Created by hukaiyin on 2023/3/1.
//

import Foundation

public struct GPDConstant {

    public nonisolated(unsafe) static var logHandler: ((_ items: [Any], _ separator: String, _ terminator: String) -> Void)?

    nonisolated(unsafe) static var service = ["FF00"]
    nonisolated(unsafe) static var commandCharacteristic = "FF01"
    nonisolated(unsafe) static var dataCharacteristic = "FF02"


    public nonisolated(unsafe) static var responseTimeout: TimeInterval = 5

    /// 多条消息之间的发送间隔
    public nonisolated(unsafe) static var messageInterval: TimeInterval = 0.05

    /// MFI OTA 原始固件分片之间的发送间隔
    public nonisolated(unsafe) static var mfiOTAPacketInterval: TimeInterval = 0.01
}

