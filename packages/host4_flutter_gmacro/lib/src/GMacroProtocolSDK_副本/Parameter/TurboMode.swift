//
//  TurboMode.swift
//  GameMacroSDKExample-ObjC
//
//  Created by hukaiyin on 2025/3/21.
//

import Foundation

@objc public
enum TurboMode: UInt8, Sendable {
    case semiAuto   = 0x00 // 半自动连发（按住时连发）
    case fullAuto   = 0x01 // 全自动连发（单击开启，再次单击取消）
    case disabled   = 0x02 // 关闭连发
    
    public var description: String {
        switch self {
        case .semiAuto:
            return "半自动连发"
        case .fullAuto:
            return "全自动连发"
        case .disabled:
            return "关闭连发"
        }
    }
}
