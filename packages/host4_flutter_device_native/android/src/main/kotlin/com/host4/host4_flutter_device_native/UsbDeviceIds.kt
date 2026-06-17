package com.host4.host4_flutter_device_native

internal object UsbDeviceIds {
    /** 将厂商 ID 与产品 ID 格式化为 "vid:pid"（十六进制） */
    fun format(vendorId: Int, productId: Int): String {
        return "${vendorId.toUInt().toString(16)}:${productId.toUInt().toString(16)}"
    }

    /** 解析 "vid:pid" 字符串，返回 (vendorId, productId) */
    fun parse(deviceId: String): Pair<Int, Int>? {
        val parts = deviceId.split(":")
        if (parts.size != 2) {
            return null
        }
        val vendorId = parts[0].toIntOrNull(10) ?: return null
        val productId = parts[1].toIntOrNull(10) ?: return null
        return vendorId to productId
    }

    /**
     * 从 connectUsb 参数解析 pid/vid 筛选条件。
     *
     * 优先级：options 中的 pids/vids 数组 > deviceId 单个设备 > 不限制
     */
    fun parseFilter(deviceId: String?, options: Map<*, *>?): UsbPidVidFilter {
        val pids = parseIntList(options?.get("pids"))
        val vids = parseIntList(options?.get("vids"))
        if (!pids.isNullOrEmpty() || !vids.isNullOrEmpty()) {
            return UsbPidVidFilter(
                pids = pids?.toIntArray(),
                vids = vids?.toIntArray(),
            )
        }

        val vidPid = deviceId?.let { parse(it) }
        if (vidPid != null) {
            return UsbPidVidFilter(
                pids = intArrayOf(vidPid.second),
                vids = intArrayOf(vidPid.first),
            )
        }

        return UsbPidVidFilter(pids = null, vids = null)
    }

    private fun parseIntList(raw: Any?): List<Int>? {
        val list = raw as? List<*> ?: return null
        return list.mapNotNull { (it as? Number)?.toInt() }.takeIf { it.isNotEmpty() }
    }
}
