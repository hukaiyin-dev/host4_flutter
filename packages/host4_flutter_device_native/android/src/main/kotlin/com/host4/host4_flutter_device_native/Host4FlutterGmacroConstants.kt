internal object Host4FlutterGmacroConstants {
    // Device
    const val fetchDeviceVersion = "fetchDeviceVersion"
    const val fetchGameMacroDefaultInfo = "fetchGameMacroDefaultInfo"
    const val fetchMobapadDeviceInfo = "fetchMobapadDeviceInfo"
    const val resetDevice = "resetDevice"
    const val fetchChargingDock = "fetchChargingDock"
    const val updateChargingDock = "updateChargingDock"

    // Mode
    const val switchToNormalMode = "switchToNormalMode"
    const val switchToTestMode = "switchToTestMode"
    const val switchToConfigMode = "switchToConfigMode"

    // Report rate
    const val fetchReportRate = "fetchReportRate"
    const val updateReportRate = "updateReportRate"

    // Light
    const val fetchLight = "fetchLight"
    const val fetchLightPosition = "fetchLightPosition"
    const val fetchSupportedLightEffects = "fetchSupportedLightEffects"
    const val fetchCurrentLightEffect = "fetchCurrentLightEffect"
    const val fetchCurrentLightConfig = "fetchCurrentLightConfig"
    const val setLightConfig = "setLightConfig"
    const val setLightColor = "setLightColor"
    const val setLightEffect = "setLightEffect"

    // Trigger
    const val trigger = "trigger"
    const val leftTriggerCurve = "leftTriggerCurve"
    const val rightTriggerCurve = "rightTriggerCurve"
    const val triggerQuickSwitch = "triggerQuickSwitch"
    const val getTriggerQuickSwitch = "getTriggerQuickSwitch"
    const val startTriggerCalibration = "startTriggerCalibration"
    const val endTriggerCalibration = "endTriggerCalibration"
    const val triggerLinearOutput = "triggerLinearOutput"
    const val updateTriggerTestVibrationSwitch = "updateTriggerTestVibrationSwitch"
    const val fetchTriggerTestVibrationSwitch = "fetchTriggerTestVibrationSwitch"
    const val updateTriggerVibration = "updateTriggerVibration"
    const val fetchTriggerVibration = "fetchTriggerVibration"

    // Rocker
    const val updateRockerLinear = "updateRockerLinear"
    const val updateLeftRocker3DCurve = "updateLeftRocker3DCurve"
    const val updateRightRocker3DCurve = "updateRightRocker3DCurve"
    const val rockerDeadZoneCompensation = "rockerDeadZoneCompensation"
    const val rockerDeadZoneRegressionComp = "rockerDeadZoneRegressionComp"
    const val rockerTriggerType = "rockerTriggerType"
    const val rockerOutputGraphics = "rockerOutputGraphics"
    const val startRockerCalibration = "startRockerCalibration"
    const val endRockerCalibration = "endRockerCalibration"
    const val updateRockerAdditional = "updateRockerAdditional"

    // Macro
    const val fetchCurrentProfile = "fetchCurrentProfile"
    const val startMacroPlatform = "startMacroPlatform"
    const val endMacroConfig = "endMacroConfig"
    const val queryCurrentMacro = "queryCurrentMacro"
    const val queryMacroKeys = "queryMacroKeys"
    const val queryMacroRecordableKeys = "queryMacroRecordableKeys"
    const val queryMacroTimeRange = "queryMacroTimeRange"
    const val queryMacroMaxGroups = "queryMacroMaxGroups"
    const val setMacroKeys = "setMacroKeys"
    const val setMacroInterval = "setMacroInterval"
    const val startRecord = "startRecord"
    const val endRecord = "endRecord"

    // Gyro / Motion
    const val queryGyroTriggerKeys = "queryGyroTriggerKeys"
    const val queryGyroMappingModes = "queryGyroMappingModes"
    const val setMotion = "setMotion"
    const val setMotionSecondary = "setMotionSecondary"
    const val setMotionHorizontalAxis = "setMotionHorizontalAxis"
    const val fetchMotionHorizontalAxis = "fetchMotionHorizontalAxis"
    const val fetchGyroDeadZoneComp = "fetchGyroDeadZoneComp"
    const val fetchGyroSensitivityCurve = "fetchGyroSensitivityCurve"
    const val fetchGyroSensitivity2 = "fetchGyroSensitivity2"
    const val setGyroXYInvert = "setGyroXYInvert"
    const val fetchGyroXYInvert = "fetchGyroXYInvert"
    const val setGyroDeadZone = "setGyroDeadZone"
    const val setGyroSensitivityCurve = "setGyroSensitivityCurve"
    const val updateGyroOuterDeadZone = "updateGyroOuterDeadZone"
    const val fetchGyroOuterDeadZone = "fetchGyroOuterDeadZone"
    const val startGyroCalibration = "startGyroCalibration"
    const val endGyroCalibration = "endGyroCalibration"
    const val updateGyroXYRatio = "updateGyroXYRatio"
    const val fetchGyroXYRatio = "fetchGyroXYRatio"
    const val updateGyroMappingType = "updateGyroMappingType"
    const val fetchGyroMappingType = "fetchGyroMappingType"

    // Mapping
    const val queryMappableKeys = "queryMappableKeys"
    const val queryMappableGamepadKeys = "queryMappableGamepadKeys"
    const val setKeyMappings = "setKeyMappings"
    const val setHandleKeyMapping = "setHandleKeyMapping"
    const val setMouseKeyMappings = "setMouseKeyMappings"
    const val setKeyboardKeyMappings = "setKeyboardKeyMappings"
    const val queryCurrentMapping = "queryCurrentMapping"
    const val setMultiKeyMapping = "setMultiKeyMapping"
    const val queryAllMultiMappings = "queryAllMultiMappings"
    const val queryMultiMapping = "queryMultiMapping"

    // Touch Mapping
    const val setScreenSize = "setScreenSize"
    const val setKeyMapping = "setKeyMapping"
    const val setMacroKey = "setMacroKey"
    const val setMacroKeyTrigger = "setMacroKeyTrigger"
    const val setMacroTerminationKey = "setMacroTerminationKey"
    const val keyMappingEnd = "keyMappingEnd"

    // Sleep
    const val getSleepTime = "getSleepTime"
    const val setSleepTime = "setSleepTime"

    // Vibration
    const val setVibrationLevel = "setVibrationLevel"
    const val testVibration = "testVibration"

    // Turbo
    const val setTurboDatas = "setTurboDatas"
    const val querySupportedTurboKeys = "querySupportedTurboKeys"

    // Other
    const val switchVibrateOpen = "switchVibrateOpen"
    const val queryVibrateOpen = "queryVibrateOpen"
    const val switchWorkStyle = "switchWorkStyle"
    const val queryWorkStyle = "queryWorkStyle"
    const val switchOutputMode = "switchOutputMode"
    const val queryOutputMode = "queryOutputMode"
    const val sendHandleBeta = "sendHandleBeta"
    const val switchHandleConfig = "switchHandleConfig"
    const val switchHandleCallbacks = "switchHandleCallbacks"
    const val queryLinerTrigger = "queryLinerTrigger"
    const val switchLinerTrigger = "switchLinerTrigger"
    const val queryLightingEffectPantas = "queryLightingEffectPantas"
    const val setLightGroupEffectPantas = "setLightGroupEffectPantas"

    const val startOta = "startOta"
}
