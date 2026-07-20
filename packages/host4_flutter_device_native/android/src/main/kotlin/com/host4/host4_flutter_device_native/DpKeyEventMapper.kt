package com.host4.host4_flutter_device_native

import com.host4.platform.kr.model.TestModeEvent

internal object DpKeyEventMapper {
    fun map(event: TestModeEvent, type: String = "dpKeyEvent"): Map<String, Any?> {
        return mapOf(
            "type" to type,
            "keyValue" to event.keyValue,
            "keys" to event.keys.orEmpty().map { it.toLong() },
            "leftRockerXValue" to event.leftRockerXValue,
            "leftRockerYValue" to event.leftRockerYValue,
            "rightRockerXValue" to event.rightRockerXValue,
            "rightRockerYValue" to event.rightRockerYValue,
            "leftKeyLTwoValue" to event.leftKeyLTwoValue,
            "rightKeyRTwoValue" to event.rightKeyRTwoValue,
            "leftRockerXOriginalValue" to event.leftRockerXOriginalValue,
            "leftRockerYOriginalValue" to event.leftRockerYOriginalLValue,
            "rightRockerXOriginalValue" to event.rightRockerXOriginalValue,
            "rightRockerYOriginalValue" to event.rightRockerYOriginalValue,
            "leftKeyLTOriginalValue" to event.leftKeyLTOriginalValue,
            "rightKeyRTOriginalValue" to event.rightKeyRTOriginalValue,
        )
    }
}
