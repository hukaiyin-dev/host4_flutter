struct Host4FlutterChannelConstants {
  // Device
  static let fetchDeviceVersion = "fetchDeviceVersion"
  static let fetchGameMacroDefaultInfo = "fetchGameMacroDefaultInfo"
  static let fetchMobapadDeviceInfo = "fetchMobapadDeviceInfo"
  static let resetDevice = "resetDevice"
  static let fetchChargingDock = "fetchChargingDock"
  static let updateChargingDock = "updateChargingDock"

  // Mode
  static let switchToNormalMode = "switchToNormalMode"
  static let switchToTestMode = "switchToTestMode"
  static let switchToConfigMode = "switchToConfigMode"

  // Report rate
  static let fetchReportRate = "fetchReportRate"
  static let updateReportRate = "updateReportRate"

  // Support / calibration / layout
  static let fetchSupportCalibration = "fetchSupportCalibration"
  static let fetchCalibrationKey = "fetchCalibrationKey"
  static let updateSwitchLayout = "updateSwitchLayout"

  // Light
  static let fetchLight = "fetchLight"
  static let fetchLightPosition = "fetchLightPosition"
  static let fetchSupportedLightEffects = "fetchSupportedLightEffects"
  static let fetchCurrentLightEffect = "fetchCurrentLightEffect"
  static let fetchCurrentLightConfig = "fetchCurrentLightConfig"
  static let setLightConfig = "setLightConfig"
  static let setLightColor = "setLightColor"
  static let setLightEffect = "setLightEffect"

  // Trigger
  static let trigger = "trigger"
  static let leftTriggerCurve = "leftTriggerCurve"
  static let rightTriggerCurve = "rightTriggerCurve"
  static let triggerQuickSwitch = "triggerQuickSwitch"
  static let getTriggerQuickSwitch = "getTriggerQuickSwitch"
  static let startTriggerCalibration = "startTriggerCalibration"
  static let endTriggerCalibration = "endTriggerCalibration"
  static let triggerLinearOutput = "triggerLinearOutput"
  static let updateTriggerTestVibrationSwitch =
      "updateTriggerTestVibrationSwitch"
  static let fetchTriggerTestVibrationSwitch =
      "fetchTriggerTestVibrationSwitch"
  static let updateTriggerVibration = "updateTriggerVibration"
  static let fetchTriggerVibration = "fetchTriggerVibration"

  // Rocker
  static let updateRockerLinear = "updateRockerLinear"
  static let updateLeftRocker3DCurve = "updateLeftRocker3DCurve"
  static let updateRightRocker3DCurve = "updateRightRocker3DCurve"
  static let rockerDeadZoneCompensation = "rockerDeadZoneCompensation"
  static let rockerDeadZoneRegressionComp = "rockerDeadZoneRegressionComp"
  static let rockerTriggerType = "rockerTriggerType"
  static let rockerOutputGraphics = "rockerOutputGraphics"
  static let startRockerCalibration = "startRockerCalibration"
  static let endRockerCalibration = "endRockerCalibration"
  static let updateRockerAdditional = "updateRockerAdditional"

  // Macro
  static let queryCurrentMacro = "queryCurrentMacro"
  static let queryMacroKeys = "queryMacroKeys"
  static let queryMacroRecordableKeys = "queryMacroRecordableKeys"
  static let queryMacroTimeRange = "queryMacroTimeRange"
  static let queryMacroMaxGroups = "queryMacroMaxGroups"
  static let setMacroKeys = "setMacroKeys"
  static let setMacroInterval = "setMacroInterval"
  static let startRecord = "startRecord"
  static let endRecord = "endRecord"

  // Gyro / Motion
  static let queryGyroTriggerKeys = "queryGyroTriggerKeys"
  static let queryGyroMappingModes = "queryGyroMappingModes"
  static let setMotion = "setMotion"
  static let setMotionSecondary = "setMotionSecondary"
  static let setMotionHorizontalAxis = "setMotionHorizontalAxis"
  static let fetchMotionHorizontalAxis = "fetchMotionHorizontalAxis"
  static let fetchGyroDeadZoneComp = "fetchGyroDeadZoneComp"
  static let fetchGyroSensitivityCurve = "fetchGyroSensitivityCurve"
  static let fetchGyroSensitivity2 = "fetchGyroSensitivity2"
  static let setGyroXYInvert = "setGyroXYInvert"
  static let fetchGyroXYInvert = "fetchGyroXYInvert"
  static let setGyroDeadZone = "setGyroDeadZone"
  static let setGyroSensitivityCurve = "setGyroSensitivityCurve"
  static let updateGyroOuterDeadZone = "updateGyroOuterDeadZone"
  static let fetchGyroOuterDeadZone = "fetchGyroOuterDeadZone"
  static let startGyroCalibration = "startGyroCalibration"
  static let endGyroCalibration = "endGyroCalibration"
  static let updateGyroXYRatio = "updateGyroXYRatio"
  static let fetchGyroXYRatio = "fetchGyroXYRatio"
  static let updateGyroMappingType = "updateGyroMappingType"
  static let fetchGyroMappingType = "fetchGyroMappingType"

  // Mapping
  static let queryMappableKeys = "queryMappableKeys"
  static let queryMappableGamepadKeys = "queryMappableGamepadKeys"
  static let setKeyMappings = "setKeyMappings"
  static let setHandleKeyMapping = "setHandleKeyMapping"
  static let setMouseKeyMappings = "setMouseKeyMappings"
  static let setKeyboardKeyMappings = "setKeyboardKeyMappings"
  static let queryCurrentMapping = "queryCurrentMapping"
  static let setMultiKeyMapping = "setMultiKeyMapping"
  static let queryAllMultiMappings = "queryAllMultiMappings"
  static let queryMultiMapping = "queryMultiMapping"

  // Sleep
  static let getSleepTime = "getSleepTime"
  static let setSleepTime = "setSleepTime"

  // Vibration
  static let setVibrationLevel = "setVibrationLevel"
  static let testVibration = "testVibration"

  // Turbo
  static let setTurboDatas = "setTurboDatas"
  static let querySupportedTurboKeys = "querySupportedTurboKeys"

  // OTA
  static let startOta = "startOta"

  // Other — 马达/手柄/扳机等功能控制
  static let queryVibrateOpen = "queryVibrateOpen"
  static let switchVibrateOpen = "switchVibrateOpen"
  static let queryWorkStyle = "queryWorkStyle"
  static let switchWorkStyle = "switchWorkStyle"
  static let queryOutputMode = "queryOutputMode"
  static let switchOutputMode = "switchOutputMode"
  static let sendHandleBeta = "sendHandleBeta"
  static let switchHandleConfig = "switchHandleConfig"
  static let switchHandleCallbacks = "switchHandleCallbacks"
  static let queryLinerTrigger = "queryLinerTrigger"
  static let switchLinerTrigger = "switchLinerTrigger"
}