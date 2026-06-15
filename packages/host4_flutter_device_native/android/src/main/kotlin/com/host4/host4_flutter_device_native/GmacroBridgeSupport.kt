package com.host4.host4_flutter_device_native

import com.host4.platform.kr.response.BaseRsp
import com.host4.platform.kr.response.LinerTriggerRsp
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
