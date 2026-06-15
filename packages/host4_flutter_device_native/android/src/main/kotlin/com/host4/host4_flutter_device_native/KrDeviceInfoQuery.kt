package com.host4.host4_flutter_device_native

import io.flutter.plugin.common.MethodChannel

internal object KrDeviceInfoQuery {
    fun query(deviceKey: String, transportKind: String, result: MethodChannel.Result) {
        GmacroSdkAccess.commands(deviceKey, transportKind)
            .queryHandleInfoReq(GmacroCallbackBridge.fetchDeviceVersion(result))
    }
}
