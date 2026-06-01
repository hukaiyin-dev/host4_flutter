package com.host4.host4_flutter_device_native

import com.host4.platform.manager.ReliableUsbCommManager

internal object UsbTransportEventMapper {
    fun mapTransportEvent(status: Int): Map<String, Any?> {
        return when (status) {
            ReliableUsbCommManager.CONNECT_ATTACHED -> mapOf("type" to "connecting")
            ReliableUsbCommManager.CONNECT_COMPLETED -> mapOf("type" to "ready")
            ReliableUsbCommManager.CONNECT_DETACHED -> mapOf(
                "type" to "disconnected",
                "failure" to TransportEventMapper.failureMap(
                    code = "usb-detached",
                    message = "USB device detached.",
                ),
            )
            ReliableUsbCommManager.CONNECT_FAIL -> mapOf(
                "type" to "error",
                "failure" to TransportEventMapper.failureMap(
                    code = "usb-connect-failed",
                    message = "USB connection failed.",
                ),
            )
            ReliableUsbCommManager.CONNECT_PERMISSION_FAIL -> mapOf(
                "type" to "error",
                "failure" to TransportEventMapper.failureMap(
                    code = "usb-permission-denied",
                    message = "USB permission was denied.",
                ),
            )
            else -> mapOf(
                "type" to "error",
                "failure" to TransportEventMapper.failureMap(
                    code = "unknown-usb-state",
                    message = "Unknown USB transport status: $status.",
                ),
            )
        }
    }
}
