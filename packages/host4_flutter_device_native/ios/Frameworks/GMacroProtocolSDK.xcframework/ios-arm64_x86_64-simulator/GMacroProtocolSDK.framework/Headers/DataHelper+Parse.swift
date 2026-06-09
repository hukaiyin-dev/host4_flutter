//
//  DataHelper+Parse.swift
//  LEDSDK
//
//  Created by hukaiyin on 2023/3/1.
//

import Foundation
import CoreBluetooth
import BluetoothKit

// MARK: - 解析协议

extension DataHelper {
    /// 处理接收到的数据
    /// - Parameter data: 包含所有信息的总数据
    /// - Length | 命令 ID | 命令序列号 sn |  结果 | 其它数据
    func parse(_ data: Data) {
        if data.count < 3 {
            print("长度错误")
            return;
        }
        
        let l = data.subdata(in: Range(NSRange(location: 0, length: 1))!)
        
        if l.toInt() != data.count {
            print("长度错误")
            return;
        }
        
        parse(data: data)
        
    }
    
    func parse(data: Data) {
        print("收到数据 <\(data.hexadecimal)>")
        
        // 提取协议字段
        let protocolIdData = data.subdata(in: Range(NSRange(location: 1, length: 1))!)
        let payload = data.subdata(in: Range(NSRange(location: 2, length: data.count - 3))!)
        let snData = data.subdata(in: Range(NSRange(location: data.count - 1, length: 1))!)
        let sn = data.last!
        
        let protocolID: UInt8 = protocolIdData.toBytes()[0]
        let pId: GMacroProtocolID = GMacroProtocolID(rawValue: protocolID) ?? .error
        
        //2026.5.58 新增：部分协议需要 subID 来区分不同的命令响应，因此在解析时尝试提取 subID 以构建更准确的 responseKey
        // 提取 subID
        var subID: UInt8? = nil
        if pId.hasSubID {
            if let first = payload.first {
                subID = first // first 本身就是 UInt8
            } else {
                print("⚠️ pid=0x\(String(format: "%02X", pId.rawValue)) 声明 hasSubID，但 payload 为空，sn=\(sn)")
            }
        }
//        let responseKey = ResponseKey(protocolID: pId, sn: sn)
        let responseKey = ResponseKey(protocolID: pId, subID: subID, sn: sn)
        
        
        print("📥 响应解析 responseKey: \(responseKey)")
        
//        callbackQueue.async { [unowned self] in
//            dispatchPrecondition(condition: .onQueue(self.callbackQueue))
//            
//            let (responseResult, isComplete) = parse(protocolID: pId, all: data, payload: payload, sn: snData)
//            var didCallback = false
//            
//            // 打印当前 pendingResponses 列表
//            print("📌 当前 pendingResponses keys:")
//            for key in self.pendingResponses.keys {
//                print("    • \(key)")
//            }
//            
//            // 1️⃣ 精确匹配
////            if let callback = self.pendingResponses.removeValue(forKey: responseKey) {
////                switch responseResult {
////                case .success(let dic): callback(.success(dic))
////                case .failure(let err): callback(.failure(err))
////                }
////                print("✅ 精确匹配回调成功，移除 pendingResponses[\(responseKey)]")
////                didCallback = true
////            }
//            
//            //2026.5.21 Flutter修改：先尝试精确匹配，如果数据完整则触发回调；如果数据不完整，则不触发回调，等待后续数据包完成后再尝试匹配。
//            if let callback = self.pendingResponses[responseKey] {
//                switch responseResult {
//                case .success(let dic):
//                    if isComplete {
//                        self.pendingResponses.removeValue(forKey: responseKey)
//                        callback(.success(dic))
//                        didCallback = true
//                    } else {
//                        // Multi-packet response is not complete yet.
//                        // Keep the pending callback and wait for the remaining packets.
//                    }
//
//                case .failure(let err):
//                    self.pendingResponses.removeValue(forKey: responseKey)
//                    callback(.failure(err))
//                    didCallback = true
//                }
//            }
//   
//
//            // 3️⃣ 数据完整但仍未匹配 → 最后保底执行
//            else if isComplete {
//                if let (anyKey, anyCallback) = self.pendingResponses
//                        .first(where: { $0.key.protocolID == pId }) {
//                    self.pendingResponses.removeValue(forKey: anyKey)
//                    switch responseResult {
//                    case .success(let dic): anyCallback(.success(dic))
//                    case .failure(let err): anyCallback(.failure(err))
//                    }
//                    print("🟡 强制触发挂起回调（数据完整但无匹配）: \(anyKey)")
//                    didCallback = true
//                } else {
//                    print("✅ 数据完整，但无回调可触发，仅移除 pendingResponses[\(responseKey)]")
//                    self.pendingResponses.removeValue(forKey: responseKey)
//                }
//            }
//
//            // 4️⃣ 未完整也未回调
//            if !didCallback && !isComplete {
//                print("⚠️ 数据未完整，且无匹配回调，保留 pendingResponses[\(responseKey)]")
//            }
//        }
        
        //2026.5.28 新增：严格区分有 subID 和无 subID 的协议的匹配策略：
        callbackQueue.async { [unowned self] in
            dispatchPrecondition(condition: .onQueue(self.callbackQueue))
            
            let (responseResult, isComplete) = parse(protocolID: pId, all: data, payload: payload, sn: snData)
            var didCallback = false
            
            // 🔑 核心逻辑：严格按 hasSubID 区分匹配策略
            print("📌 当前 pendingResponses keys:")
            for key in self.pendingResponses.keys {
                print("    • \(key)")
            }
            
            if pId.hasSubID {
                // ✅ 对有 subID 的协议：必须精确匹配 (protocolID, subID, sn)
                if let callback = self.pendingResponses[responseKey] {
                    switch responseResult {
                    case .success(let dic):
                        if isComplete {
                            self.pendingResponses.removeValue(forKey: responseKey)
                            callback(.success(dic))
                            didCallback = true
                            print("✅ [hasSubID] 精确匹配成功，触发回调并移除: \(responseKey)")
                        } else {
                            print("⏳ [hasSubID] 数据未完整，保留等待后续包: \(responseKey)")
                        }

                    case .failure(let err):
                        self.pendingResponses.removeValue(forKey: responseKey)
                        callback(.failure(err))
                        didCallback = true
                        print("✅ [hasSubID] 精确匹配成功（失败），触发回调并移除: \(responseKey)")
                    }
                } else {
                    // 对于有 subID 的协议，如果无精确匹配，直接忽略，等待超时或正确包
                    print("❌ [hasSubID] 无精确匹配的待处理回调，丢弃该包并等待超时: \(responseKey)")
                    // 不触发任何兜底逻辑
                }
            } else {
                // ✅ 对无 subID 的协议：先尝试精确匹配，再兜底
                if let callback = self.pendingResponses[responseKey] {
                    switch responseResult {
                    case .success(let dic):
                        if isComplete {
                            self.pendingResponses.removeValue(forKey: responseKey)
                            callback(.success(dic))
                            didCallback = true
                            print("✅ [noSubID] 精确匹配成功，触发回调并移除: \(responseKey)")
                        } else {
                            print("⏳ [noSubID] 数据未完整，保留等待后续包: \(responseKey)")
                        }

                    case .failure(let err):
                        self.pendingResponses.removeValue(forKey: responseKey)
                        callback(.failure(err))
                        didCallback = true
                        print("✅ [noSubID] 精确匹配成功（失败），触发回调并移除: \(responseKey)")
                    }
                } else if isComplete {
                    // 数据完整但精确匹配失败 → 按 protocolID 尝试兜底（仅对无 subID 协议）
                    if let (anyKey, anyCallback) = self.pendingResponses
                            .first(where: { $0.key.protocolID == pId && $0.key.subID == nil }) {
                        self.pendingResponses.removeValue(forKey: anyKey)
                        switch responseResult {
                        case .success(let dic): anyCallback(.success(dic))
                        case .failure(let err): anyCallback(.failure(err))
                        }
                        print("🟡 [noSubID] 兜底匹配成功，触发回调: \(anyKey)")
                        didCallback = true
                    } else {
                        print("✅ [noSubID] 数据完整但无回调可触发，忽略")
                        self.pendingResponses.removeValue(forKey: responseKey)
                    }
                }

                if !didCallback && !isComplete {
                    print("⏳ [noSubID] 数据未完整，保留待后续包: \(responseKey)")
                }
            }
        }
    }
    
    /// 按协议 ID 解析数据
    /// all是接收到的所有data
    /// payload是去掉开始的长度，ID，以及末尾的SN的data
    func parse(protocolID: GMacroProtocolID, all: Data, payload: Data, sn: Data) -> (response: Result<[String: Any], Error>, isComplete: Bool) {
        var responseDic: [String: Any] = [:]
        
        var isComplete = true
        
        switch protocolID {
            
        case .deviceInfo:
            // 多包数据（有 subID）
            if let (completeData, subID, sn) = handleSubIDFragmentedData(all, sn) {
                responseDic = analyzeDeviceInfo(completeData, subID, sn)
                isComplete = true
            } else {
                isComplete = false
            }
        case .deviceVersion:
            responseDic = analyzeDeviceVersion(payload)
        case .mode:
            return analyzeResult(payload: payload)
        case .rocker:
            return analyzeResult(payload: payload)
        case .rocker3D:
//            let subID = RockerSubID(rawValue: all[2])
            //2026.5.28 新增：rocker3D 协议需要 subID 来区分左右摇杆曲线和其他设置，因此在解析时尝试提取 subID 以构建更准确的 responseKey
            guard let subIDRaw = extractSubID(from: all, protocolID: protocolID),
                let subID = RockerSubID(rawValue: subIDRaw) else {
                return (.failure(invalidSubIDPacketError(protocolID, packet: all)), true)
            }
            switch subID {
            case .leftCurve:
                return analyzeResultWithSubId(payload: payload, isSubID: true, isDev: false)
            case .rightCurve:
                return analyzeResultWithSubId(payload: payload, isSubID: true, isDev: false)
            case .fetchAntiDeadZone:
                responseDic = analyzeRockerAntiDeadZone(payload)
            default:
                return analyzeResultWithSubId(payload: payload, isSubID: true, isDev: true)
            }
        case .rockerAdditional:
            return analyzeResult(payload: payload)
        case .setTrigger:
            return analyzeResult(payload: payload)
        case .supportKey:
            // 多包数据（有 subID）
//            let subID = SupportKeySubID(rawValue: all[2])
            //2026.5.28 新增：supportKey 协议需要 subID 来区分不同的查询类型，因此在解析时尝试提取 subID 以构建更准确的 responseKey
            guard let subIDRaw = extractSubID(from: all, protocolID: protocolID), let subID = SupportKeySubID(rawValue: subIDRaw) else {
                return (.failure(invalidSubIDPacketError(protocolID, packet: all)), true)
            }
            switch subID {
            case .queryMacroTimeRange:
                responseDic = analyzeMacroTimeRange(payload)
            case .queryMacroMaxGroups:
                responseDic = analyzeMacroMaxGroups(payload)
            case .queryGyroMappingModes:
                responseDic = analyzeGyroMappingModes(payload)
            default:
                if let (completeData, subID, sn) = handleSubIDFragmentedData(all, sn) {
                    responseDic = analyzeSupportKey(completeData, subID, sn)
                    isComplete = true
                } else {
                    isComplete = false
                }
            }
        case .currentMapping:
            // 多包数据（无 subID）
            if let (completeData, sn) = handleFragmentedData(all, sn) {
                responseDic = analyzeCurrnetMapping(completeData, sn)
                isComplete = true
            } else {
                isComplete = false
            }
        case .currentMacro:
            // 多包数据（有 subID）
            if let (completeData, subID, sn) = handleSubIDFragmentedData(all, sn) {
                responseDic = analyzeCurrentMacro(completeData, subID, sn)
                isComplete = true
            } else {
                isComplete = false
            }
        case .keyMacro:
            return analyzeResult(payload: payload)
        case .sleep:
            responseDic = analyzeSleep(payload)
        case .handleFunction:
            responseDic = analyzeHandleFunction(payload)
        case .light:
            // 多包数据（有 subID）
            if let (completeData, subID, sn) = handleSubIDFragmentedData(all, sn) {
                responseDic = analyzeLight(completeData, subID, sn)
                isComplete = true
            } else {
                isComplete = false
            }
        case .reset:
            return analyzeResultWithSubId(payload: payload, isSubID: true, isDev: true)
        case .gptest:
            responseDic = analyzeGamePadTestKeys(payload)
        case .gpDeviceKeysState:
//            let subID = DeviceKeysStateSubID(rawValue: all[2])
            //2026.5.28 新增：gpDeviceKeysState 协议需要 subID 来区分不同的状态上报类型，因此在解析时尝试提取 subID 以构建更准确的 responseKey
            guard let subIDRaw = extractSubID(from: all, protocolID: protocolID),
                      let subID = DeviceKeysStateSubID(rawValue: subIDRaw) else {
                return (.failure(invalidSubIDPacketError(protocolID, packet: all)), true)
            }
            
            if subID == .state_06{
                responseDic = analyzeGamePadKeysState(all)
            }
        case .gpkeys:
            responseDic = analyzeGamePadBitKeys(payload)
        case .vibration:
            responseDic = analyzeVibration(payload)
        case .handleMode:
            responseDic = analyzeHandleMode(payload)
        case .gyro:
//            let subID = GyroSubID(rawValue: all[2])
            //2026.5.28 新增：gyro 协议需要 subID 来区分不同的查询类型，因此在解析时尝试提取 subID 以构建更准确的 responseKey
            guard let subIDRaw = extractSubID(from: all, protocolID: protocolID),
                      let subID = GyroSubID(rawValue: subIDRaw) else {
                return (.failure(invalidSubIDPacketError(protocolID, packet: all)), true)
            }
            if subID == .setGyroParam{
                return analyzeResultWithSubId(payload: payload, isSubID: true, isDev: true)
            }else{
                responseDic = analyzeGyro(payload)
            }
        case .mapping:
            // 多包数据（有 subID）
//            let subID = MappingSubID(rawValue: all[2])
            //2026.5.28 新增：mapping 协议需要 subID 来区分不同的查询类型，因此在解析时尝试提取 subID 以构建更准确的 responseKey
            guard let subIDRaw = extractSubID(from: all, protocolID: protocolID),
                      let subID = MappingSubID(rawValue: subIDRaw) else {
                return (.failure(invalidSubIDPacketError(protocolID, packet: all)), true)
            }
            switch subID {
            case .fetchOneMapping:
                responseDic = analyzeMappings(payload)
            case .fetchAllMappings:
                // 多包数据（有 subID）
                if let (completeData, subID, sn) = handleSubIDFragmentedData(all, sn, skip: 1) {
                    responseDic = analyzeMapping(completeData, subID, sn)
                    isComplete = true
                } else {
                    isComplete = false
                }
                
            default:
                print("未处理的 MappingSubID 0x\(String(format: "%02X", subID.rawValue))")
            }
        case .startMacro:
            return analyzeResult(payload: payload)
        case .endMaco:
            return analyzeResult(payload: payload)
        case .recordValue:
            responseDic = analyzeRecordKeys(payload)
        case .startRecord:
            return analyzeResult(payload: payload)
        case .endRecord:
            return analyzeResult(payload: payload)
        case .setSleep:
            return analyzeResultWithSubId(payload: payload, isSubID: true, isDev: true)
        case .beginCheck:
            return analyzeCheckResult(payload: payload)
        case .stopCheck:
            responseDic = analyzeStopCalibration(payload, protocolID: protocolID)
        case .finishCheck:
            responseDic = analyzeFinishCalibration(payload, protocolID: protocolID)
        case .beginCalibration:
//            let subID = CalibrationStartSubID(rawValue: all[2])
            //2026.5.28 新增：beginCalibration 协议需要 subID 来区分不同的校准类型，因此在解析时尝试提取 subID 以构建更准确的 responseKey
            guard let subIDRaw = extractSubID(from: all, protocolID: protocolID),
                let subID = CalibrationStartSubID(rawValue: subIDRaw) else {
                return (.failure(invalidSubIDPacketError(protocolID, packet: all)), true)
            }
            switch subID {
            case .quitCalibration:
                return analyzeCalibrationResult(payload: payload)
            case .supportCalibration:
                return analyzeCalibrationResult(payload: payload)
            default:
                return analyzeCheckResult(payload: payload)
            }
            
        case .stopCalibration:
            responseDic = analyzeStopCalibration(payload, protocolID: protocolID)
        case .finishCalibration:
            responseDic = analyzeFinishCalibration(payload, protocolID: protocolID)
        case .keyMap:
            return analyzeResult(payload: payload)
        case .setTurbo:
            return analyzeResult(payload: payload)
        case .motion:
            return analyzeResult(payload: payload)
        case .setVibrate:
            return analyzeResult(payload: payload)
        case .getLightConfig:
            responseDic = analyzeCurrentLightConfig(payload)
        case .setLightConfig:
            return analyzeResultWithSubId(payload: payload, isSubID: true, isDev: true)
        case .channelLight:
            responseDic = analyzeChannelLight(payload)
        case .handleProfile:
            responseDic = analyzeHandleProfile(payload)
        case .trigger3D:
//            let subID = TriggerSubID(rawValue: all[2])
            //2026.5.28 新增：trigger3D 协议需要 subID 来区分不同的查询类型，因此在解析时尝试提取 subID 以构建更准确的 responseKey
            guard let subIDRaw = extractSubID(from: all, protocolID: protocolID),
                     let subID = TriggerSubID(rawValue: subIDRaw) else {
                return (.failure(invalidSubIDPacketError(protocolID, packet: all)), true)
            }
            switch subID {
            case .fetchLinearOutput:
                responseDic = analyzeFetchLinearOutput(payload)
            case .linearOutput:
                return analyzeResultWithSubId(payload: payload, isSubID: true, isDev: true)
            case .getQuickSwitch:
                responseDic = analyzeQuickTrigger(payload)
            case .leftCurve:
                return analyzeResultWithSubId(payload: payload, isSubID: true, isDev: false)
            case .rightCurve:
                return analyzeResultWithSubId(payload: payload, isSubID: true, isDev: false)
            default:
                return analyzeResultWithSubId(payload: payload, isSubID: true, isDev: true)
            }
        case .switchLayout:
            return analyzeResult(payload: payload)
        case .iap2ConnectState:
            responseDic = analyzeDevConnectState(payload)
        default:
            print("未处理的 protocolID 0x\(String(format: "%02X", protocolID.rawValue))")
            break
        }
        
        return (.success(responseDic), isComplete)
    }
    
    
    /// 处理成功/失败 数据， 不为 0 时判定为失败
    func analyzeResult(payload: Data) -> (response: Result<[String: Any], Error>, isComplete: Bool) {
        var responseDic: [String: Any] = [:]
        
        let result = payload.toInt()
        
        if result != 0 && result != 0x50{
            let error = BluetoothError.deviceReportedError(code: result)
            return (.failure(error), true)
        }
        
        responseDic = ["result": result]
        return (.success(responseDic), true)
    }
    
    /// 处理成功/失败 数据， 不为 0 时判定为失败(有subId的时候)
    func analyzeResultWithSubId(payload: Data, isSubID:Bool, isDev: Bool) -> (response: Result<[String: Any], Error>, isComplete: Bool) {
        var responseDic: [String: Any] = [:]
        
        var parser = DataParser(payload)
        
        if isSubID {
            parser.skip(1)
        }
        
        if (isDev) {
            parser.skip(1)
        }
        
        let result = parser.next(1).toInt()
        
        if result != 0 && result != 0x50{
            let error = BluetoothError.deviceReportedError(code: result)
            return (.failure(error), true)
        }
        
        responseDic = ["result": result]
        return (.success(responseDic), true)
    }
    
    /// 处理有subid,dev 成功/失败 数据， 为0 时判定为失败（校准使用）
    /// 原始设备值： 0 = 失败, 非0 = 成功；转换为外部统一约定：0 = 成功, 1 = 失败
    func analyzeCheckResult(payload: Data) -> (response: Result<[String: Any], Error>, isComplete: Bool) {
        var responseDic: [String: Any] = [:]
        var parser = DataParser(payload)
        
        parser.skip(2)  // 跳过 subID(1) + dev(1)
        
        let result = parser.next(1).toInt()
        
        if result == 0 {
            let error = BluetoothError.deviceReportedError(code: 1)
            
            return (.failure(error), true)
        }
        
        // result 非0(设备成功) → 转为 0(外部成功)
        responseDic = ["result": 0]
        
        return (.success(responseDic), true)
    }
    
    /// 处理分包数据，返回完整数据、subID、sn，如果未完成则返回 nil
    /// 格式 长度 | ID | SubID | 总包数 | 当前包序号 | 有效数据 | SN
    /// skip 表示 subID 后跳过的字节数，如有 dev 就传入 1
    private func handleSubIDFragmentedData(_ data: Data, _ snData: Data, skip: Int = 0) -> (Data, UInt8, UInt8)? {
        guard data.count >= 6 else { return nil } // 确保数据足够长
        
        let _ = data[0]
        let id = data[1]
        let subID = data[2]
        let totalPackets = Int(data[3 + skip])
        let currentPacketIndex = Int(data[4 + skip])
        let payloadStart = 5 + skip
        let payload = data.subdata(in: payloadStart..<data.count-1)
        let sn = snData[0]
        
        
        // 收到第 1 个包时初始化
        if currentPacketIndex == 1 {
            keepReceive = true
            receivingData.removeAll()
            expectedPacketCount = totalPackets
            receivedPacketCount = 0
            currentReceivingProtocolID = GMacroProtocolID(rawValue: id) ?? .error
            currentReceivingSubID = subID
            currentReceivingSN = sn
        }
        
//        // 确保包序号递增
//        if currentPacketIndex == receivedPacketCount + 1 {
//            receivingData.append(payload)
//            receivedPacketCount += 1
//        } else {
//            print("⚠️ 数据包顺序异常，丢弃该包: 期望 \(receivedPacketCount + 1) 收到 \(currentPacketIndex)")
//            return nil
//        }
        
//        // 确保包序号递增
//        if currentPacketIndex == receivedPacketCount + 1 {
            receivingData.append(payload)
            receivedPacketCount += 1
//        } else {
//            print("⚠️ 数据包顺序异常，丢弃该包: 期望 \(receivedPacketCount + 1) 收到 \(currentPacketIndex)")
//            return nil
//        }
        
        
        // 数据接收完毕，返回完整数据
        if receivedPacketCount == expectedPacketCount {
            keepReceive = false
            let data = receivingData
            let subID = currentReceivingSubID
            let sn = currentReceivingSN
            resetReceivingState()
            return (data, subID, sn)
        }
        
        return nil
    }
    
    
    /// 处理分包数据，返回完整数据、sn，如果未完成则返回 nil
    /// 格式 长度 | ID | | 总包数 | 当前包序号 | 有效数据 | SN
    private func handleFragmentedData(_ data: Data, _ snData: Data) -> (Data, UInt8)? {
        guard data.count >= 6 else { return nil } // 确保数据足够长
        
        let _ = data[0]
        let id = data[1]
        let totalPackets = Int(data[2])
        let currentPacketIndex = Int(data[3])
        let payload = data.subdata(in: 4..<data.count-1)
        let sn = snData[0]
        
        
        // 收到第 1 个包时初始化
        if currentPacketIndex == 1 {
            keepReceive = true
            receivingData.removeAll()
            expectedPacketCount = totalPackets
            receivedPacketCount = 0
            currentReceivingProtocolID = GMacroProtocolID(rawValue: id) ?? .error
            currentReceivingSN = sn
        }
        
        // 确保包序号递增
        if currentPacketIndex == receivedPacketCount + 1 {
            receivingData.append(payload)
            receivedPacketCount += 1
        } else {
            print("⚠️ 数据包顺序异常，丢弃该包: 期望 \(receivedPacketCount + 1) 收到 \(currentPacketIndex)")
            return nil
        }
        
        
        // 数据接收完毕，返回完整数据
        if receivedPacketCount == expectedPacketCount {
            keepReceive = false
            let data = receivingData
            let sn = currentReceivingSN
            resetReceivingState()
            return (data, sn)
        }
        
        return nil
    }
    
    /// 清理接收缓存
    private func resetReceivingState() {
        receivingData.removeAll()
        expectedPacketCount = 0
        receivedPacketCount = 0
        currentReceivingProtocolID = nil
        currentReceivingSubID = 0
        currentReceivingSN = 0
    }
    
    //将一个data高低位转换，并且将为1的每个byte记录并返回这些byte的index,组成数组返回
    func getReversedBitIndices(from data: Data) -> [Int] {
        guard let byte = data.first else { return [] }
        
        // 反转字节的比特顺序
        var reversed: UInt8 = 0
        for i in 0..<8 {
            let bit = (byte >> i) & 1
            reversed |= bit << (7 - i)
        }
        
        // 收集反转后字节中所有值为1的位索引（索引0=MSB, 7=LSB）
        var indices = [Int]()
        for j in 0..<8 {
            if ((reversed >> (7 - j)) & 1) == 1 {
                indices.append(j)
            }
        }
        
        print("indices \(indices)")
        
        return indices
    }
}

private extension DataHelper {
    func extractSubID(from packet: Data, protocolID: GMacroProtocolID) -> UInt8? {
        guard protocolID.hasSubID else { return nil }
        guard packet.count > 2 else { return nil } // [len][pid][subID]...
        return packet[2]
    }

    func invalidSubIDPacketError(_ protocolID: GMacroProtocolID, packet: Data) -> BluetoothError {
        print("⚠️ 协议 0x\(String(format: "%02X", protocolID.rawValue)) 需要 subID，但数据长度不足: \(packet.count)")
        return .deviceReportedError(code: -1)
    }
}
