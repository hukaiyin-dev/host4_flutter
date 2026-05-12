//
//  DataHelper+Gyro.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation
import BluetoothKit
// MARK: - 体感
extension DataHelper {
    
    // MARK: - 8608
    /// 查询支持体感触发的按键 8608
    func queryGyroTriggerKeys(profile: Int,
                              finish: (() -> Void)? = nil,
                              response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = SupportKeySubID.queryGyroTriggerKeys
        
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(subID.rawValue))
        payload.append(Data.from(profile, count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 8609
    /// 查询支持体感映射的模式 8609
    func queryGyroMappingModes(profile: Int,
                               finish: (() -> Void)? = nil,
                               response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = SupportKeySubID.queryGyroMappingModes
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(subID.rawValue))
        payload.append(Data.from(profile, count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 5B
    /// 体感设置二 5B
    func setMotion(info: MotionInfo,
                   finish: (() -> Void)? = nil,
                   response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        if !info.isValid() {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        let protocolID = GMacroProtocolID.motion
        
        var payload = Data()
        payload.append(info.data())
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 6A1E
    /// 设置体感二级灵敏度(主要用于FPS游戏，开镜前和开镜后使用两套灵敏度) 6A1E
    func setMotionSecondary(isOn: Bool,
                            triggerMode: MotionTriggerMode,
                            triggerKey: GamepadKey,
                            sensitivity: Int,
                            finish: (() -> Void)? = nil,
                            response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        if !(0...1000).contains(sensitivity) {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        
        
        var payload = Data()
        
        // subID
        let subID = GyroSubID.setGyroSensitivity2
        payload.append(Data.from(subID.rawValue))
        
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))
        
        // 二级灵敏度开关 1：开启；2：关闭
        if isOn {
            payload.append(Data.from(1, count: 1))
        } else {
            payload.append(Data.from(2, count: 1))
        }
        
        payload.append(Data.from(Int(triggerMode.rawValue), count: 1))
        // 体感触发按键：持续模式为 0，单击/按下模式为映射按键键值
        if triggerMode == .continuous {
            payload.append(Data.from(0, count: 1))
        } else {
            payload.append(Data.from(triggerKey.gamepadOneByteKeyCode, count: 1))
        }
        // 灵敏度
        payload.append(Data.from(sensitivity, count: 2))
        
        let protocolID = subID.proID
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 6A1A
    /// 设置体感水平方向使用的轴  6A1A
    func setMotionHorizontalAxis(axis: GyroAxis,
                                 finish: (() -> Void)? = nil,
                                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
                
        var payload = Data()
        
        // subID
        let subID = GyroSubID.setHorizontalAxis
        payload.append(Data.from(subID.rawValue))
        
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))
        
        // Param
        payload.append(Data.from(axis.rawValue))
        
        let protocolID = subID.proID
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 6A1B
    /// 查询体感水平方向轴向  6A1B
    func fetchMotionHorizontalAxis(finish: (() -> Void)? = nil,
                                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
                
        var payload = Data()
        
        // subID
        let subID = GyroSubID.fetchHorizontalAxis
        payload.append(Data.from(subID.rawValue))
        
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))
        
        
        let protocolID = subID.proID
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 6A1F
    /// 查询体感二级灵敏度 6A1F
    func fetchGyroSensitivity2(finish: (() -> Void)? = nil,
                               response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        var payload = Data()
        
        // subID
        let subID = GyroSubID.fetchGyroSensitivity2
        payload.append(Data.from(subID.rawValue))
        
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))
        
        let protocolID = subID.proID
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 6A0F
    /// 设置陀螺仪 X 轴 Y 轴反转 6A0F
    func setGyroXYInvert(xOn: Bool,
                         yOn: Bool,
                         finish: (() -> Void)? = nil,
                         response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        var payload = Data()
        
        // subID
        let subID = GyroSubID.setGyroXYInvert
        payload.append(Data.from(subID.rawValue))
        
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))
        
        // 1、X 轴反转关闭；  2：X 轴反转开启
        if !xOn {
            payload.append(Data.from(1))
        } else {
            payload.append(Data.from(2))
        }
        
        if !yOn {
            payload.append(Data.from(1))
        } else {
            payload.append(Data.from(2))
        }
        
        let protocolID = subID.proID
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 6A10
    /// 查询陀螺仪 XY 轴反转信息 6A10
    func fetchGyroXYInvert(finish: (()->())? = nil,
                               response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = GyroSubID.fetchGyroXYInvert
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // MARK: - 6A13
    /// 设置陀螺仪死区补偿 6A13
    func setGyroDeadZone(compensate: Int,
                         finish: (() -> Void)? = nil,
                         response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        
        if !(0...100).contains(compensate) {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        
        var payload = Data()
        
        // subID
        let subID = GyroSubID.setGyroDeadZoneComp
        payload.append(Data.from(subID.rawValue))
        
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))
        
        
        payload.append(Data.from(compensate, count: 1))
        
        
        let protocolID = subID.proID
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 6A14
    /// 查询陀螺仪死区补偿（仅适用于陀螺仪模拟摇杆）  6A14
    func fetchGyroDeadZoneComp(finish: (() -> Void)? = nil,
                               response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        var payload = Data()
        
        // subID
        let subID = GyroSubID.fetchGyroDeadZoneComp
        payload.append(Data.from(subID.rawValue))
        
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))
        
        
        let protocolID = subID.proID
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 6A1C
    /// 设置陀螺仪灵敏度曲线 6A1C
    func setGyroSensitivityCurve(p1: Point,
                                 p2: Point,
                                 p3: Point,
                                 finish: (() -> Void)? = nil,
                                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        var payload = Data()
        
        // subID
        let subID = GyroSubID.setGyroSensitivityCurve
        payload.append(Data.from(subID.rawValue))
        
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))
        
        let ps = [p1, p2, p3]
        
        for p in ps {
            payload.append(p.data())
        }
        
        let protocolID = subID.proID
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 6A1D
    /// 查询陀螺仪灵敏度曲线 6A1D
    func fetchGyroSensitivityCurve(finish: (() -> Void)? = nil,
                                   response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        var payload = Data()
        
        // subID
        let subID = GyroSubID.fetchGyroSensitivityCurve
        payload.append(Data.from(subID.rawValue))
        
        // Dev 值固定 0x05
        payload.append(Data.from(0x05))
        
        let protocolID = subID.proID
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    // MARK: - 6A24
    /// 设置陀螺仪外圈死区 6A24
    func update(gyroOuterDead: Int,
                finish: (()->())? = nil,
                response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        if !(0...100).contains(gyroOuterDead) {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        
        let subID = GyroSubID.setGyroOuterDeadZone
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05

        payload.append(Data.from(gyroOuterDead, count: 1))

        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // MARK: - 6A25
    /// 查询陀螺仪外圈死区 6A25
    func fetchGyroOuterDeadZone(finish: (()->())? = nil,
                               response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = GyroSubID.fetchGyroOuterDeadZone
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // MARK: - 6A22
    /// 设置陀螺仪X/Y轴比例 6A22
    func update(gyroXYRatio: Int,
                finish: (()->())? = nil,
                response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        if !(0...100).contains(gyroXYRatio) {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        
        let subID = GyroSubID.setGyroXYRatio
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05

        payload.append(Data.from(gyroXYRatio, count: 1))

        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }

    // MARK: - 6A23
    /// 查询陀螺仪X/Y轴比例 6A23
    func fetchgyroXYRatio(finish: (()->())? = nil,
                               response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = GyroSubID.fetchGyroXYRatio
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }

    // MARK: - 6A09
    /// 设置陀螺仪映射类型 6A09
    func update(gyroMappingType: GyroMappingType,
                finish: (()->())? = nil,
                response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        
        
        let subID = GyroSubID.setGyroMappingType
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05

        payload.append(Data.from(gyroMappingType.rawValue))

        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
        
    }

    // MARK: - 6A0A
    /// 查询陀螺仪映射类型 6A0A
    func fetchGyroMappingType(finish: (()->())? = nil,
                              response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = GyroSubID.fetchGyroMappingType
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
}


extension DataHelper {
    // MARK: - 0x41 开始陀螺仪校准
    func startGyroCalibration(finish:(()->())? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.beginCheck
        
        var payload = Data()
        
        // subID
        let subID = 0x01
        
        payload.append(Data.from(UInt8(subID)))
        
        // dev 固定值0x00
        payload.append(Data.from(0x00))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // MARK: - 0x42 结束陀螺仪校准
    func endGyroCalibration(finish:(()->())? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.stopCheck
        
        var payload = Data()
        
        // subID
        let subID = 0x01
        
        payload.append(Data.from(UInt8(subID)))
        
        // dev 固定值0x00
        payload.append(Data.from(0x00))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    func setMotionParam(info: MotionParam,
                      finish:(()->())? = nil,
                          response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        if  !(0...3).contains(info.triggerMode) || !(0...2).contains(info.triggerKey) || !(0...1).contains(info.inputType) || !(0...2).contains(info.inputMode) || !(0...100).contains(info.sensitivity) || !(0...100).contains(info.deadZoneCompensation) || !(0...3).contains(info.curveType) || !(0...100).contains(info.curvature) || !(0...200).contains(info.ratio){
            
            response(.failure(BluetoothError.outOfRange))
            
            return
        }
        
        let protocolID = GMacroProtocolID.gyro
        
        var payload = Data()
        
        //subid
        payload.append(Data.from(0x28))
        //dev
        payload.append(Data.from(0x00))
        
        payload.append(Data.from(info.mappingSwitch.int, count: 1)) // 映射开关
        payload.append(Data.from(info.mappingKey.rawValue, count: 1)) // 映射键值
        payload.append(Data.from(info.triggerMode, count: 1)) // 触发方式
        payload.append(Data.from(info.triggerKey, count: 1)) // 映射对象
        payload.append(Data.from(info.inputType, count: 1)) // 输入类型
        payload.append(Data.from(info.inputMode, count: 1)) // 输入模式
        
        let reversal = (info.rollReversal ? 1 : 0) << 0 | (info.pitchReversal ? 1 : 0) << 1 | (info.yawReversal ? 1 : 0) << 2
        payload.append(Data.from(reversal, count: 1)) // 反转
        
        payload.append(Data.from(info.sensitivity, count: 1)) // 灵敏度
        payload.append(Data.from(info.deadZoneCompensation, count: 1)) // 死区补偿
        payload.append(Data.from(info.curveType, count: 1)) // 曲线类型
        payload.append(Data.from(info.curvature, count: 1)) // 曲率
        payload.append(Data.from(info.ratio, count: 1)) // 水平垂直比
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
}


extension DataHelper {
    
    func analyzeGyro(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)
        
        // subID
        let subIDData = parser.next(1)
        let subID = GyroSubID(rawValue: UInt8(subIDData.toInt()))
        
        // Dev
        _ = parser.next(1)
        
        switch subID {
        case .fetchGyroXYRatio:
            // Param：0-100，为比例值
            let param = parser.next(1).toInt()
            dic["ratio"] = param
        case .fetchGyroMappingType:
            let value = parser.next(1).toInt()
            dic["type"] = GyroMappingType(rawValue: UInt8(value))
        case .fetchHorizontalAxis:
            let value = parser.next(1).toInt()
            dic["axis"] = GyroAxis(rawValue: UInt8(value))
        case .fetchGyroDeadZoneComp:
            let value = parser.next(1).toInt()
            dic["deadZoneComp"] = value
        case .fetchGyroSensitivityCurve:
            let x1 = parser.next(1).toInt()
            let y1 = parser.next(1).toInt()
            let x2 = parser.next(1).toInt()
            let y2 = parser.next(1).toInt()
            let x3 = parser.next(1).toInt()
            let y3 = parser.next(1).toInt()
            
            dic["curve"] = [
                ["x": x1, "y": y1],
                ["x": x2, "y": y2],
                ["x": x3, "y": y3]
            ]
        case .fetchGyroSensitivity2:
            
            let isOn = parser.next(1).toBool()
            let triggerMode = MotionTriggerMode(rawValue: UInt8(parser.next(1).toInt()))
            let triggerKey = GamepadKey(rawValue: parser.next(1).toInt())
            let sensitivity = parser.next(2).toInt()
            
            dic["isOn"] = isOn
            dic["triggerMode"] = triggerMode
            dic["triggerKey"] = triggerKey
            dic["sensitivity"] = sensitivity
        case .fetchGyroOuterDeadZone:
            let value = parser.next(1).toInt()
            dic["value"] = value
        case .fetchGyroXYInvert:
            let xValue = parser.next(1).toInt()
            let yValue = parser.next(1).toInt()
            
            var x = false
            var y = false
            if xValue == 2 {
                x = true
            }
            if yValue == 2 {
                y = true
            }
            dic["x"] = x
            dic["y"] = y

        default:
            print("未处理的 GyroSubID 0x\(String(format: "%02X", subID!.rawValue))")
        }
    
        return dic
    }
    
    /// 处理有subid,dev 成功/失败 数据， 为0 时判定为失败（校准使用）
    func analyzeCalibrationResult(payload: Data) -> (response: Result<[String: Any], Error>, isComplete: Bool) {
        var responseDic: [String: Any] = [:]
        var parser = DataParser(payload)
        
        // subID
        let subId = parser.next(1).toInt()
        
        if subId == 0x04 {
            //查询校准退出按键
            let keyCode = parser.next(1).toInt()
            
            if let key = GamepadKey.from(oneByteKeyCode: keyCode) {
                
                responseDic = ["key": key]
                
                return (.success(responseDic), true)
                
            }
        
        }else if subId == 0x05 {
            //查询校准支持的模块
            var p1Data = parser.next(1)
            
            var param1 : [Int] = self.getReversedBitIndices(from: p1Data)
            
            responseDic = ["module": param1]
            
            return (.success(responseDic), true)
        }
        
        let error = BluetoothError.deviceReportedError(code: 0)
        
        return (.failure(error), true)
    }
    
    
    func analyzeStopCalibration(_ data: Data, protocolID: GMacroProtocolID) -> [String: Any] {
        var dic: [String: Any] = [:]
        
        var param1 : [Int] = []
        var param2 : [Int] = []
        
        var parser = DataParser(data)
        
        let subId = parser.next(1).toInt()
        
        let _ = parser.next(1).toInt()
        
        let result = parser.next(1).toInt()
        
        let returnRelust = result == 1 ? 0 : 1
        
        var type : Int = 0
            
        switch protocolID {
            case .stopCheck:
            //陀螺仪校准
                type = 0
            case .stopCalibration:
                if subId == 02 {
                    //摇杆校准
                    type = 1
                }else{
                    //扳机校准
                    type = 2
                }
            default:
                type = 3
        }
        
        if protocolID == .stopCalibration{
            var p1Data = parser.next(1)
            var p2Data = parser.next(1)
            
            param1 = self.getReversedBitIndices(from: p1Data)

            param2 = self.getReversedBitIndices(from: p2Data)
            
        }else if protocolID == .stopCheck{
            var p1Data = parser.next(1)
            
            param1 = self.getReversedBitIndices(from: p1Data)
        }
        
        dic = [
            "subId" : subId,
            "result" : returnRelust,
            "param1" : param1,
            "param2" : param2,
        ]

        return dic
    }
    
    func analyzeFinishCalibration(_ data: Data, protocolID: GMacroProtocolID) -> [String: Any] {
        var dic: [String: Any] = [:]
        
        var param1 : [Int] = []
        var param2 : [Int] = []
        
        var parser = DataParser(data)
        
        let subId = parser.next(1).toInt()
        
        let _ = parser.next(1).toInt()
        
        //1成功 0失败（为了跟其他接口统一，转一下）
        let result = parser.next(1).toInt()
        
        let returnRelust = result == 1 ? 0 : 1
        
        var type : Int = 0
            
        switch protocolID {
            case .finishCheck:
            //陀螺仪校准
                type = 0
            case .finishCalibration:
                if subId == 02 {
                    //摇杆校准
                    type = 1
                }else{
                    //扳机校准
                    type = 2
                }
            default:
                type = 3
        }
        
        if protocolID == .finishCalibration{
            var p1Data = parser.next(1)
            var p2Data = parser.next(1)
            
            param1 = self.getReversedBitIndices(from: p1Data)

            param2 = self.getReversedBitIndices(from: p2Data)
            
        }else if protocolID == .finishCheck{
            var p1Data = parser.next(1)
            
            param1 = self.getReversedBitIndices(from: p1Data)
        }
        
        delegate?.finishCalibration(type, subId: subId, result: returnRelust, param1: param1, param2: param2)

        return dic
    }
}
