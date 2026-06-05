import Flutter
import UIKit

public class Host4FlutterAiVoicePlugin: NSObject, FlutterPlugin {
  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?
  private var eventSink: FlutterEventSink?
  private var aiVoiceManager: AiVoiceManager?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = Host4FlutterAiVoicePlugin()

    let methodChannel = FlutterMethodChannel(
      name: "host4_flutter_aivoice",
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: "host4_flutter_aivoice_events",
      binaryMessenger: registrar.messenger()
    )

    instance.methodChannel = methodChannel
    instance.eventChannel = eventChannel

    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "buildEngine":
      guard let args = call.arguments as? [String: Any],
            let roomId = args["roomId"] as? String,
            let userId = args["userId"] as? String
      else {
        result(FlutterError(code: "invalid_args", message: "Missing roomId/userId", details: nil))
        return
      }
      let manager = AiVoiceManager(roomId: roomId, userId: userId)
      manager.eventCallback = { [weak self] event in
        self?.eventSink?(event)
      }
      self.aiVoiceManager = manager
      manager.buildEngineAndJoin()
      result(true)

    case "rejoinRoom":
      aiVoiceManager?.reJoinRoom()
      result(true)

    case "startTalk":
      aiVoiceManager?.startTalk()
      result(true)

    case "stopTalk":
      aiVoiceManager?.stopTalk()
      result(true)

    case "setVolume":
      guard let args = call.arguments as? [String: Any],
            let level = args["level"] as? Int
      else {
        result(FlutterError(code: "invalid_args", message: "Missing level", details: nil))
        return
      }
      aiVoiceManager?.setVolume(level)
      result(nil)

    case "destroy":
      aiVoiceManager?.destroy()
      aiVoiceManager = nil
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

extension Host4FlutterAiVoicePlugin: FlutterStreamHandler {
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
