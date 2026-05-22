package com.host4.host4_flutter_device_native

import android.os.Handler
import android.os.Looper
import com.host4.platform.kr.response.QueryHandleInfoRsp
import com.host4.platform.util.Constants
import com.host4.platform.v2.api.PlatformSdkFactory
import io.flutter.plugin.common.MethodChannel

internal object KrDeviceInfoQuery {
    private val mainHandler = Handler(Looper.getMainLooper())

    fun query(deviceMac: String, result: MethodChannel.Result) {
        val commands = PlatformSdkFactory.full().commands()
        commands.queryHandleInfoReq { code, rsp ->
            mainHandler.post {
                if (code == Constants.SUCCESS && rsp != null) {
                    result.success(deviceInfoToMap(rsp))
                } else {
                    result.error(
                        "query-device-info-failed",
                        "queryDeviceInfo failed with code=$code",
                        null,
                    )
                }
            }
        }
    }

    fun deviceInfoToMap(rsp: QueryHandleInfoRsp): Map<String, Any?> {
        return mapOf(
            "projectCoding" to rsp.projectCoding,
            "agreementVersion" to rsp.agreementVersion,
            "firmwareVersion" to rsp.firmwareVersion,
            "hardwareVersion" to rsp.hardwareVersion,
        )
    }
}
