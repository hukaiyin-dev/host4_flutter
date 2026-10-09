package com.host4.host4_flutter_device_native.broker

import com.host4.host4_flutter_device_native.GmacroCommandBackend
import com.host4.host4_flutter_device_native.GmacroResult

internal class AidlGmacroBackend(
    private val client: DeviceBrokerClient,
) : GmacroCommandBackend {
    override fun invoke(
        method: String,
        arguments: Map<String, Any?>,
        callback: (GmacroResult) -> Unit,
    ) {
        client.invoke(method, arguments, callback)
    }
}
