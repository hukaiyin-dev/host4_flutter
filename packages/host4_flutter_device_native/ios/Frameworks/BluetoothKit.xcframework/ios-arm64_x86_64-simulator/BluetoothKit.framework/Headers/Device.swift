//
//  Device.swift
//  BaseBluetooth
//
//  Created by hukaiyin on 2021/7/26.
//  Copyright © 2021 sunday. All rights reserved.
//

import Foundation

public
class Device: NSObject, @unchecked Sendable {
    
    
    override init() { }
    
    static let current: Device = Device()
    
    var connected = false
    
    var otaByteCount = 0 // ota 单次下发 Byte 数
}
