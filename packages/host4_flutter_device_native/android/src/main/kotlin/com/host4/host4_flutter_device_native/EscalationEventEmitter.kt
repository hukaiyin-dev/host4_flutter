package com.host4.host4_flutter_device_native

import com.host4.platform.kr.response.DPKeyEventRsp
import com.host4.platform.kr.response.DeviceAlignRsp
import com.host4.platform.kr.response.EscalationRsp
import com.host4.platform.kr.response.TestModeEventRsp

internal object EscalationEventEmitter {
    fun emit(handler: QueuedEventStreamHandler?, message: EscalationRsp) {
        val target = handler ?: return
        GmacroEscalationMapper.toEvent(message)?.let(target::emit)
    }
}

/** Shared active-report mapping for direct USB/BLE and brokered UART transports. */
object GmacroEscalationMapper {
    fun toEvent(message: EscalationRsp): Map<String, Any?>? {
        return when (message) {
            is DPKeyEventRsp -> {
                val modeEvent = message.modeEvent ?: return null
                DpKeyEventMapper.map(modeEvent)
            }
            is TestModeEventRsp -> {
                val modeEvent = message.testModeEvent ?: return null
                DpKeyEventMapper.map(modeEvent, type = "testModeEvent")
            }
            is DeviceAlignRsp -> DeviceAlignEventMapper.map(message)
            else -> null
        }
    }
}
