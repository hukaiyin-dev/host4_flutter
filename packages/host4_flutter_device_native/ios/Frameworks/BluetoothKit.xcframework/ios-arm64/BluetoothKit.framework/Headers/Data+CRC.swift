//
//  Data+CRC.swift
//  AmiiBook
//
//  Created by hukaiyin on 2021/3/12.
//

import Foundation

public
extension Data {

    typealias bit_order_16 = (_ value: UInt16) -> UInt16
    typealias bit_order_8 = (_ value: UInt8) -> UInt8

    func straight_16(value: UInt16) -> UInt16 {
        return value
    }

    func reverse_16(value: UInt16) -> UInt16 {
        var value = value
        var reversed: UInt16 = 0
        for _ in 0..<16 {
            reversed <<= 1
            reversed |= (value & 0x1)
            value >>= 1
        }
        return reversed
    }

    func straight_8(value: UInt8) -> UInt8 {
        return value
    }

    func reverse_8(value: UInt8) -> UInt8 {
        var value = value
        var reversed: UInt8 = 0
        for _ in 0..<8 {
            reversed <<= 1
            reversed |= (value & 0x1)
            value >>= 1
        }
        return reversed
    }

    func crc16(data_order: bit_order_8, remainder_order: bit_order_16, remainder: UInt16, polynomial: UInt16) -> UInt16 {
        var remainder = remainder

        for byte in self {
            remainder ^= UInt16(data_order(byte)) << 8
            for _ in 0..<8 {
                if (remainder & 0x8000) != 0 {
                    remainder = (remainder << 1) ^ polynomial
                } else {
                    remainder = (remainder << 1)
                }
            }
        }
        return remainder_order(remainder)
    }

    func crc16ccitt() -> UInt16 {
        return crc16(data_order: straight_8, remainder_order: straight_16, remainder: 0xffff, polynomial: 0x1021)
    }

    func crc16ccitt_xmodem() -> UInt16 {
        return crc16(data_order: straight_8, remainder_order: straight_16, remainder: 0x0000, polynomial: 0x1021)
    }

    func crc16ccitt_kermit() -> UInt16 {
        let swap = crc16(data_order: reverse_8, remainder_order: reverse_16, remainder: 0x0000, polynomial: 0x1021)
        return swap.byteSwapped
    }

    func crc16ccitt_1d0f() -> UInt16 {
        return crc16(data_order: straight_8, remainder_order: straight_16, remainder: 0x1d0f, polynomial: 0x1021)
    }

    func crc16ibm() -> UInt16 {
        return crc16(data_order: reverse_8, remainder_order: reverse_16, remainder: 0x0000, polynomial: 0x8005)
    }
}
