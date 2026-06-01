package com.host4.host4_flutter_device_native

internal object UsbDeviceIds {
    fun format(vendorId: Int, productId: Int): String {
        return "${vendorId.toUInt().toString(16)}:${productId.toUInt().toString(16)}"
    }

    fun parse(deviceId: String): Pair<Int, Int>? {
        val parts = deviceId.split(":")
        if (parts.size != 2) {
            return null
        }
        val vendorId = parts[0].toIntOrNull(16) ?: return null
        val productId = parts[1].toIntOrNull(16) ?: return null
        return vendorId to productId
    }
}
