//
//  OTAProtocolID.swift
//  LEDSDK
//
//  Created by hukaiyin on 2023/3/11.
//

import Foundation

public
enum OTAProtocolID: Int, CaseIterable {
    
    case dfuReady       = 0x5000    // 查询是否可以开始升级
    case askBytes       = 0x5100    // 获取单次发送字节数
    case sendedBytes    = 0x5200    // 已发送数据字节总数
    case checkOTA       = 0x5300    // 检查升级是否成功

    case error      = 0xFF00
    
    var data: Data {
        return Data.from(rawValue, count: 2)
    }
}
