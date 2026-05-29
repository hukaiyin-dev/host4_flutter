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
    
}
// MARK: - Parse
extension DataHelper {
    
    func analyzeDeviceInfo(_ data: Data, _ subID: UInt8, _ sn: UInt8) -> [String: Any] {
        let subID = DeviceInfoSubID(rawValue: subID)
        switch subID {
        case .mobpad:
            return analyzeMobpadDeviceInfo(data)
        case .none:
            print("未处理的 DeviceInfoSubID 0x\(String(format: "%02X", subID!.rawValue))")
            return [:]
        }
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
        default:
            let rawHex = payload.map { String(format: "%02X", $0) }.joined(separator: " ")
            print("未处理的完整数据: [\(rawHex)]")
            dic["error"] = "unhandled_subID_0x\(String(format: "%02X", subIDNum))"
            dic["rawData"] = payload.map { String(format: "%02X", $0) }.joined(separator: " ")
        }
        return dic
    }
    
    
    //MFI设备连接上报的数据处理
    func analyzeDevConnectState(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        
        var parser = DataParser(data)
        
        let subId = parser.next(1).toInt()
        
        let _ = parser.next(1).toInt()
        
        let result = parser.next(1).toInt()
        
        dic = ["result" : result]
        
        //判断subId == 0x02
        if subId == 0x02 && result == 2{
            delegate?.devConnectState(result)
        }
        
        return dic
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
