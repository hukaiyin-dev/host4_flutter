import BluetoothKit
import CoreBluetooth
import Flutter
import Foundation
import GMacroProtocolSDK
import MFiKit
import UIKit

private final class QueuedEventStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var bufferedEvents: [[String: Any]] = []

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    bufferedEvents.forEach(events)
    bufferedEvents.removeAll()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func emit(_ event: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      if let eventSink = self.eventSink {
        eventSink(event)
      } else {
        self.bufferedEvents.append(event)
      }
    }
  }
}

// MARK: - Native Log Channel

private final class NativeLogHandler: NSObject, FlutterStreamHandler {
  static let shared = NativeLogHandler()

  private var eventSink: FlutterEventSink?

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func log(_ message: String) {
    print("[Native] \(message)")
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(message)
    }
  }
}

private func nativeLog(_ message: String) {
  NativeLogHandler.shared.log(message)
}

private final class BleScanStreamHandler: NSObject, FlutterStreamHandler {
  private let runtime = BluetoothCentralRuntime.shared
  private var eventSink: FlutterEventSink?

  override init() {
    super.init()

    runtime.onDiscovery = { [weak self] descriptor in
      print("[BLE Scan] Device discovered: \(descriptor.name) (\(descriptor.deviceId))")
      self?.emit(descriptor: descriptor)
    }
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    print("[BLE Scan] onListen called with arguments: \(String(describing: arguments))")
    eventSink = events

    let payload = arguments as? [String: Any]
    let serviceIds = payload?["serviceIds"] as? [String] ?? []
    let serviceUUIDs = serviceIds.isEmpty ? nil : serviceIds.map(CBUUID.init(string:))

    print("[BLE Scan] Starting BLE scan with serviceUUIDs: \(String(describing: serviceUUIDs))")
    runtime.scan(serviceUUIDs: serviceUUIDs)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    print("[BLE Scan] onCancel called")
    stop()
    return nil
  }

  func stop() {
    print("[BLE Scan] Stopping scan")
    runtime.stopScan()
    eventSink = nil
  }

  private func emit(descriptor: BluetoothDeviceDescriptor) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      let event = [
        "deviceId": descriptor.deviceId.uuidString,
        "name": descriptor.name,
        "kind": "ble",
        "metadata": [
          "manufacturerDataHex": descriptor.manufacturerData.hexadecimal,
          "rssi": descriptor.rssi,
        ],
      ] as [String: Any]
      print("[BLE Scan] Emitting event: \(event)")
      self.eventSink?(event)
    }
  }
}

private final class TransportSessionRecord {
  enum Source {
    case ble
    case mfi(session: MFiTransportSession, byteTransport: AnyByteStreamTransport)
  }

  let sessionId: String
  let source: Source
  let eventChannel: FlutterEventChannel
  let eventHandler: QueuedEventStreamHandler
  let disconnectHandler: () -> Void

  init(
    sessionId: String,
    source: Source,
    eventChannel: FlutterEventChannel,
    eventHandler: QueuedEventStreamHandler,
    disconnectHandler: @escaping () -> Void
  ) {
    self.sessionId = sessionId
    self.source = source
    self.eventChannel = eventChannel
    self.eventHandler = eventHandler
    self.disconnectHandler = disconnectHandler
  }

  var byteTransport: AnyByteStreamTransport? {
    switch source {
    case .ble:
      return nil
    case .mfi(_, let byteTransport):
      return byteTransport
    }
  }

  func disconnect() {
    disconnectHandler()
  }
}

private final class GMacroProtocolRecord {
  let sessionId: String
  let transportSessionId: String
  let session: GMacroProtocolSession
  let eventChannel: FlutterEventChannel
  let eventHandler: QueuedEventStreamHandler

  init(
    sessionId: String,
    transportSessionId: String,
    session: GMacroProtocolSession,
    eventChannel: FlutterEventChannel,
    eventHandler: QueuedEventStreamHandler
  ) {
    self.sessionId = sessionId
    self.transportSessionId = transportSessionId
    self.session = session
    self.eventChannel = eventChannel
    self.eventHandler = eventHandler
  }
}

public final class Host4FlutterDeviceNativePlugin: NSObject, FlutterPlugin {
  private let methodChannel: FlutterMethodChannel
  private let messenger: FlutterBinaryMessenger
  private let bleScanHandler = BleScanStreamHandler()
  private var transportSessions: [String: TransportSessionRecord] = [:]
  private var gmacroProtocolSessions: [String: GMacroProtocolRecord] = [:]

  private init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    methodChannel = FlutterMethodChannel(
      name: "host4_flutter_device_native",
      binaryMessenger: messenger
    )

    super.init()

    let bleScanChannel = FlutterEventChannel(
      name: "host4_flutter_device_native/ble_scan",
      binaryMessenger: messenger
    )
    bleScanChannel.setStreamHandler(bleScanHandler)

    let logChannel = FlutterEventChannel(
      name: "host4_flutter_device_native/native_log",
      binaryMessenger: messenger
    )
    logChannel.setStreamHandler(NativeLogHandler.shared)

    // 接管 BluetoothKit / GMacroProtocolSDK 内部的所有 print() 输出
    let logForwarder: (_ items: [Any], _ separator: String, _ terminator: String) -> Void = { items, sep, _ in
      let message = items.map { "\($0)" }.joined(separator: sep)
      NativeLogHandler.shared.log(message)
    }
    BluetoothKitConstant.logHandler = logForwarder
    GPDConstant.logHandler = logForwarder
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = Host4FlutterDeviceNativePlugin(messenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: instance.methodChannel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "stopBleScan":
      bleScanHandler.stop()
      result(nil)
    case "connectBle":
      handleConnectBle(call, result: result)
    case "disconnectTransport":
      handleDisconnectTransport(call, result: result)
    case "attachGmacroProtocol":
      handleAttachGmacroProtocol(call, result: result)
    case "invokeGmacroMethod":
      handleInvokeGmacroMethod(call, result: result)
    case "closeProtocol":
      handleCloseProtocol(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleConnectBle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let deviceId = arguments["deviceId"] as? String,
      !deviceId.isEmpty
    else {
      result(flutterError(code: "invalid-arguments", message: "deviceId is required."))
      return
    }

    let eventHandler = QueuedEventStreamHandler()
    let sessionId = NativeAdapterRuntime.shared.connect(deviceIdString: deviceId) {
      [weak self, weak eventHandler] stateRawValue in
      guard let self, let eventHandler else { return }
      eventHandler.emit(self.transportEventMap(fromBleState: stateRawValue))
    }

    guard let sessionId else {
      result(
        flutterError(
          code: "ble-connect-failed",
          message: "NativeAdapterRuntime failed to create a BLE transport session."
        )
      )
      return
    }

    let eventChannel = FlutterEventChannel(
      name: "host4_flutter_device_native/transport_events/\(sessionId)",
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(eventHandler)

    transportSessions[sessionId] = TransportSessionRecord(
      sessionId: sessionId,
      source: .ble,
      eventChannel: eventChannel,
      eventHandler: eventHandler,
      disconnectHandler: {
        NativeAdapterRuntime.shared.disconnect(transportSessionId: sessionId)
      }
    )

    result(sessionId)
  }

  private func handleDisconnectTransport(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard
      let arguments = call.arguments as? [String: Any],
      let transportSessionId = arguments["transportSessionId"] as? String,
      let transportRecord = transportSessions[transportSessionId]
    else {
      result(
        flutterError(
          code: "transport-session-not-found",
          message: "No transport session exists for the provided transportSessionId."
        )
      )
      return
    }

    transportRecord.disconnect()
    result(nil)
  }

  private func handleAttachGmacroProtocol(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard
      let arguments = call.arguments as? [String: Any],
      let transportSessionId = arguments["transportSessionId"] as? String,
      let transportRecord = transportSessions[transportSessionId]
    else {
      result(
        flutterError(
          code: "transport-session-not-found",
          message: "No transport session exists for the provided transportSessionId."
        )
      )
      return
    }

    let eventHandler = QueuedEventStreamHandler()
    let session: GMacroProtocolSession

    switch transportRecord.source {
    case .ble:
      guard
        let bleSession = NativeAdapterRuntime.shared.attachGMacroProtocol(
          transportSessionId: transportSessionId,
          onEvent: { [weak self, weak eventHandler] event in
            guard let self, let eventHandler else { return }
            eventHandler.emit(self.protocolEventMap(from: event))
          }
        )
      else {
        result(
          flutterError(
            code: "gmacro-bind-failed",
            message: "Native runtime failed to create a GMacro protocol session."
          )
        )
        return
      }
      // 配置 OTA 写入通道（BLE 特征 FF11 / FF12）
      let bleTransport = TransportSessionRegistry.shared.getSession(transportSessionId) as? BluetoothTransportSession
      if bleTransport == nil {
        nativeLog("[GMacro] ⚠ attachGMacro: bleTransport cast failed, OTA writers will be no-op")
      } else {
        nativeLog("[GMacro] attachGMacro: bleTransport OK, OTA writers configured (FF11/FF12)")
      }
      bleSession.otaCommandWriter = { data, completion in
        nativeLog("[OTA] commandWriter called, size=\(data.count)")
        do {
          try bleTransport?.send(data, to: "FF11")
        } catch {
          nativeLog("[OTA] commandWriter send error: \(error)")
        }
        completion?()
      }
      bleSession.otaDataWriter = { data, completion in
        nativeLog("[OTA] dataWriter called, size=\(data.count)")
        do {
          try bleTransport?.send(data, to: "FF12")
        } catch {
          nativeLog("[OTA] dataWriter send error: \(error)")
        }
        completion?()
      }
      session = bleSession
    case .mfi(_, let byteTransport):
      let sessionId = UUID().uuidString
      let mfiSession = GMacroProtocolSession(sessionId: sessionId, transport: byteTransport)
      mfiSession.onEvent = { [weak self, weak eventHandler] event in
        guard let self, let eventHandler else { return }
        eventHandler.emit(self.protocolEventMap(from: event))
      }
      session = mfiSession
    }

    let protocolSessionId = session.sessionId
    let eventChannel = FlutterEventChannel(
      name: "host4_flutter_device_native/protocol_events/\(protocolSessionId)",
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(eventHandler)

    gmacroProtocolSessions[protocolSessionId] = GMacroProtocolRecord(
      sessionId: protocolSessionId,
      transportSessionId: transportSessionId,
      session: session,
      eventChannel: eventChannel,
      eventHandler: eventHandler
    )

    result(protocolSessionId)
  }

  private func handleInvokeGmacroMethod(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard
      let payload = call.arguments as? [String: Any],
      let protocolSessionId = payload["protocolSessionId"] as? String,
      let method = payload["method"] as? String,
      let protocolRecord = gmacroProtocolSessions[protocolSessionId]
    else {
      result(
        flutterError(
          code: "invalid-arguments",
          message: "protocolSessionId and method are required."
        )
      )
      return
    }

    let arguments = payload["arguments"] as? [String: Any] ?? [:]
    let session = protocolRecord.session

    do {
      switch method {
      case "fetchLight":
        invoke(result) { callback in session.fetchLight(response: callback) }
      case "fetchLightPosition":
        invoke(result) { callback in session.fetchLightPosition(response: callback) }
      case "fetchSupportedLightEffects":
        invoke(result) { callback in session.fetchSupportedLightEffects(response: callback) }
      case "fetchCurrentLightEffect":
        invoke(result) { callback in session.fetchCurrentLightEffect(response: callback) }
      case "fetchCurrentLightConfig":
        invoke(result) { callback in session.fetchCurrentLightConfig(response: callback) }
      case "fetchDeviceVersion":
        invoke(result) { callback in session.fetchDeviceVersion(callback) }
      case "fetchMobapadDeviceInfo":
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.fetchMobapadDeviceInfo(profile: profile, response: callback)
        }
      case "resetDevice":
        invoke(result) { callback in session.resetDevice(callback) }
      case "switchToNormalMode":
        invoke(result) { callback in session.switchToNormalMode(callback) }
      case "switchToTestMode":
        invoke(result) { callback in session.switchToTestMode(callback) }
      case "switchToConfigMode":
        invoke(result) { callback in session.switchToConfigMode(callback) }
      case "updateReportRate":
        let rate = try intArg("rate", from: arguments)
        invoke(result) { callback in session.updateReportRate(rate, response: callback) }
      case "fetchReportRate":
        invoke(result) { callback in session.fetchReportRate(response: callback) }
      case "fetchSupportCalibration":
        invoke(result) { callback in session.fetchSupportCalibration(response: callback) }
      case "fetchCalibrationKey":
        invoke(result) { callback in session.fetchCalibrationKey(response: callback) }
      case "updateSwitchLayout":
        let isOpen = try boolArg("isOpen", from: arguments)
        let locking = try boolArg("locking", from: arguments)
        let exchange = try boolArg("exchange", from: arguments)
        invoke(result) { callback in
          session.updateSwitchLayout(
            isOpen: isOpen,
            locking: locking,
            exchange: exchange,
            response: callback
          )
        }
      case "querySupportedTurboKeys":
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.querySupportedTurboKeys(profile: profile, response: callback)
        }
      case "setSleepTime":
        let time = try intArg("time", from: arguments)
        invoke(result) { callback in session.setSleepTime(time: time, response: callback) }
      case "getSleepTime":
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in session.getSleepTime(profile: profile, response: callback) }
      case "queryCurrentMacro":
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in session.queryCurrentMacro(profile: profile, response: callback) }
      case "queryMacroKeys":
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in session.queryMacroKeys(profile: profile, response: callback) }
      case "queryMacroRecordableKeys":
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.queryMacroRecordableKeys(profile: profile, response: callback)
        }
      case "queryMacroTimeRange":
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.queryMacroTimeRange(profile: profile, response: callback)
        }
      case "queryMacroMaxGroups":
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.queryMacroMaxGroups(profile: profile, response: callback)
        }
      case "startRecord":
        invoke(result) { callback in session.startRecord(callback) }
      case "endRecord":
        invoke(result) { callback in session.endRecord(callback) }
      case "trigger":
        let leftMin = try intArg("leftMin", from: arguments)
        let leftMax = try intArg("leftMax", from: arguments)
        let rightMin = try intArg("rightMin", from: arguments)
        let rightMax = try intArg("rightMax", from: arguments)
        invoke(result) { callback in
          session.trigger(
            leftMin: leftMin,
            leftMax: leftMax,
            rightMin: rightMin,
            rightMax: rightMax,
            response: callback
          )
        }
      case "triggerQuickSwitch":
        let leftOn = try boolArg("leftOn", from: arguments)
        let rightOn = try boolArg("rightOn", from: arguments)
        invoke(result) { callback in
          session.triggerQuickSwitch(leftOn: leftOn, rightOn: rightOn, response: callback)
        }
      case "getTriggerQuickSwitch":
        invoke(result) { callback in session.getTriggerQuickSwitch(response: callback) }
      case "startTriggerCalibration":
        invoke(result) { callback in session.startTriggerCalibration(callback) }
      case "endTriggerCalibration":
        invoke(result) { callback in session.endTriggerCalibration(callback) }
      case "triggerLinearOutput":
        let leftMode = try intArg("leftMode", from: arguments)
        let leftThreshold = try intArg("leftThreshold", from: arguments)
        let rightMode = try intArg("rightMode", from: arguments)
        let rightThreshold = try intArg("rightThreshold", from: arguments)
        invoke(result) { callback in
          session.triggerLinearOutput(
            leftMode: leftMode,
            leftThreshold: leftThreshold,
            rightMode: rightMode,
            rightThreshold: rightThreshold,
            response: callback
          )
        }
      case "setVibrationLevel":
        let left = try intArg("left", from: arguments)
        let right = try intArg("right", from: arguments)
        invoke(result) { callback in
          session.setVibrationLevel(left: left, right: right, response: callback)
        }
      case "testVibration":
        let left = try intArg("left", from: arguments)
        let right = try intArg("right", from: arguments)
        let position: VibrationPosition = try enumArg("position", from: arguments)
        invoke(result) { callback in
          session.testVibration(left: left, right: right, position: position, response: callback)
        }
      case "queryMappableKeys":
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in session.queryMappableKeys(profile: profile, response: callback) }
      case "queryMappableGamepadKeys":
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.queryMappableGamepadKeys(profile: profile, response: callback)
        }
      case "queryCurrentMapping":
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.queryCurrentMapping(profile: profile, response: callback)
        }
      case "updateRockerLinear":
        invoke(result) { callback in
          session.updateRockerLinear(
            leftMin: try intArg("leftMin", from: arguments),
            leftMax: try intArg("leftMax", from: arguments),
            leftXFlip: try boolArg("leftXFlip", from: arguments),
            leftYFlip: try boolArg("leftYFlip", from: arguments),
            rightMin: try intArg("rightMin", from: arguments),
            rightMax: try intArg("rightMax", from: arguments),
            rightXFlip: try boolArg("rightXFlip", from: arguments),
            rightYFlip: try boolArg("rightYFlip", from: arguments),
            response: callback
          )
        }
      case "rockerDeadZoneCompensation":
        let left = try intArg("left", from: arguments)
        let right = try intArg("right", from: arguments)
        invoke(result) { callback in
          session.rockerDeadZoneCompensation(left: left, right: right, response: callback)
        }
      case "rockerDeadZoneRegressionComp":
        let left = try intArg("left", from: arguments)
        let right = try intArg("right", from: arguments)
        invoke(result) { callback in
          session.rockerDeadZoneRegressionComp(left: left, right: right, response: callback)
        }
      case "rockerTriggerType":
        let leftRigger: CurveTriggerMode = try enumArg("leftRigger", from: arguments)
        let leftGamepadKey: GamepadKey = try enumArg("leftGamepadKey", from: arguments)
        let rightRigger: CurveTriggerMode = try enumArg("rightRigger", from: arguments)
        let rightGamepadKey: GamepadKey = try enumArg("rightGamepadKey", from: arguments)
        invoke(result) { callback in
          session.rockerTriggerType(
            leftRigger: leftRigger,
            leftGamepadKey: leftGamepadKey,
            rightRigger: rightRigger,
            rightGamepadKey: rightGamepadKey,
            response: callback
          )
        }
      case "rockerOutputGraphics":
        let left: OutputGraphics = try enumArg("left", from: arguments)
        let right: OutputGraphics = try enumArg("right", from: arguments)
        invoke(result) { callback in
          session.rockerOutputGraphics(left: left, right: right, response: callback)
        }
      case "updateTriggerTestVibrationSwitch":
        let value = try boolArg("triggerTestVibration", from: arguments)
        invoke(result) { callback in
          session.updateTriggerTestVibrationSwitch(
            triggerTestVibration: value,
            response: callback
          )
        }
      case "fetchTriggerTestVibrationSwitch":
        invoke(result) { callback in session.fetchTriggerTestVibrationSwitch(response: callback) }
      case "updateTriggerVibration":
        let value = try boolArg("triggerVibration", from: arguments)
        invoke(result) { callback in
          session.updateTriggerVibration(triggerVibration: value, response: callback)
        }
      case "fetchTriggerVibration":
        invoke(result) { callback in session.fetchTriggerVibration(response: callback) }
      case "updategyroXYRatio", "updateGyroXYRatio":
        let ratio = try intArg("gyroXYRatio", from: arguments)
        invoke(result) { callback in session.updategyroXYRatio(gyroXYRatio: ratio, response: callback) }
      case "fetchgyroXYRatio", "fetchGyroXYRatio":
        invoke(result) { callback in session.fetchgyroXYRatio(response: callback) }
      case "updateGyroMappingType":
        let value: GyroMappingType = try enumArg("gyroMappingType", from: arguments)
        invoke(result) { callback in
          session.updateGyroMappingType(gyroMappingType: value, response: callback)
        }
      case "fetchGyroMappingType":
        invoke(result) { callback in session.fetchGyroMappingType(response: callback) }
      case "updateChargingDock":
        let value = try boolArg("isOn", from: arguments)
        invoke(result) { callback in session.updateChargingDock(isOn: value, response: callback) }
      case "fetchChargingDock":
        invoke(result) { callback in session.fetchChargingDock(response: callback) }
      case "startRockerCalibration":
        invoke(result) { callback in session.startRockerCalibration(callback) }
      case "endRockerCalibration":
        invoke(result) { callback in session.endRockerCalibration(callback) }
      case "updateRockerAdditional":
        invoke(result) { callback in
          session.updateRockerAdditional(
            leftDeadZone: try intArg("leftDeadZone", from: arguments),
            leftOutMax: try intArg("leftOutMax", from: arguments),
            leftCurveApply: try intArg("leftCurveApply", from: arguments),
            leftCurveApplyKey: try intArg("leftCurveApplyKey", from: arguments),
            leftLineCorrection: try intArg("leftLineCorrection", from: arguments),
            rightDeadZone: try intArg("rightDeadZone", from: arguments),
            rightOutMax: try intArg("rightOutMax", from: arguments),
            rightCurveApply: try intArg("rightCurveApply", from: arguments),
            rightCurveApplyKey: try intArg("rightCurveApplyKey", from: arguments),
            rightLineCorrection: try intArg("rightLineCorrection", from: arguments),
            response: callback
          )
        }
      case "queryGyroTriggerKeys":
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.queryGyroTriggerKeys(profile: profile, response: callback)
        }
      case "queryGyroMappingModes":
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.queryGyroMappingModes(profile: profile, response: callback)
        }
      case "setMotion":
        let triggerMode: MotionTriggerMode = try enumArg("triggerMode", from: arguments)
        let triggerKey: GamepadKey = try enumArg("triggerKey", from: arguments)
        let mappingMode: MotionMappingMode = try enumArg("mappingMode", from: arguments)
        invoke(result) { callback in
          session.setMotion(
            motionEnabled: try boolArg("motionEnabled", from: arguments),
            mappingEnabled: try boolArg("mappingEnabled", from: arguments),
            triggerMode: triggerMode,
            triggerKey: triggerKey,
            deadZone: try intArg("deadZone", from: arguments),
            sensitivity: try intArg("sensitivity", from: arguments),
            mappingMode: mappingMode,
            response: callback
          )
        }
      case "setMotionSecondary":
        let triggerMode: MotionTriggerMode = try enumArg("triggerMode", from: arguments)
        let triggerKey: GamepadKey = try enumArg("triggerKey", from: arguments)
        invoke(result) { callback in
          session.setMotionSecondary(
            isOn: try boolArg("isOn", from: arguments),
            triggerMode: triggerMode,
            triggerKey: triggerKey,
            sensitivity: try intArg("sensitivity", from: arguments),
            response: callback
          )
        }
      case "setMotionHorizontalAxis":
        let axis: GyroAxis = try enumArg("axis", from: arguments)
        invoke(result) { callback in session.setMotionHorizontalAxis(axis: axis, response: callback) }
      case "fetchMotionHorizontalAxis":
        invoke(result) { callback in session.fetchMotionHorizontalAxis(callback) }
      case "fetchGyroDeadZoneComp":
        invoke(result) { callback in session.fetchGyroDeadZoneComp(callback) }
      case "fetchGyroSensitivityCurve":
        invoke(result) { callback in session.fetchGyroSensitivityCurve(callback) }
      case "fetchGyroSensitivity2":
        invoke(result) { callback in session.fetchGyroSensitivity2(callback) }
      case "setGyroXYInvert":
        let xOn = try boolArg("xOn", from: arguments)
        let yOn = try boolArg("yOn", from: arguments)
        invoke(result) { callback in session.setGyroXYInvert(xOn: xOn, yOn: yOn, response: callback) }
      case "fetchGyroXYInvert":
        invoke(result) { callback in session.fetchGyroXYInvert(response: callback) }
      case "setGyroDeadZone":
        let compensate = try intArg("compensate", from: arguments)
        invoke(result) { callback in session.setGyroDeadZone(compensate: compensate, response: callback) }
      case "update", "updateGyroOuterDeadZone":
        let gyroOuterDeadZone = try intArg("gyroOuterDeadZone", from: arguments)
        invoke(result) { callback in
          session.update(gyroOuterDeadZone: gyroOuterDeadZone, response: callback)
        }
      case "fetchGyroOuterDeadZone":
        invoke(result) { callback in session.fetchGyroOuterDeadZone(response: callback) }
      case "startGyroCalibration":
        invoke(result) { callback in session.startGyroCalibration(callback) }
      case "endGyroCalibration":
        invoke(result) { callback in session.endGyroCalibration(callback) }
      case "startOta":
        let firmwareData = (arguments["data"] as? FlutterStandardTypedData)?.data ?? Data()
        nativeLog("[OTA] startOTA called, firmware=\(firmwareData.count) bytes, commandWriter=\(session.otaCommandWriter != nil), dataWriter=\(session.otaDataWriter != nil)")
        session.startOTA(data: firmwareData)
        nativeLog("[OTA] startOTA dispatched")
        result([:] as [String: Any])
      default:
        result(
          flutterError(
            code: "unsupported-gmacro-method",
            message: "Unsupported GMacro method: \(method)."
          )
        )
      }
    } catch {
      result(asFlutterError(error))
    }
  }

  private func handleCloseProtocol(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let protocolSessionId = arguments["protocolSessionId"] as? String,
      let protocolRecord = gmacroProtocolSessions.removeValue(forKey: protocolSessionId)
    else {
      result(
        flutterError(
          code: "protocol-session-not-found",
          message: "No protocol session exists for the provided protocolSessionId."
        )
      )
      return
    }

    protocolRecord.session.close()
    result(nil)
  }

  private func invoke(
    _ flutterResult: @escaping FlutterResult,
    body: (@escaping (Result<[String: Any], Error>) -> Void) throws -> Void
  ) {
    do {
      try body { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let payload):
            flutterResult(payload)
          case .failure(let error):
            flutterResult(self.asFlutterError(error))
          }
        }
      }
    } catch {
      flutterResult(asFlutterError(error))
    }
  }

  private func transportEventMap(fromBleState rawValue: Int) -> [String: Any] {
    guard let state = TransportState(rawValue: rawValue) else {
      return [
        "type": "error",
        "failure": failureMap(
          code: "unknown-transport-state",
          message: "Unknown BLE transport state raw value: \(rawValue)."
        ),
      ]
    }

    switch state {
    case .connecting:
      return ["type": "connecting"]
    case .connected:
      return ["type": "connected"]
    case .ready:
      return ["type": "ready"]
    case .disconnected:
      return ["type": "disconnected"]
    case .error:
      return [
        "type": "error",
        "failure": failureMap(
          code: "native-transport-error",
          message: "BLE transport reported an error state."
        ),
      ]
    }
  }

  private func protocolEventMap(from event: GMacroProtocolEvent) -> [String: Any] {
    switch event {
    case .progress(let progress):
      return [
        "type": "busy",
        "reason": "progress",
        "payload": [
          "event": "progress",
          "progress": Double(progress),
        ],
      ]
    case .success:
      return [
        "type": "busy",
        "reason": "success",
        "payload": ["event": "success"],
      ]
    case .failure(let message):
      return [
        "type": "error",
        "failure": failureMap(code: "gmacro-failure", message: message),
      ]
    case .deviceConnected:
      return [
        "type": "ready",
        "payload": ["event": "deviceConnected"],
      ]
    case .testKeys(let keys, let j1x, let j1y, let j2x, let j2y, let l2, let r2):
      return [
        "type": "busy",
        "reason": "testKeys",
        "payload": [
          "event": "testKeys",
          "keys": keys.map(\.rawValue),
          "j1x": j1x,
          "j1y": j1y,
          "j2x": j2x,
          "j2y": j2y,
          "l2": l2,
          "r2": r2,
        ],
      ]
    case .configKeys(let keys):
      return [
        "type": "busy",
        "reason": "configKeys",
        "payload": [
          "event": "configKeys",
          "keys": keys.map(\.rawValue),
        ],
      ]
    case .testKeyboardMouse(
      let modifierKeys,
      let keyboardKeys,
      let mouseCores,
      let mouseWheels,
      let mouseX,
      let mouseY,
      let mediaKeys
    ):
      return [
        "type": "busy",
        "reason": "testKeyboardMouse",
        "payload": [
          "event": "testKeyboardMouse",
          "modifierKeys": modifierKeys.map(\.rawValue),
          "keyboardKeys": keyboardKeys.map(\.rawValue),
          "mouseCores": mouseCores.map(\.rawValue),
          "mouseWheels": mouseWheels.map(\.rawValue),
          "mouseX": Int(mouseX),
          "mouseY": Int(mouseY),
          "mediaKeys": mediaKeys.map(\.rawValue),
        ],
      ]
    case .recordKeys(let value):
      return [
        "type": "busy",
        "reason": "recordKeys",
        "payload": [
          "event": "recordKeys",
          "keys": value.keys.map(\.intValue),
          "keepTime": value.keepTime,
          "intervalTime": value.intervalTime,
        ],
      ]
    case .endRecord(let code):
      return [
        "type": "busy",
        "reason": "endRecord",
        "payload": [
          "event": "endRecord",
          "code": code,
        ],
      ]
    case .calibrationFinished(let type, let subId, let result, let param1, let param2):
      return [
        "type": "busy",
        "reason": "calibrationFinished",
        "payload": [
          "event": "calibrationFinished",
          "type": type,
          "subId": subId,
          "result": result,
          "param1": param1,
          "param2": param2,
        ],
      ]
    case .devKeysState(
      let keys,
      let j1x,
      let j1xOriginal,
      let j1y,
      let j1yOriginal,
      let j2x,
      let j2xOriginal,
      let j2y,
      let j2yOriginal,
      let l2,
      let l2Original,
      let r2,
      let r2Original
    ):
      return [
        "type": "busy",
        "reason": "devKeysState",
        "payload": [
          "event": "devKeysState",
          "keys": keys.map(\.rawValue),
          "j1x": j1x,
          "j1xOriginal": j1xOriginal,
          "j1y": j1y,
          "j1yOriginal": j1yOriginal,
          "j2x": j2x,
          "j2xOriginal": j2xOriginal,
          "j2y": j2y,
          "j2yOriginal": j2yOriginal,
          "l2": l2,
          "l2Original": l2Original,
          "r2": r2,
          "r2Original": r2Original,
        ],
      ]
    }
  }

  private func intArg(_ key: String, from arguments: [String: Any]) throws -> Int {
    guard let value = arguments[key] as? Int else {
      throw BridgeArgumentError.missing(key: key, expected: "Int")
    }
    return value
  }

  private func boolArg(_ key: String, from arguments: [String: Any]) throws -> Bool {
    guard let value = arguments[key] as? Bool else {
      throw BridgeArgumentError.missing(key: key, expected: "Bool")
    }
    return value
  }

  private func enumArg<T>(_ key: String, from arguments: [String: Any]) throws -> T
  where T: RawRepresentable, T.RawValue == Int {
    guard let rawValue = arguments[key] as? Int, let value = T(rawValue: rawValue) else {
      throw BridgeArgumentError.invalidEnum(key: key)
    }
    return value
  }

  private func enumArg<T>(_ key: String, from arguments: [String: Any]) throws -> T
  where T: RawRepresentable, T.RawValue == UInt8 {
    guard let rawValue = arguments[key] as? Int, let value = T(rawValue: UInt8(rawValue)) else {
      throw BridgeArgumentError.invalidEnum(key: key)
    }
    return value
  }

  private func failureMap(code: String, message: String, details: Any? = nil) -> [String: Any] {
    var payload: [String: Any] = [
      "code": code,
      "message": message,
    ]
    if let details {
      payload["details"] = details
    }
    return payload
  }

  private func flutterError(code: String, message: String, details: Any? = nil) -> FlutterError {
    FlutterError(code: code, message: message, details: details)
  }

  private func asFlutterError(_ error: Error) -> FlutterError {
    if let bridgeError = error as? BridgeArgumentError {
      return flutterError(code: bridgeError.code, message: bridgeError.localizedDescription)
    }

    return flutterError(code: "native-error", message: error.localizedDescription)
  }
}

private enum BridgeArgumentError: LocalizedError {
  case missing(key: String, expected: String)
  case invalidEnum(key: String)

  var code: String {
    switch self {
    case .missing:
      return "missing-argument"
    case .invalidEnum:
      return "invalid-enum"
    }
  }

  var errorDescription: String? {
    switch self {
    case .missing(let key, let expected):
      return "Argument '\(key)' is required and must be a \(expected)."
    case .invalidEnum(let key):
      return "Argument '\(key)' contains an unsupported enum raw value."
    }
  }
}
