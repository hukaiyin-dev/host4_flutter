//
//  LinearInfo.swift
//  BluetoothKitDemo
//
//  Created by hukaiyin on 2025/3/17.
//

import Foundation

struct LinearInfo {
    
    /// 左摇杆起始值
    var leftMin: Int = 10
    /// 左摇杆终止值
    var leftMax: Int = 80
    /// 左摇杆反转 X
    var leftXFlip = false
    /// 左摇杆反转 Y
    var leftYFlip = false

    /// 右摇杆起始值
    var rightMin: Int = 10
    /// 右摇杆终止值
    var rightMax: Int = 80
    /// 右摇杆反转 X
    var rightXFlip = false
    /// 右摇杆反转 Y
    var rightYFlip = false
}

struct RockerAdditionalInfo {
    ///外形死区：0：圆形，1：方形，2：椭圆（圆角矩形）
    var leftDeadZone: Int = 0
    ///输出最大值：0-100（0%-100%）
    var leftOutMax: Int = 100
    ///曲线应用：0：持续，1：单击，2：按住
    var leftCurveApply: Int = 0
    ///曲线应用按键：持续模式为 0，单击模式和按住模式设定按键（附表键值）
    var leftCurveApplyKey: GamepadKey = .none
    ///直线修正：0：关（圆形内死区），1：开（方形内死区）
    var leftLineCorrection: Int = 0
    var rightDeadZone: Int = 0
    var rightOutMax: Int = 100
    var rightCurveApply: Int = 0
    var rightCurveApplyKey: GamepadKey = .none
    var rightLineCorrection: Int = 0
}
