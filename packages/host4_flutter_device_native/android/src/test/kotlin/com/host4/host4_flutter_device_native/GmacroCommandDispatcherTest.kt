package com.host4.host4_flutter_device_native

import com.host4.platform.kr.model.LightEffect
import com.host4.platform.kr.model.MacroMapping
import com.host4.platform.kr.response.AlignGyroscopeRsp
import com.host4.platform.kr.response.AlignRockerOrTriggerRsp
import com.host4.platform.kr.response.LinerTriggerRsp
import com.host4.platform.kr.response.MacroMappingKeyRsp
import com.host4.platform.kr.response.MacroProfileRsp
import com.host4.platform.kr.response.QueryCurrentLightEffectRsp
import com.host4.platform.kr.response.QueryHandleInfoRsp
import com.host4.platform.kr.response.VibrateOpenRsp
import com.host4.platform.util.Constants
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs

internal class GmacroCommandDispatcherTest {
    @Test
    fun deviceVersion_successCodes_preserveDartFieldNames() {
        val rsp = QueryHandleInfoRsp().apply {
            projectCoding = "M6"
            agreementVersion = "2.1"
            firmwareVersion = "1.0.3"
            hardwareVersion = "A1"
        }

        assertEquals(
            mapOf(
                "project" to "M6",
                "protocol" to "2.1",
                "firmware" to "1.0.3",
                "hardware" to "A1",
            ),
            successMap { GmacroCallbackBridge.fetchDeviceVersion(it).message(Constants.SUCCESS, rsp) },
        )
        assertEquals(
            mapOf(
                "project" to "M6",
                "protocol" to "2.1",
                "firmware" to "1.0.3",
                "hardware" to "A1",
            ),
            successMap { GmacroCallbackBridge.fetchDeviceVersion(it).message(80, rsp) },
        )
    }

    @Test
    fun currentProfile_mapsModeToProfile() {
        val rsp = MacroProfileRsp().apply { mode = 3 }

        assertEquals(
            mapOf("profile" to 3),
            successMap { GmacroCallbackBridge.fetchCurrentProfile(it).message(Constants.SUCCESS, rsp) },
        )
    }

    @Test
    fun vibrationSwitch_statusTwoMeansOff() {
        val onRsp = VibrateOpenRsp().apply { status = 1 }
        val offRsp = VibrateOpenRsp().apply { status = 2 }

        assertEquals(
            mapOf("isOn" to true),
            successMap { GmacroCallbackBridge.queryVibrateOpen(it).message(Constants.SUCCESS, onRsp) },
        )
        assertEquals(
            mapOf("isOn" to false),
            successMap { GmacroCallbackBridge.queryVibrateOpen(it).message(Constants.SUCCESS, offRsp) },
        )
    }

    @Test
    fun lightConfig_usesHost4FieldNames() {
        val rsp = QueryCurrentLightEffectRsp().apply {
            lightEffect = LightEffect().apply {
                effect = 4
                colorR = 10
                colorG = 20
                colorB = 30
                brightness = 80
                speed = 5
                profile = 2
            }
        }

        assertEquals(
            mapOf(
                "effect" to 4,
                "colorR" to 10,
                "colorG" to 20,
                "colorB" to 30,
                "light" to 80,
                "speed" to 5,
                "profile" to 2,
            ),
            successMap { GmacroCallbackBridge.fetchCurrentLightConfig(it).message(Constants.SUCCESS, rsp) },
        )
    }

    @Test
    fun linerTrigger_keepsThresholdDefaults() {
        val rsp = LinerTriggerRsp().apply {
            triggerLeft = 1
            triggerRight = 2
        }

        assertEquals(
            mapOf(
                "leftMode" to 1,
                "rightMode" to 2,
                "leftThreshold" to 0,
                "rightThreshold" to 0,
            ),
            successMap { GmacroCallbackBridge.queryLinerTrigger(it).message(Constants.SUCCESS, rsp) },
        )
    }

    @Test
    fun currentMapping_renamesMappingToMapped() {
        val mapping = MacroMapping().apply {
            original = 11
            mapping = 22
            type = 0
        }
        val rsp = MacroMappingKeyRsp().apply {
            macroMappings = listOf(mapping)
        }

        assertEquals(
            mapOf(
                "keyMappings" to listOf(
                    mapOf(
                        "original" to 11,
                        "mapped" to 22,
                        "type" to 0,
                    ),
                ),
            ),
            successMap { GmacroCallbackBridge.queryCurrentMapping(it).message(Constants.SUCCESS, rsp) },
        )
    }

    @Test
    fun rockerAndGyroCalibration_alwaysSucceed() {
        val rockerRsp = AlignRockerOrTriggerRsp().apply {
            subId = 2
            result = 1
            param1 = listOf(1, 2)
            param2 = listOf(3, 4)
        }
        val gyroRsp = AlignGyroscopeRsp().apply {
            subId = 1
            result = 0
            param = listOf(9)
        }

        assertEquals(
            mapOf(
                "subId" to 2,
                "result" to 1,
                "param1" to listOf(1, 2),
                "param2" to listOf(3, 4),
            ),
            successMap { GmacroCallbackBridge.endAlignRockerOrTrigger(it).message(99, rockerRsp) },
        )
        assertEquals(
            mapOf(
                "subId" to 1,
                "result" to 0,
                "param1" to listOf(9),
            ),
            successMap { GmacroCallbackBridge.endGyroCalibration(it).message(99, gyroRsp) },
        )
    }

    @Test
    fun protocolFailure_preservesFailedCodeAndDetails() {
        val rsp = QueryHandleInfoRsp().apply {
            projectCoding = "M6"
        }

        val result = capture { GmacroCallbackBridge.fetchDeviceVersion(it).message(7, rsp) }
        val error = assertIs<GmacroResult.Error>(result)
        assertEquals(GmacroResult.FAILED_CODE, error.code)
        assertEquals("GMacro method failed with code=7", error.message)
        val details = error.details as Map<*, *>
        assertEquals("M6", details["projectCoding"])
    }

    @Test
    fun deviceVersion_timeoutWithNullResponse_deliversProtocolError() {
        val result = capture {
            GmacroCallbackBridge.fetchDeviceVersion(it).message(Constants.TIMEOUT, null)
        }

        val error = assertIs<GmacroResult.Error>(result)
        assertEquals(GmacroResult.FAILED_CODE, error.code)
        assertEquals("GMacro method failed with code=${Constants.TIMEOUT}", error.message)
    }

    @Test
    fun protocolBackedCallbacks_timeoutWithNullResponse_deliverErrorsWithoutThrowing() {
        val callbacks: List<(((GmacroResult) -> Unit) -> Unit)> = listOf(
            { sink -> GmacroCallbackBridge.fetchPrintingType(sink).message(Constants.TIMEOUT, null) },
            { sink -> GmacroCallbackBridge.queryVibrateOpen(sink).message(Constants.TIMEOUT, null) },
            { sink -> GmacroCallbackBridge.queryCurrentMapping(sink).message(Constants.TIMEOUT, null) },
            { sink -> GmacroCallbackBridge.fetchCurrentLightConfig(sink).message(Constants.TIMEOUT, null) },
            { sink -> GmacroCallbackBridge.queryWorkStyle(sink).message(Constants.TIMEOUT, null) },
            { sink -> GmacroCallbackBridge.fetchCurrentProfile(sink).message(Constants.TIMEOUT, null) },
            { sink -> GmacroCallbackBridge.fetchGameMacroDefaultInfo(sink).message(Constants.TIMEOUT, null) },
            { sink -> GmacroCallbackBridge.queryLinerTrigger(sink).message(Constants.TIMEOUT, null) },
            { sink -> GmacroCallbackBridge.fetchAppWakeKeyType(sink).message(Constants.TIMEOUT, null) },
        )

        callbacks.forEach { callback ->
            val error = assertIs<GmacroResult.Error>(capture(callback))
            assertEquals(GmacroResult.FAILED_CODE, error.code)
            assertEquals("GMacro method failed with code=${Constants.TIMEOUT}", error.message)
        }
    }

    @Test
    fun dispatcher_forwardsSuccessFromBackend() {
        val backend = GmacroCommandBackend { method, arguments, callback ->
            assertEquals("fetchDeviceVersion", method)
            assertEquals(emptyMap(), arguments)
            callback(GmacroResult.Success(mapOf("project" to "M6")))
        }

        val result = capture { GmacroCommandDispatcher(backend).invoke("fetchDeviceVersion", emptyMap(), it) }
        assertEquals(GmacroResult.Success(mapOf("project" to "M6")), result)
    }

    @Test
    fun dispatcher_mapsThrownExceptionsToGmacroErrors() {
        val invalid = capture {
            GmacroCommandDispatcher { _, _, _ ->
                throw IllegalArgumentException("profile is required")
            }.invoke("fetchGameMacroDefaultInfo", emptyMap(), it)
        }
        val invalidError = assertIs<GmacroResult.Error>(invalid)
        assertEquals(GmacroResult.INVALID_ARGUMENTS, invalidError.code)
        assertEquals("profile is required", invalidError.message)

        val failed = capture {
            GmacroCommandDispatcher { _, _, _ ->
                throw IllegalStateException("sdk not ready")
            }.invoke("fetchDeviceVersion", emptyMap(), it)
        }
        val invocationError = assertIs<GmacroResult.Error>(failed)
        assertEquals(GmacroResult.INVOCATION_ERROR, invocationError.code)
        assertEquals("sdk not ready", invocationError.message)
    }

    @Test
    fun deliverTo_convertsResultForMethodChannelOnly() {
        val successResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        GmacroResult.Success(mapOf("isOn" to true)).deliverTo(successResult)
        Mockito.verify(successResult).success(mapOf("isOn" to true))

        val errorResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        GmacroResult.unsupported("unknownMethod").deliverTo(errorResult)
        Mockito.verify(errorResult).error(
            GmacroResult.UNSUPPORTED_METHOD,
            "Unsupported GMacro method on Android: unknownMethod",
            null,
        )
    }

    private fun successMap(block: ((GmacroResult) -> Unit) -> Unit): Map<*, *> {
        val payload = (capture(block) as GmacroResult.Success).payload
        return payload as Map<*, *>
    }

    private fun capture(block: ((GmacroResult) -> Unit) -> Unit): GmacroResult {
        var captured: GmacroResult? = null
        block { captured = it }
        return requireNotNull(captured) { "callback was not invoked" }
    }
}
