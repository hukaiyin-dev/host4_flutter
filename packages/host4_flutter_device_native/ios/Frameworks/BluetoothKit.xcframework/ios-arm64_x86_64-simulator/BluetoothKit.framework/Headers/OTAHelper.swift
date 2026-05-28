//
//  OTAHelper.swift
//  BaseBluetooth
//
//  Created by hukaiyin on 2021/7/27.
//  Copyright © 2021 sunday. All rights reserved.
//

import Foundation

@objc
public protocol OTADelegate {
    func ota(progress: CGFloat)
    func otaDidSucceed()
    func otaDidFail(withCode code: Int)
}

public class OTAHelper: NSObject, @unchecked Sendable {
    @objc public static let shared = OTAHelper()
    var delegate: OTADelegate?

    var otaData: Data?
    var updating: Bool = false
    
    var otaReadyClosure: (() -> Void)?

    override init() {
        super.init()
    }
    
    
    /// 开始 OTA
    /// - Parameters:
    ///   - data: 从 .bin 获取的 data
    public func ota(with data:Data) {
        self.otaData = data
        OTAHelper.dfuReadyCheak(data)
    }
}
