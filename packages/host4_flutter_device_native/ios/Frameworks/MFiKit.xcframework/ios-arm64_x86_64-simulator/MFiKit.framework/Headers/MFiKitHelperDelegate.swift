//
//  MFiKitHelperDelegate.swift
//  MFiKit
//
//  Created by hukaiyin on 2025/11/6.
//

import Foundation

@objc public protocol MFiKitHelperDelegate: AnyObject {
    
    // 设备连接成功，可以开始通信
    @objc func startCommunication()
    
    // 接收到数据
    @objc func parse(data: Data)
    
    // 发生错误
    @objc func errorOccurred(_ error: Error)
    
    // 设备连接状态变化
    @objc func deviceConnectionDidChange(status: ConnectionStatus)
}

@objc public enum ConnectionStatus: Int {
    case connected      // 已连接
    case disconnected   // 已断开
    case failed         // 连接失败
}

@objc public enum MFiProtocolType: Int {
    case hid
    case iap2
}
