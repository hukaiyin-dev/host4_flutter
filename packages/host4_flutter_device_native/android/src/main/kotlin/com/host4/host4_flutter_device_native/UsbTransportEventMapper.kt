package com.host4.host4_flutter_device_native

import com.host4.platform.manager.ReliableUsbCommManager

/** 将 SDK USB 连接状态码映射为 Flutter 传输事件 */
internal object UsbTransportEventMapper {
    fun mapTransportEvent(status: Int): Map<String, Any?> {
        return when (status) {
            // 设备已接入，正在连接
            ReliableUsbCommManager.CONNECT_ATTACHED -> mapOf("type" to "connecting")
            // 连接完成，可以通信
            ReliableUsbCommManager.CONNECT_COMPLETED -> mapOf("type" to "ready")
            // 设备拔出
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
