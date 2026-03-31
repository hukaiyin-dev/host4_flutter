import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate {
  private let logShareChannelName = "host4_flutter_demo/log_share"
  private let usbDriveChannelName = "host4_flutter_demo/usb_drive"
  private var usbDriveResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: logShareChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "shareText" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let args = call.arguments as? [String: Any],
        let text = args["text"] as? String,
        !text.isEmpty
      else {
        result(
          FlutterError(
            code: "invalid_args",
            message: "Non-empty text is required.",
            details: nil
          )
        )
        return
      }

      let subject = args["subject"] as? String
      self?.presentLogShareSheet(text: text, subject: subject, result: result)
    }

    let usbDriveChannel = FlutterMethodChannel(
      name: usbDriveChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    usbDriveChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "pickDocument" else {
        result(FlutterMethodNotImplemented)
        return
      }

      self?.presentDocumentPicker(result: result)
    }
  }

  private func presentLogShareSheet(
    text: String,
    subject: String?,
    result: @escaping FlutterResult
  ) {
    DispatchQueue.main.async {
      guard let rootViewController = self.topViewController() else {
        result(
          FlutterError(
            code: "no_view_controller",
            message: "No view controller available for sharing.",
            details: nil
          )
        )
        return
      }

      let activityViewController = UIActivityViewController(
        activityItems: [text],
        applicationActivities: nil
      )

      if let subject, !subject.isEmpty {
        activityViewController.setValue(subject, forKey: "subject")
      }

      if let popover = activityViewController.popoverPresentationController {
        popover.sourceView = rootViewController.view
        popover.sourceRect = CGRect(
          x: rootViewController.view.bounds.midX,
          y: rootViewController.view.bounds.maxY - 1,
          width: 1,
          height: 1
        )
        popover.permittedArrowDirections = []
      }

      rootViewController.present(activityViewController, animated: true) {
        result(nil)
      }
    }
  }

  private func topViewController(
    base: UIViewController? = nil
  ) -> UIViewController? {
    let root = base ?? connectedRootViewController()

    if let navigationController = root as? UINavigationController {
      return topViewController(base: navigationController.visibleViewController)
    }

    if let tabBarController = root as? UITabBarController {
      return topViewController(base: tabBarController.selectedViewController)
    }

    if let presented = root?.presentedViewController {
      return topViewController(base: presented)
    }

    return root
  }

  private func connectedRootViewController() -> UIViewController? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .rootViewController
  }

  private func presentDocumentPicker(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      guard self.usbDriveResult == nil else {
        result(
          FlutterError(
            code: "busy",
            message: "A document picker is already active.",
            details: nil
          )
        )
        return
      }

      guard let rootViewController = self.topViewController() else {
        result(
          FlutterError(
            code: "no_view_controller",
            message: "No view controller available for document picking.",
            details: nil
          )
        )
        return
      }

      self.usbDriveResult = result

      let picker = UIDocumentPickerViewController(
        forOpeningContentTypes: [UTType.data],
        asCopy: false
      )
      picker.delegate = self
      picker.allowsMultipleSelection = false
      rootViewController.present(picker, animated: true)
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let result = usbDriveResult
    usbDriveResult = nil
    result?(
      FlutterError(
        code: "cancelled",
        message: "Document picking was cancelled.",
        details: nil
      )
    )
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    let result = usbDriveResult
    usbDriveResult = nil

    guard let url = urls.first else {
      result?(
        FlutterError(
          code: "empty_selection",
          message: "No document was selected.",
          details: nil
        )
      )
      return
    }

    let hasAccess = url.startAccessingSecurityScopedResource()
    defer {
      if hasAccess {
        url.stopAccessingSecurityScopedResource()
      }
    }

    do {
      let values = try url.resourceValues(forKeys: [.fileSizeKey, .nameKey])
      let data = try Data(contentsOf: url)
      let previewData = data.prefix(8192)
      let previewText =
        String(data: previewData, encoding: .utf8) ??
        String(data: previewData, encoding: .unicode) ??
        "[Binary or unsupported text encoding]"

      result?([
        "name": values.name ?? url.lastPathComponent,
        "size": values.fileSize ?? data.count,
        "path": url.path,
        "preview": previewText,
      ])
    } catch {
      result?(
        FlutterError(
          code: "read_failed",
          message: "Failed to read selected file.",
          details: error.localizedDescription
        )
      )
    }
  }
}
