package com.host4.host4_flutter_device_native

import com.host4.platform.util.Constants

internal object TransportEventMapper {
    fun mapTransportEvent(status: Int): Map<String, Any?> {
        return when (status) {
            Constants.CONNECTING -> mapOf("type" to "connecting")
            Constants.CONNECTED -> mapOf("type" to "connected")
            Constants.COMPLETE_CONNECT -> mapOf("type" to "ready")
            Constants.DISCONNECT,
            Constants.CONNECT_TIMEOUT,
            Constants.CONNECT_EXCEPTION -> mapOf(
                "type" to "disconnected",
                "failure" to failureMap(
                    code = "ble-disconnected",
                    message = "BLE transport disconnected (status=$status).",
                ),
            )
            else -> mapOf(
                "type" to "error",
                "failure" to failureMap(
                    code = "unknown-transport-state",
                    message = "Unknown BLE transport status: $status.",
                ),
            )
        }
    }

    fun failureMap(
        code: String,
        message: String,
        details: Any? = null,
    ): Map<String, Any?> {
        val payload = mutableMapOf<String, Any?>(
            "code" to code,
            "message" to message,
        )
        if (details != null) {
            payload["details"] = details
        }
        return payload
    }
}
