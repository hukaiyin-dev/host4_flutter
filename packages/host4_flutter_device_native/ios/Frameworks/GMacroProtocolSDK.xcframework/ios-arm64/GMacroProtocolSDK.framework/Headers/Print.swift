//
//  Misc.swift
//  Frame
//
//  Created by hukaiyin on 2023/5/16.
//

import Foundation

func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if !DEBUG
    return
    #endif
    if let handler = GPDConstant.logHandler {
        handler(items, separator, terminator)
        return
    }
    
    // 主项目未注入时默认输出
    let prefix = "GPD"
    let message = items.map { "\($0)" }.joined(separator: separator)
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss SSS"
    let timestamp = formatter.string(from: Date())
    Swift.print("[\(timestamp)] [\(prefix)] \(message)", separator: separator, terminator: terminator)
}
