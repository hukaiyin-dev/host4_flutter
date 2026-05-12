//
//  DataParser.swift
//  BluetoothKitDemo
//
//  Created by hukaiyin on 2025/3/16.
//

import Foundation

struct DataParser {
    private let data: Data
    var offset = 0

    init(_ data: Data) {
        self.data = data
    }

    /// 解析指定字节长度的数据
    mutating func next(_ length: Int) -> Data {
        guard offset + length <= data.count else {
            print("Error: 数据超出范围 (\(offset) + \(length) > \(data.count))")
            return Data()
        }
        
        let subData = data.subdata(in: offset..<offset + length)
        offset += length
        return subData
    }


    /// 跳过指定字节数
    mutating func skip(_ length: Int) {
        guard offset + length <= data.count else {
            print("Error: 跳过超出范围")
            return
        }
        offset += length
    }

    mutating func nextMultiple(keys: [String], sizes: [Int]) -> [String: Int] {
        var result = [String: Int]()
        for (index, key) in keys.enumerated() {
            result[key] = next(sizes[index]).toInt()
        }
        return result
    }

    /// 剩余可解析的字节数
    var remaining: Int {
        return data.count - offset
    }
    
    /// 获取剩余未解析的数据
    func trimmed() -> Data {
        guard offset < data.count else { return Data() }
        return data.subdata(in: offset..<data.count)
    }
}
