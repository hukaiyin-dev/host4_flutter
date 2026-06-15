package com.host4.host4_flutter_device_native

import Host4FlutterGmacroConstants
import io.flutter.plugin.common.MethodChannel

internal object GmacroMethodInvoker {
    private const val MODE_NORMAL = 0x04
    private const val MODE_TEST = 0x02
    private const val MODE_MACRO = 0x10

    private const val CALIB_ROCKER_SUB_ID = 0x02
    private const val CALIB_TRIGGER_SUB_ID = 0x03
    private const val CALIB_GYRO_SUB_ID = 0x01

    private const val SIDE_LEFT = 0
    private const val SIDE_RIGHT = 1

    fun invoke(
        deviceKey: String,
        transportKind: String,
        method: String,
        arguments: Map<String, Any?>,
        result: MethodChannel.Result,
    ) {
        val commands = GmacroSdkAccess.commands(deviceKey, transportKind)

        try {
            when (method) {
                //手柄信息
                Host4FlutterGmacroConstants.fetchDeviceVersion ->
                    KrDeviceInfoQuery.query(deviceKey, transportKind, result)

                Host4FlutterGmacroConstants.fetchMobapadDeviceInfo -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    //commands.queryMacroConfigInfoReq(profile, GmacroCallbackBridge.message(result))
                }

                //恢复出厂
                Host4FlutterGmacroConstants.resetDevice -> commands.resetKeyBoard(GmacroCallbackBridge.message(result))

                //切换模式
                Host4FlutterGmacroConstants.switchToNormalMode -> commands.setKeyBoardMode(MODE_NORMAL, GmacroCallbackBridge.message(result))
                Host4FlutterGmacroConstants.switchToTestMode -> commands.setKeyBoardMode(MODE_TEST, GmacroCallbackBridge.message(result))
                Host4FlutterGmacroConstants.switchToConfigMode -> commands.setKeyBoardMode(MODE_MACRO, GmacroCallbackBridge.message(result))

                //查询上报率
                Host4FlutterGmacroConstants.fetchReportRate -> commands.QueryRateOfReturn(GmacroCallbackBridge.message(result))
                //设置上报率
                Host4FlutterGmacroConstants.updateReportRate -> {
                    val rate = GmacroArgParser.intArg(arguments, "rate")
                    commands.setRateOfReturn(rate, GmacroCallbackBridge.message(result))
                }

                //查询充电底座启停开关
                Host4FlutterGmacroConstants.fetchChargingDock -> commands.queryChargingDock(GmacroCallbackBridge.message(result))
                //设置充电底座启停开关
                Host4FlutterGmacroConstants.updateChargingDock -> {
                    val isOn = GmacroArgParser.boolArg(arguments, "isOn")
                    commands.setChargingDock(if (isOn) 1 else 2, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.fetchLight -> commands.queryCurrentLightingEffect(GmacroCallbackBridge.message(result))
                Host4FlutterGmacroConstants.fetchLightPosition -> commands.queryLightingPositionGroup(GmacroCallbackBridge.message(result))
                Host4FlutterGmacroConstants.fetchSupportedLightEffects -> commands.queryLightingPositionEffect(GmacroCallbackBridge.message(result))
                Host4FlutterGmacroConstants.fetchCurrentLightEffect -> commands.queryCurrentLightEffect(GmacroCallbackBridge.message(result))

                //查询等效 0x71
                Host4FlutterGmacroConstants.fetchCurrentLightConfig -> commands.queryCurrentLightEffect(GmacroCallbackBridge.message(result))

                //设置灯光 0x72
                Host4FlutterGmacroConstants.setLightConfig -> {
                    commands.setLightEffect(
                        GmacroArgParser.intArg(arguments, "effect"),
                        GmacroArgParser.intArg(arguments, "light"),
                        GmacroArgParser.intArg(arguments, "speed"),
                        GmacroArgParser.intArg(arguments, "profile"),
                        GmacroArgParser.intArg(arguments, "colorR"),
                        GmacroArgParser.intArg(arguments, "colorG"),
                        GmacroArgParser.intArg(arguments, "colorB"),
                        GmacroCallbackBridge.message(result),
                    )
                }

                Host4FlutterGmacroConstants.setLightColor -> {
                    val position = GmacroArgParser.intArg(arguments, "position")
                    val groupCount = GmacroArgParser.intArg(arguments, "groupCount")
                    val (red, green, blue) = GmacroModelFactory.lightColors(arguments)
                    commands.setLightGroupColor(
                        position,
                        groupCount,
                        red,
                        green,
                        blue,
                        groupCount,
                        GmacroCallbackBridge.message(result),
                    )
                }

                Host4FlutterGmacroConstants.setLightEffect -> {
                    commands.setLightGroupEffect(
                        GmacroArgParser.intArg(arguments, "position"),
                        GmacroArgParser.intArg(arguments, "groupCount"),
                        if (GmacroArgParser.boolArg(arguments, "isOn")) 1 else 0,
                        GmacroArgParser.intArg(arguments, "light"),
                        GmacroArgParser.intArg(arguments, "speed"),
                        GmacroArgParser.intArg(arguments, "mode"),
                        GmacroArgParser.intArg(arguments, "subMode"),
                        GmacroCallbackBridge.message(result),
                    )
                }

                Host4FlutterGmacroConstants.trigger -> commands.setMacroTrigger(
                    GmacroArgParser.intArg(arguments, "leftMin"),
                    GmacroArgParser.intArg(arguments, "leftMax"),
                    GmacroArgParser.intArg(arguments, "rightMin"),
                    GmacroArgParser.intArg(arguments, "rightMax"),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.leftTriggerCurve -> {
                    val points = GmacroModelFactory.macroPoints(GmacroArgParser.mapList(arguments, "cgPoints"))
                    commands.setMacroTriggerPointReq(SIDE_LEFT, points.size, points, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.rightTriggerCurve -> {
                    val points = GmacroModelFactory.macroPoints(GmacroArgParser.mapList(arguments, "cgPoints"))
                    commands.setMacroTriggerPointReq(SIDE_RIGHT, points.size, points, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.triggerQuickSwitch -> commands.SetQuickTriggerSwitchReq(
                    if (GmacroArgParser.boolArg(arguments, "leftOn")) 1 else 2,
                    if (GmacroArgParser.boolArg(arguments, "rightOn")) 1 else 2,
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.getTriggerQuickSwitch -> commands.queryQuickTriggerSwitch(GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.startTriggerCalibration -> commands.beginAlignRockerOrTrigger(CALIB_TRIGGER_SUB_ID, 0, GmacroCallbackBridge.message(result))
                Host4FlutterGmacroConstants.endTriggerCalibration -> commands.endAlignRockerOrTrigger(CALIB_TRIGGER_SUB_ID, 0, GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.triggerLinearOutput -> commands.setTriggerCurveType(
                    GmacroArgParser.intArg(arguments, "leftMode"),
                    GmacroArgParser.intArg(arguments, "leftThreshold"),
                    GmacroArgParser.intArg(arguments, "rightMode"),
                    GmacroArgParser.intArg(arguments, "rightThreshold"),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.updateTriggerTestVibrationSwitch -> commands.setTriggerTestVibration(
                    if (GmacroArgParser.boolArg(arguments, "triggerTestVibration")) 1 else 0,
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.fetchTriggerTestVibrationSwitch -> commands.queryTriggerTestVibration(GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.updateTriggerVibration -> commands.setTriggerVibration(
                    if (GmacroArgParser.boolArg(arguments, "triggerVibration")) 1 else 0,
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.fetchTriggerVibration -> commands.queryTriggerVibration(GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.updateRockerLinear -> commands.setMacroRockerLinear(
                    GmacroModelFactory.macroRockerLinear(arguments),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.updateLeftRocker3DCurve -> {
                    val points = GmacroModelFactory.macroPoints(GmacroArgParser.mapList(arguments, "cgPoints"))
                    commands.setMacroRockerPointReq(SIDE_LEFT, points.size, points, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.updateRightRocker3DCurve -> {
                    val points = GmacroModelFactory.macroPoints(GmacroArgParser.mapList(arguments, "cgPoints"))
                    commands.setMacroRockerPointReq(SIDE_RIGHT, points.size, points, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.rockerDeadZoneCompensation -> commands.setRockerDeadCompensate(
                    GmacroArgParser.intArg(arguments, "left"),
                    GmacroArgParser.intArg(arguments, "right"),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.rockerDeadZoneRegressionComp -> commands.setRockerDeadBackCompensate(
                    GmacroArgParser.intArg(arguments, "left"),
                    GmacroArgParser.intArg(arguments, "right"),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.rockerTriggerType -> commands.setRockerMethodAndKey(
                    GmacroArgParser.intArg(arguments, "leftRigger"),
                    GmacroArgParser.intArg(arguments, "leftGamepadKey"),
                    GmacroArgParser.intArg(arguments, "rightRigger"),
                    GmacroArgParser.intArg(arguments, "rightGamepadKey"),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.rockerOutputGraphics -> commands.setRockerOutputTrajectory(
                    GmacroArgParser.intArg(arguments, "left"),
                    GmacroArgParser.intArg(arguments, "right"),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.startRockerCalibration -> commands.beginAlignRockerOrTrigger(CALIB_ROCKER_SUB_ID,0 , GmacroCallbackBridge.message(result))
                Host4FlutterGmacroConstants.endRockerCalibration -> commands.endAlignRockerOrTrigger(CALIB_ROCKER_SUB_ID, 0, GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.updateRockerAdditional -> commands.setRockerAdditionalReq(
                    GmacroModelFactory.rockerParam(arguments),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.queryCurrentMacro -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.startMacroProfileReq(profile, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.queryMacroKeys -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryMacroKeyReq(profile, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.queryMacroRecordableKeys -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryRecordSupportReq(profile, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.queryMacroTimeRange -> commands.queryHandleTimeReq(GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.queryMacroMaxGroups -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryMacroSubReq(profile, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.setMacroKeys -> {
                    @Suppress("UNCHECKED_CAST")
                    val macroKey = arguments["macroKey"] as? Map<String, Any?>
                        ?: throw IllegalArgumentException("Missing macroKey argument.")
                    val comKeys = GmacroArgParser.mapList(macroKey, "comKeys")
                    val firstComKey = comKeys.firstOrNull() ?: emptyMap()
                    val keys = GmacroArgParser.intList(firstComKey, "keys").toIntArray()
                    commands.setMacroSubKeys(
                        GmacroArgParser.intArg(macroKey, "value"),
                        GmacroArgParser.intArg(macroKey, "cycle"),
                        GmacroArgParser.intArg(macroKey, "intervalTime"),
                        comKeys.size,
                        GmacroArgParser.intArg(firstComKey, "keepTime", 100),
                        keys,
                        GmacroCallbackBridge.message(result),
                    )
                }

                Host4FlutterGmacroConstants.setMacroInterval -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    val key = GmacroArgParser.intArg(arguments, "key")
                    val intervalTime = GmacroArgParser.intArg(arguments, "intervalTime")
                    commands.setMacroCycleTimeReq(profile, key, intervalTime, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.startRecord -> commands.setRecordMacroStart(GmacroCallbackBridge.message(result))
                Host4FlutterGmacroConstants.endRecord -> commands.setRecordMacroStop(true, GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.queryGyroTriggerKeys -> commands.QueryKinectTriggerSupport(GmacroCallbackBridge.message(result))
                Host4FlutterGmacroConstants.queryGyroMappingModes -> commands.QueryKinectMappingModeReq(GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.setMotion -> commands.setKinectConfigReq(
                    GmacroModelFactory.macroKinect(arguments),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.setMotionSecondary -> commands.SetMotionSecondarySensitivity(
                    if (GmacroArgParser.boolArg(arguments, "isOn")) 1 else 0,
                    GmacroArgParser.intArg(arguments, "triggerMode"),
                    GmacroArgParser.intArg(arguments, "triggerKey"),
                    GmacroArgParser.intArg(arguments, "sensitivity"),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.setMotionHorizontalAxis -> commands.setMotionHorizontalAxial(
                    GmacroArgParser.intArg(arguments, "axis"),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.fetchMotionHorizontalAxis -> commands.queryMotionHorizontalAxial(GmacroCallbackBridge.message(result))
                Host4FlutterGmacroConstants.fetchGyroDeadZoneComp -> commands.queryHandleConfig(0, GmacroCallbackBridge.message(result))
                Host4FlutterGmacroConstants.fetchGyroSensitivityCurve -> commands.queryHandleConfig(0, GmacroCallbackBridge.message(result))
                Host4FlutterGmacroConstants.fetchGyroSensitivity2 -> commands.queryHandleConfig(0, GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.setGyroXYInvert -> commands.SetMotionXYReversal(
                    if (GmacroArgParser.boolArg(arguments, "xOn")) 2 else 1,
                    if (GmacroArgParser.boolArg(arguments, "yOn")) 2 else 1,
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.fetchGyroXYInvert -> commands.queryHandleConfig(0, GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.setGyroDeadZone -> commands.SetMotionDeadZoneCompensate(
                    GmacroArgParser.intArg(arguments, "compensate"),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.setGyroSensitivityCurve -> {
                    val points = GmacroModelFactory.macroPoints(
                        listOf(
                            mapOf(
                                "x" to GmacroArgParser.intArg(arguments, "x1"),
                                "y" to GmacroArgParser.intArg(arguments, "y1"),
                            ),
                            mapOf(
                                "x" to GmacroArgParser.intArg(arguments, "x2"),
                                "y" to GmacroArgParser.intArg(arguments, "y2"),
                            ),
                            mapOf(
                                "x" to GmacroArgParser.intArg(arguments, "x3"),
                                "y" to GmacroArgParser.intArg(arguments, "y3"),
                            ),
                        ),
                    )
                    commands.setMotionPointReq(points, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.updateGyroOuterDeadZone -> commands.setMotionOuterDeadZone(
                    GmacroArgParser.intArg(arguments, "gyroOuterDeadZone"),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.fetchGyroOuterDeadZone -> commands.queryMotionOuterDeadZone(GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.startGyroCalibration -> commands.beginAlignGyroscope(CALIB_GYRO_SUB_ID, 0, GmacroCallbackBridge.message(result))
                Host4FlutterGmacroConstants.endGyroCalibration -> commands.endAlignGyroscope(CALIB_GYRO_SUB_ID, 0, GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.updateGyroXYRatio -> commands.setMotionXYAxisRatio(
                    GmacroArgParser.intArg(arguments, "gyroXYRatio"),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.fetchGyroXYRatio -> commands.queryMotionXYAxisRatio(GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.updateGyroMappingType -> commands.setMotionMappingType(
                    GmacroArgParser.intArg(arguments, "gyroMappingType"),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.fetchGyroMappingType -> commands.queryMotionMappingType(GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.queryMappableKeys -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryMapperSupportReq(profile, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.queryMappableGamepadKeys -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryMapperSettingReq(profile, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.setKeyMappings -> {
                    val mappings = GmacroArgParser.mapList(arguments, "keyMappings")
                    val first = mappings.firstOrNull()
                        ?: throw IllegalArgumentException("keyMappings must not be empty.")
                    commands.setMacroKeyMapping(
                        GmacroArgParser.intArg(first, "original"),
                        GmacroArgParser.intArg(first, "mapped"),
                        GmacroCallbackBridge.message(result),
                    )
                }

                Host4FlutterGmacroConstants.setMouseKeyMappings -> {
                    val mappings = GmacroArgParser.mapList(arguments, "keyMappings")
                    val first = mappings.firstOrNull()
                        ?: throw IllegalArgumentException("keyMappings must not be empty.")
                    commands.setMacroKeyMouse(
                        GmacroArgParser.intArg(first, "original"),
                        GmacroArgParser.intArg(first, "mapped"),
                        GmacroCallbackBridge.message(result),
                    )
                }

                Host4FlutterGmacroConstants.setKeyboardKeyMappings -> {
                    val mappings = GmacroArgParser.mapList(arguments, "keyMappings")
                    val first = mappings.firstOrNull()
                        ?: throw IllegalArgumentException("keyMappings must not be empty.")
                    commands.setMacroKeyKeyboard(
                        GmacroArgParser.intArg(first, "original"),
                        GmacroArgParser.intArg(first, "mapped"),
                        GmacroCallbackBridge.message(result),
                    )
                }

                Host4FlutterGmacroConstants.queryCurrentMapping -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryMappingKeyReq(profile, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.setMultiKeyMapping -> {
                    val mapping = com.host4.platform.kr.model.MultiKeyMapping().apply {
                        setOriginalKey(GmacroArgParser.intArg(arguments, "original"))
                        setTypeNum(GmacroArgParser.mapList(arguments, "mappedKeys").size)
                    }
                    commands.setMultiKeyMapping(mapping, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.queryAllMultiMappings -> commands.queryAllMultiMappingKey(GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.queryMultiMapping -> commands.queryMultiMappingByKey(
                    GmacroArgParser.intArg(arguments, "original"),
                    GmacroCallbackBridge.message(result),
                )

                Host4FlutterGmacroConstants.getSleepTime -> commands.querySleepTime(GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.setSleepTime -> commands.setSleepTimeReq(
                    GmacroArgParser.intArg(arguments, "time"),
                    GmacroCallbackBridge.message(result),
                )

                //设置振动
                Host4FlutterGmacroConstants.setVibrationLevel -> commands.setVibrationLevel(
                    GmacroArgParser.intArg(arguments, "left"),
                    GmacroArgParser.intArg(arguments, "right"),
                    GmacroCallbackBridge.message(result),
                )

                //测试振动
                Host4FlutterGmacroConstants.testVibration -> {
                    val left = GmacroArgParser.intArg(arguments, "left")
                    val right = GmacroArgParser.intArg(arguments, "right")
                    val position = GmacroArgParser.intArg(arguments, "position")
                    val relLeft = (2.55f * left).toInt()
                    val relRight = (2.55f * right).toInt()
                    commands.forceVibrationTest(
                        relLeft,
                        relRight,
                        position,
                        GmacroCallbackBridge.message(result),
                    )
                }

                Host4FlutterGmacroConstants.setTurboDatas -> {
                    val turbos = GmacroArgParser.mapList(arguments, "keyTurbos")
                    val first = turbos.firstOrNull()
                        ?: throw IllegalArgumentException("keyTurbos must not be empty.")
                    commands.setMacroBurstRate(
                        GmacroArgParser.intArg(first, "key"),
                        GmacroArgParser.intArg(first, "turbo"),
                        GmacroArgParser.intArg(first, "speed"),
                        GmacroCallbackBridge.message(result),
                    )
                }

                Host4FlutterGmacroConstants.querySupportedTurboKeys -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryBurstSupportReq(profile, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.switchVibrateOpen -> {
                    val status = GmacroArgParser.intArg(arguments, "status")
                    commands.switchVibrateOpen(status, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.queryVibrateOpen ->
                    commands.queryVibrateOpen(GmacroCallbackBridge.queryVibrateOpen(result))

                Host4FlutterGmacroConstants.switchWorkStyle -> {
                    val mode = GmacroArgParser.intArg(arguments, "mode")
                    commands.switchWorkStyle(mode, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.queryWorkStyle ->
                    commands.queryWorkStyle(GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.switchOutputMode -> {
                    val mode = GmacroArgParser.intArg(arguments, "mode")
                    commands.switchOutputMode(mode, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.queryOutputMode ->
                    commands.queryOutputMode(GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.sendHandleBeta -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.sendHandleBeta(profile, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.switchHandleConfig -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.switchHandleConfig(profile, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.switchHandleCallbacks -> {
                    val method = GmacroArgParser.intArg(arguments, "method")
                    commands.switchHandleCallbacks(method, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.queryLinerTrigger ->
                    commands.queryLinerTrigger(GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.switchLinerTrigger -> {
                    val mode = GmacroArgParser.intArg(arguments, "mode")
                    commands.switchLinerTrigger(mode, GmacroCallbackBridge.message(result))
                }

                Host4FlutterGmacroConstants.queryLightingEffectPantas ->
                    commands.queryLightingEffectPantas(GmacroCallbackBridge.message(result))

                Host4FlutterGmacroConstants.setLightGroupEffectPantas -> {
                    commands.setLightGroupEffectPantas(
                        GmacroArgParser.boolArg(arguments, "open"),
                        GmacroArgParser.intArg(arguments, "mode"),
                        GmacroArgParser.intArg(arguments, "brightness"),
                        GmacroArgParser.intArg(arguments, "colorR"),
                        GmacroArgParser.intArg(arguments, "colorG"),
                        GmacroArgParser.intArg(arguments, "colorB"),
                        GmacroCallbackBridge.message(result),
                    )
                }

                else -> {
                    result.error(
                        "unsupported-gmacro-method",
                        "Unsupported GMacro method on Android: $method",
                        null,
                    )
                }
            }
        } catch (error: IllegalArgumentException) {
            result.error("invalid-arguments", error.message, null)
        } catch (error: Exception) {
            result.error(
                "gmacro-invocation-error",
                error.message ?: "Failed to invoke GMacro method '$method'.",
                null,
            )
        }
    }
}
