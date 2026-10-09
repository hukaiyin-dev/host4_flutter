package com.host4.host4_flutter_device_native

import Host4FlutterGmacroConstants

internal object GmacroMethodInvoker {
    private const val MODE_NORMAL = 0x04
    private const val MODE_TEST = 0x02
    private const val MODE_MACRO = 0x10
    private const val MODE_SETTING = 0x01
    private const val MODE_TOUCH_MAPPING = 0x00

    private const val CALIB_ROCKER_SUB_ID = 0x02
    private const val CALIB_TRIGGER_SUB_ID = 0x03
    private const val CALIB_GYRO_SUB_ID = 0x01

    private const val SIDE_LEFT = 13
    private const val SIDE_RIGHT = 14
    private const val TRIGGER_LEFT = 3
    private const val TRIGGER_RIGHT = 4

    fun invoke(
        deviceKey: String,
        transportKind: String,
        method: String,
        arguments: Map<String, Any?>,
        onResult: (GmacroResult) -> Unit,
    ) {
        val commands = GmacroSdkAccess.commands(deviceKey, transportKind)

        try {
            when (method) {
                //手柄信息
                Host4FlutterGmacroConstants.fetchDeviceVersion ->{
                    commands.queryDeviceInfo(GmacroCallbackBridge.fetchDeviceVersion(onResult))
                }

                //查询长按按键类型
                Host4FlutterGmacroConstants.fetchAppWakeKeyType-> {
                    commands.fetchAppWakeKeyType(GmacroCallbackBridge.fetchAppWakeKeyType(onResult))
                }

                // 0x77 04 查询 Game Macro 默认值
                Host4FlutterGmacroConstants.fetchGameMacroDefaultInfo -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryMacroHandle(
                        profile,
                        GmacroCallbackBridge.fetchGameMacroDefaultInfo(onResult),
                    )
                }
                //0x77 08
                Host4FlutterGmacroConstants.fetchMobapadDeviceInfo -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryMacroHandleInfo(profile, GmacroCallbackBridge.message(onResult))
                }

                //0x44 查询实物外观
                Host4FlutterGmacroConstants.fetchPrintingType ->
                    commands.queryPhysicalAppearance(GmacroCallbackBridge.fetchPrintingType(onResult))

                //恢复出厂
                Host4FlutterGmacroConstants.resetDevice -> commands.resetKeyBoard(GmacroCallbackBridge.message(onResult))

                //切换模式
                Host4FlutterGmacroConstants.switchToNormalMode -> commands.switchHandleMode(MODE_NORMAL, GmacroCallbackBridge.message(onResult))
                Host4FlutterGmacroConstants.switchToTestMode -> commands.switchHandleMode(MODE_TEST, GmacroCallbackBridge.message(onResult))
                Host4FlutterGmacroConstants.switchToConfigMode -> commands.switchHandleMode(MODE_MACRO, GmacroCallbackBridge.message(onResult))
                //触点映射配置模式
                Host4FlutterGmacroConstants.switchToSettingMode -> commands.switchHandleMode(MODE_SETTING, GmacroCallbackBridge.message(onResult))
                Host4FlutterGmacroConstants.switchToTouchMappingMode -> commands.switchHandleMode(MODE_TOUCH_MAPPING, GmacroCallbackBridge.message(onResult))

                //查询上报率
                Host4FlutterGmacroConstants.fetchReportRate -> commands.QueryRateOfReturn(GmacroCallbackBridge.message(onResult))
                //设置上报率
                Host4FlutterGmacroConstants.updateReportRate -> {
                    val rate = GmacroArgParser.intArg(arguments, "rate")
                    commands.setRateOfReturn(rate, GmacroCallbackBridge.message(onResult))
                }

                //查询充电底座启停开关
                Host4FlutterGmacroConstants.fetchChargingDock -> commands.queryChargingDock(GmacroCallbackBridge.message(onResult))
                //设置充电底座启停开关
                Host4FlutterGmacroConstants.updateChargingDock -> {
                    val isOn = GmacroArgParser.boolArg(arguments, "isOn")
                    commands.setChargingDock(if (isOn) 1 else 2, GmacroCallbackBridge.message(onResult))
                }

                //查询设备支持灯效及当前灯效（支持模式固定，无小模式）0x82 01
                Host4FlutterGmacroConstants.fetchLight -> {
                    //TODO 0x82 01
                }
                //0x82 04
                Host4FlutterGmacroConstants.fetchLightPosition -> commands.queryLightingPositionGroup(GmacroCallbackBridge.message(onResult))
                //0x82 05
                Host4FlutterGmacroConstants.fetchSupportedLightEffects -> commands.queryLightingPositionEffect(GmacroCallbackBridge.message(onResult))
                //0x82 06
                Host4FlutterGmacroConstants.fetchCurrentLightEffect -> commands.queryCurrentLightingEffect(GmacroCallbackBridge.message(onResult))

                //查询等效 0x71
                Host4FlutterGmacroConstants.fetchCurrentLightConfig ->
                    commands.queryCurrentLightEffect(GmacroCallbackBridge.fetchCurrentLightConfig(onResult))

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
                        GmacroCallbackBridge.message(onResult),
                    )
                }

                //0x4E
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
                        GmacroCallbackBridge.message(onResult),
                    )
                }

                //0x4F
                Host4FlutterGmacroConstants.setLightEffect -> {
                    commands.setLightGroupEffect(
                        GmacroArgParser.intArg(arguments, "position"),
                        GmacroArgParser.intArg(arguments, "groupCount"),
                        if (GmacroArgParser.boolArg(arguments, "isOn")) 1 else 0,
                        GmacroArgParser.intArg(arguments, "light"),
                        GmacroArgParser.intArg(arguments, "speed"),
                        GmacroArgParser.intArg(arguments, "mode"),
                        GmacroArgParser.intArg(arguments, "subMode"),
                        GmacroCallbackBridge.message(onResult),
                    )
                }

                Host4FlutterGmacroConstants.trigger -> commands.setMacroTrigger(
                    GmacroArgParser.intArg(arguments, "leftMin"),
                    GmacroArgParser.intArg(arguments, "leftMax"),
                    GmacroArgParser.intArg(arguments, "rightMin"),
                    GmacroArgParser.intArg(arguments, "rightMax"),
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.leftTriggerCurve -> {
                    val points = GmacroModelFactory.macroPoints(GmacroArgParser.mapList(arguments, "cgPoints"))
                    commands.setMacroTriggerPoint(TRIGGER_LEFT, points.size, points, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.rightTriggerCurve -> {
                    val points = GmacroModelFactory.macroPoints(GmacroArgParser.mapList(arguments, "cgPoints"))
                    commands.setMacroTriggerPoint(TRIGGER_RIGHT, points.size, points, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.triggerQuickSwitch -> commands.setQuickTriggerSwitch(
                    if (GmacroArgParser.boolArg(arguments, "leftOn")) 1 else 2,
                    if (GmacroArgParser.boolArg(arguments, "rightOn")) 1 else 2,
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.getTriggerQuickSwitch -> commands.queryQuickTriggerSwitch(GmacroCallbackBridge.message(onResult))

                //板机校准
                Host4FlutterGmacroConstants.startTriggerCalibration ->
                    commands.beginAlignRockerOrTrigger(CALIB_TRIGGER_SUB_ID,  GmacroCallbackBridge.message(onResult))
                Host4FlutterGmacroConstants.endTriggerCalibration ->
                    commands.endAlignRockerOrTrigger(CALIB_TRIGGER_SUB_ID,  GmacroCallbackBridge.endAlignRockerOrTrigger(onResult))

                //设置左右扳机线性输出
                Host4FlutterGmacroConstants.triggerLinearOutput -> commands.switchLinerTrigger(
                    GmacroArgParser.intArg(arguments, "leftMode"),
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.updateTriggerTestVibrationSwitch -> commands.setTriggerTestVibration(
                    if (GmacroArgParser.boolArg(arguments, "triggerTestVibration")) 1 else 0,
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.fetchTriggerTestVibrationSwitch -> commands.queryTriggerTestVibration(GmacroCallbackBridge.message(onResult))

                Host4FlutterGmacroConstants.updateTriggerVibration -> commands.setTriggerVibration(
                    if (GmacroArgParser.boolArg(arguments, "triggerVibration")) 1 else 0,
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.fetchTriggerVibration -> commands.queryTriggerVibration(GmacroCallbackBridge.message(onResult))

                Host4FlutterGmacroConstants.updateRockerLinear -> commands.setMacroRockerLinear(
                    GmacroModelFactory.macroRockerLinear(arguments),
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.updateLeftRocker3DCurve -> {
                    val points = GmacroModelFactory.macroPoints(GmacroArgParser.mapList(arguments, "cgPoints"))
                    commands.setMacroRockerPoint(SIDE_LEFT, points.size, points, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.updateRightRocker3DCurve -> {
                    val points = GmacroModelFactory.macroPoints(GmacroArgParser.mapList(arguments, "cgPoints"))
                    commands.setMacroRockerPoint(SIDE_RIGHT, points.size, points, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.rockerDeadZoneCompensation -> commands.setRockerDeadCompensate(
                    GmacroArgParser.intArg(arguments, "left"),
                    GmacroArgParser.intArg(arguments, "right"),
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.rockerDeadZoneRegressionComp -> commands.setRockerDeadBackCompensate(
                    GmacroArgParser.intArg(arguments, "left"),
                    GmacroArgParser.intArg(arguments, "right"),
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.rockerTriggerType -> commands.setRockerMethodAndKey(
                    GmacroArgParser.intArg(arguments, "leftRigger"),
                    GmacroArgParser.intArg(arguments, "leftGamepadKey"),
                    GmacroArgParser.intArg(arguments, "rightRigger"),
                    GmacroArgParser.intArg(arguments, "rightGamepadKey"),
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.rockerOutputGraphics -> commands.setRockerOutputTrajectory(
                    GmacroArgParser.intArg(arguments, "left"),
                    GmacroArgParser.intArg(arguments, "right"),
                    GmacroCallbackBridge.message(onResult),
                )

                //摇杆校准
                Host4FlutterGmacroConstants.startRockerCalibration ->
                    commands.beginAlignRockerOrTrigger(CALIB_ROCKER_SUB_ID, GmacroCallbackBridge.message(onResult))
                Host4FlutterGmacroConstants.endRockerCalibration ->
                    commands.endAlignRockerOrTrigger(CALIB_ROCKER_SUB_ID,  GmacroCallbackBridge.endAlignRockerOrTrigger(onResult))

                Host4FlutterGmacroConstants.updateRockerAdditional -> commands.setRockerAdditional(
                    GmacroModelFactory.rockerParam(arguments),
                    GmacroCallbackBridge.message(onResult),
                )

                // 0x5C 查询手柄当前配置页
                Host4FlutterGmacroConstants.fetchCurrentProfile ->
                    commands.queryMacroProfileNum( GmacroCallbackBridge.fetchCurrentProfile(onResult))

                // 0x36 平台设置
                Host4FlutterGmacroConstants.startMacroPlatform -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.setMacroPlatform(profile,GmacroCallbackBridge.message(onResult))
                }

                // 0x34 结束配置
                Host4FlutterGmacroConstants.endMacroConfig ->
                    commands.setMacroProfileEnd(GmacroCallbackBridge.message(onResult))

                Host4FlutterGmacroConstants.queryCurrentMacro -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryMacroCurrentConfig(profile, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.queryMacroKeys -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryMacroSupport(profile, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.queryMacroRecordableKeys -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryRecordSupport(profile, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.queryMacroTimeRange -> commands.queryHandleTime(GmacroCallbackBridge.message(onResult))

                //查询宏录制最大支持组数
                Host4FlutterGmacroConstants.queryMacroMaxGroups -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.querySupportMacroMaxNum(profile, GmacroCallbackBridge.message(onResult))
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
                        GmacroCallbackBridge.message(onResult),
                    )
                }

                Host4FlutterGmacroConstants.setMacroInterval -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    val key = GmacroArgParser.intArg(arguments, "key")
                    val intervalTime = GmacroArgParser.intArg(arguments, "intervalTime")
                    commands.setMacroCycleTime(profile, key, intervalTime, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.startRecord -> commands.setRecordMacroStart(GmacroCallbackBridge.message(onResult))
                Host4FlutterGmacroConstants.endRecord -> commands.setRecordMacroStop(true, GmacroCallbackBridge.message(onResult))

                //支持体感触发按键 魔派
                Host4FlutterGmacroConstants.queryGyroTriggerKeys -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.QueryKinectTriggerSupport(profile,GmacroCallbackBridge.message(onResult))
                }
                //支持体感映射模式 魔派
                Host4FlutterGmacroConstants.queryGyroMappingModes -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryKinectMappingMode(profile,GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.setMotion -> commands.setKinectConfig(
                    GmacroModelFactory.macroKinect(arguments),
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.setMotionSecondary -> commands.setMotionSecondarySensitivity(
                    if (GmacroArgParser.boolArg(arguments, "isOn")) 1 else 0,
                    GmacroArgParser.intArg(arguments, "triggerMode"),
                    GmacroArgParser.intArg(arguments, "triggerKey"),
                    GmacroArgParser.intArg(arguments, "sensitivity"),
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.setMotionHorizontalAxis -> commands.setMotionHorizontalAxial(
                    GmacroArgParser.intArg(arguments, "axis"),
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.fetchMotionHorizontalAxis -> commands.queryMotionHorizontalAxial(GmacroCallbackBridge.message(onResult))
                //查询陀螺仪死区补偿
                Host4FlutterGmacroConstants.fetchGyroDeadZoneComp ->
                    commands.queryMotionDeadZoneCompensate(GmacroCallbackBridge.message(onResult))

                //查询陀螺仪灵敏度曲线 0x6A 0x1D
                Host4FlutterGmacroConstants.fetchGyroSensitivityCurve ->{
                    commands.queryMotionSensitivityCurve(GmacroCallbackBridge.message(onResult))
                }

                //查询陀螺仪二级灵敏度 0x6A 0x1F
                Host4FlutterGmacroConstants.fetchGyroSensitivity2 ->{
                    //TODO 查询陀螺仪二级灵敏度
                }

                Host4FlutterGmacroConstants.setGyroXYInvert -> commands.setMotionXYReversal(
                    if (GmacroArgParser.boolArg(arguments, "xOn")) 2 else 1,
                    if (GmacroArgParser.boolArg(arguments, "yOn")) 2 else 1,
                    GmacroCallbackBridge.message(onResult),
                )

                //查询陀螺仪 XY 轴反转信息 0x6A 0x10
                Host4FlutterGmacroConstants.fetchGyroXYInvert ->{
                    //TODO 查询陀螺仪 XY 轴反转信息
                }

                Host4FlutterGmacroConstants.setGyroDeadZone -> commands.setMotionDeadZoneCompensate(
                    GmacroArgParser.intArg(arguments, "compensate"),
                    GmacroCallbackBridge.message(onResult),
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
                    commands.setMotionSensitivityCurve(points, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.updateGyroOuterDeadZone -> commands.setMotionOuterDeadZone(
                    GmacroArgParser.intArg(arguments, "gyroOuterDeadZone"),
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.fetchGyroOuterDeadZone -> commands.queryMotionOuterDeadZone(GmacroCallbackBridge.message(onResult))

                Host4FlutterGmacroConstants.startGyroCalibration -> commands.beginAlignGyroscope( GmacroCallbackBridge.message(onResult))
                Host4FlutterGmacroConstants.endGyroCalibration -> commands.endAlignGyroscope( GmacroCallbackBridge.endGyroCalibration(onResult))

                Host4FlutterGmacroConstants.updateGyroXYRatio -> commands.setMotionXYAxisRatio(
                    GmacroArgParser.intArg(arguments, "gyroXYRatio"),
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.fetchGyroXYRatio -> commands.queryMotionXYAxisRatio(GmacroCallbackBridge.message(onResult))

                Host4FlutterGmacroConstants.updateGyroMappingType -> commands.setMotionMappingType(
                    GmacroArgParser.intArg(arguments, "gyroMappingType"),
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.fetchGyroMappingType -> commands.queryMotionMappingType(GmacroCallbackBridge.message(onResult))

                //查询支持映射的按键
                Host4FlutterGmacroConstants.queryMappableKeys -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryMapperSupport(profile, GmacroCallbackBridge.message(onResult))
                }

                //查询支持映射为手柄的按键
                Host4FlutterGmacroConstants.queryMappableGamepadKeys -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryMapperSetting(profile, GmacroCallbackBridge.message(onResult))
                }

                //设置按键映射为手柄
                Host4FlutterGmacroConstants.setKeyMappings -> {
                    val mappings = GmacroArgParser.mapList(arguments, "keyMappings")
                    val first = mappings.firstOrNull()
                        ?: throw IllegalArgumentException("keyMappings must not be empty.")
                    commands.setMacroKeyMapping(
                        GmacroArgParser.intArg(first, "original"),
                        GmacroArgParser.intArg(first, "mapped"),
                        GmacroCallbackBridge.message(onResult),
                    )
                }

                // 6C 0D 设置手柄按键映射（单映射）
                Host4FlutterGmacroConstants.setHandleKeyMapping -> {
                    val original = GmacroArgParser.intArg(arguments, "original")
                    val mapped = GmacroArgParser.intArg(arguments, "mapped")
                    commands.sendMacroMapping(
                        original,
                        mapped,
                        GmacroCallbackBridge.message(onResult))
                }

                //设置按键映射为鼠标
                Host4FlutterGmacroConstants.setMouseKeyMappings -> {
                    val mappings = GmacroArgParser.mapList(arguments, "keyMappings")
                    val first = mappings.firstOrNull()
                        ?: throw IllegalArgumentException("keyMappings must not be empty.")
                    commands.setMacroKeyMouse(
                        GmacroArgParser.intArg(first, "original"),
                        GmacroArgParser.intArg(first, "mapped"),
                        GmacroCallbackBridge.message(onResult),
                    )
                }

                Host4FlutterGmacroConstants.setKeyboardKeyMappings -> {
                    val mappings = GmacroArgParser.mapList(arguments, "keyMappings")
                    val first = mappings.firstOrNull()
                        ?: throw IllegalArgumentException("keyMappings must not be empty.")
                    commands.setMacroKeyKeyboard(
                        GmacroArgParser.intArg(first, "original"),
                        GmacroArgParser.intArg(first, "mapped"),
                        GmacroCallbackBridge.message(onResult),
                    )
                }

                //查询当前按键映射配置
                Host4FlutterGmacroConstants.queryCurrentMapping -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryMappingKey(profile, GmacroCallbackBridge.queryCurrentMapping(onResult))
                }

                //设置手柄按键映射（支持同时映射多种类型键值）
                Host4FlutterGmacroConstants.setMultiKeyMapping -> {
                    val mapping = com.host4.platform.kr.model.MultiKeyMapping().apply {
                        setOriginalKey(GmacroArgParser.intArg(arguments, "original"))
                        setTypeNum(GmacroArgParser.mapList(arguments, "mappedKeys").size)
                    }
                    commands.setMultiKeyMapping(mapping, GmacroCallbackBridge.message(onResult))
                }

                //获取手柄按键映射
                Host4FlutterGmacroConstants.queryAllMultiMappings -> commands.queryAllMultiMappingKey(GmacroCallbackBridge.message(onResult))

                //查询某个手柄按键的多映射配置
                Host4FlutterGmacroConstants.queryMultiMapping -> commands.queryMultiMappingByKey(
                    GmacroArgParser.intArg(arguments, "original"),
                    GmacroCallbackBridge.message(onResult),
                )

                //设置触点映射屏幕尺寸
                Host4FlutterGmacroConstants.setScreenSize -> commands.setScreenSize(
                    GmacroArgParser.intArg(arguments, "orientation"),
                    GmacroArgParser.intArg(arguments, "width"),
                    GmacroArgParser.intArg(arguments, "height"),
                    GmacroCallbackBridge.message(onResult),
                )

                //设置触点映射按键
                Host4FlutterGmacroConstants.setKeyMapping -> commands.setKeyMapping(
                    GmacroArgParser.intArg(arguments, "type"),
                    GmacroArgParser.longArg(arguments, "keyCode"),
                    GmacroArgParser.intArg(arguments, "x"),
                    GmacroArgParser.intArg(arguments, "y"),
                    GmacroArgParser.intArg(arguments, "range"),
                    GmacroArgParser.intArg(arguments, "sensitivity"),
                    GmacroArgParser.intArg(arguments, "x1"),
                    GmacroArgParser.intArg(arguments, "y1"),
                    GmacroArgParser.intArg(arguments, "attribute"),
                    GmacroArgParser.intArg(arguments, "page"),
                    GmacroCallbackBridge.message(onResult),
                )

                //设置触点宏按键
                Host4FlutterGmacroConstants.setMacroKey -> commands.setMacroKey(
                    GmacroArgParser.longArg(arguments, "keyCode"),
                    GmacroArgParser.intArg(arguments, "x"),
                    GmacroArgParser.intArg(arguments, "y"),
                    GmacroArgParser.intArg(arguments, "flag"),
                    GmacroArgParser.intArg(arguments, "interval"),
                    GmacroArgParser.intArg(arguments, "during"),
                    GmacroArgParser.intArg(arguments, "attribute"),
                    GmacroArgParser.intArg(arguments, "range"),
                    GmacroArgParser.intArg(arguments, "sensitivity"),
                    GmacroArgParser.intArg(arguments, "opposite"),
                    GmacroCallbackBridge.message(onResult),
                )

                //设置触点宏按键触发方式
                Host4FlutterGmacroConstants.setMacroKeyTrigger -> commands.setMacroKeyTrigger(
                    GmacroArgParser.longArg(arguments, "keyCode"),
                    GmacroArgParser.intArg(arguments, "touchType"),
                    GmacroCallbackBridge.message(onResult),
                )

                //设置触点宏终止按键
                Host4FlutterGmacroConstants.setMacroTerminationKey -> commands.setMacroTerminationKey(
                    GmacroArgParser.longArg(arguments, "keyCode"),
                    GmacroArgParser.longArg(arguments, "terminateKey"),
                    GmacroCallbackBridge.message(onResult),
                )

                //设置触点映射的 turbo 速率
                Host4FlutterGmacroConstants.setKeyTurboSpeed -> commands.setKeyTurboSpeed(
                    GmacroArgParser.longArg(arguments, "keyCode"),
                    GmacroArgParser.intArg(arguments, "turbo"),
                    GmacroCallbackBridge.message(onResult),
                )

                //结束触点映射配置
                Host4FlutterGmacroConstants.keyMappingEnd -> commands.keyMappingEnd(
                    GmacroArgParser.intArg(arguments, "page"),
                    GmacroArgParser.intArg(arguments, "packet"),
                    GmacroCallbackBridge.message(onResult),
                )

                Host4FlutterGmacroConstants.getSleepTime -> commands.querySleepTime(GmacroCallbackBridge.message(onResult))

                Host4FlutterGmacroConstants.setSleepTime -> commands.setSleepTime(
                    GmacroArgParser.intArg(arguments, "time"),
                    GmacroCallbackBridge.message(onResult),
                )

                //设置振动
                Host4FlutterGmacroConstants.setVibrationLevel -> commands.setVibrationLevel(
                    GmacroArgParser.intArg(arguments, "left"),
                    GmacroArgParser.intArg(arguments, "right"),
                    GmacroCallbackBridge.message(onResult),
                )

                //测试振动
                Host4FlutterGmacroConstants.testVibration -> {
                    val left = GmacroArgParser.intArg(arguments, "left")
                    val right = GmacroArgParser.intArg(arguments, "right")
                    val position = GmacroArgParser.intArg(arguments, "position")
                    commands.forceVibrationTest(
                        left,
                        right,
                        position,
                        GmacroCallbackBridge.message(onResult),
                    )
                }

                //设置连发
                Host4FlutterGmacroConstants.setTurboDatas -> {
                    val turbos = GmacroArgParser.mapList(arguments, "keyTurbos")
                    val first = turbos.firstOrNull()
                        ?: throw IllegalArgumentException("keyTurbos must not be empty.")
                    commands.setMacroBurstRate(
                        GmacroArgParser.intArg(first, "key"),
                        GmacroArgParser.intArg(first, "turbo"),
                        GmacroArgParser.intArg(first, "speed"),
                        GmacroCallbackBridge.message(onResult),
                    )
                }

                //查询支持连发的按键
                Host4FlutterGmacroConstants.querySupportedTurboKeys -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.queryBurstSupport(profile, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.switchVibrateOpen -> {
                    val status = GmacroArgParser.intArg(arguments, "status")
                    commands.switchVibrateOpen(status, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.queryVibrateOpen ->
                    commands.queryVibrateOpen(GmacroCallbackBridge.queryVibrateOpen(onResult))

                Host4FlutterGmacroConstants.switchWorkStyle -> {
                    val mode = GmacroArgParser.intArg(arguments, "mode")
                    commands.switchWorkStyle(mode, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.queryWorkStyle ->
                    commands.queryWorkStyle(GmacroCallbackBridge.queryWorkStyle(onResult))

                Host4FlutterGmacroConstants.switchOutputMode -> {
                    val mode = GmacroArgParser.intArg(arguments, "mode")
                    commands.switchOutputMode(mode, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.queryOutputMode ->
                    commands.queryOutputMode(GmacroCallbackBridge.message(onResult))

                Host4FlutterGmacroConstants.sendHandleBeta -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.sendHandleBeta(profile, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.switchHandleConfig -> {
                    val profile = GmacroArgParser.intArg(arguments, "profile")
                    commands.switchHandleConfig(profile, GmacroCallbackBridge.message(onResult))
                }

                //0x83 02 开关手柄功能以及 EP3 回调，按 bit 参数兼容 Android 旧 SDK
                Host4FlutterGmacroConstants.updateHandleFunction -> {
                    val handleOn = GmacroArgParser.boolArg(arguments, "handleOn")
                    val ep3CallbackOn = GmacroArgParser.boolArg(arguments, "ep3CallbackOn")
                    val method = (if (handleOn) 1 else 0) or (if (ep3CallbackOn) 2 else 0)
                    commands.switchHandleCallbacks(method, GmacroCallbackBridge.message(onResult))
                }

                //0x83 02
                Host4FlutterGmacroConstants.switchHandleCallbacks -> {
                    val method = GmacroArgParser.intArg(arguments, "method")
                    commands.switchHandleCallbacks(method, GmacroCallbackBridge.message(onResult))
                }

                /**
                 * 查询左右扳机线性输出
                 */
                Host4FlutterGmacroConstants.queryLinerTrigger ->
                    commands.queryLinerTrigger(GmacroCallbackBridge.queryLinerTrigger(onResult))

                Host4FlutterGmacroConstants.switchLinerTrigger -> {
                    val mode = GmacroArgParser.intArg(arguments, "mode")
                    commands.switchLinerTrigger(mode, GmacroCallbackBridge.message(onResult))
                }

                Host4FlutterGmacroConstants.queryLightingEffectPantas ->
                    commands.queryLightingEffectPantas(GmacroCallbackBridge.message(onResult))

                Host4FlutterGmacroConstants.setLightGroupEffectPantas -> {
                    commands.setLightGroupEffectPantas(
                        GmacroArgParser.boolArg(arguments, "open"),
                        GmacroArgParser.intArg(arguments, "mode"),
                        GmacroArgParser.intArg(arguments, "brightness"),
                        GmacroArgParser.intArg(arguments, "colorR"),
                        GmacroArgParser.intArg(arguments, "colorG"),
                        GmacroArgParser.intArg(arguments, "colorB"),
                        GmacroCallbackBridge.message(onResult),
                    )
                }

                else -> onResult(GmacroResult.unsupported(method))
            }
        } catch (error: IllegalArgumentException) {
            onResult(GmacroResult.invalidArguments(error.message))
        } catch (error: Exception) {
            onResult(GmacroResult.invocationError(method, error))
        }
    }
}
