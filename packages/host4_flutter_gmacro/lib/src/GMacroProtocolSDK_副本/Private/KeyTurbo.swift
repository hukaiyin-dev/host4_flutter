//
//  KeyTurbo.swift
//  BluetoothKitDemo
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation

// 连发
public
struct KeyTurbo {
    public var key: GamepadKey
    public var turbo: TurboMode
    public var speed: Int = 10
    
    public init(key: GamepadKey, turbo: TurboMode, speed: Int = 10) {
        self.key = key
        self.turbo = turbo
        self.speed = speed
    }
}
