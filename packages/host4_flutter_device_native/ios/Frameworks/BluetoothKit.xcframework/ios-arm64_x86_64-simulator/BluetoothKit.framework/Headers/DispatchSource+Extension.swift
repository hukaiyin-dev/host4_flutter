//
//  DispatchSource+Extension.swift
//  LED
//
//  Created by hukaiyin on 2019/9/9.
//  Copyright © 2019 sunday. All rights reserved.
//

import Foundation

public
extension DispatchSource {
    
    /// 轮询（无限）, 返回的 timer timer?.cancel(), timer = nil 停止轮询
    ///
    /// - Parameters:
    ///   - interval: 延时多少秒开始行动
    ///   - repeating: 每隔多少秒行动一次
    ///   - handler: 重复行动内容
    /// - Returns: timer，timer?.cancel(), timer = nil 停止轮询
    public class func pollingSchedule(interval: DispatchTimeInterval = DispatchTimeInterval.seconds(0),
                               repeating: Double = 1,
                               handler: @escaping (DispatchSourceTimer?) -> Void)
    -> DispatchSourceTimer {
        
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timer.setEventHandler {
            handler(timer)
        }
        timer.schedule(deadline: DispatchTime.now() + interval, repeating: repeating)
        timer.resume()
        
        return timer
    }
}
