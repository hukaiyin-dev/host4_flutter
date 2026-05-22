package com.host4.host4_flutter_device_native

import com.host4.platform.v2.api.FullPlatformSdk
import com.host4.platform.v2.protocol.V2KrCmdController
import io.flutter.plugin.common.MethodChannel

internal object GmacroMethodInvoker {
    fun invoke(
        mac: String,
        method: String,
        @Suppress("UNUSED_PARAMETER") arguments: Map<String, Any?>,
        result: MethodChannel.Result,
    ) {
        val commands: V2KrCmdController = FullPlatformSdk.getInstance().commands(mac)

        when (method) {
            "fetchDeviceVersion" -> KrDeviceInfoQuery.query(mac, result)
            else -> {
                result.error(
                    "unsupported-gmacro-method",
                    "Unsupported GMacro method on Android: $method",
                    null,
                )
            }
        }
    }
}
