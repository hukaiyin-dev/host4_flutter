//
//  MotionInfo.swift
//  BluetoothKitDemo
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation


struct MotionInfo {
    
    /// 体感开关：false 关闭，true 开启
    var motionEnabled: Bool = false
    
    /// 体感映射开关：false 关闭，true 开启（仅在非 Switch 模式有用）
    var mappingEnabled: Bool = false
    
    /// 体感触发方式
    var triggerMode: MotionTriggerMode = .click
    
    /// 体感触发按键
    var triggerKey: GamepadKey = .A
    
    /// 体感死区
    var deadZone: Int = 0
    
    /// 体感灵敏度
    var sensitivity: Int = 100
    
    /// 体感映射模式
    var mappingMode: MotionMappingMode = .leftStick
    
    func data() -> Data {
        var payload = Data()
        
        payload.append(Data.from(motionEnabled.int, count: 1))
        payload.append(Data.from(mappingEnabled.int, count: 1))
        payload.append(Data.from(Int(triggerMode.rawValue), count: 1))
        
        // 体感触发按键：持续模式为 0，单击/按下模式为映射按键键值
        if triggerMode == .continuous {
            payload.append(Data.from(0, count: 1))
        } else {
            payload.append(Data.from(triggerKey.gamepadOneByteKeyCode, count: 1))
        }
        
        payload.append(Data.from(deadZone, count: 1))
        payload.append(Data.from(sensitivity, count: 2))
        payload.append(Data.from(Int(mappingMode.rawValue), count: 1))

        return payload
    }
    
    func isValid() -> Bool {
        // 体感死区
        guard (0...100).contains(deadZone) else { return false }
        
        // 体感灵敏度
        guard (0...1000).contains(sensitivity) else { return false }
        
        return true
    }
}


struct MotionParam {
    
    /// 映射开关：false 关闭，true 开启
    var mappingSwitch: Bool = false
    
    /// 映射键值
    var mappingKey: GamepadKey = .none
    
    /// 触发方式 0：null，1：单击，2：长按，3：常开
    var triggerMode: Int = 0
    
    /// 映射对象 0：null，1：左摇杆，2：右摇杆
    var triggerKey: Int = 0
    
    /// 输入类型：0：角速度，1：加速度
    var inputType: Int = 0
    
    /// 输入模式：0：yz 模式，1：xy 模式，2：xyz 模式
    var inputMode: Int = 0
    
    /// 横滚反转
    var rollReversal: Bool = false
    
    ///俯仰反转
    var pitchReversal: Bool = false
    
    ///偏航反转
    var yawReversal: Bool = false
    
    /// 灵敏度： 0-100；默认：50
    var sensitivity: Int = 50
    
    /// 死区补偿：0-100；默认：0
    var deadZoneCompensation: Int = 0
    
    ///曲线类型：0：直性，1：凹线，2：凸线，3：S 线
    var curveType: Int = 0
    
    ///曲率：0-100；默认：50
    var curvature: Int = 50
    
    ///水平垂直比：0-200；默认：100
    var ratio: Int = 100
}
