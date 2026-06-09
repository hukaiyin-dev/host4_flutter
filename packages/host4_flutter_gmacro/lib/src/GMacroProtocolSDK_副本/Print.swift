//
//  Misc.swift
//  Frame
//
//  Created by hukaiyin on 2023/5/16.
//

import Foundation

func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    // logHandler 优先级最高，无论 Debug/Release 均转发
    if let handler = GPDConstant.logHandler {
        handler(items, separator, terminator)
        return
    }
    #if !DEBUG
    return
    #endif
    // 未注入 logHandler 时，Debug 模式默认输出到控制台
    let prefix = "GPD"
    let message = items.map { "\($0)" }.joined(separator: separator)
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss SSS"
    let timestamp = formatter.string(from: Date())
    Swift.print("[\(timestamp)] [\(prefix)] \(message)", separator: separator, terminator: terminator)
}
