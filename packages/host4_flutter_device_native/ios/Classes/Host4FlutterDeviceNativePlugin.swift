#if HOST4_DISABLE_GMACRO_SDK
import Flutter
import Foundation
import UIKit

private final class DisabledEventStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    nil
  }
}

public final class Host4FlutterDeviceNativePlugin: NSObject, FlutterPlugin {
  private let methodChannel: FlutterMethodChannel
  private let disabledEventStreamHandler = DisabledEventStreamHandler()
  private var disabledEventChannels: [FlutterEventChannel] = []

  private init(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(
      name: "host4_flutter_device_native",
      binaryMessenger: messenger
    )

    super.init()

    disabledEventChannels = [
      "host4_flutter_device_native/ble_scan",
      "host4_flutter_device_native/native_log",
      "host4_flutter_device_native/mfi_accessory_events",
    ].map {
      FlutterEventChannel(name: $0, binaryMessenger: messenger)
    }
    disabledEventChannels.forEach {
      $0.setStreamHandler(disabledEventStreamHandler)
    }
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
      result(nil)
    default:
      result(
        FlutterError(
          code: "native-sdk-disabled",
          message:
            "host4_flutter_device_native iOS SDK is disabled because the bundled GMacroProtocolSDK is not compatible with this Xcode.",
          details: ["method": call.method]
        )
      )
    }
  }
}
#else
import BluetoothKit
import CoreBluetooth
import Flutter
import Foundation
import GMacroProtocolSDK
import UIKit

private final class QueuedEventStreamHandler: NSObject, FlutterStreamHandler {
  var debugLabel: String
  private var eventSink: FlutterEventSink?
  private var bufferedEvents: [[String: Any]] = []

  init(debugLabel: String = "") {
    self.debugLabel = debugLabel
    super.init()
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    if !debugLabel.isEmpty {
      print("[NativeChannel] onListen \(debugLabel), buffered=\(bufferedEvents.count)")
    }
    eventSink = events
    bufferedEvents.forEach(events)
    bufferedEvents.removeAll()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if !debugLabel.isEmpty {
      print("[NativeChannel] onCancel \(debugLabel)")
    }
    eventSink = nil
    return nil
  }

  func emit(_ event: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      if let eventSink = self.eventSink {
        if event["reason"] as? String == "calibrationFinished" {
          print("[NativeChannel] emit \(self.debugLabel) to sink event=\(event)")
        }
        eventSink(event)
      } else {
        if event["reason"] as? String == "calibrationFinished" {
          print("[NativeChannel] emit \(self.debugLabel) buffered event=\(event)")
        }
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

private final class EmptyEventStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    nil
  }
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
  let sessionId: String
  let eventChannel: FlutterEventChannel
  let eventHandler: QueuedEventStreamHandler
  let disconnectHandler: () -> Void

  init(
    sessionId: String,
    eventChannel: FlutterEventChannel,
    eventHandler: QueuedEventStreamHandler,
    disconnectHandler: @escaping () -> Void
  ) {
    self.sessionId = sessionId
    self.eventChannel = eventChannel
    self.eventHandler = eventHandler
    self.disconnectHandler = disconnectHandler
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
  let otaEventChannel: FlutterEventChannel
  let otaEventHandler: QueuedEventStreamHandler

  init(
    sessionId: String,
    transportSessionId: String,
    session: GMacroProtocolSession,
    eventChannel: FlutterEventChannel,
    eventHandler: QueuedEventStreamHandler,
    otaEventChannel: FlutterEventChannel,
    otaEventHandler: QueuedEventStreamHandler
  ) {
    self.sessionId = sessionId
    self.transportSessionId = transportSessionId
    self.session = session
    self.eventChannel = eventChannel
    self.eventHandler = eventHandler
    self.otaEventChannel = otaEventChannel
    self.otaEventHandler = otaEventHandler
  }
}

public final class Host4FlutterDeviceNativePlugin: NSObject, FlutterPlugin {
  private let methodChannel: FlutterMethodChannel
  private let messenger: FlutterBinaryMessenger
  private let bleScanHandler = BleScanStreamHandler()
  private let mfiAccessoryEventHandler = EmptyEventStreamHandler()
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

    let mfiAccessoryChannel = FlutterEventChannel(
      name: "host4_flutter_device_native/mfi_accessory_events",
      binaryMessenger: messenger
    )
    mfiAccessoryChannel.setStreamHandler(mfiAccessoryEventHandler)

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
    case "connectSystemConnectedBle":
    handleConnectSystemConnectedBle(call, result: result)
    case "connectMfi":
      result(mfiUnsupportedError(method: call.method))
    case "isMfiAccessoryConnected":
      result(false)
    case "disconnectTransport":
      handleDisconnectTransport(call, result: result)
    case "attachGmacroProtocol":
      handleAttachGmacroProtocol(call, result: result)
    case "invokeGmacroMethod":
      handleInvokeGmacroMethod(call, result: result)
    case "closeProtocol":
      handleCloseProtocol(call, result: result)
    case "startOta":
      handleStartOta(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleStartOta(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard
      let arguments = call.arguments as? [String: Any],
      let protocolSessionId = arguments["protocolSessionId"] as? String,
      let firmwareData = arguments["firmwareData"] as? FlutterStandardTypedData,
      let protocolRecord = gmacroProtocolSessions[protocolSessionId]
    else {
      result(
        flutterError(
          code: "invalid-arguments",
          message: "protocolSessionId and firmwareData are required."
        )
      )
      return
    }

    let data = firmwareData.data
    nativeLog("[GMacro] startOta requested, protocolSessionId=\(protocolSessionId), size=\(data.count)")
    startOta(protocolRecord: protocolRecord, data: data)
    result(nil)
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
      eventChannel: eventChannel,
      eventHandler: eventHandler,
      disconnectHandler: {
        NativeAdapterRuntime.shared.disconnect(transportSessionId: sessionId)
      }
    )

    result(sessionId)
  }

  private func handleConnectSystemConnectedBle(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard
      let arguments = call.arguments as? [String: Any],
      let serviceIds = arguments["serviceIds"] as? [String],
      !serviceIds.isEmpty
    else {
      result(
        flutterError(
          code: "invalid-arguments",
          message: "serviceIds is required."
        )
      )
      return
    }

    let deviceNames = arguments["deviceNames"] as? [String] ?? []
    nativeLog("[SystemConnected] connect requested, serviceIds=\(serviceIds), deviceNames=\(deviceNames)")

    let eventHandler = QueuedEventStreamHandler()
    let sessionId = NativeAdapterRuntime.shared.connectSystemConnectedDevice(
      deviceNames: deviceNames,
      serviceUUIDs: serviceIds,
      onState: { [weak self, weak eventHandler] (stateRawValue: Int) in
        nativeLog("[SystemConnected] stateRawValue=\(stateRawValue)")
        guard let self, let eventHandler else { return }
        eventHandler.emit(self.transportEventMap(fromBleState: stateRawValue))
      },
      onLog: { message in nativeLog(message) }
    )

    nativeLog("[SystemConnected] sessionId=\(String(describing: sessionId))")

    guard let sessionId else {
      nativeLog("[SystemConnected] connect failed: sessionId is nil")
      result(
        flutterError(
          code: "ble-connect-failed",
          message: "NativeAdapterRuntime failed to create a system-connected BLE transport session."
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
      eventChannel: eventChannel,
      eventHandler: eventHandler,
      disconnectHandler: {
        NativeAdapterRuntime.shared.disconnect(transportSessionId: sessionId)
      }
    )

    nativeLog("[SystemConnected] transport session registered: \(sessionId)")
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
      transportSessions[transportSessionId] != nil
    else {
      result(
        flutterError(
          code: "transport-session-not-found",
          message: "No transport session exists for the provided transportSessionId."
        )
      )
      return
    }

    let otaCommandChar = arguments["otaCommandCharacteristic"] as? String ?? "FF11"
    let otaDataChar = arguments["otaDataCharacteristic"] as? String ?? "FF12"

    nativeLog("[GMacro] attachGMacro requested, transportSessionId=\(transportSessionId), otaCmd=\(otaCommandChar), otaData=\(otaDataChar)")

    // 注入 BLE 底层日志转发，使 Release 构建也能在 Flutter 侧看到收发数据
    BluetoothKitConstant.logHandler = { items, separator, terminator in
      let message = items.map { "\($0)" }.joined(separator: separator)
      nativeLog("[BLE] \(message)")
    }
    GPDConstant.logHandler = { items, separator, terminator in
      let message = items.map { "\($0)" }.joined(separator: separator)
      nativeLog("[GPD] \(message)")
    }
    GPDConstant.responseTimeout = 2

    let eventHandler = QueuedEventStreamHandler(debugLabel: "protocol pending")
    let otaEventHandler = QueuedEventStreamHandler(debugLabel: "ota pending")
    let session: GMacroProtocolSession

    guard
      let bleSession = NativeAdapterRuntime.shared.attachGMacroProtocol(
        transportSessionId: transportSessionId,
        onEvent: { [weak self, weak eventHandler] event in
          guard let self, let eventHandler else { return }
          self.emitGMacroEvent(
            event,
            protocolEventHandler: eventHandler,
            otaEventHandler: otaEventHandler
          )
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
    // 配置 OTA 写入通道
    let bleTransport = TransportSessionRegistry.shared.getSession(transportSessionId) as? BluetoothTransportSession
    if bleTransport == nil {
      nativeLog("[GMacro] ⚠ attachGMacro: bleTransport cast failed, OTA writers will be no-op")
    } else {
      nativeLog("[GMacro] attachGMacro: bleTransport OK, OTA writers configured (\(otaCommandChar)/\(otaDataChar))")
    }
    bleSession.otaCommandWriter = { data, completion in
      nativeLog("[OTA] commandWriter called, size=\(data.count)")
      do {
        try bleTransport?.writeValue(data, to: otaCommandChar, completion: completion)
      } catch {
        nativeLog("[OTA] commandWriter send error: \(error)")
        completion?()
      }
    }
    bleSession.otaDataWriter = { data, completion in
      nativeLog("[OTA] dataWriter called, size=\(data.count)")
      do {
        try bleTransport?.writeValue(data, to: otaDataChar, completion: completion)
      } catch {
        nativeLog("[OTA] dataWriter send error: \(error)")
        completion?()
      }
    }
    session = bleSession

    let protocolSessionId = session.sessionId
    eventHandler.debugLabel = "protocol_events/\(protocolSessionId)"
    otaEventHandler.debugLabel = "ota_events/\(protocolSessionId)"
    let eventChannel = FlutterEventChannel(
      name: "host4_flutter_device_native/protocol_events/\(protocolSessionId)",
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(eventHandler)
    let otaEventChannel = FlutterEventChannel(
      name: "host4_flutter_device_native/ota_events/\(protocolSessionId)",
      binaryMessenger: messenger
    )
    otaEventChannel.setStreamHandler(otaEventHandler)

    gmacroProtocolSessions[protocolSessionId] = GMacroProtocolRecord(
      sessionId: protocolSessionId,
      transportSessionId: transportSessionId,
      session: session,
      eventChannel: eventChannel,
      eventHandler: eventHandler,
      otaEventChannel: otaEventChannel,
      otaEventHandler: otaEventHandler
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
      // case Host4FlutterChannelConstants.fetchLight:
      //   invoke(result) { callback in session.fetchLight(response: callback) }
      // case Host4FlutterChannelConstants.fetchLightPosition:
      //   invoke(result) { callback in session.fetchLightPosition(response: callback) }
      // case Host4FlutterChannelConstants.fetchSupportedLightEffects:
      //   invoke(result) { callback in session.fetchSupportedLightEffects(response: callback) }
      // case Host4FlutterChannelConstants.fetchCurrentLightEffect:
      //   invoke(result) { callback in session.fetchCurrentLightEffect(response: callback) }
      // case Host4FlutterChannelConstants.fetchCurrentLightConfig:
      //   invoke(result) { callback in session.fetchCurrentLightConfig(response: callback) }
      case Host4FlutterChannelConstants.fetchLight:
        invoke(result) { callback in
          session.fetchLight { res in
            switch res {
            case .success(let payload):
              nativeLog("[GMacro][fetchLight][RAW] \(payload)")
            case .failure(let error):
              nativeLog("[GMacro][fetchLight][ERROR] \(error)")
            }
            callback(res)
          }
        }

      case Host4FlutterChannelConstants.fetchLightPosition:
        invoke(result) { callback in
          session.fetchLightPosition { res in
            switch res {
            case .success(let payload):
              nativeLog("[GMacro][fetchLightPosition][RAW] \(payload)")
            case .failure(let error):
              nativeLog("[GMacro][fetchLightPosition][ERROR] \(error)")
            }
            callback(res)
          }
        }

      case Host4FlutterChannelConstants.fetchSupportedLightEffects:
        invoke(result) { callback in
          session.fetchSupportedLightEffects { res in
            switch res {
            case .success(let payload):
              nativeLog("[GMacro][fetchSupportedLightEffects][RAW] \(payload)")
            case .failure(let error):
              nativeLog("[GMacro][fetchSupportedLightEffects][ERROR] \(error)")
            }
            callback(res)
          }
        }

      case Host4FlutterChannelConstants.fetchCurrentLightEffect:
        invoke(result) { callback in
          session.fetchCurrentLightEffect { res in
            switch res {
            case .success(let payload):
              nativeLog("[GMacro][fetchCurrentLightEffect][RAW] \(payload)")
            case .failure(let error):
              nativeLog("[GMacro][fetchCurrentLightEffect][ERROR] \(error)")
            }
            callback(res)
          }
        }

      case Host4FlutterChannelConstants.fetchCurrentLightConfig:
        invoke(result) { callback in
          session.fetchCurrentLightConfig { res in
            switch res {
            case .success(let payload):
              nativeLog("[GMacro][fetchCurrentLightConfig][RAW] \(payload)")
            case .failure(let error):
              nativeLog("[GMacro][fetchCurrentLightConfig][ERROR] \(error)")
            }
            callback(res)
          }
        }

      case Host4FlutterChannelConstants.fetchDeviceVersion:
        invoke(result) { callback in
          session.fetchDeviceVersion { res in
            switch res {
            case .success(var payload):
              // project/protocol/firmware/hardware 以十进制 int 返回，转为 hex 字符串再传给 Flutter
              if let project = payload["project"] as? Int {
                payload["project"] = String(format: "%06X", project)
              }
              if let proto = payload["protocol"] as? Int {
                payload["protocol"] = String(format: "%06X", proto)
              }
              if let firmware = payload["firmware"] as? Int {
                payload["firmware"] = String(format: "%08X", firmware)
              }
              if let hardware = payload["hardware"] as? Int {
                payload["hardware"] = String(format: "%06X", hardware)
              }
              callback(.success(payload))
            case .failure(let error):
              callback(.failure(error))
            }
          }
        }
      case Host4FlutterChannelConstants.fetchAppWakeKeyType:
        invoke(result) { callback in session.fetchAppWakeKeyType(callback) }
      case Host4FlutterChannelConstants.fetchGameMacroDefaultInfo:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.fetchGameMacroDefaultInfo(profile: profile) { res in
            switch res {
            case .success(var payload):
              callback(.success(gmacroConvertDeviceInfoEnums(payload)))
            case .failure(let error):
              callback(.failure(error))
            }
          }
        }
      case Host4FlutterChannelConstants.fetchMobapadDeviceInfo:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.fetchMobapadDeviceInfo(profile: profile) { res in
            switch res {
            case .success(var payload):
              callback(.success(gmacroConvertDeviceInfoEnums(payload)))
            case .failure(let error):
              callback(.failure(error))
            }
          }
        }
      case Host4FlutterChannelConstants.fetchPrintingType:
        invoke(result) { callback in session.fetchPrintingType(callback) }
      case Host4FlutterChannelConstants.resetDevice:
        invoke(result) { callback in session.resetDevice(callback) }
      case Host4FlutterChannelConstants.switchToNormalMode:
        invoke(result) { callback in session.switchToNormalMode(callback) }
      case Host4FlutterChannelConstants.switchToTestMode:
        invoke(result) { callback in session.switchToTestMode(callback) }
      case Host4FlutterChannelConstants.switchToConfigMode:
        invoke(result) { callback in session.switchToConfigMode(callback) }
      case Host4FlutterChannelConstants.updateReportRate:
        let rate = try intArg("rate", from: arguments)
        invoke(result) { callback in session.updateReportRate(rate, response: callback) }
      case Host4FlutterChannelConstants.fetchReportRate:
        invoke(result) { callback in session.fetchReportRate(response: callback) }
      case Host4FlutterChannelConstants.fetchSupportCalibration:
        invoke(result) { callback in session.fetchSupportCalibration(response: callback) }
      case Host4FlutterChannelConstants.fetchCalibrationKey:
        invoke(result) { callback in session.fetchCalibrationKey(response: callback) }
      case Host4FlutterChannelConstants.updateSwitchLayout:
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
      case Host4FlutterChannelConstants.querySupportedTurboKeys:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.querySupportedTurboKeys(profile: profile, response: callback)
        }
      case Host4FlutterChannelConstants.setSleepTime:
        let time = try intArg("time", from: arguments)
        invoke(result) { callback in session.setSleepTime(time: time, response: callback) }
      case Host4FlutterChannelConstants.getSleepTime:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in session.getSleepTime(profile: profile, response: callback) }
      case Host4FlutterChannelConstants.fetchCurrentProfile:
        invoke(result) { callback in session.fetchCurrentProfile(response: callback) }
      case Host4FlutterChannelConstants.startMacroPlatform:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in session.startMacroPlatform(profile: profile, response: callback) }
      case Host4FlutterChannelConstants.endMacroConfig:
        invoke(result) { callback in session.endMacroConfig(response: callback) }
      case Host4FlutterChannelConstants.queryCurrentMacro:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in session.queryCurrentMacro(profile: profile, response: callback) }
      case Host4FlutterChannelConstants.queryMacroKeys:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in session.queryMacroKeys(profile: profile, response: callback) }
      case Host4FlutterChannelConstants.queryMacroRecordableKeys:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.queryMacroRecordableKeys(profile: profile, response: callback)
        }
      case Host4FlutterChannelConstants.queryMacroTimeRange:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.queryMacroTimeRange(profile: profile, response: callback)
        }
      case Host4FlutterChannelConstants.queryMacroMaxGroups:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.queryMacroMaxGroups(profile: profile, response: callback)
        }
      case Host4FlutterChannelConstants.startRecord:
        invoke(result) { callback in session.startRecord(callback) }
      case Host4FlutterChannelConstants.endRecord:
        invoke(result) { callback in session.endRecord(callback) }
      case Host4FlutterChannelConstants.trigger:
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
      case Host4FlutterChannelConstants.triggerQuickSwitch:
        let leftOn = try boolArg("leftOn", from: arguments)
        let rightOn = try boolArg("rightOn", from: arguments)
        invoke(result) { callback in
          session.triggerQuickSwitch(leftOn: leftOn, rightOn: rightOn, response: callback)
        }
      case Host4FlutterChannelConstants.getTriggerQuickSwitch:
        invoke(result) { callback in session.getTriggerQuickSwitch(response: callback) }
      case Host4FlutterChannelConstants.startTriggerCalibration:
        invoke(result) { callback in session.startTriggerCalibration(callback) }
      case Host4FlutterChannelConstants.endTriggerCalibration:
        invoke(result) { callback in session.endTriggerCalibration(callback) }
      case Host4FlutterChannelConstants.triggerLinearOutput:
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
      case Host4FlutterChannelConstants.setVibrationLevel:
        let left = try intArg("left", from: arguments)
        let right = try intArg("right", from: arguments)
        invoke(result) { callback in
          session.setVibrationLevel(left: left, right: right, response: callback)
        }
      case Host4FlutterChannelConstants.testVibration:
        let left = try intArg("left", from: arguments)
        let right = try intArg("right", from: arguments)
        let position: VibrationPosition = try enumArg("position", from: arguments)
        invoke(result) { callback in
          session.testVibration(left: left, right: right, position: position, response: callback)
        }
      case Host4FlutterChannelConstants.queryMappableKeys:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in session.queryMappableKeys(profile: profile, response: callback) }
      case Host4FlutterChannelConstants.queryMappableGamepadKeys:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.queryMappableGamepadKeys(profile: profile, response: callback)
        }
      case Host4FlutterChannelConstants.queryCurrentMapping:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.queryCurrentMapping(profile: profile) { res in
            switch res {
            case .success(var payload):
              // SDK 返回的是 Swift 结构体数组，Flutter 方法通道无法序列化
              // 需要转为 [String: Any] 字典后再传给 Flutter
              if let gamepadMappings = payload["gamepadMappings"] as? [GamepadKeyMapping] {
                payload["gamepadMappings"] = gamepadMappings.map {
                  ["original": $0.original.rawValue, "mapped": $0.mapped.rawValue]
                }
              }
              if let mouseMappings = payload["mouseMappings"] as? [MouseKeyMapping] {
                payload["mouseMappings"] = mouseMappings.map {
                  ["original": $0.original.rawValue, "mapped": Int($0.mapped.rawValue)]
                }
              }
              if let keyboardMappings = payload["keyboardMappings"] as? [KeyboardKeyMapping] {
                payload["keyboardMappings"] = keyboardMappings.map {
                  ["original": $0.original.rawValue, "mapped": Int($0.mapped.rawValue)]
                }
              }
              // 重命名 gamepadMappings → keyMappings，与 setKeyMappings 输入参数名一致
              if let gamepad = payload.removeValue(forKey: "gamepadMappings") {
                payload["keyMappings"] = gamepad
              }
              callback(.success(payload))
            case .failure(let error):
              callback(.failure(error))
            }
          }
        }
      case Host4FlutterChannelConstants.updateRockerLinear:
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
      case Host4FlutterChannelConstants.rockerDeadZoneCompensation:
        let left = try intArg("left", from: arguments)
        let right = try intArg("right", from: arguments)
        invoke(result) { callback in
          session.rockerDeadZoneCompensation(left: left, right: right, response: callback)
        }
      case Host4FlutterChannelConstants.rockerDeadZoneRegressionComp:
        let left = try intArg("left", from: arguments)
        let right = try intArg("right", from: arguments)
        invoke(result) { callback in
          session.rockerDeadZoneRegressionComp(left: left, right: right, response: callback)
        }
      case Host4FlutterChannelConstants.rockerTriggerType:
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
      case Host4FlutterChannelConstants.rockerOutputGraphics:
        let left: OutputGraphics = try enumArg("left", from: arguments)
        let right: OutputGraphics = try enumArg("right", from: arguments)
        invoke(result) { callback in
          session.rockerOutputGraphics(left: left, right: right, response: callback)
        }
      case Host4FlutterChannelConstants.updateTriggerTestVibrationSwitch:
        let value = try boolArg("triggerTestVibration", from: arguments)
        invoke(result) { callback in
          session.updateTriggerTestVibrationSwitch(
            triggerTestVibration: value,
            response: callback
          )
        }
      case Host4FlutterChannelConstants.fetchTriggerTestVibrationSwitch:
        invoke(result) { callback in session.fetchTriggerTestVibrationSwitch(response: callback) }
      case Host4FlutterChannelConstants.updateTriggerVibration:
        let value = try boolArg("triggerVibration", from: arguments)
        invoke(result) { callback in
          session.updateTriggerVibration(triggerVibration: value, response: callback)
        }
      case Host4FlutterChannelConstants.fetchTriggerVibration:
        invoke(result) { callback in session.fetchTriggerVibration(response: callback) }
      case Host4FlutterChannelConstants.updateGyroXYRatio:
        let ratio = try intArg("gyroXYRatio", from: arguments)
        invoke(result) { callback in session.updategyroXYRatio(gyroXYRatio: ratio, response: callback) }
      case Host4FlutterChannelConstants.fetchGyroXYRatio:
        invoke(result) { callback in session.fetchgyroXYRatio(response: callback) }
      case Host4FlutterChannelConstants.updateGyroMappingType:
        let value: GyroMappingType = try enumArg("gyroMappingType", from: arguments)
        invoke(result) { callback in
          session.updateGyroMappingType(gyroMappingType: value, response: callback)
        }
      case Host4FlutterChannelConstants.fetchGyroMappingType:
        invoke(result) { callback in session.fetchGyroMappingType(response: callback) }
      case Host4FlutterChannelConstants.updateChargingDock:
        let value = try boolArg("isOn", from: arguments)
        invoke(result) { callback in session.updateChargingDock(isOn: value, response: callback) }
      case Host4FlutterChannelConstants.fetchChargingDock:
        invoke(result) { callback in session.fetchChargingDock(response: callback) }
      case Host4FlutterChannelConstants.startRockerCalibration:
        invoke(result) { callback in session.startRockerCalibration(callback) }
      case Host4FlutterChannelConstants.endRockerCalibration:
        invoke(result) { callback in session.endRockerCalibration(callback) }
      case Host4FlutterChannelConstants.updateRockerAdditional:
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
      case Host4FlutterChannelConstants.queryGyroTriggerKeys:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.queryGyroTriggerKeys(profile: profile, response: callback)
        }
      case Host4FlutterChannelConstants.queryGyroMappingModes:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.queryGyroMappingModes(profile: profile, response: callback)
        }
      case Host4FlutterChannelConstants.setMotion:
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
      case Host4FlutterChannelConstants.setMotionSecondary:
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
      case Host4FlutterChannelConstants.setMotionHorizontalAxis:
        let axis: GyroAxis = try enumArg("axis", from: arguments)
        invoke(result) { callback in session.setMotionHorizontalAxis(axis: axis, response: callback) }
      case Host4FlutterChannelConstants.fetchMotionHorizontalAxis:
        invoke(result) { callback in session.fetchMotionHorizontalAxis(callback) }
      case Host4FlutterChannelConstants.fetchGyroDeadZoneComp:
        invoke(result) { callback in session.fetchGyroDeadZoneComp(callback) }
      case Host4FlutterChannelConstants.fetchGyroSensitivityCurve:
        invoke(result) { callback in session.fetchGyroSensitivityCurve(callback) }
      case Host4FlutterChannelConstants.fetchGyroSensitivity2:
        invoke(result) { callback in session.fetchGyroSensitivity2(callback) }
      case Host4FlutterChannelConstants.setGyroXYInvert:
        let xOn = try boolArg("xOn", from: arguments)
        let yOn = try boolArg("yOn", from: arguments)
        invoke(result) { callback in session.setGyroXYInvert(xOn: xOn, yOn: yOn, response: callback) }
      case Host4FlutterChannelConstants.fetchGyroXYInvert:
        invoke(result) { callback in session.fetchGyroXYInvert(response: callback) }
      case Host4FlutterChannelConstants.setGyroDeadZone:
        let compensate = try intArg("compensate", from: arguments)
        invoke(result) { callback in session.setGyroDeadZone(compensate: compensate, response: callback) }
      case Host4FlutterChannelConstants.updateGyroOuterDeadZone:
        let gyroOuterDeadZone = try intArg("gyroOuterDeadZone", from: arguments)
        invoke(result) { callback in
          session.update(gyroOuterDeadZone: gyroOuterDeadZone, response: callback)
        }
      case Host4FlutterChannelConstants.fetchGyroOuterDeadZone:
        invoke(result) { callback in session.fetchGyroOuterDeadZone(response: callback) }
      case Host4FlutterChannelConstants.startGyroCalibration:
        invoke(result) { callback in session.startGyroCalibration(callback) }
      case Host4FlutterChannelConstants.endGyroCalibration:
        invoke(result) { callback in session.endGyroCalibration(callback) }
      case Host4FlutterChannelConstants.setLightConfig:
        let effect = try intArg("effect", from: arguments)
        let colorR = UInt8(try intArg("colorR", from: arguments))
        let colorG = UInt8(try intArg("colorG", from: arguments))
        let colorB = UInt8(try intArg("colorB", from: arguments))
        let light = try intArg("light", from: arguments)
        let speed = try intArg("speed", from: arguments)
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in
          session.setLightConfig(
            effect: effect,
            colorR: colorR,
            colorG: colorG,
            colorB: colorB,
            light: light,
            speed: speed,
            profile: profile,
            response: callback
          )
        }

      case Host4FlutterChannelConstants.setLightColor:
        let position: LightPosition = try enumArg("position", from: arguments)
        let groupCount = try intArg("groupCount", from: arguments)
        let colors = try rgbColorsArg("colors", from: arguments)
        invoke(result) { callback in
          session.setLightColor(
            position: position,
            groupCount: groupCount,
            colors: colors,
            response: callback
          )
        }

      case Host4FlutterChannelConstants.setLightEffect:
        let position: LightPosition = try enumArg("position", from: arguments)
        let groupCount = try intArg("groupCount", from: arguments)
        let isOn = try boolArg("isOn", from: arguments)
        let light = try intArg("light", from: arguments)
        let speed = try intArg("speed", from: arguments)
        let mode: LightMajorMode = try enumArg("mode", from: arguments)
        let subMode: LightSubMode = try enumArg("subMode", from: arguments)
        let colors = try rgbColorsArg("colors", from: arguments)
        invoke(result) { callback in
          session.setLightEffect(
            position: position,
            groupCount: groupCount,
            isOn: isOn,
            light: light,
            speed: speed,
            mode: mode,
            subMode: subMode,
            colors: colors,
            response: callback
          )
        }

      case Host4FlutterChannelConstants.leftTriggerCurve:
        let cgPoints = try cgPointsArg("cgPoints", from: arguments)
        invoke(result) { callback in
          session.leftTriggerCurve(cgPoints: cgPoints, response: callback)
        }

      case Host4FlutterChannelConstants.rightTriggerCurve:
        let cgPoints = try cgPointsArg("cgPoints", from: arguments)
        invoke(result) { callback in
          session.rightTriggerCurve(cgPoints: cgPoints, response: callback)
        }

      case Host4FlutterChannelConstants.updateLeftRocker3DCurve:
        let cgPoints = try cgPointsArg("cgPoints", from: arguments)
        invoke(result) { callback in
          session.updateLeftRocker3DCurve(cgPoints: cgPoints, response: callback)
        }

      case Host4FlutterChannelConstants.updateRightRocker3DCurve:
        let cgPoints = try cgPointsArg("cgPoints", from: arguments)
        invoke(result) { callback in
          session.updateRightRocker3DCurve(cgPoints: cgPoints, response: callback)
        }

      case Host4FlutterChannelConstants.setMacroKeys:
        let macroKey = try macroKeyArg("macroKey", from: arguments)
        invoke(result) { callback in
          session.setMacroKeys(macroKey, response: callback)
        }

      case Host4FlutterChannelConstants.setMacroInterval:
        let profile = try intArg("profile", from: arguments)
        let key: GamepadKey = try enumArg("key", from: arguments)
        let intervalTime = try intArg("intervalTime", from: arguments)
        invoke(result) { callback in
          session.setMacroInterval(
            profile: profile,
            key: key,
            intervalTime: intervalTime,
            response: callback
          )
        }

      case Host4FlutterChannelConstants.setGyroSensitivityCurve:
        let x1 = try intArg("x1", from: arguments)
        let y1 = try intArg("y1", from: arguments)
        let x2 = try intArg("x2", from: arguments)
        let y2 = try intArg("y2", from: arguments)
        let x3 = try intArg("x3", from: arguments)
        let y3 = try intArg("y3", from: arguments)
        invoke(result) { callback in
          session.setGyroSensitivityCurve(
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            x3: x3,
            y3: y3,
            response: callback
          )
        }

      case Host4FlutterChannelConstants.setKeyMappings:
        let keyMappings = try gamepadKeyMappingsArg("keyMappings", from: arguments)
        invoke(result) { callback in
          session.setKeyMappings(keyMappings, response: callback)
        }

      case Host4FlutterChannelConstants.setHandleKeyMapping:
        let original = GamepadKey(rawValue: try intArg("original", from: arguments)) ?? .none
        let mapped = GamepadKey(rawValue: try intArg("mapped", from: arguments)) ?? .none
        invoke(result) { callback in
          session.setHandleKeyMapping(original: original, mapped: mapped, response: callback)
        }
      case Host4FlutterChannelConstants.setMouseKeyMappings:
        let keyMappings = try mouseKeyMappingsArg("keyMappings", from: arguments)
        invoke(result) { callback in
          session.setMouseKeyMappings(keyMappings, response: callback)
        }

      case Host4FlutterChannelConstants.setKeyboardKeyMappings:
        let keyMappings = try keyboardKeyMappingsArg("keyMappings", from: arguments)
        invoke(result) { callback in
          session.setKeyboardKeyMappings(keyMappings, response: callback)
        }

      case Host4FlutterChannelConstants.setMultiKeyMapping:
        let original: GamepadKey = try enumArg("original", from: arguments)
        let mappedKeys = try mappedKeysArg("mappedKeys", from: arguments)
        invoke(result) { callback in
          session.setMultiKeyMapping(
            original: original,
            mappedKeys: mappedKeys,
            response: callback
          )
        }

      case Host4FlutterChannelConstants.queryAllMultiMappings:
        invoke(result) { callback in
          session.queryAllMultiMappings(response: callback)
        }

      case Host4FlutterChannelConstants.queryMultiMapping:
        let original: GamepadKey = try enumArg("original", from: arguments)
        invoke(result) { callback in
          session.queryMultiMapping(for: original, response: callback)
        }

      case Host4FlutterChannelConstants.setTurboDatas:
        let values = try turboTuplesArg("keyTurbos", from: arguments)
        invoke(result) { callback in
          session.updateKeyTurbo(values, response: callback)
        }
      case Host4FlutterChannelConstants.startOta:
        let firmwareData = (arguments["data"] as? FlutterStandardTypedData)?.data ?? Data()
        nativeLog("[OTA] startOTA called, firmware=\(firmwareData.count) bytes, commandWriter=\(session.otaCommandWriter != nil), dataWriter=\(session.otaDataWriter != nil)")
        startOta(protocolRecord: protocolRecord, data: firmwareData)
        nativeLog("[OTA] startOTA dispatched")
        result([:] as [String: Any])

      // MARK: - Other / handle control
      case Host4FlutterChannelConstants.queryVibrateOpen:
        invoke(result) { callback in session.fetchMotorSwitchState(response: callback) }
      case Host4FlutterChannelConstants.switchVibrateOpen:
        let status = try intArg("status", from: arguments)
        invoke(result) { callback in session.updateMotorSwitchState(isOn: status == 1, response: callback) }
      case Host4FlutterChannelConstants.queryWorkStyle:
        invoke(result) { callback in session.fetchHandleWorkMode(response: callback) }
      case Host4FlutterChannelConstants.switchWorkStyle:
        let mode = try intArg("mode", from: arguments)
        invoke(result) { callback in session.updateHandleWorkMode(mode: mode, response: callback) }
      case Host4FlutterChannelConstants.queryOutputMode:
        invoke(result) { callback in session.fetchCurrentHandleMode(response: callback) }
      case Host4FlutterChannelConstants.switchOutputMode:
        let mode = try intArg("mode", from: arguments)
        invoke(result) { callback in session.updateCurrentHandleMode(mode: mode, response: callback) }
      case Host4FlutterChannelConstants.sendHandleBeta:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in session.switchToTestProfile(profile: profile, response: callback) }
      case Host4FlutterChannelConstants.switchHandleConfig:
        let profile = try intArg("profile", from: arguments)
        invoke(result) { callback in session.switchToProfile(profile: profile, response: callback) }
      case Host4FlutterChannelConstants.updateHandleFunction:
        let handleOn = try boolArg("handleOn", from: arguments)
        let ep3CallbackOn = try boolArg("ep3CallbackOn", from: arguments)
        invoke(result) { callback in session.updateHandleFunction(handleOn: handleOn, ep3CallbackOn: ep3CallbackOn, response: callback) }
      case Host4FlutterChannelConstants.switchHandleCallbacks:
        let method = try intArg("method", from: arguments)
        let handleOn = method != 0
        let ep3CallbackOn = method == 2
        invoke(result) { callback in session.updateHandleFunction(handleOn: handleOn, ep3CallbackOn: ep3CallbackOn, response: callback) }
      case Host4FlutterChannelConstants.queryLinerTrigger:
        invoke(result) { callback in session.fetchTriggerLinearOutput(response: callback) }
      case Host4FlutterChannelConstants.switchLinerTrigger:
        let mode = try intArg("mode", from: arguments)
        // mode: 1=线性输出, 2=非线性输出
        // threshold 必须 >= 1，SDK 校验 1-255，传 0 会返回 outOfRange
        let threshold = mode == 1 ? 1 : 128
        invoke(result) { callback in
          session.triggerLinearOutput(leftMode: mode, leftThreshold: threshold, rightMode: mode, rightThreshold: threshold, response: callback)
        }

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
    body: (@escaping @Sendable (Result<[String: Any], Error>) -> Void) throws -> Void
  ) {
    do {
      try body { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let payload):
            // flutterResult(payload)

            nativeLog("[GMacro][RAW] \(payload)")
            let serialized = Host4FlutterBridgeSerializer.payload(payload)
            nativeLog("[GMacro][SERIALIZED] \(serialized)")
            flutterResult(serialized)

            // flutterResult(Host4FlutterBridgeSerializer.payload(payload))
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
    @unknown default:
      return [
        "type": "error",
        "failure": failureMap(
          code: "unknown-transport-state",
          message: "BLE transport reported an unknown state."
        ),
      ]
    }
  }

  private func emitGMacroEvent(
    _ event: GMacroProtocolEvent,
    protocolEventHandler: QueuedEventStreamHandler,
    otaEventHandler: QueuedEventStreamHandler
  ) {
    protocolEventHandler.emit(protocolEventMap(from: event))
    if let otaEvent = otaEventMap(from: event) {
      otaEventHandler.emit(otaEvent)
    }
  }

  private func protocolEventMap(from event: GMacroProtocolEvent) -> [String: Any] {
    switch event {
    case .ota(let type, let code, let progress, let total, let percent):
      let typeName = "\(type)"
      return [
        "type": "busy",
        "reason": typeName,
        "payload": [
          "event": typeName,
          "type": typeName,
          "code": code,
          "progress": progress,
          "total": total,
          "percent": Double(percent),
        ],
      ]
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
      print("[Native] [GMacro] calibrationFinished event type=\(type) subId=\(subId) result=\(result) param1=\(param1) param2=\(param2)")
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
    @unknown default:
      return [
        "type": "error",
        "failure": failureMap(
          code: "unknown-gmacro-event",
          message: "GMacro protocol emitted an unknown event."
        ),
      ]
    }
  }

  private func otaEventMap(from event: GMacroProtocolEvent) -> [String: Any]? {
    switch event {
    case .ota(let type, let code, let progress, let total, let percent):
      return [
        "type": "\(type)",
        "code": code,
        "progress": progress,
        "total": total,
        "percent": Double(percent),
      ]
    default:
      return nil
    }
  }

  private func startOta(protocolRecord: GMacroProtocolRecord, data: Data) {
    nativeLog("[BLE OTA] startOTA dispatched")
    protocolRecord.session.startOTA(data: data)
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

  private func dictArg(_ key: String, from arguments: [String: Any]) throws -> [String: Any] {
  guard let value = arguments[key] as? [String: Any] else {
    throw BridgeArgumentError.missing(key: key, expected: "[String: Any]")
  }
  return value
}

  private func dictArrayArg(_ key: String, from arguments: [String: Any]) throws -> [[String: Any]] {
    guard let value = arguments[key] as? [[String: Any]] else {
      throw BridgeArgumentError.missing(key: key, expected: "[[String: Any]]")
    }
    return value
  }

  private func cgPointsArg(_ key: String, from arguments: [String: Any]) throws -> [CGPoint] {
    try dictArrayArg(key, from: arguments).map { item in
      guard let x = item["x"] as? Double, let y = item["y"] as? Double else {
        throw BridgeArgumentError.missing(key: key, expected: "CGPoint(x, y)")
      }
      return CGPoint(x: x, y: y)
    }
  }

  private func rgbColorsArg(
    _ key: String,
    from arguments: [String: Any]
  ) throws -> [(red: UInt8, green: UInt8, blue: UInt8)] {
    try dictArrayArg(key, from: arguments).map { item in
      let red = try intArg("red", from: item)
      let green = try intArg("green", from: item)
      let blue = try intArg("blue", from: item)
      return (red: UInt8(red), green: UInt8(green), blue: UInt8(blue))
    }
  }

  private func gamepadKeysArg(_ key: String, from arguments: [String: Any]) throws -> [GamepadKey] {
    guard let values = arguments[key] as? [Int] else {
      throw BridgeArgumentError.missing(key: key, expected: "[Int]")
    }
    return try values.map { rawValue in
      guard let gamepadKey = GamepadKey(rawValue: rawValue) else {
        throw BridgeArgumentError.invalidEnum(key: key)
      }
      return gamepadKey
    }
  }

  private func macroComkeysArg(_ key: String, from arguments: [String: Any]) throws -> [MacroComkey] {
    try dictArrayArg(key, from: arguments).map { item in
      let keys = try gamepadKeysArg("keys", from: item)
      let keepTime = (item["keepTime"] as? Int) ?? 100
      let intervalTime = (item["intervalTime"] as? Int) ?? 0
      return MacroComkey(keys: keys, keepTime: keepTime, intervalTime: intervalTime)
    }
  }

  private func macroKeyArg(_ key: String, from arguments: [String: Any]) throws -> MacroKey {
    let item = try dictArg(key, from: arguments)
    let value: GamepadKey = try enumArg("value", from: item)
    let cycle: CycleMode = try enumArg("cycle", from: item)
    let intervalTime = try intArg("intervalTime", from: item)
    let comKeys = try macroComkeysArg("comKeys", from: item)
    return MacroKey(value: value, cycle: cycle, intervalTime: intervalTime, comKeys: comKeys)
  }

  private func gamepadKeyMappingsArg(
    _ key: String,
    from arguments: [String: Any]
  ) throws -> [GamepadKeyMapping] {
    try dictArrayArg(key, from: arguments).map { item in
      let original: GamepadKey = try enumArg("original", from: item)
      let mapped: GamepadKey = try enumArg("mapped", from: item)
      return GamepadKeyMapping(original: original, mapped: mapped)
    }
  }

  private func mouseKeyMappingsArg(
    _ key: String,
    from arguments: [String: Any]
  ) throws -> [MouseKeyMapping] {
    try dictArrayArg(key, from: arguments).map { item in
      let original: GamepadKey = try enumArg("original", from: item)
      let mapped: MouseKey = try enumArg("mapped", from: item)
      return MouseKeyMapping(original: original, mapped: mapped)
    }
  }

  private func keyboardKeyMappingsArg(
    _ key: String,
    from arguments: [String: Any]
  ) throws -> [KeyboardKeyMapping] {
    try dictArrayArg(key, from: arguments).map { item in
      let original: GamepadKey = try enumArg("original", from: item)
      let mapped: KeyboardKey = try enumArg("mapped", from: item)
      return KeyboardKeyMapping(original: original, mapped: mapped)
    }
  }

  private func mappedKeysArg(_ key: String, from arguments: [String: Any]) throws -> [MappedKey] {
    try dictArrayArg(key, from: arguments).map { item in
      let type = try intArg("type", from: item)

      guard let values = item["values"] as? [Int] else {
        throw BridgeArgumentError.missing(key: "values", expected: "[Int]")
      }

      switch type {
      case 0:
        let gamepadKeys = try values.map { rawValue in
          guard let gamepadKey = GamepadKey(rawValue: rawValue) else {
            throw BridgeArgumentError.invalidEnum(key: "values")
          }
          return gamepadKey
        }
        return .gamepad(gamepadKeys)

      case 1:
        let mouseKeys = try values.map { rawValue in
          guard let uint8Value = UInt8(exactly: rawValue),
                let mouseKey = MouseKey(rawValue: uint8Value) else {
            throw BridgeArgumentError.invalidEnum(key: "values")
          }
          return mouseKey
        }
        return .mouse(mouseKeys)

      case 2:
        let keyboardKeys = try values.map { rawValue in
          guard let uint8Value = UInt8(exactly: rawValue),
                let keyboardKey = KeyboardKey(rawValue: uint8Value) else {
            throw BridgeArgumentError.invalidEnum(key: "values")
          }
          return keyboardKey
        }
        return .keyboard(keyboardKeys)

      default:
        throw BridgeArgumentError.invalidEnum(key: "type")
      }
    }
  }

  private func turboTuplesArg(
    _ key: String,
    from arguments: [String: Any]
  ) throws -> [(GamepadKey, TurboMode, Int)] {
    try dictArrayArg(key, from: arguments).map { item in
      let gamepadKey: GamepadKey = try enumArg("key", from: item)
      let turbo: TurboMode = try enumArg("turbo", from: item)
      let speed = try intArg("speed", from: item)
      return (gamepadKey, turbo, speed)
    }
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

  private func mfiUnsupportedError(method: String) -> FlutterError {
    flutterError(
      code: "mfi-unsupported",
      message: "MFi transport is not available in this build.",
      details: ["method": method]
    )
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

/// 将 0x77 设备信息响应中的 Swift 枚举转为 Int rawValue，便于 Flutter 方法通道序列化
private func gmacroConvertDeviceInfoEnums(_ payload: [String: Any]) -> [String: Any] {
  var result = payload

  // rapidList: key(GamepadKey), mode(TurboMode) → rawValue
  if let rapidList = result["rapidList"] as? [[String: Any]] {
    result["rapidList"] = rapidList.map { item in
      var m = item
      if let key = m["key"] as? GamepadKey { m["key"] = key.rawValue }
      if let mode = m["mode"] as? TurboMode { m["mode"] = Int(mode.rawValue) }
      // 兼容旧字段名 turbo
      if let turbo = m["turbo"] as? TurboMode { m["mode"] = Int(turbo.rawValue); m.removeValue(forKey: "turbo") }
      return m
    }
  }

  return result
}
#endif
