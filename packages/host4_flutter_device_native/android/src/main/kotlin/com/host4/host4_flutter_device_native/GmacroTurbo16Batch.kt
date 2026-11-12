package com.host4.host4_flutter_device_native

internal object GmacroTurbo16Batch {
    private data class Entry(val key: Int, val turbo: Int, val duration: Int, val interval: Int)

    fun send(
        items: List<Map<String, Any?>>,
        pressDuration: Int?,
        device: Int,
        sendOne: (Int, Int, Int, Int, Int, (GmacroResult) -> Unit) -> Unit,
        onResult: (GmacroResult) -> Unit,
    ) {
        require(items.isNotEmpty()) { "keyTurbos must not be empty." }
        require((pressDuration == null || pressDuration in 0..0xFFFF) && device in 0..0xFF) {
            "Invalid turbo16 timing or device."
        }
        val entries = items.map { item ->
            val key = GmacroArgParser.intArg(item, "key")
            val turbo = GmacroArgParser.intArg(item, "turbo")
            val duration = pressDuration ?: GmacroArgParser.intArg(item, "pressDuration", 0)
            val interval = GmacroArgParser.intArg(item, if (pressDuration == null) "interval" else "speed")
            require(key in 0..0xFF && turbo in 0..2 && duration in 0..0xFFFF && interval in 1..0xFFFF) {
                "Invalid turbo16 key, mode, duration or interval."
            }
            Entry(key, turbo, duration, interval)
        }
        fun sendNext(index: Int) {
            val (key, turbo, duration, interval) = entries[index]
            sendOne(key, turbo, duration, interval, device) { result ->
                if (result is GmacroResult.Error || index == entries.lastIndex) {
                    onResult(result)
                } else {
                    sendNext(index + 1)
                }
            }
        }
        sendNext(0)
    }
}
