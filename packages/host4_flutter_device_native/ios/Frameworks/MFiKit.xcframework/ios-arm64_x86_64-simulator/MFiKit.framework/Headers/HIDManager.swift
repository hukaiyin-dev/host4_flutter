//
//  HIDManager.swift
//  MFiKit
//
//  Created by hukaiyin on 2025/11/6.
//

import Foundation
import GameController

public class HIDManager {

    // 回调
    public var onTx: ((Data) -> Void)?
    public var onRx: ((Data) -> Void)?
    public var onErrorOccurred: ((Error) -> Void)?
    public var onDeviceConnected: (() -> Void)?
    public var onDeviceDisconnected: (() -> Void)?
    public var onDeviceConnectionFailed: (() -> Void)?

    private var gameController: GCController?

    // 防抖
    private var lastLX: Float = 0, lastLY: Float = 0
    private var lastRX: Float = 0, lastRY: Float = 0
    private var lastDX: Float = 0, lastDY: Float = 0
    private let deadzone: Float = 0.15   // 死区，小于这个值视为 0
    private let step: Float = 0.10       // 最小输出间隔

    // 连接 HID 设备
    public func connect() {
        print("尝试连接 HID 设备...")

        // 查找已连接的控制器
        if let controller = GCController.controllers().first {
            self.gameController = controller
            onDeviceConnected?()

            // 设置控制器事件监听
            setupGameController(controller)
        } else {
            print("未找到 HID 设备")
            let error = NSError(
                domain: "HIDManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "未找到 HID 设备"]
            )
            onErrorOccurred?(error)
        }
    }

    // 配置手柄事件回调
    private func setupGameController(_ controller: GCController) {
        controller.controllerPausedHandler = { [weak self] _ in
            self?.onDeviceDisconnected?()
            print("[GC] Pause/菜单键")
        }

        if let gamepad = controller.extendedGamepad {
            setupExtendedGamepad(gamepad)
        } else if let microGamepad = controller.microGamepad {
            setupMicroGamepad(microGamepad)
        }
    }

    // 设置 extendedGamepad 的事件处理
    private func setupExtendedGamepad(_ gamepad: GCExtendedGamepad) {
        gamepad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.onButtonPress("A", pressed: pressed)
        }
        gamepad.buttonB.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.onButtonPress("B", pressed: pressed)
        }
        
        // 按钮监听
        gamepad.valueChangedHandler = { [weak self] pad, element in
            guard let self = self else { return }
            if element == pad.leftThumbstick {
                let x = pad.leftThumbstick.xAxis.value, y = pad.leftThumbstick.yAxis.value
                if self.changed(&self.lastLX, to: x) || self.changed(&self.lastLY, to: y) {
                    self.log(String(format: "[GC] LeftStick x=%.2f y=%.2f", x, y))
                    self.onRx?(Data([UInt8(x), UInt8(y)]))  // 假设通过此方式传送
                }
            } else if element == pad.rightThumbstick {
                let x = pad.rightThumbstick.xAxis.value, y = pad.rightThumbstick.yAxis.value
                if self.changed(&self.lastRX, to: x) || self.changed(&self.lastRY, to: y) {
                    self.log(String(format: "[GC] RightStick x=%.2f y=%.2f", x, y))
                    self.onRx?(Data([UInt8(x), UInt8(y)]))  // 假设通过此方式传送
                }
            } else if element == pad.dpad {
                let x = pad.dpad.xAxis.value, y = pad.dpad.yAxis.value
                if self.changed(&self.lastDX, to: x) || self.changed(&self.lastDY, to: y) {
                    self.log(String(format: "[GC] DPad x=%.2f y=%.2f", x, y))
                    self.onRx?(Data([UInt8(x), UInt8(y)]))  // 假设通过此方式传送
                }
            }
        }
    }
    
    //  microGamepad
    private func setupMicroGamepad(_ gamepad: GCMicroGamepad) {
        gamepad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.onButtonPress("A", pressed: pressed)
        }

        // 处理 DPad 按钮的按下和抬起
        gamepad.dpad.up.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.onDpadPress(direction: "Up", pressed: pressed)
        }
        gamepad.dpad.down.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.onDpadPress(direction: "Down", pressed: pressed)
        }
        gamepad.dpad.left.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.onDpadPress(direction: "Left", pressed: pressed)
        }
        gamepad.dpad.right.pressedChangedHandler = { [weak self] _, _, pressed in
            self?.onDpadPress(direction: "Right", pressed: pressed)
        }
    }

    //DPad
    private func onDpadPress(direction: String, pressed: Bool) {
        self.log("[GC] DPad \(direction): " + (pressed ? "Down" : "Up"))
        let data = Data([UInt8(direction.hashValue)])  // 这是一个示例，你可以根据实际情况调整数据结构
        self.onRx?(data)
    }

    // 处理按钮按下事件
    private func onButtonPress(_ name: String, pressed: Bool) {
        print("[GC] \(name): " + (pressed ? "Down" : "Up"))
        // 在这里可以进行按钮按下时的处理，发送数据或其他操作
        onTx?(Data([UInt8(name.hashValue)]))  // 假设发送按钮的 hash 值作为命令
    }

    // 防抖处理
    private func changed(_ old: inout Float, to new: Float) -> Bool {
        // 死区处理
        if abs(new) < deadzone {
            if old != 0 {
                old = 0
                return true
            }
            return false
        }

        if abs(new - old) >= step {
            old = new
            return true
        }
        return false
    }

    // 发送数据
    public func send(data: Data) {
        print("发送数据到设备: \(data.hexString())")
        onTx?(data)  // 发送数据的回调
    }

    // 断开接
    public func disconnect() {
        print("断开与 HID 设备的连接")
        gameController = nil
        onDeviceDisconnected?()  // 设备已断开
    }

    // 打印日志
    private func log(_ s: String) {
        print("[HID] \(s)")
    }
}

extension Data {
    func hexString() -> String {
        map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
