package com.host4.host4_flutter_device_native

import com.host4.platform.kr.response.DeviceAlignRsp
import java.util.Collections.emptyList

internal object DeviceAlignEventMapper {
    fun map(rsp: DeviceAlignRsp): Map<String, Any?> {
        val event = rsp.alignEvent
        return mapOf(
            "type" to "deviceAlign",
            "subId" to (event?.subId ?: event.subId),
            "result" to (event?.result ?: event.result),
            "param1" to toIntList(event?.param1),
            "param2" to toIntList(event?.param2),
        )
    }

    private fun toIntList(values: List<*>?): List<Int> {
        if (values.isNullOrEmpty()) {
            return emptyList()
        }
        return values.mapNotNull { value ->
            when (value) {
                is Int -> value
                is Number -> value.toInt()
                else -> null
            }
        }
    }
}
