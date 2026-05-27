abstract final class GmacroMethods {
  // Device
  static const fetchDeviceVersion = 'fetchDeviceVersion';
  static const fetchMobapadDeviceInfo = 'fetchMobapadDeviceInfo';
  static const resetDevice = 'resetDevice';
  static const fetchChargingDock = 'fetchChargingDock';
  static const updateChargingDock = 'updateChargingDock';

  // Mode
  static const switchToNormalMode = 'switchToNormalMode';
  static const switchToTestMode = 'switchToTestMode';
  static const switchToConfigMode = 'switchToConfigMode';

  // Report rate
  static const fetchReportRate = 'fetchReportRate';
  static const updateReportRate = 'updateReportRate';

  // Light
  static const fetchLight = 'fetchLight';
  static const fetchLightPosition = 'fetchLightPosition';
  static const fetchSupportedLightEffects = 'fetchSupportedLightEffects';
  static const fetchCurrentLightEffect = 'fetchCurrentLightEffect';
  static const fetchCurrentLightConfig = 'fetchCurrentLightConfig';
  static const setLightConfig = 'setLightConfig';
  static const setLightColor = 'setLightColor';
  static const setLightEffect = 'setLightEffect';

  // Trigger
  static const trigger = 'trigger';
  static const leftTriggerCurve = 'leftTriggerCurve';
  static const rightTriggerCurve = 'rightTriggerCurve';
  static const triggerQuickSwitch = 'triggerQuickSwitch';
  static const getTriggerQuickSwitch = 'getTriggerQuickSwitch';
  static const startTriggerCalibration = 'startTriggerCalibration';
  static const endTriggerCalibration = 'endTriggerCalibration';
  static const triggerLinearOutput = 'triggerLinearOutput';
  static const updateTriggerTestVibrationSwitch =
      'updateTriggerTestVibrationSwitch';
  static const fetchTriggerTestVibrationSwitch =
      'fetchTriggerTestVibrationSwitch';
  static const updateTriggerVibration = 'updateTriggerVibration';
  static const fetchTriggerVibration = 'fetchTriggerVibration';

  // Rocker
  static const updateRockerLinear = 'updateRockerLinear';
  static const updateLeftRocker3DCurve = 'updateLeftRocker3DCurve';
  static const updateRightRocker3DCurve = 'updateRightRocker3DCurve';
  static const rockerDeadZoneCompensation = 'rockerDeadZoneCompensation';
  static const rockerDeadZoneRegressionComp = 'rockerDeadZoneRegressionComp';
  static const rockerTriggerType = 'rockerTriggerType';
  static const rockerOutputGraphics = 'rockerOutputGraphics';
  static const startRockerCalibration = 'startRockerCalibration';
  static const endRockerCalibration = 'endRockerCalibration';
  static const updateRockerAdditional = 'updateRockerAdditional';

  // Macro
  static const queryCurrentMacro = 'queryCurrentMacro';
  static const queryMacroKeys = 'queryMacroKeys';
  static const queryMacroRecordableKeys = 'queryMacroRecordableKeys';
  static const queryMacroTimeRange = 'queryMacroTimeRange';
  static const queryMacroMaxGroups = 'queryMacroMaxGroups';
  static const setMacroKeys = 'setMacroKeys';
  static const setMacroInterval = 'setMacroInterval';
  static const startRecord = 'startRecord';
  static const endRecord = 'endRecord';

  // Gyro / Motion
  static const queryGyroTriggerKeys = 'queryGyroTriggerKeys';
  static const queryGyroMappingModes = 'queryGyroMappingModes';
  static const setMotion = 'setMotion';
  static const setMotionSecondary = 'setMotionSecondary';
  static const setMotionHorizontalAxis = 'setMotionHorizontalAxis';
  static const fetchMotionHorizontalAxis = 'fetchMotionHorizontalAxis';
  static const fetchGyroDeadZoneComp = 'fetchGyroDeadZoneComp';
  static const fetchGyroSensitivityCurve = 'fetchGyroSensitivityCurve';
  static const fetchGyroSensitivity2 = 'fetchGyroSensitivity2';
  static const setGyroXYInvert = 'setGyroXYInvert';
  static const fetchGyroXYInvert = 'fetchGyroXYInvert';
  static const setGyroDeadZone = 'setGyroDeadZone';
  static const setGyroSensitivityCurve = 'setGyroSensitivityCurve';
  static const updateGyroOuterDeadZone = 'updateGyroOuterDeadZone';
  static const fetchGyroOuterDeadZone = 'fetchGyroOuterDeadZone';
  static const startGyroCalibration = 'startGyroCalibration';
  static const endGyroCalibration = 'endGyroCalibration';
  static const updateGyroXYRatio = 'updateGyroXYRatio';
  static const fetchGyroXYRatio = 'fetchGyroXYRatio';
  static const updateGyroMappingType = 'updateGyroMappingType';
  static const fetchGyroMappingType = 'fetchGyroMappingType';

  // Mapping
  static const queryMappableKeys = 'queryMappableKeys';
  static const queryMappableGamepadKeys = 'queryMappableGamepadKeys';
  static const setKeyMappings = 'setKeyMappings';
  static const setMouseKeyMappings = 'setMouseKeyMappings';
  static const setKeyboardKeyMappings = 'setKeyboardKeyMappings';
  static const queryCurrentMapping = 'queryCurrentMapping';
  static const setMultiKeyMapping = 'setMultiKeyMapping';
  static const queryAllMultiMappings = 'queryAllMultiMappings';
  static const queryMultiMapping = 'queryMultiMapping';

  // Sleep
  static const getSleepTime = 'getSleepTime';
  static const setSleepTime = 'setSleepTime';

  // Vibration
  static const setVibrationLevel = 'setVibrationLevel';
  static const testVibration = 'testVibration';

  // Turbo
  static const setTurboDatas = 'setTurboDatas';
  static const querySupportedTurboKeys = 'querySupportedTurboKeys';
}
