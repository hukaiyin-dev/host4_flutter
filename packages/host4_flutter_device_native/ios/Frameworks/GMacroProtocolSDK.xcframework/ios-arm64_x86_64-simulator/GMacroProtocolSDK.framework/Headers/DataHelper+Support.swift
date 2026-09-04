//
//  DataHelper+GMacro.swift
//  BluetoothKit
//
//  Created by hukaiyin on 2025/3/13.
//

import Foundation
import BluetoothKit

struct SDKSendableBox<T>: @unchecked Sendable {
    let value: T
}

extension DataHelper {

    func write(protocolID: GMacroProtocolID,
               data: Data,
               finish: (() -> Void)? = nil,
               response: @escaping @Sendable (Result<[String: Any], Error>) -> Void
    ) {

        // data 末尾必须带 sn，否则会崩
        guard let snByte = data.last else {
            response(.failure(NSError(domain: "InvalidPacket",
                                      code: -2,
                                      userInfo: [NSLocalizedDescriptionKey: "Packet is empty (missing SN)"])))
            finish?()
            return
        }

        // 2026.5.28 修改：新增 subID 区分同一 protocolID 下不同的命令响应，确保 responseKey 唯一性
        let snData = Data([snByte])
        _ = snData // 如未使用可删掉 snData 变量

        var subID: UInt8? = nil
        if protocolID.hasSubID {
            guard data.count >= 4 else { // [len][pid][subID][sn] 最短
                response(.failure(NSError(
                    domain: "InvalidPacket",
                    code: -4,
                    userInfo: [NSLocalizedDescriptionKey:
                        "Protocol 0x\(String(format: "%02X", protocolID.rawValue)) requires subID, but packet is too short"]
                )))
                finish?()
                return
            }
            subID = data[2]
        }
        
//        let responseKey = ResponseKey(protocolID: protocolID, sn: snByte)
        let responseKey = ResponseKey(protocolID: protocolID, subID: subID, sn: snByte)

        callbackQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            self.pendingResponses[responseKey] = response
        }

        print("开始超时计时 \(Date()) data.sn \(snData.nsDescription()) protocolID \(protocolID)")

        // 只保留一次超时计时，并且触发前再次确认 callback 还存在
        DispatchQueue.global().asyncAfter(deadline: .now() + GPDConstant.responseTimeout) { [weak self] in
            guard let self else { return }
            self.callbackQueue.async {
                dispatchPrecondition(condition: .onQueue(self.callbackQueue))

                guard let cb = self.pendingResponses[responseKey] else {
//                    print("已收到回应，超时取消 protocolID \(responseKey)")
                    print("已收到回应，超时取消 pid=0x\(String(format: "%02X", responseKey.protocolID.rawValue)) key=\(responseKey)")
                    return
                }

                let sn = Data([snByte])
//                print("触发超时 \(Date()) data.sn \(sn.nsDescription()) protocolID \(protocolID)")
                print("触发超时 \(Date()) data.sn \(sn.nsDescription()) pid=0x\(String(format: "%02X", protocolID.rawValue)) key=\(responseKey)")

                cb(.failure(BluetoothError.timeout))
                self.callbackQueue.async(flags: .barrier) {
                    self.pendingResponses.removeValue(forKey: responseKey)
                }
            }
        }

        print("写入数据 <\(data.hexadecimal)>")

        let finish = finish ?? {}

        let totalCount: Int = 1
        let sentCount: Int = 0

        // session 化路径：优先走 sendPacketHandler（由 GMacroProtocolSession 注入）
        if let handler = sendPacketHandler {
            handler(data, totalCount, sentCount, GPDConstant.commandCharacteristic, false, finish) { dic, err in
                if let err = err {
                    response(.failure(err))
                } else if let dic = dic as? [String: Any] {
                    response(.success(dic))
                } else {
                    response(.failure(NSError(domain: "InvalidResponse",
                                              code: -1,
                                              userInfo: [NSLocalizedDescriptionKey: "Empty or invalid response"])))
                }
            }
            return
        }

        assertionFailure("DataHelper.sendPacketHandler 未设置：请先通过 GMacroProtocolSession 连接 transport")
        response(.failure(NSError(domain: "BLESendHandlerNil",
                                  code: -3,
                                  userInfo: [NSLocalizedDescriptionKey: "DataHelper.sendPacketHandler is nil"])))
        finish()
    }


    // 多条指令递归发送
    func write(protocolID: GMacroProtocolID,
               datas: [Data],
               finish: (() -> Void)?,
               response: @escaping @Sendable (Result<[String: Any], Error>) -> Void
    ) {

        callbackQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            self.writeQueue.append((protocolID, datas, finish, response))
            self.tryDequeueWrite()
        }
    }

    private func tryDequeueWrite() {
        guard !isWriting, !writeQueue.isEmpty else {
            print("isWriting \(isWriting) \(writeQueue.isEmpty)")
            return
        }

        let nextTask = writeQueue.removeFirst()

        let safeNextTask = SDKSendableBox(value: nextTask)

        var mutableQueue = nextTask.datas
        guard !mutableQueue.isEmpty else {
            nextTask.finish?()
            isWriting = false
            tryDequeueWrite()
            return
        }

        let nextPacket = mutableQueue.removeFirst()

        self.write(protocolID: nextTask.protocolID,
                   data: nextPacket,
                   finish: { [weak self] in
            guard let self else { return }

            DispatchQueue.global().asyncAfter(deadline: .now() + GPDConstant.messageInterval) {
                self.callbackQueue.async {
                    let originalTask = safeNextTask.value
                    var updatedTask = (
                        protocolID: originalTask.protocolID,
                        datas: mutableQueue,
                        finish: originalTask.finish,
                        response: originalTask.response
                    )

                    if mutableQueue.isEmpty {
                        updatedTask.finish?()
                        self.isWriting = false
                        self.tryDequeueWrite()
                    } else {
                        self.writeQueue.insert(updatedTask, at: 0)
                        self.isWriting = false
                        self.tryDequeueWrite()
                    }
                }
            }
        }, response: { result in
            safeNextTask.value.response(result)
        })
    }


    func dataFrom(protocolID: GMacroProtocolID,
                  payload: Data?) -> Data {

        var body = Data([protocolID.rawValue])
        if let payload = payload {
            body.append(payload)
        }

        // length = (protocolID + payload) + sn + lengthByte 本身？
        // 你原逻辑是 body.count + 2，这里保持一致
        let lenInt = body.count + 2
        let len = UInt8(clamping: lenInt)
        var all = Data([len])
        all.append(body)

        all.append(UInt8(clamping: sn))
        sn += 1
        // SN 是 1 字节，允许本包使用 0xFF；下一次再回到 0x01，避免超过 0xFF 后被 clamping 一直压成 0xFF。
        if sn > 0xFF {
            sn = 1
        }

        return all
    }

}

extension DataHelper {

    // 坐标转换
    func convertAndValidatePoints(cgPoints: [CGPoint],
                                  response: @escaping (Result<[String: Any], Error>) -> Void) -> [Point]? {
        var points: [Point] = []

        for cgPoint in cgPoints {
            let point = Point(x: Int(cgPoint.x), y: Int(cgPoint.y))
            points.append(point)

            if !(0...100).contains(point.x) || !(0...100).contains(point.y) {
                response(.failure(BluetoothError.outOfRange))
                return nil
            }
        }

        return points
    }

    // 创建多条 Points 指令
    func pointDatas(protocolID: GMacroProtocolID,
                    subID: UInt8,
                    points: [Point]) -> [Data] {
        let maxPointsPerPacket = 7
        let totalPoints = points.count
        let totalPackets = (totalPoints + maxPointsPerPacket - 1) / maxPointsPerPacket
        var commandQueue: [Data] = []

        let totalPointsByte = UInt8(clamping: totalPoints)

        for packetIndex in 0..<totalPackets {
            let start = packetIndex * maxPointsPerPacket
            let end = min(start + maxPointsPerPacket, totalPoints)
            let chunk = points[start..<end]

            var payload = Data()
            payload.append(Data.from(Int(subID), count: 1))               // subID
            payload.append(Data.from(Int(totalPointsByte), count: 1))     // 总点数(1 byte)
            payload.append(Data.from(packetIndex + 1, count: 1))          // 当前包序号

            var pointDatas = Data()
            for point in chunk {
                pointDatas.append(point.data())
            }

            payload.append(pointDatas)
            let packet = dataFrom(protocolID: protocolID, payload: payload)
            commandQueue.append(packet)
        }

        return commandQueue
    }

}
