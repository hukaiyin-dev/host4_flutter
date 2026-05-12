//
//  SDKConstant.swift
//  LEDSDK
//
//  Created by hukaiyin on 2023/3/1.
//

import Foundation

struct GPDConstant {
    
    nonisolated(unsafe) static var logHandler: ((_ items: [Any], _ separator: String, _ terminator: String) -> Void)?
    
    nonisolated(unsafe) static var service = ["FF00"]
    nonisolated(unsafe) static var commandCharacteristic = "FF01"
    nonisolated(unsafe) static var dataCharacteristic = "FF02"
    
    
    nonisolated(unsafe) static var responseTimeout: TimeInterval = 5
    
    /// 多条消息之间的发送间隔
    nonisolated(unsafe) static var messageInterval: TimeInterval = 0.05
}

