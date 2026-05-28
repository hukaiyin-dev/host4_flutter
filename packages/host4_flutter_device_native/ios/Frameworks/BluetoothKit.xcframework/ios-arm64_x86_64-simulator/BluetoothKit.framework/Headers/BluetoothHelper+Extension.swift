//
//  LEDBluetoothHelper+Extension.swift
//  LED
//
//  Created by hukaiyin on 2021/3/31.
//  Copyright © 2021 sunday. All rights reserved.
//

import CoreBluetooth

extension BluetoothHelper {
    
    /// 订阅特征后发送第一条消息
    /// 
    func startCommunication(with characteristics: [CBCharacteristic]) {
        BaseBluetooth.shared.stopScan(notif: true)
        
        if OTAHelper.shared.updating {
            return
        }
        
        guard let delegate = delegate else {
            return
        }
        
        let hasCommand = characteristics.contains {
            $0.uuid.uuidString == BluetoothKitConstant.commandCharacteristic
        }
        
        if hasCommand {
            DispatchQueue.global().async {
                delegate.startCommunication()
            }
        }
    }
    
    public
    func cancelPeripheralConnection() {
        BaseBluetooth.shared.cancelPeripheralConnection()
        endPolling()
        OTAHelper.shared.updating = false
    }
}


// MARK: - Timer
public
extension BluetoothHelper {
    
    // 如果是断连状态，每 2s 检查一遍是否有连接
    @objc func startPolling() {
        if timer != nil {
            timer?.cancel()
            timer = nil
        }
        
        polling = true
        dontCheck = false
        timer = DispatchSource.pollingSchedule(repeating: 2, handler: {  [weak self] _ in
            guard let `self` = self  else { return }
            self.checkConnect()
        })
    }
    
    func checkConnect() {
        if self.dontCheck {
            return
        }
        BluetoothHelper.shared.checkConnect { [weak self] connected in
            guard let `self` = self  else { return }
            
            if self.isConnect == connected {
                // 连接状态未改变
                
                return
            }
            self.update(connect: connected)
            if self.dontCheck {
                return
            }
            if !connected {
                self.polling = true
                //                    Device.current = nil
                // 如果还在扫描中，不要发断连消息
                if !BaseBluetooth.shared.centralManager.isScanning {
                    
//                    print("checkConnect 断连，self.isConnect == false \(self.dontCheck)")
//                    NotificationCenter.default.post(name: .bluetoothDisconncet, object: nil)
                }
            } else {
//                NotificationCenter.default.post(name: .bluetoothConncet, object: nil)
            }
        }
    }
    
    
    // 蓝牙已连接，取消轮询
    @objc public func endPolling() {
        if polling {
            polling = false
            timer?.cancel()
            timer = nil
            dontCheck = true
        }
    }
}

