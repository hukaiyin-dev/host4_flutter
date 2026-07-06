import Flutter
import UIKit

/// Flutter AI Voice 插件入口
/// 只暴露两个接口：showAI / hideAI，所有逻辑由 Native 端处理

// MARK: - 全局资源加载工具
/// 使用 s.resources 后图片在主 bundle 中，直接 UIImage(named:) 即可
public class Host4FlutterAiVoicePlugin: NSObject, FlutterPlugin {
  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?
  private var eventSink: FlutterEventSink?

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
    case "showAI":
      guard let args = call.arguments as? [String: Any],
            let boostingTableID = args["boostingTableID"] as? String,
            !boostingTableID.isEmpty
      else {
        result(FlutterError(code: "invalid_args", message: "Missing boostingTableID", details: nil))
        return
      }
      AiVoiceManager.shared.boostingTableID = boostingTableID
      AiVoiceManager.shared.eventCallback = { [weak self] event in
        self?.eventSink?(event)
      }
      if let language = args["language"] as? String, !language.isEmpty {
        AiVoiceManager.shared.language = language
      }
      AiViewManager.shared.showFloatWindow(true)
      result(true)

    case "hideAI":
      AiVoiceManager.shared.vipMethodChannel = nil
      AiViewManager.shared.showFloatWindow(false)
      result(true)

    case "registerVip":
      AiVoiceManager.shared.vipMethodChannel = methodChannel
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
