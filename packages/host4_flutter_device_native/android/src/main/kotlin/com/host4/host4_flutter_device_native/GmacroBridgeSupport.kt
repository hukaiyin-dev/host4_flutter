package com.host4.host4_flutter_device_native

import com.host4.platform.kr.response.AlignGyroscopeRsp
import com.host4.platform.kr.response.AlignRockerOrTriggerRsp
import com.host4.platform.kr.response.BaseRsp
import com.host4.platform.kr.response.LinerTriggerRsp
import com.host4.platform.kr.response.MacroHandleConfigRsp
import com.host4.platform.kr.response.MacroProfileRsp
import com.host4.platform.kr.response.QueryCurrentLightEffectRsp
import com.host4.platform.kr.response.QueryHandleInfoRsp
import com.host4.platform.kr.response.VibrateOpenRsp
import com.host4.platform.kr.response.WorkStyleRsp
import com.host4.platform.listener.OnMessageCallback
import com.host4.platform.util.Constants
import com.host4.platform.v2.api.FullPlatformSdk
import com.host4.platform.v2.api.PlatformSdkFactory
import com.host4.platform.v2.protocol.V2KrCmdController
import io.flutter.plugin.common.MethodChannel
import java.util.Collections.emptyMap

internal object GmacroSdkAccess {
    const val USB_DEVICE_KEY = "__usb__"

    private val fullSdk: FullPlatformSdk
        get() = PlatformSdkFactory.full()

    fun commands(deviceKey: String, transportKind: String): V2KrCmdController {
        return if (transportKind == Host4FlutterTransportKinds.USB) {
            fullSdk.usb().commands()
        } else {
            fullSdk.commands(deviceKey)
        }
    }
}

internal object Host4FlutterTransportKinds {
    const val BLE = "ble"
    const val USB = "usb"
}

internal object GmacroCallbackBridge {
    private val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())

    @Suppress("UNCHECKED_CAST")
    fun <T : BaseRsp> message(result: MethodChannel.Result): OnMessageCallback<T> {
        val callback = OnMessageCallback<BaseRsp> { code, rsp ->
            mainHandler.post { deliver(code, rsp, result) }
        }
        return callback as OnMessageCallback<T>
    }

    /**
     * 查询设备版本（0x80），与 iOS fetchDeviceVersion 返回字段对齐。
     */
    fun fetchDeviceVersion(result: MethodChannel.Result): OnMessageCallback<QueryHandleInfoRsp> {
        return OnMessageCallback { code, rsp ->
            mainHandler.post {
                if (code == Constants.SUCCESS || code == 80) {
                    result.success(
                        mapOf(
                            "project" to (rsp.projectCoding ?: ""),
                            "protocol" to (rsp.agreementVersion ?: ""),
                            "firmware" to (rsp.firmwareVersion ?: ""),
                            "hardware" to (rsp.hardwareVersion ?: ""),
                        ),
                    )
                } else {
                    result.error(
                        "gmacro-method-failed",
                        "GMacro method failed with code=$code",
                        GmacroResponseSerializer.toMap(rsp),
                    )
                }
            }
        }
    }

    /**
     * 结束摇杆板机校准
     */
    fun endAlignRockerOrTrigger(result: MethodChannel.Result): OnMessageCallback<AlignRockerOrTriggerRsp>{
        return OnMessageCallback { code, rsp ->
            mainHandler.post {
                result.success(
                    mapOf(
                        "subId" to (rsp.subId),
                        "result" to (rsp.result),
                        "param1" to (rsp.param1),
                        "param2" to (rsp.param2),
                    ),
                )
            }
        }
    }

    /**
     * 结束体感校准
     */
    fun endGyroCalibration(result: MethodChannel.Result): OnMessageCallback<AlignGyroscopeRsp>{
        return OnMessageCallback { code, rsp ->
            mainHandler.post {
                result.success(
                    mapOf(
                        "subId" to (rsp?.subId ?: 1),
                        "result" to (rsp?.result ?: 1),
                        "param1" to (rsp?.param ),
                    ),
                )
            }
        }
    }

    /**
     * 查询振动开关
     */
    fun queryVibrateOpen(result: MethodChannel.Result): OnMessageCallback<VibrateOpenRsp> {
        return OnMessageCallback{ code, rsp ->
            mainHandler.post {
                if (code == Constants.SUCCESS || code == 80) {
                    result.success(mapOf("isOn" to (rsp.status != 2)))
                } else {
                    result.error(
                        "gmacro-method-failed",
                        "GMacro method failed with code=$code",
                        GmacroResponseSerializer.toMap(rsp),
                    )
                }
            }
        }
    }

    /**
     * 查询当前灯效配置（0x71），与 iOS fetchCurrentLightConfig 返回结构对齐。
     */
    fun fetchCurrentLightConfig(result: MethodChannel.Result): OnMessageCallback<QueryCurrentLightEffectRsp> {
        return OnMessageCallback { code, rsp ->
            mainHandler.post {
                if (code == Constants.SUCCESS || code == 80) {
                    val effect = rsp.lightEffect
                    result.success(
                        mapOf(
                            "effect" to (effect?.effect ?: 0),
                            "colorR" to (effect?.colorR ?: 0),
                            "colorG" to (effect?.colorG ?: 0),
                            "colorB" to (effect?.colorB ?: 0),
                            "light" to (effect?.brightness ?: 0),
                            "speed" to (effect?.speed ?: 0),
                            "profile" to (effect?.profile ?: 0),
                        ),
                    )
                } else {
                    result.error(
                        "gmacro-method-failed",
                        "GMacro method failed with code=$code",
                        GmacroResponseSerializer.toMap(rsp),
                    )
                }
            }
        }
    }

    /**
     * 查询手柄工作模式（0x69），与 iOS fetchHandleWorkMode 返回结构对齐。
     */
    fun queryWorkStyle(result: MethodChannel.Result): OnMessageCallback<WorkStyleRsp> {
        return OnMessageCallback { code, rsp ->
            mainHandler.post {
                if (code == Constants.SUCCESS || code == 80) {
                    result.success(mapOf("mode" to rsp.mode))
                } else {
                    result.error(
                        "gmacro-method-failed",
                        "GMacro method failed with code=$code",
                        GmacroResponseSerializer.toMap(rsp),
                    )
                }
            }
        }
    }

    /**
     * 查询当前配置页
     */
    fun fetchCurrentProfile(result: MethodChannel.Result): OnMessageCallback<MacroProfileRsp> {
        return OnMessageCallback { code, rsp ->
            mainHandler.post {
                if (code == Constants.SUCCESS || code == 80) {
                    result.success(mapOf("profile" to rsp.mode))
                } else {
                    result.error(
                        "gmacro-method-failed",
                        "GMacro method failed with code=$code",
                        GmacroResponseSerializer.toMap(rsp),
                    )
                }
            }
        }
    }

    /**
     * 0x77 04 查询 Game Macro 默认值，与 Dart GmacroDefaultInfo 字段对齐。
     */
    fun fetchGameMacroDefaultInfo(result: MethodChannel.Result): OnMessageCallback<MacroHandleConfigRsp> {
        return OnMessageCallback { code, rsp ->
            mainHandler.post {
                if (code == Constants.SUCCESS || code == 80) {
                    result.success(GmacroDefaultInfoMapper.toMap(rsp))
                } else {
                    result.error(
                        "gmacro-method-failed",
                        "GMacro method failed with code=$code",
                        GmacroResponseSerializer.toMap(rsp),
                    )
                }
            }
        }
    }

    /**
     * 查询左右扳机线性输出
     * final leftMode
     * final leftThreshold
     * final rightThreshold
     */
    fun queryLinerTrigger(result: MethodChannel.Result): OnMessageCallback<LinerTriggerRsp> {
        return OnMessageCallback { code, rsp ->
            mainHandler.post {
                if (code == Constants.SUCCESS || code == 80) {
                    result.success(
                        mapOf(
                            "leftMode" to (rsp.triggerLeft),
                            "rightMode" to (rsp.triggerRight),
                            "leftThreshold" to 0,
                            "rightThreshold" to 0,
                        ),
                    )
                } else {
                    result.error(
                        "gmacro-method-failed",
                        "GMacro method failed with code=$code",
                        GmacroResponseSerializer.toMap(rsp),
                    )
                }
            }
        }
    }

    private fun deliver(code: Int, rsp: Any?, result: MethodChannel.Result) {
        if (code == Constants.SUCCESS || code == 80) {
            result.success(GmacroResponseSerializer.toMap(rsp))
        } else {
            result.error(
                "gmacro-method-failed",
                "GMacro method failed with code=$code",
                GmacroResponseSerializer.toMap(rsp),
            )
        }
    }
}

private object GmacroDefaultInfoMapper {
    fun toMap(rsp: MacroHandleConfigRsp): Map<String, Any?> {
        val trigger = rsp.macroTrigger
        val rocker = rsp.macroRocker
        val vibration = rsp.macroVibrate
        val motion = rsp.macroKinect

        return mapOf(
            "rapidList" to rsp.torrents.orEmpty().map {
                mapOf(
                    "key" to it.code,
                    "turbo" to it.mode,
                    "speed" to it.speed,
                )
            },
            "leftTrigger" to mapOf(
                "start" to (trigger?.startLeft ?: 0),
                "end" to (trigger?.terminationLeft ?: 0),
                "pointCount" to (trigger?.pointCountLeft ?: 0),
                "points" to points(trigger?.leftPointList),
                "fastTrigger" to (trigger?.isMacroSwitchLeft ?: false),
            ),
            "rightTrigger" to mapOf(
                "start" to (trigger?.startRight ?: 0),
                "end" to (trigger?.terminationRight ?: 0),
                "pointCount" to (trigger?.pointCountRight ?: 0),
                "points" to points(trigger?.rightPointList),
                "fastTrigger" to (trigger?.isMacroSwitchRight ?: false),
            ),
            "leftStick" to mapOf(
                "deadzoneComp" to (rocker?.deathZoneLeft ?: 0),
                "returnComp" to (rocker?.maxOutLeft ?: 0),
                "start" to (rocker?.x_startLeft ?: 0),
                "end" to (rocker?.x_terminationLeft ?: 0),
                "reverseX" to (rocker?.isX_isExchangeLeft ?: false),
                "reverseY" to (rocker?.isY_isExchangeLeft ?: false),
                "triggerMode" to (rocker?.curveApplyLeft ?: 0),
                "triggerKey" to (rocker?.curveKeyLeft ?: 0),
                "outputGraphic" to if (rocker?.isLineCorrectionLeft == true) 1 else 0,
                "pointCount" to (rocker?.pointCountLeft ?: 0),
                "points" to points(rocker?.leftPointList),
            ),
            "rightStick" to mapOf(
                "deadzoneComp" to (rocker?.deathZoneRight ?: 0),
                "returnComp" to (rocker?.maxOutRight ?: 0),
                "start" to (rocker?.x_startRight ?: 0),
                "end" to (rocker?.x_terminationRight ?: 0),
                "reverseX" to (rocker?.isX_isExchangeRight ?: false),
                "reverseY" to (rocker?.isY_isExchangeRight ?: false),
                "triggerMode" to (rocker?.curveApplyRight ?: 0),
                "triggerKey" to (rocker?.curveKeyRight ?: 0),
                "outputGraphic" to if (rocker?.isLineCorrectionRight == true) 1 else 0,
                "pointCount" to (rocker?.pointCountRight ?: 0),
                "points" to points(rocker?.rightPointList),
            ),
            "vibration" to mapOf(
                "left" to (vibration?.vibrationLeft ?: 0),
                "right" to (vibration?.vibrationRight ?: 0),
            ),
            "motion" to mapOf(
                "enabled" to (motion?.isMotionSwitch ?: false),
                "mappingEnabled" to (motion?.isMotionMapperSwitch ?: false),
                "triggerMode" to (motion?.motionMethod ?: 0),
                "triggerKey" to (motion?.motionKey ?: 0),
                "deadzone" to (motion?.motionDeathZone ?: 0),
                "sensitivity" to (motion?.motionSensitivity ?: 0),
                "mappingMode" to (motion?.motionMapperModel ?: 0),
                "axis" to 0,
                "reverseX" to false,
                "reverseY" to (motion?.isMotionYaxisSwitch ?: false),
                "deadzoneComp" to 0,
                "curve" to emptyList<Map<String, Int>>(),
                "secondaryEnabled" to false,
                "secondaryTriggerMode" to 0,
                "secondaryTriggerKey" to 0,
                "secondarySensitivity" to 0,
            ),
        )
    }

    private fun points(points: List<com.host4.platform.kr.model.MacroPoint>?): List<Map<String, Int>> {
        return points.orEmpty().map {
            mapOf(
                "x" to it.x_axis,
                "y" to it.y_axis,
            )
        }
    }
}

internal object GmacroArgParser {
    fun intArg(arguments: Map<String, Any?>, key: String): Int {
        val value = arguments[key] ?: throw IllegalArgumentException("Missing required argument: $key")
        return when (value) {
            is Int -> value
            is Number -> value.toInt()
            is String -> value.toInt()
            else -> throw IllegalArgumentException("Invalid int argument '$key': $value")
        }
    }

    fun intArg(arguments: Map<String, Any?>, key: String, fallback: Int): Int {
        return if (arguments.containsKey(key)) intArg(arguments, key) else fallback
    }

    fun longArg(arguments: Map<String, Any?>, key: String): Long {
        val value = arguments[key] ?: throw IllegalArgumentException("Missing required argument: $key")
        return when (value) {
            is Long -> value
            is Number -> value.toLong()
            is String -> value.toLong()
            else -> throw IllegalArgumentException("Invalid long argument '$key': $value")
        }
    }

    fun boolArg(arguments: Map<String, Any?>, key: String): Boolean {
        val value = arguments[key] ?: throw IllegalArgumentException("Missing required argument: $key")
        return when (value) {
            is Boolean -> value
            is Int -> value != 0
            is Number -> value.toInt() != 0
            is String -> value.equals("true", ignoreCase = true) || value == "1"
            else -> throw IllegalArgumentException("Invalid bool argument '$key': $value")
        }
    }

    fun mapList(arguments: Map<String, Any?>, key: String): List<Map<String, Any?>> {
        @Suppress("UNCHECKED_CAST")
        val raw = arguments[key] as? List<*> ?: throw IllegalArgumentException("Missing list argument: $key")
        return raw.map { item ->
            (item as? Map<String, Any?>) ?: throw IllegalArgumentException("Invalid map entry in '$key': $item")
        }
    }

    fun intList(arguments: Map<String, Any?>, key: String): List<Int> {
        @Suppress("UNCHECKED_CAST")
        val raw = arguments[key] as? List<*> ?: throw IllegalArgumentException("Missing list argument: $key")
        return raw.map { intValue(it, key) }
    }

    fun intValue(value: Any?, key: String = "value"): Int {
        return when (value) {
            is Int -> value
            is Number -> value.toInt()
            is String -> value.toInt()
            else -> throw IllegalArgumentException("Invalid int value for '$key': $value")
        }
    }

    fun boolValue(value: Any?, key: String = "value"): Boolean {
        return when (value) {
            is Boolean -> value
            is Int -> value != 0
            is Number -> value.toInt() != 0
            is String -> value.equals("true", ignoreCase = true) || value == "1"
            else -> throw IllegalArgumentException("Invalid bool value for '$key': $value")
        }
    }
}

internal object GmacroModelFactory {
    fun macroPoints(points: List<Map<String, Any?>>): List<com.host4.platform.kr.model.MacroPoint> {
        return points.map { point ->
            com.host4.platform.kr.model.MacroPoint().apply {
                val x = if (point.containsKey("x")) {
                    GmacroArgParser.intArg(point, "x")
                } else {
                    GmacroArgParser.intArg(point, "x_axis")
                }
                val y = if (point.containsKey("y")) {
                    GmacroArgParser.intArg(point, "y")
                } else {
                    GmacroArgParser.intArg(point, "y_axis")
                }
                setX_axis(x)
                setY_axis(y)
            }
        }
    }

    fun macroRockerLinear(arguments: Map<String, Any?>): com.host4.platform.kr.model.MacroRockerLinear {
        return com.host4.platform.kr.model.MacroRockerLinear().apply {
            setLeftMin(GmacroArgParser.intArg(arguments, "leftMin"))
            setLeftMax(GmacroArgParser.intArg(arguments, "leftMax"))
            setRightMin(GmacroArgParser.intArg(arguments, "rightMin"))
            setRightMax(GmacroArgParser.intArg(arguments, "rightMax"))
            setExchangeLx(GmacroArgParser.boolArg(arguments, "leftXFlip"))
            setExchangeLy(GmacroArgParser.boolArg(arguments, "leftYFlip"))
            setExchangeRx(GmacroArgParser.boolArg(arguments, "rightXFlip"))
            setExchangeRy(GmacroArgParser.boolArg(arguments, "rightYFlip"))
        }
    }

    fun rockerParam(arguments: Map<String, Any?>): com.host4.platform.kr.model.RockerParam {
        return com.host4.platform.kr.model.RockerParam().apply {
            setShapeDeadZoneLeft(GmacroArgParser.intArg(arguments, "leftDeadZone"))
            setMaxOutLeft(GmacroArgParser.intArg(arguments, "leftOutMax"))
            setCurveApplyLeft(GmacroArgParser.intArg(arguments, "leftCurveApply"))
            setCurveKeyLeft(GmacroArgParser.intArg(arguments, "leftCurveApplyKey"))
            setLineCorrectionLeft(GmacroArgParser.intArg(arguments, "leftLineCorrection") != 0)
            setShapeDeadZoneRight(GmacroArgParser.intArg(arguments, "rightDeadZone"))
            setMaxOutRight(GmacroArgParser.intArg(arguments, "rightOutMax"))
            setCurveApplyRight(GmacroArgParser.intArg(arguments, "rightCurveApply"))
            setCurveKeyRight(GmacroArgParser.intArg(arguments, "rightCurveApplyKey"))
            setLineCorrectionRight(GmacroArgParser.intArg(arguments, "rightLineCorrection") != 0)
        }
    }

    fun macroKinect(arguments: Map<String, Any?>): com.host4.platform.kr.model.MacroKinect {
        return com.host4.platform.kr.model.MacroKinect().apply {
            setMotionSwitch(GmacroArgParser.boolArg(arguments, "motionEnabled"))
            setMotionMapperSwitch(GmacroArgParser.boolArg(arguments, "mappingEnabled"))
            setMotionMethod(GmacroArgParser.intArg(arguments, "triggerMode"))
            setMotionKey(GmacroArgParser.intArg(arguments, "triggerKey"))
            setMotionDeathZone(GmacroArgParser.intArg(arguments, "deadZone"))
            setMotionSensitivity(GmacroArgParser.intArg(arguments, "sensitivity"))
            setMotionMapperModel(GmacroArgParser.intArg(arguments, "mappingMode"))
        }
    }

    fun lightColors(arguments: Map<String, Any?>, key: String = "colors"): Triple<Int, Int, Int> {
        val colors = GmacroArgParser.mapList(arguments, key)
        val first = colors.firstOrNull() ?: emptyMap()
        val red = GmacroArgParser.intArg(first, "red", GmacroArgParser.intArg(first, "colorR", 0))
        val green = GmacroArgParser.intArg(first, "green", GmacroArgParser.intArg(first, "colorG", 0))
        val blue = GmacroArgParser.intArg(first, "blue", GmacroArgParser.intArg(first, "colorB", 0))
        return Triple(red, green, blue)
    }
}

internal object GmacroResponseSerializer {
    fun toMap(value: Any?): Map<String, Any?> {
        if (value == null) {
            return emptyMap()
        }

        val serialized = serializeValue(value)
        return when (serialized) {
            is Map<*, *> -> {
                @Suppress("UNCHECKED_CAST")
                serialized as Map<String, Any?>
            }
            else -> mapOf("value" to serialized)
        }
    }

    private fun serializeValue(value: Any?): Any? {
        return when (value) {
            null -> null
            is String, is Int, is Long, is Short, is Byte, is Double, is Float, is Boolean -> value
            is ByteArray -> value.map { it.toInt() and 0xFF }
            is IntArray -> value.toList()
            is LongArray -> value.toList()
            is Array<*> -> value.map { serializeValue(it) }
            is List<*> -> value.map { serializeValue(it) }
            is Map<*, *> -> value.entries.associate { (k, v) -> k.toString() to serializeValue(v) }
            else -> beanToMap(value)
        }
    }

    private fun beanToMap(value: Any): Map<String, Any?> {
        val result = linkedMapOf<String, Any?>()
        for (method in value.javaClass.methods) {
            if (method.declaringClass == Any::class.java || method.parameterCount != 0) {
                continue
            }

            val propertyName = when {
                method.name.startsWith("get") && method.name.length > 3 ->
                    method.name.substring(3).replaceFirstChar { it.lowercase() }

                method.name.startsWith("is") && method.name.length > 2 &&
                    (method.returnType == Boolean::class.java || method.returnType == java.lang.Boolean.TYPE) ->
                    method.name.substring(2).replaceFirstChar { it.lowercase() }

                else -> continue
            }

            if (propertyName == "class") {
                continue
            }

            runCatching {
                result[propertyName] = serializeValue(method.invoke(value))
            }
        }
        return result
    }
}
