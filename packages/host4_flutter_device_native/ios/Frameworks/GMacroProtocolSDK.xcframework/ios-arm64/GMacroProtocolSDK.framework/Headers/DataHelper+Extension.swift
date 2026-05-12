//
//  DataHelper+Extension.swift
//  LEDSDK
//
//  Created by hukaiyin on 2023/2/27.
//

import Foundation
import UIKit

extension DataHelper {
        
    func getSN() -> Data {
        if sn >= 0xFFFE {
            sn = 1
        }
        
        let snData = Data.from(sn, count: 2)
        sn += 1
        return snData
    }
    
    
    
    func getbluetoothSN() -> Data {
        if bluetoothSN >= 0xFFFFFFFE {
            bluetoothSN = 1
        }
        
        let snData = Data.from(bluetoothSN, count: 4)
        bluetoothSN += 1
        return snData
    }
    
    
    func getOneByteSN() -> Data {
        if oneByteSN >= 0xFF {
            oneByteSN = 1
        }
        
        let snData = Data.from(oneByteSN, count: 1)
        oneByteSN += 1
        return snData
    }
}

