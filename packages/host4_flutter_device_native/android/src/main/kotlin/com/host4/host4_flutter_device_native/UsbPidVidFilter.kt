package com.host4.host4_flutter_device_native

/**
 * USB 设备 pid/vid 筛选条件。
 *
 * - [pids]：允许的产品 ID 列表，null 或空表示不限制
 * - [vids]：允许的厂商 ID 列表，null 或空表示不限制
 */
internal data class UsbPidVidFilter(
    val pids: IntArray?,
    val vids: IntArray?,
) {
    /** 是否指定了单个 pid/vid（兼容旧版 init(context, pid, vid) 调用） */
    val singlePid: Int?
        get() = pids?.singleOrNull()

    val singleVid: Int?
        get() = vids?.singleOrNull()

    val hasSinglePair: Boolean
        get() = pids?.size == 1 && vids?.size == 1

    val hasArrayFilter: Boolean
        get() = (pids != null && pids.isNotEmpty()) || (vids != null && vids.isNotEmpty())

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is UsbPidVidFilter) return false
        return pids.contentEquals(other.pids) && vids.contentEquals(other.vids)
    }

    override fun hashCode(): Int {
        var result = pids?.contentHashCode() ?: 0
        result = 31 * result + (vids?.contentHashCode() ?: 0)
        return result
    }
}
