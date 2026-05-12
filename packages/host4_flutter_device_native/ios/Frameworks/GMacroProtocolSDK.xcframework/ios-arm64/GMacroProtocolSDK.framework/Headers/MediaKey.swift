//
//  MediaKey.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/8/6.
//

import Foundation

@objc public
enum MediaKey: UInt8, CaseIterable {
    case none        = 0x00
    case volumeUp    = 0xE9
    case volumeDown  = 0xEA
    case mute        = 0xE2
    case play        = 0xB0
    case pause       = 0xB1
    case screenshot  = 0xD3
    case multitask   = 0x40
    case pageUp      = 0x4B
    case pageDown    = 0x4E
}

extension MediaKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none: return "None"
        case .volumeUp: return "VolumeUp"
        case .volumeDown: return "VolumeDown"
        case .mute: return "Mute"
        case .play: return "Play"
        case .pause: return "Pause"
        case .screenshot: return "Screenshot"
        case .multitask: return "Multitask"
        case .pageUp: return "PageUp"
        case .pageDown: return "PageDown"
        }
    }
}

extension MediaKey {
    static func key(from data: Data) -> MediaKey {
        guard let value = data.first else {
            return .none
        }
        return MediaKey(rawValue: value) ?? .none
    }
    
    
    static func keys(from data: Data) -> [MediaKey] {
        var result: [MediaKey] = []
        for byte in data {
            if let key = MediaKey(rawValue: byte), key != .none {
                result.append(key)
            }
        }
        return result
    }
}
