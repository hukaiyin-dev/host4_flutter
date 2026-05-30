package com.host4.host4_flutter_device_native

import io.flutter.plugin.common.MethodChannel

internal object KrDeviceInfoQuery {
    fun query(deviceMac: String, result: MethodChannel.Result) {
        GmacroSdkAccess.commands(deviceMac).queryHandleInfoReq(GmacroCallbackBridge.message(result))
    }
}
