//
//  DataHelper+Rocker.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation
import BluetoothKit

// MARK: - 摇杆
extension DataHelper {
    
    /// 设置摇杆（线性 0x3E
    func rockerLinear(info: LinearInfo,
                      finish:(()->())? = nil,
                      response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let protocolID = GMacroProtocolID.rocker
        
        var payload = Data()
        
        payload.append(Data.from(info.leftMin, count: 1)) // 左摇杆起始
        payload.append(Data.from(info.leftMax, count: 1)) // 左摇杆终止
        payload.append(Data.from(info.leftXFlip.int, count: 1)) // 左摇杆反转X
        payload.append(Data.from(info.leftYFlip.int, count: 1)) // 左摇杆反转Y
        
        payload.append(Data.from(info.rightMin, count: 1)) // 右摇杆起始
        payload.append(Data.from(info.rightMax, count: 1)) // 右摇杆终止
        payload.append(Data.from(info.rightXFlip.int, count: 1)) // 右摇杆反转X
        payload.append(Data.from(info.rightYFlip.int, count: 1)) // 右摇杆反转X
        
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    /// 设置摇杆曲线（0x3F
    func rocker3dLinear(leftInfo: ThreeDInfo, rightInfo: ThreeDInfo,
                        finish:(()->())? = nil,
                        response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.rocker3D
        
        var payload = Data()
        
        payload.append(leftInfo.data())
        payload.append(rightInfo.data())
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    
    // 设置摇杆曲线 0x3F 0x0D/0x0E
    func rocker3DCurve(cgPoints: [CGPoint],
                       subID: RockerSubID,
                       finish: (() -> Void)? = nil,
                       response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        if subID != .leftCurve && subID != .rightCurve {
            print("传入错误的 subID，请检查")
            return
        }
        let protocolID = subID.proID
        
        guard let points = convertAndValidatePoints(cgPoints: cgPoints, response: response) else { return }
        let datas = pointDatas(protocolID: protocolID, subID: subID.rawValue, points: points)
        self.write(protocolID: protocolID, datas: datas, finish: finish, response: response)
    }
    
    
    // 设置死区补偿 0x3F 0x12/0x13
    func rockerDeadZone(left: Int,
                        right: Int,
                        subID: RockerSubID,
                        finish:(()->())? = nil,
                        response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        if subID != .deadZoneCompensation && subID != .deadZoneRegressionComp {
            print("传入错误的 subID，请检查")
            return
        }
        let protocolID = subID.proID
        if !(0...0xFFFF).contains(left) || !(0...0xFFFF).contains(right) {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05
        payload.append(Data.from(left, count: 2))
        payload.append(Data.from(right, count: 2))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // 设置摇杆曲线触发方式以及触发按键 0x3F 0x14
    func rockerTriggerType(leftRigger: CurveTriggerMode,
                           leftGamepadKey: GamepadKey,
                           rightRigger: CurveTriggerMode,
                           rightGamepadKey: GamepadKey,
                           finish:(()->())? = nil,
                           response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = RockerSubID.triggerModeAndButton
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05
        
        payload.append(Data.from(Int(leftRigger.rawValue), count: 1))
        if leftRigger == .continuous {
            payload.append(Data.from(0, count: 1))
            
        } else {
            payload.append(Data.from(leftGamepadKey.gamepadOneByteKeyCode, count: 1))
            
        }
        
        payload.append(Data.from(Int(rightRigger.rawValue), count: 1))
        if rightRigger == .continuous {
            payload.append(Data.from(0, count: 1))
        } else {
            payload.append(Data.from(rightGamepadKey.gamepadOneByteKeyCode, count: 1))
        }
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // 设置摇杆输出轨迹 0x3F 0x15
    func rockerOutputGraphics(left: OutputGraphics,
                              right:OutputGraphics,
                              finish:(()->())? = nil,
                              response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = RockerSubID.rockerOutputGraphics
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05
        
        payload.append(Data.from(Int(left.rawValue), count: 1))
        payload.append(Data.from(Int(right.rawValue), count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
}


extension DataHelper {

    /// 设置扳机测试握把振动开关 670B
    func update(triggerTestVibration: Bool,
                finish: (()->())? = nil,
                response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = VibrationSubID.setTriggerTestGripVibration
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05

        // 1 为开启，2 为关闭
        if triggerTestVibration {
            payload.append(Data.from(1, count: 1))
        } else {
            payload.append(Data.from(2, count: 1))
        }
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }

    /// 查询扳机测试握把振动开关 670C
    func fetchTriggerTestVibration(finish: (()->())? = nil,
                                   response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = VibrationSubID.fetchTriggerTestGripVibration
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

    /// 设置扳机振动开关 670D
    func update(triggerVibration: Bool,
                finish: (()->())? = nil,
                response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = VibrationSubID.setTriggerVibration
        let protocolID = subID.proID
        
        var payload = Data()
        payload.append(Data.from(Int(subID.rawValue), count: 1)) // subID
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05

        // 1 为开启，2 为关闭
        if triggerVibration {
            payload.append(Data.from(1, count: 1))
        } else {
            payload.append(Data.from(2, count: 1))
        }
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }

    /// 查询获取扳机振动开关 670E
    func fetchTriggerVibration(finish: (()->())? = nil,
                               response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = VibrationSubID.fetchTriggerVibration
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

    /// 设置充电底座启停开关
    func updateChargingDock(_ isOn: Bool,
                            finish: (()->())? = nil,
                            response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        
        var payload = Data()
        
        // subID
        let subID = DeviceVersionSubID.setChargingDock
        payload.append(Data.from(subID.rawValue))
        
        payload.append(Data.from(Int(0x05), count: 1)) // Dev 值固定 0x05
        
        payload.append(Data.from(isOn.int, count: 1))

        let protocolID = subID.proID
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }

    /// 查询充电底座启停开关
    func fetchChargingDock(finish: (()->())? = nil,
                           response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let subID = DeviceVersionSubID.fetchChargingDock
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
    // MARK: - 0x55 subID:02 开始摇杆校准
    func startRockerCalibration(finish:(()->())? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.beginCalibration
        
        var payload = Data()
        
        // subID
        let subID = 0x02
        
        payload.append(Data.from(UInt8(subID)))
        
        // dev 固定值0x00
        payload.append(Data.from(0x00))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
    
    // MARK: - 0x56 subID:02 结束摇杆校准
    func endRockerCalibration(finish:(()->())? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        let protocolID = GMacroProtocolID.stopCalibration
        
        var payload = Data()
        
        // subID
        let subID = 0x02
        
        payload.append(Data.from(UInt8(subID)))
        
        // dev 固定值0x00
        payload.append(Data.from(0x00))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
}

extension DataHelper {
    
    // MARK: - 设置摇杆附加功能（线性 0x59
    func rockerAdditional(info: RockerAdditionalInfo,
                      finish:(()->())? = nil,
                      response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        if !(0...2).contains(info.leftDeadZone) ||  !(0...2).contains(info.rightDeadZone) || !(0...100).contains(info.leftOutMax) || !(0...100).contains(info.rightOutMax) || !(0...2).contains(info.leftCurveApply) || !(0...2).contains(info.rightCurveApply) || !(0...1).contains(info.leftLineCorrection) || !(0...1).contains(info.rightLineCorrection) {
            
            response(.failure(BluetoothError.outOfRange))
            
            return
        }
        
        
        let protocolID = GMacroProtocolID.rockerAdditional
        
        var payload = Data()
        
        payload.append(Data.from(info.leftDeadZone, count: 1)) // 外形死区
        payload.append(Data.from(info.leftOutMax, count: 1)) // 输出最大值
        payload.append(Data.from(info.leftCurveApply, count: 1)) // 曲线应用
        payload.append(Data.from(info.leftCurveApplyKey.rawValue, count: 1)) // 曲线应用按键
        payload.append(Data.from(info.leftLineCorrection, count: 1)) //直线修正
        
        payload.append(Data.from(info.rightDeadZone, count: 1)) // 外形死区
        payload.append(Data.from(info.rightOutMax, count: 1)) // 输出最大值
        payload.append(Data.from(info.rightCurveApply, count: 1)) // 曲线应用
        payload.append(Data.from(info.rightCurveApplyKey.rawValue, count: 1)) // 曲线应用按键
        payload.append(Data.from(info.rightLineCorrection, count: 1)) //直线修正
        
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID,
                   data: all,
                   finish: finish,
                   response: response)
    }
}
