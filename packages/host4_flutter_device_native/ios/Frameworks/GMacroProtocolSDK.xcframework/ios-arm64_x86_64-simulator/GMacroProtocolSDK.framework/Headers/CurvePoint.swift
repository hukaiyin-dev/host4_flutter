//
//  CurvePoint.swift
//  BluetoothKitDemo
//
//  Created by hukaiyin on 2025/3/17.
//

import Foundation

struct Point {
    var x: Int
    var y: Int
    
    func data() -> Data {
        var payload = Data()
        
        payload.append(Data.from(x, count: 1))
        payload.append(Data.from(y, count: 1))
        return payload
    }
}

struct Size {
    var width: Int
    var height: Int
    
    func data() -> Data {
        var payload = Data()
        
        payload.append(Data.from(width, count: 1))
        payload.append(Data.from(height, count: 1))
        return payload
    }
}

struct Rect {
    var origin: Point
    var size: Size
    
    init(x: Int, y: Int, width: Int, height: Int) {
        self.origin = Point(x: x, y: y)
        self.size = Size(width: width, height: height)
    }
    
    func data() -> Data {
        var payload = Data()
        
        payload.append(origin.data())
        payload.append(size.data())

        return payload
    }
}
