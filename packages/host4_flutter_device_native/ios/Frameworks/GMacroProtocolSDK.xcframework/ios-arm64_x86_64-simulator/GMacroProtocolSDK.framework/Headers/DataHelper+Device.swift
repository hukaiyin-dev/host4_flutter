//
//  DataHelper+Device.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation

extension DataHelper {
    
    func switchToNormalMode(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        change(mode: .normal, response: response)
    }
    
    func switchToTestMode(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        change(mode: .test, response: response)
    }
    
    func switchToConfigMode(response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        change(mode: .macro, response: response)
    }
    
    
    func change(mode: GamepadMode,
                finish:(()->())? = nil,
                response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let protocolID = GMacroProtocolID.mode
        
        let payload = Data(bytes: [mode.rawValue], count: 1)
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
        
    }
    
    // 获取设备版本
    func deviceVersion(finish:(()->())? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        
        
        var payload = Data()
        
        // subID
        let subID = DeviceVersionSubID.version
        payload.append(Data.from(subID.rawValue))
        
        // device
        let device = GMacroDeviceType.gamepad.rawValue
        payload.append(Data.from(device))
        
        let protocolID = subID.proID
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }

    // MARK: - 8410 获取唤醒 APP 的按键类型
    func fetchAppWakeKeyType(finish:(()->())? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        var payload = Data()

        let subID = DeviceVersionSubID.fetchAppWakeKeyType
        payload.append(Data.from(subID.rawValue))

        let device = GMacroDeviceType.gamepad.rawValue
        payload.append(Data.from(device))

        let protocolID = subID.proID
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // 获取设备信息(魔派)
    func deviceInfo(profile: Int,
                    finish:(()->())? = nil,
                    response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.deviceInfo
        
        var payload = Data()
        
        // subID 魔派
        let subID = 0x08
        payload.append(Data.from(UInt8(subID)))
        
        // profile
        payload.append(Data.from(UInt8(profile)))
        
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // MARK: - 7704 获取 Game Macro 默认值（完整设备配置）
    func fetchGameMacroDefault(profile: Int,
                                finish: (() -> Void)? = nil,
                                response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let protocolID = GMacroProtocolID.deviceInfo
        
        var payload = Data()
        
        // subID 0x04
        let subID = UInt8(0x04)
        payload.append(Data.from(subID))
        
        // profile
        payload.append(Data.from(UInt8(profile)))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    func resetDevice(finish:(()->())? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.reset
        
        var payload = Data()
        
        // subID
        let subID = 0x01
        payload.append(Data.from(UInt8(subID)))
        
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))
        
//        payload.append(Data.from(0x00)
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }

    // 查询实物外观类型 0x44
    func fetchPrintingType(finish: (() -> Void)? = nil,
                           response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let protocolID = GMacroProtocolID.printingType
        let all = dataFrom(protocolID: protocolID, payload: nil)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    
    func updateSwitchLayout(isOpen : Bool, locking : Bool, exchange : Bool,
                    finish:(()->())? = nil,
                    response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.switchLayout
        
        var payload = Data()

        payload.append(Data.from(isOpen.int, count: 1))
        payload.append(Data.from(locking.int, count: 1))
        payload.append(Data.from(exchange.int, count: 1))
        //param1
        payload.append(Data.from(0x00))
        //param2
        payload.append(Data.from(0x00))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // MARK: - 6901 获取手柄工作模式
    func fetchHandleWorkMode(finish: (() -> Void)? = nil,
                              response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = 0x01
        let protocolID = GMacroProtocolID.handleMode
        
        var payload = Data()
        payload.append(Data.from(subID, count: 1))  // subID
        payload.append(Data.from(0x05, count: 1))   // Dev
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 6902 设置手柄工作模式
    func setHandleWorkMode(mode: Int,
                            finish: (() -> Void)? = nil,
                            response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = 0x02
        let protocolID = GMacroProtocolID.handleMode
        
        var payload = Data()
        payload.append(Data.from(subID, count: 1))  // subID
        payload.append(Data.from(0x05, count: 1))   // Dev
        payload.append(Data.from(mode, count: 1))   // mode
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 6907 获取当前手柄模式
    func fetchCurrentHandleMode(finish: (() -> Void)? = nil,
                                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = 0x07
        let protocolID = GMacroProtocolID.handleMode
        
        var payload = Data()
        payload.append(Data.from(subID, count: 1))  // subID
        payload.append(Data.from(0x05, count: 1))   // Dev
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 6908 设置当前手柄模式
    func setCurrentHandleMode(mode: Int,
                               finish: (() -> Void)? = nil,
                               response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = 0x08
        let protocolID = GMacroProtocolID.handleMode
        
        var payload = Data()
        payload.append(Data.from(subID, count: 1))  // subID
        payload.append(Data.from(0x05, count: 1))   // Dev
        payload.append(Data.from(mode, count: 1))   // mode
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 8101 切换手柄配置页
    func switchToProfile(profile: Int,
                          finish: (() -> Void)? = nil,
                          response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = 0x01
        let protocolID = GMacroProtocolID.handleProfile
        
        var payload = Data()
        payload.append(Data.from(subID, count: 1))     // subID
        payload.append(Data.from(profile, count: 1))   // profile
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 8102 测试模式切换配置页
    func switchToTestProfile(profile: Int,
                              finish: (() -> Void)? = nil,
                              response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = 0x02
        let protocolID = GMacroProtocolID.handleProfile
        
        var payload = Data()
        payload.append(Data.from(subID, count: 1))     // subID
        payload.append(Data.from(profile, count: 1))   // profile
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 8302 开关手柄功能以及回调
    /// Bit0: 手柄功能开关 (0=关, 1=开)
    /// Bit1: EP3 回调开关 (0=关, 1=开)
    func updateHandleFunction(handleOn: Bool, ep3CallbackOn: Bool,
                               finish: (() -> Void)? = nil,
                               response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let protocolID = GMacroProtocolID.handleFunction
        
        var payload = Data()
        payload.append(Data.from(0x02, count: 1))  // subID
        payload.append(Data.from(0x05, count: 1))  // Dev
        
        // Bit0=手柄功能, Bit1=EP3回调
        let param = (handleOn ? 1 : 0) | (ep3CallbackOn ? 2 : 0)
        payload.append(Data.from(param, count: 1)) // param
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
}
// MARK: - Parse
extension DataHelper {
    
    func analyzeDeviceInfo(_ data: Data, _ subID: UInt8, _ sn: UInt8) -> [String: Any] {
        let subID = DeviceInfoSubID(rawValue: subID)
        switch subID {
        case .gameMacroDefault:
            return analyzeGameMacroDeviceInfo(data)
        case .mobpad:
            return analyzeMobpadDeviceInfo(data)
        case .none:
            print("未处理的 DeviceInfoSubID 0x\(String(format: "%02X", subID!.rawValue))")
            return [:]
        }
    }
    
    func analyzeGameMacroDeviceInfo(_ data: Data) -> [String: Any] {
        print("分析 Game Macro 默认值数据 \(data.count) \(data.nsDescription())")
        var parser = DataParser(data)
        var dic: [String: Any] = [:]

        // 1️⃣ 连发参数
        let rapidList = parseRapidFire(&parser)
        dic["rapidList"] = rapidList

        // 2️⃣ 左扳机: length(1) + start(1) + end(1) + macroOn(1) + macroThreshold(1) + pointCount(1) + X1,Y1...
        let _ = parser.next(1).toInt() // leftTriggerLength（跳过，不输出）
        let leftTriggerStart = parser.next(1).toInt()
        let leftTriggerEnd = parser.next(1).toInt()
        let leftTriggerMacroOn = parser.next(1).toInt() != 0
        let leftTriggerMacroThreshold = parser.next(1).toInt()
        let leftTriggerPointCount = parser.next(1).toInt()
        var leftTriggerPoints: [[Int]] = []
        for _ in 0..<leftTriggerPointCount {
            let x = parser.next(1).toInt()
            let y = parser.next(1).toInt()
            leftTriggerPoints.append([x, y])
        }
        dic["leftTrigger"] = [
            "start": leftTriggerStart,
            "end": leftTriggerEnd,
            "macroOn": leftTriggerMacroOn,
            "macroThreshold": leftTriggerMacroThreshold,
            "pointCount": leftTriggerPointCount,
            "points": leftTriggerPoints
        ]

        // 3️⃣ 右扳机: start(1) + end(1) + macroOn(1) + macroThreshold(1) + pointCount(1) + X1,Y1...
        let rightTriggerStart = parser.next(1).toInt()
        let rightTriggerEnd = parser.next(1).toInt()
        let rightTriggerMacroOn = parser.next(1).toInt() != 0
        let rightTriggerMacroThreshold = parser.next(1).toInt()
        let rightTriggerPointCount = parser.next(1).toInt()
        var rightTriggerPoints: [[Int]] = []
        for _ in 0..<rightTriggerPointCount {
            let x = parser.next(1).toInt()
            let y = parser.next(1).toInt()
            rightTriggerPoints.append([x, y])
        }
        dic["rightTrigger"] = [
            "start": rightTriggerStart,
            "end": rightTriggerEnd,
            "macroOn": rightTriggerMacroOn,
            "macroThreshold": rightTriggerMacroThreshold,
            "pointCount": rightTriggerPointCount,
            "points": rightTriggerPoints
        ]

        // 4️⃣ 摇杆长度头(1) + 摇杆交换(1)
        let _ = parser.next(1).toInt() // stickLength（跳过，不输出）
        let stickSwap = parser.next(1).toInt()
        dic["stickSwap"] = stickSwap

        // 5️⃣ 左摇杆X: start(1) + end(1) + sensitivity(1) + reverseX(1)
        let lxStart = parser.next(1).toInt()
        let lxEnd = parser.next(1).toInt()
        let lxSensitivity = parser.next(1).toInt()
        let lxReverse = parser.next(1).toInt()
        dic["leftStickX"] = ["start": lxStart, "end": lxEnd, "sensitivity": lxSensitivity, "reverse": lxReverse]

        // 6️⃣ 左摇杆Y: start(1) + end(1) + sensitivity(1) + reverseX(1)
        let lyStart = parser.next(1).toInt()
        let lyEnd = parser.next(1).toInt()
        let lySensitivity = parser.next(1).toInt()
        let lyReverse = parser.next(1).toInt()
        dic["leftStickY"] = ["start": lyStart, "end": lyEnd, "sensitivity": lySensitivity, "reverse": lyReverse]

        // 7️⃣ 右摇杆X: start(1) + end(1) + sensitivity(1) + reverse(1)（与左摇杆顺序一致）
        let rxStart = parser.next(1).toInt()
        let rxEnd = parser.next(1).toInt()
        let rxSensitivity = parser.next(1).toInt()
        let rxReverse = parser.next(1).toInt()
        dic["rightStickX"] = ["start": rxStart, "end": rxEnd, "sensitivity": rxSensitivity, "reverse": rxReverse]

        // 8️⃣ 右摇杆Y: start(1) + end(1) + sensitivity(1) + reverse(1)
        let ryStart = parser.next(1).toInt()
        let ryEnd = parser.next(1).toInt()
        let rySensitivity = parser.next(1).toInt()
        let ryReverse = parser.next(1).toInt()
        dic["rightStickY"] = ["start": ryStart, "end": ryEnd, "sensitivity": rySensitivity, "reverse": ryReverse]

        // 9️⃣ 左摇杆按键: deadZoneShape(1)+maxOutput(1)+curveApply(1)+curveApplyKey(1)+lineCorrection(1)+pointCount(1)+X1,Y1...
        let lkDeadZoneShape = parser.next(1).toInt()
        let lkMaxOutput = parser.next(1).toInt()
        let lkCurveApply = parser.next(1).toInt()
        let lkCurveApplyKey = parser.next(1).toInt()
        let lkLineCorrection = parser.next(1).toInt()
        let lkPointCount = parser.next(1).toInt()
        var lkPoints: [[Int]] = []
        for _ in 0..<lkPointCount {
            let x = parser.next(1).toInt()
            let y = parser.next(1).toInt()
            lkPoints.append([x, y])
        }
        dic["leftStickKey"] = [
            "deadZoneShape": lkDeadZoneShape,
            "maxOutput": lkMaxOutput,
            "curveApply": lkCurveApply,
            "curveApplyKey": lkCurveApplyKey,
            "lineCorrection": lkLineCorrection,
            "pointCount": lkPointCount,
            "points": lkPoints
        ]

        // 🔟 右摇杆按键: deadZoneShape(1)+maxOutput(1)+curveApply(1)+curveApplyKey(1)+lineCorrection(1)+pointCount(1)+X1,Y1...
        let rkDeadZoneShape = parser.next(1).toInt()
        let rkMaxOutput = parser.next(1).toInt()
        let rkCurveApply = parser.next(1).toInt()
        let rkCurveApplyKey = parser.next(1).toInt()
        let rkLineCorrection = parser.next(1).toInt()
        let rkPointCount = parser.next(1).toInt()
        var rkPoints: [[Int]] = []
        for _ in 0..<rkPointCount {
            let x = parser.next(1).toInt()
            let y = parser.next(1).toInt()
            rkPoints.append([x, y])
        }
        dic["rightStickKey"] = [
            "deadZoneShape": rkDeadZoneShape,
            "maxOutput": rkMaxOutput,
            "curveApply": rkCurveApply,
            "curveApplyKey": rkCurveApplyKey,
            "lineCorrection": rkLineCorrection,
            "pointCount": rkPointCount,
            "points": rkPoints
        ]

        // 1️⃣1️⃣ 振动: length(1)+left(1)+right(1)
        let _ = parser.next(1).toInt() // vibrationLength（跳过，不输出）
        let vibrationLeft = parser.next(1).toInt()
        let vibrationRight = parser.next(1).toInt()
        dic["vibration"] = ["left": vibrationLeft, "right": vibrationRight]

        // 1️⃣2️⃣ 体感: length(1)+sensitivity(2B)+yReverse(1)+switch(1)+mappingSwitch(1)+triggerMode(1)+triggerKey(1)+deadZone(1)+mapping(1)
        let _ = parser.next(1).toInt() // motionLength（跳过，不输出）
        let motionSensitivityHi = parser.next(1).toInt()
        let motionSensitivityLo = parser.next(1).toInt()
        let motionSensitivity = (motionSensitivityHi << 8) | motionSensitivityLo
        dic["motion"] = [
            "sensitivity": motionSensitivity,
            "yReverse": parser.next(1).toInt(),
            "switch": parser.next(1).toInt(),
            "mappingSwitch": parser.next(1).toInt(),
            "triggerMode": parser.next(1).toInt(),
            "triggerKey": parser.next(1).toInt(),
            "deadZone": parser.next(1).toInt(),
            "mapping": parser.next(1).toInt()
        ]

        return dic
    }
    
    func analyzeMobpadDeviceInfo(_ data: Data) -> [String: Any] {
        print("分析完整设备信息数据 \(data.count) \(data.nsDescription())")
        var parser = DataParser(data)
        var dic: [String: Any] = [:]

        // 1️⃣ 连发参数
        let rapidList = parseRapidFire(&parser)
        dic["rapidList"] = rapidList

        // 2️⃣ 扳机参数
        let _ = parser.next(1).toInt()
        let leftTrigger = parseTrigger(&parser, name: "left")
        dic["leftTrigger"] = leftTrigger
        let rightTrigger = parseTrigger(&parser, name: "right")
        dic["rightTrigger"] = rightTrigger

        // 3️⃣ 摇杆参数
        let _ = parser.next(1).toInt()
        let leftStick = parseStick(&parser, name: "left")
        dic["leftStick"] = leftStick
        let rightStick = parseStick(&parser, name: "right")
        dic["rightStick"] = rightStick

        // 4️⃣ 振动参数
        let vibration = parseVibration(&parser)
        dic["vibration"] = vibration

        // 5️⃣ 体感参数
        let motion = parseMotion(&parser)
        dic["motion"] = motion
        
        return dic
    }
    func analyzeDeviceVersion(_ payload: Data) -> [String: Any] {
        
        var parser = DataParser(payload)
        
        let subIDNum = parser.next(1).toInt()
        let subID = DeviceVersionSubID(rawValue: UInt8(subIDNum))
        
        // 防止 payload 只有 1 字节时越界
        if parser.remaining >= 1 {
            let _ = parser.next(1)
        }

        var dic: [String: Any] = [:]
        switch subID {
        case .version:
            
            let sizes = [1, 1, 3, 3, 4, 3]
            let keys = ["project", "protocol", "firmware", "hardware"]
            
            guard payload.count >= sizes.reduce(0, +) else {
                print("Error: payload 数据长度不足")
                return [:]
            }
            dic = parser.nextMultiple(keys: keys, sizes: Array(sizes[2...]))
        case .setReportRate:
            let result = parser.next(1).toInt()
            dic = ["result": result]
        case .fetchReportRate:
            guard parser.remaining >= 2 else {
                return ["error": "Insufficient data for report rate"]
            }
            let rate = parser.next(2).toInt()
            dic = ["rate": rate]
        case .setChargingDock:
            let result = parser.next(1).toInt()
            dic["result"] = result
        case .fetchChargingDock:
            // Param：1 为开启，2 为关闭
            let param = parser.next(1).toInt()
            var isOn = true
            if param == 2 {
                isOn = false
            }
            dic["isOn"] = isOn
        case .fetchAppWakeKeyType:
            let keyType = parser.next(1).toInt()
            dic["keyType"] = keyType
        default:
            let rawHex = payload.map { String(format: "%02X", $0) }.joined(separator: " ")
            print("未处理的完整数据: [\(rawHex)]")
            dic["error"] = "unhandled_subID_0x\(String(format: "%02X", subIDNum))"
            dic["rawData"] = payload.map { String(format: "%02X", $0) }.joined(separator: " ")
        }
        return dic
    }
    
    
    // MARK: - 手柄工作模式解析 0x69
    /// 格式: [subID][dev][value]
    /// subID 0x01/0x07 → value = mode 直接传出
    /// subID 0x02/0x08 → value = result 直接传出
    func analyzeHandleMode(_ data: Data) -> [String: Any] {
        var parser = DataParser(data)
        
        let subID = parser.next(1).toInt()  // subID
        _ = parser.next(1)                   // dev
        
        let value = parser.next(1).toInt()   // mode/result
        
        // 根据 subID 类型传出对应的 key
        if subID == 0x02 || subID == 0x08 {
            return ["result": value]
        } else {
            return ["mode": value]
        }
    }
    
    // MARK: - 手柄配置页解析 0x81
    /// 格式: [subID][result]
    func analyzeHandleProfile(_ data: Data) -> [String: Any] {
        var parser = DataParser(data)
        
        _ = parser.next(1)   // subID
        
        let result = parser.next(1).toInt()
        
        return ["result": result]
    }
    
    // MARK: - 0x83 开关手柄功能以及回调解析
    /// 格式: [subID][dev][result]
    func analyzeHandleFunction(_ data: Data) -> [String: Any] {
        var parser = DataParser(data)
        
        _ = parser.next(1)   // subID
        _ = parser.next(1)   // dev
        
        let result = parser.next(1).toInt()
        
        return ["result": result]
    }
}

extension DataHelper {
    /// 连发参数解析
    private func parseRapidFire(_ parser: inout DataParser) -> [[String: Any]] {
        let rapidLength = parser.next(1).toInt()
        let keyCount = rapidLength / 3
        var rapidList: [[String: Any]] = []
        for _ in 0..<keyCount {
            // 按键
            let key = parser.next(1).toInt()
            // 连发模式
            let auto = parser.next(1).toInt()
            // 速率
            let speed = parser.next(1).toInt()
            rapidList.append([
                "key": GamepadKey.from(oneByteKeyCode: key) ?? .none,
                "turbo": TurboMode(rawValue: UInt8(auto)) ?? .disabled,
                "speed": speed
            ])
        }
        return rapidList
    }
    
    /// 扳机参数解析
    private func parseTrigger(_ parser: inout DataParser, name: String) -> [String: Any] {
        // 起始值
        let start = parser.next(1).toInt()
        // 终止值
        let end = parser.next(1).toInt()
        // 曲线点个数
        let pointCount = parser.next(1).toInt()
        
        // [(x,y)]
        var points: [[String: Int]] = []
        for _ in 0..<pointCount {
            let x = parser.next(1).toInt()
            let y = parser.next(1).toInt()
            points.append(["x": x, "y": y])
        }
        // 快速扳机开关
        let fastTriggerValue = parser.next(1).toInt()
        var fastTrigger = true
        // 1 为开启，2 为关闭
        if fastTriggerValue == 2 {
            fastTrigger = false
        }
        
        
        return [
            "start": start,
            "end": end,
            "pointCount": pointCount,
            "points": points,
            "fastTrigger": fastTrigger
        ]
    }
    ///  摇杆参数解析
    private func parseStick(_ parser: inout DataParser, name: String) -> [String: Any] {
        var result: [String: Any] = [:]
        // 死区补偿
        let deadzoneComp = parser.next(2).toInt()
        // 死区回归补偿
        let returnComp = parser.next(2).toInt()
        // 起始值
        let start = parser.next(1).toInt()
        // 终止值
        let end = parser.next(1).toInt()
        // 反转 X
        let reverseX = parser.next(1).toBool()
        // 反转 Y
        let reverseY = parser.next(1).toBool()
        // 曲线触发方式
        let triggerModeValue = parser.next(1).toInt()
        // 曲线触发按键
        let triggerKeyValue = parser.next(1).toInt()
        // 摇杆输出轨迹
        let outputGraphicValue = parser.next(1).toInt()
        // 曲线点个数
        let pointCount = parser.next(1).toInt()
        
        // [(x,y)]
        var points: [[String: Int]] = []
        for _ in 0..<pointCount {
            let x = parser.next(1).toInt()
            let y = parser.next(1).toInt()
            points.append(["x": x, "y": y])
        }

        result["deadzoneComp"] = deadzoneComp
        result["returnComp"] = returnComp
        result["start"] = start
        result["end"] = end
        result["reverseX"] = reverseX
        result["reverseY"] = reverseY
        result["triggerMode"] =  CurveTriggerMode(rawValue: UInt8(triggerModeValue))
        result["triggerKey"] = GamepadKey.from(oneByteKeyCode: triggerKeyValue) ?? .none
        result["outputGraphic"] = OutputGraphics(rawValue: UInt8(outputGraphicValue))
        result["pointCount"] = pointCount
        result["points"] = points
        return result
    }
    
    // 振动参数
    private func parseVibration(_ parser: inout DataParser) -> [String: Int] {
        let _ = parser.next(1).toInt()
        // 左马达
        let left = parser.next(1).toInt()
        // 右马达
        let right = parser.next(1).toInt()
        return [
            "left": left,
            "right": right
        ]
    }
    
    // 体感参数
    private func parseMotion(_ parser: inout DataParser) -> [String: Any] {
        print("⚾️ parser.trimmed \(parser.trimmed().nsDescription())")
        let _ = parser.next(1).toInt() // length
        
        // 体感开关
        let enabled = parser.next(1).toBool()
        // 体感映射开关
        let mappingEnabled = parser.next(1).toBool()
        // 体感触发方式
        let triggerMode = MotionTriggerMode(rawValue: UInt8(parser.next(1).toInt())) ?? .continuous
        // 体感触发按键
        let triggerKey = GamepadKey.from(oneByteKeyCode: parser.next(1).toInt()) ?? .none
        // 体感死区
        let deadzone = parser.next(1).toInt()
        // 体感灵敏度
        let sensitivity = parser.next(2).toInt()
        // 体感映射模式
        let mappingMode = MotionMappingMode(rawValue: UInt8(parser.next(1).toInt())) ?? .dPad
        // 水平方向轴向
        let axis = GyroAxis(rawValue: UInt8(parser.next(1).toInt())) ?? .zAxis
        // X 轴反转
        let reverseXValue = parser.next(1).toInt()
        let reverseX =  reverseXValue == 2 ? true : false

        // Y 轴反转
        let reverseYValue = parser.next(1).toInt()
        let reverseY =  reverseYValue == 2 ? true : false
        
        // 体感死区补偿
        let deadzoneComp = parser.next(1).toInt()
        
        // 体感曲线
        var curvePoints: [[String: Int]] = []
        for _ in 0..<3 {
            let x = parser.next(1).toInt()
            let y = parser.next(1).toInt()
            curvePoints.append(["x": x, "y": y])
        }
        
        // 二级灵敏度开关
        let secondaryEnabled = parser.next(1).toBool()
        
        // 二级灵敏度触发方式
        let secondaryTriggerMode = MotionTriggerMode(rawValue: UInt8(parser.next(1).toInt())) ?? .continuous
        
        
        // 二级灵敏度触发按键
        let secondaryTriggerKey = GamepadKey.from(oneByteKeyCode: parser.next(1).toInt()) ?? .none
        
        // 二级灵敏度
        let secondarySensitivity = parser.next(2).toInt()

        
        return [
            "enabled": enabled,
            "mappingEnabled": mappingEnabled,
            "triggerMode": triggerMode,
            "triggerKey": triggerKey,
            "deadzone": deadzone,
            "sensitivity": sensitivity,
            "mappingMode": mappingMode,
            "axis": axis,
            "reverseX": reverseX,
            "reverseY": reverseY,
            "deadzoneComp": deadzoneComp,
            "curve": curvePoints,
            "secondaryEnabled": secondaryEnabled,
            "secondaryTriggerMode": secondaryTriggerMode,
            "secondaryTriggerKey": secondaryTriggerKey,
            "secondarySensitivity": secondarySensitivity,
        ]
    }
}
