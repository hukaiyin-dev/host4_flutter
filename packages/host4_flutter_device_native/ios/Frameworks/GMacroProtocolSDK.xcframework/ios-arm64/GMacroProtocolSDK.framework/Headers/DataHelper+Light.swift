//
//  DataHelper+Light.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation
import BluetoothKit

// MARK: - 灯光
extension DataHelper {
    
    /// 查询自动休眠时间 0x82 0x01
    func fetchLight(finish: (() -> Void)? = nil,
                    response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        var payload = Data()
        
        // subID
        let subID = LightSubID.fetchCurrent
        payload.append(Data.from(subID.rawValue))
        
        let protocolID = subID.proID
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    /// 查询灯光位置及组数 0x82 0x04
    func fetchLightPosition(finish: (() -> Void)? = nil,
                            response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        var payload = Data()
        
        // subID
        let subID = LightSubID.fetchLightPositionAndGroup
        payload.append(Data.from(subID.rawValue))
        let protocolID = subID.proID
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    /// 查询灯光位置及组数 0x82 0x05
    func fetchSupportedLightEffects(finish: (() -> Void)? = nil,
                                    response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        var payload = Data()
        
        // subID
        let subID = LightSubID.fetchSupportedLightEffects
        payload.append(Data.from(subID.rawValue))
        let protocolID = subID.proID
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    /// 查询灯光位置及组数 0x82 0x06
    func fetchCurrentLightEffect(finish: (() -> Void)? = nil,
                                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        var payload = Data()
        
        // subID
        let subID = LightSubID.fetchCurrentLightEffect
        payload.append(Data.from(subID.rawValue))
        let protocolID = subID.proID
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    /// 设置灯组颜色 0x4E
    func setLightColor(position: LightPosition,
                       groupCount: Int,
                       colors: [(red: UInt8, green: UInt8, blue: UInt8)],
                       finish: (() -> Void)? = nil,
                       response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let protocolID = GMacroProtocolID.setLightColor
        
        var datas = [Data]()
        
        for (index, color) in colors.enumerated() {
            var payload = Data()
            
            // subID
            let subID = 0x01
            payload.append(Data.from(UInt8(subID)))
            
            payload.append(Data.from(position.rawValue))
            payload.append(Data.from(groupCount, count: 1))
            payload.append(Data.from(index, count: 1))
            
            payload.append(Data.from(color.red))
            payload.append(Data.from(color.green))
            payload.append(Data.from(color.blue))
            
            let data = dataFrom(protocolID: protocolID, payload: payload)
            datas.append(data)
        }
        
        self.write(protocolID: protocolID, datas: datas, finish: finish, response: response)
    }
    
    /// 设置灯组灯效 0x4F
    func setLightEffect(position: LightPosition,
                        groupCount: Int,
                        isOn: Bool,
                        light: Int,
                        speed: Int,
                        mode: LightMajorMode,
                        subMode: LightSubMode,
                        colors: [(red: UInt8, green: UInt8, blue: UInt8)],
                        finish: (() -> Void)? = nil,
                        response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        if !(0...100).contains(light) || !(0...100).contains(speed) {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        
        guard let subValue = mode.subModeValue(subMode: subMode) else {
            print("大模式 小模式 不匹配")
            response(.failure(BluetoothError.invalidInput))
            return
        }
        
        let protocolID = GMacroProtocolID.setLightEffect
        
        var payload = Data()
        
        // subID
        let subID = 0x01
        payload.append(Data.from(UInt8(subID)))
        
        
        payload.append(Data.from(position.rawValue))
        payload.append(Data.from(groupCount, count: 1))
        
        // 开关
        payload.append(Data.from(isOn.int, count: 1))
        
        payload.append(Data.from(light, count: 1))
        payload.append(Data.from(speed, count: 1))
        
        // 大模式
        payload.append(Data.from(mode.rawValue))
        // 小模式
        payload.append(Data.from(subValue))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
}

// MARK: - 通道灯亮度 0x70
extension DataHelper {
    /// 设置通道灯开关 0x70 0x08
    func setChannelLightSwitch(isOn: Bool,
                               finish: (() -> Void)? = nil,
                               response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = ChannelLightSubID.setChannelSwitch
        let protocolID = subID.proID

        var payload = Data()
        payload.append(Data.from(subID.rawValue))
        payload.append(Data.from(0x05))
        payload.append(Data.from(isOn ? 0x02 : 0x01)) // 1 关, 2 开

        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }

    /// 获取通道灯开关 0x70 0x09
    func fetchChannelLightSwitch(finish: (() -> Void)? = nil,
                                 response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = ChannelLightSubID.fetchChannelSwitch
        let protocolID = subID.proID

        var payload = Data()
        payload.append(Data.from(subID.rawValue))
        payload.append(Data.from(0x05))

        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }

    /// 设置通道灯亮度 0x70 0x0A
    func setChannelLightBrightness(brightness: Int,
                                   finish: (() -> Void)? = nil,
                                   response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        if !(0...100).contains(brightness) {
            response(.failure(BluetoothError.outOfRange))
            return
        }

        let subID = ChannelLightSubID.setChannelBrightness
        let protocolID = subID.proID

        var payload = Data()
        payload.append(Data.from(subID.rawValue))
        payload.append(Data.from(0x05))
        payload.append(Data.from(brightness, count: 1))

        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }

    /// 获取通道灯亮度 0x70 0x0B
    func fetchChannelLightBrightness(finish: (() -> Void)? = nil,
                                     response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        let subID = ChannelLightSubID.fetchChannelBrightness
        let protocolID = subID.proID

        var payload = Data()
        payload.append(Data.from(subID.rawValue))
        payload.append(Data.from(0x05))

        let all = dataFrom(protocolID: protocolID, payload: payload)
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }

    func analyzeChannelLight(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)

        let subIDValue = parser.next(1).toInt()
        let subID = ChannelLightSubID(rawValue: UInt8(subIDValue))
        _ = parser.next(1) // Dev

        switch subID {
        case .setChannelSwitch, .setChannelBrightness:
            if parser.remaining >= 1 {
                dic["result"] = parser.next(1).toInt()
            }
        case .fetchChannelSwitch:
            if parser.remaining >= 1 {
                let rawValue = parser.next(1).toInt()
                dic["switch"] = rawValue
                dic["isOn"] = rawValue == 2
            }
        case .fetchChannelBrightness:
            if parser.remaining >= 1 {
                dic["brightness"] = parser.next(1).toInt()
            }
        case .none:
            print("未处理的 ChannelLightSubID 0x\(String(format: "%02X", subIDValue))")
        }

        return dic
    }
}

extension DataHelper {
    
    func analyzeLight(_ data: Data, _ subID: UInt8, _ sn: UInt8) -> [String: Any] {
        let subID = LightSubID(rawValue: subID)
        switch subID {
        case .fetchLightPositionAndGroup:
            return analyzeLightPositionAndGroup(data)
        case .fetchSupportedLightEffects:
            return analyzeSupportedLightEffects(data)
        case .fetchCurrentLightEffect:
            return analyzeCurrentLightEffect(data)
        default:
            print("未处理的 SupportKeySubID 0x\(String(format: "%02X", subID!.rawValue))")
            return [:]
        }
    }
    
    
    //  查询灯光位置及组数
    func analyzeLightPositionAndGroup(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)
        
        guard parser.remaining >= 1 else {
            print("⚠️ 数据不足")
            return dic
        }
        
        let supported = parser.next(1).toInt()
        dic["supported"] = supported == 1
        
        // 不支持灯效，直接返回
        if supported == 0 {
            return dic
        }
        
        guard parser.remaining >= 1 else {
            print("⚠️ 缺少灯光位置总数字段")
            return dic
        }
        
        let count = parser.next(1).toInt()
        dic["count"] = count
        
        var positions: [[String: Any]] = []
        
        for i in 0..<count {
            guard parser.remaining >= 2 else {
                print("⚠️ 灯光位置 \(i + 1) 数据不足")
                break
            }
            
            let posRaw = parser.next(1).toInt()
            let groupCount = parser.next(1).toInt()
            
            let position = LightPosition(rawValue: UInt8(posRaw)) ?? .chargingDock
            
            positions.append([
                "position": position,
                "groupCount": groupCount
            ])
        }
        
        dic["positions"] = positions
        return dic
    }
    
 
    
    // 查询当前灯效（灯颜色）
    func analyzeCurrentLightEffect(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)
        
        var groups: [[String: Any]] = []
        var groupIndex = 0
        
        while parser.remaining >= 1 {
            groupIndex += 1
            let groupLength = parser.next(1).toInt()
            
            // 若剩余不足 groupLength 字节，则说明数据异常
            if parser.remaining < groupLength {
                print("⚠️ 灯组 \(groupIndex) 数据不足，长度应为 \(groupLength)，剩余 \(parser.remaining)")
                break
            }
            
            let startOffset = parser.offset
            let isOn = parser.next(1).toInt() == 1
            let brightness = parser.next(1).toInt()
            let speed = parser.next(1).toInt()
            let majorModeRaw = parser.next(1).toInt()
            let subModeRaw = parser.next(1).toInt()
            let colorCount = parser.next(1).toInt()
            
            var colors: [[String: Int]] = []
            for _ in 0..<colorCount {
                guard parser.remaining >= 3 else { break }
                let r = parser.next(1).toInt()
                let g = parser.next(1).toInt()
                let b = parser.next(1).toInt()
                colors.append(["colorR": r, "colorG": g, "colorB": b])
            }
            
            groups.append([
                "on": isOn,
                "brightness": brightness,
                "speed": speed,
                "majorMode": LightMajorMode(rawValue: UInt8(majorModeRaw)) ?? .constant,
                "subMode": LightSubMode(rawValue: subModeRaw) ?? .fixedColor,
                "colors": colors
            ])
            
            // 防止跳不准：跳过剩余未解析的部分（若颜色不满 groupLength）
            let parsedLength = parser.offset - startOffset
            if parsedLength < groupLength {
                parser.skip(groupLength - parsedLength)
            }
        }
        
        dic["groups"] = groups
        return dic
    }
    
    
    // 查询支持的灯效（灯位置）
    func analyzeSupportedLightEffects(_ data: Data) -> [String: Any] {
        var dic: [String: Any] = [:]
        var parser = DataParser(data)
        
        let colorCount = parser.next(1).toInt()
        let majorCount = parser.next(1).toInt()
        
        var majorModes: [[String: Any]] = []
        
        for _ in 0..<majorCount {
            let majorRaw = parser.next(1).toInt()
            let major = LightMajorMode(rawValue: UInt8(majorRaw)) ?? .constant
            let subCount = parser.next(1).toInt()
            var subModes: [LightSubMode] = []
            for _ in 0..<subCount {
                let subRaw = parser.next(1).toInt()
                let sub = LightSubMode(rawValue: subRaw) ?? .fixedColor
                subModes.append(sub)
            }
            
            let positionCount = parser.next(1).toInt()
            var positions: [LightPosition] = []
            for _ in 0..<positionCount {
                let posRaw = parser.next(1).toInt()
                let pos = LightPosition(rawValue: UInt8(posRaw)) ?? .chargingDock
                positions.append(pos)
            }
            
            majorModes.append([
                "majorMode": major,
                "subModes": subModes,
                "positions": positions
            ])
        }
        
        dic["colorCount"] = colorCount
        dic["majorModes"] = majorModes
        return dic
    }
}


extension DataHelper{
    /// 查询灯光位置及组数 0x71 0x01
    func fetchCurrentLightConfig(finish: (() -> Void)? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        var payload = Data()
        
        let protocolID = GMacroProtocolID.getLightConfig
        
        // subID
        payload.append(Data.from(UInt8(0x01)))
        
        // dev
        payload.append(Data.from(UInt8(0x00)))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
    
    /// 设置灯组灯效 0x72 01
    func setLightConfig(effect: Int, colorR: UInt8, colorG: UInt8, colorB: UInt8, light: Int, speed: Int, profile: Int, finish: (() -> Void)? = nil, response: @Sendable @escaping (Result<[String: Any], Error>) -> Void) {
        
        if !(0...100).contains(light) || !(0...100).contains(speed) {
            response(.failure(BluetoothError.outOfRange))
            return
        }
        
        if !(1...3).contains(effect){
            response(.failure(BluetoothError.outOfRange))
            return
        }
        
        let protocolID = GMacroProtocolID.setLightConfig
        
        var payload = Data()
        
        // subID
        let subID = 0x01
        payload.append(Data.from(UInt8(subID)))
        
        // dev
        payload.append(Data.from(UInt8(0x00)))
        
        // effect
        payload.append(Data.from(effect, count: 1))
        
        //colors
        payload.append(Data.from(colorR))
        payload.append(Data.from(colorG))
        payload.append(Data.from(colorB))
        
        payload.append(Data.from(light, count: 1))
        payload.append(Data.from(speed, count: 1))
        
        let all = dataFrom(protocolID: protocolID, payload: payload)
        
        self.write(protocolID: protocolID, data: all, finish: finish, response: response)
    }
}

extension DataHelper{
    // 查询当前灯效（灯颜色）0x71 01
    func analyzeCurrentLightConfig(_ data: Data) -> [String: Any] {
        
        var dic: [String: Any] = [:]
        var groups: [[String: Any]] = []
        
        var parser = DataParser(data)
        
        parser.skip(2)
        
        let effect = parser.next(1).toInt()
        let colorR = parser.next(1).toInt()
        let colorG = parser.next(1).toInt()
        let colorB = parser.next(1).toInt()
        let light = parser.next(1).toInt()
        let speed = parser.next(1).toInt()
        let profile = parser.next(1).toInt()
        
        groups.append([
            "effect" : effect,
            "colorR" : colorR,
            "colorG" : colorG,
            "colorB" : colorB,
            "light" : light,
            "speed" : speed,
            "profile" : profile
        ])
        
        dic["groups"] = groups
        
        return dic
    }
}
