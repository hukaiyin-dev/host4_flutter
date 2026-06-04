package com.host4.host4_flutter_device_native

import com.host4.platform.kr.response.DPKeyEventRsp
import com.host4.platform.kr.response.DeviceAlignRsp
import com.host4.platform.kr.response.EscalationRsp

internal object EscalationEventEmitter {
    fun emit(handler: QueuedEventStreamHandler?, message: EscalationRsp) {
        val target = handler ?: return
        when (message) {
            is DPKeyEventRsp -> {
                val modeEvent = message.modeEvent ?: return
                target.emit(DpKeyEventMapper.map(modeEvent))
            }
            is DeviceAlignRsp -> {
                target.emit(DeviceAlignEventMapper.map(message))
            }
        }
    }
}
