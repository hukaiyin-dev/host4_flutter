//
//  ThreeDswift
//  BluetoothKitDemo
//
//  Created by hukaiyin on 2025/3/17.
//
import Foundation
struct ThreeDInfo {
    
    var sensitivity: Int        = 0 // 灵敏度 1 byte(0-50百分比)

    var deadZoneX: Int          = 2 // 死区 X，例如左 3D 的死区为 （1，8），那么 left3DX.deadZone == 1, left3DY.deadZone == 8
    var deadZoneY: Int          = 2 // 死区 Y
    var lowX: Int               = 0x1E // 曲线点 1 X， 点 1 byte，点位为（33，42），那么 left3DX.pointL == 33, left3DY.pointL == 42
    var lowY: Int               = 0x1E // 曲线点 1 Y
    var highX: Int              = 0x46 // 曲线点 2 X
    var highY: Int              = 0x46 // 曲线点 2 Y
    
    var exchangeX               = false // 反转 X
    var exchangeY               = false // 反转 Y
    
    func data() -> Data {
        var payload = Data()
        
        payload.append(Data.from(sensitivity, count: 1))
        payload.append(Data.from(deadZoneX, count: 1))
        payload.append(Data.from(deadZoneY, count: 1))
        payload.append(Data.from(lowX, count: 1))
        payload.append(Data.from(lowY, count: 1))
        payload.append(Data.from(highX, count: 1))
        payload.append(Data.from(highY, count: 1))
        payload.append(Data.from(exchangeX.int, count: 1))
        payload.append(Data.from(exchangeY.int, count: 1))

        return payload
    }
}
