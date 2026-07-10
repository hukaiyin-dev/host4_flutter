import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate {
  private let logShareChannelName = "host4_flutter_demo/log_share"
  private let usbDriveChannelName = "host4_flutter_demo/usb_drive"
  private let iosTfCardChannelName = "host4_flutter_demo/ios_tf_card"
  private let iosTfCardBookmarkStore = IosTfCardBookmarkStore()

  private enum DocumentPickerPurpose {
    case usbDrive
    case iosTfCard
  }

  private var usbDriveResult: FlutterResult?
  private var iosTfCardResult: FlutterResult?
  private var documentPickerPurpose: DocumentPickerPurpose?

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

    let iosTfCardChannel = FlutterMethodChannel(
      name: iosTfCardChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    iosTfCardChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "scanRoms" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let args = call.arguments as? [String: Any]
      let forcePick = args?["forcePick"] as? Bool ?? false
      self?.scanLastTfCardOrPresentPicker(forcePick: forcePick, result: result)
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
      guard self.documentPickerPurpose == nil else {
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
      self.documentPickerPurpose = .usbDrive

      let picker = UIDocumentPickerViewController(
        forOpeningContentTypes: [UTType.data],
        asCopy: false
      )
      picker.delegate = self
      picker.allowsMultipleSelection = false
      rootViewController.present(picker, animated: true)
    }
  }

  private func scanLastTfCardOrPresentPicker(
    forcePick: Bool,
    result: @escaping FlutterResult
  ) {
    if !forcePick, let bookmark = iosTfCardBookmarkStore.resolve() {
      let hasAccess = bookmark.url.startAccessingSecurityScopedResource()
      defer {
        if hasAccess {
          bookmark.url.stopAccessingSecurityScopedResource()
        }
      }
      guard hasAccess else {
        iosTfCardBookmarkStore.clear()
        presentTfCardDirectoryPicker(result: result)
        return
      }

      do {
        let scanner = IosTfCardRomScanner()
        let scanResult = try scanner.scan(selectedURL: bookmark.url)
        if bookmark.isStale {
          try? iosTfCardBookmarkStore.save(url: bookmark.url)
        }
        result(scanResult)
        return
      } catch {
        iosTfCardBookmarkStore.clear()
      }
    }

    presentTfCardDirectoryPicker(result: result)
  }

  private func presentTfCardDirectoryPicker(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      guard self.documentPickerPurpose == nil else {
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
            message: "No view controller available for TF card picking.",
            details: nil
          )
        )
        return
      }

      self.iosTfCardResult = result
      self.documentPickerPurpose = .iosTfCard

      let picker = UIDocumentPickerViewController(
        forOpeningContentTypes: [UTType.folder],
        asCopy: false
      )
      if let lastURL = self.iosTfCardBookmarkStore.resolveWithoutSecurityScope() {
        picker.directoryURL = lastURL
      }
      picker.delegate = self
      picker.allowsMultipleSelection = false
      rootViewController.present(picker, animated: true)
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let result = pendingDocumentPickerResult()
    clearDocumentPickerState()
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
    let purpose = documentPickerPurpose
    let result = pendingDocumentPickerResult()
    clearDocumentPickerState()

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

    switch purpose {
    case .usbDrive:
      readPickedDocument(url: url, result: result)
    case .iosTfCard:
      scanPickedTfCardDirectory(url: url, result: result)
    case nil:
      result?(FlutterMethodNotImplemented)
    }
  }

  private func pendingDocumentPickerResult() -> FlutterResult? {
    switch documentPickerPurpose {
    case .usbDrive:
      return usbDriveResult
    case .iosTfCard:
      return iosTfCardResult
    case nil:
      return nil
    }
  }

  private func clearDocumentPickerState() {
    usbDriveResult = nil
    iosTfCardResult = nil
    documentPickerPurpose = nil
  }

  private func readPickedDocument(url: URL, result: FlutterResult?) {
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

  private func scanPickedTfCardDirectory(url: URL, result: FlutterResult?) {
    let hasAccess = url.startAccessingSecurityScopedResource()
    defer {
      if hasAccess {
        url.stopAccessingSecurityScopedResource()
      }
    }

    do {
      let scanner = IosTfCardRomScanner()
      let scanResult = try scanner.scan(selectedURL: url)
      try? iosTfCardBookmarkStore.save(url: url)
      result?(scanResult)
    } catch let error as IosTfCardScanError {
      result?(
        FlutterError(
          code: error.code,
          message: error.message,
          details: nil
        )
      )
    } catch {
      result?(
        FlutterError(
          code: "scan_failed",
          message: "Failed to scan TF card.",
          details: error.localizedDescription
        )
      )
    }
  }
}

private struct IosTfCardScanError: Error {
  let code: String
  let message: String
}

private struct IosTfCardGameType {
  let name: String
  let fullName: String
  let directory: String
  let extensions: Set<String>
}

private struct IosTfCardGameMetadata {
  let path: String
  let name: String
  let image: String?
  let video: String?
  let desc: String?
}

private final class IosTfCardBookmarkStore {
  private let dataKey = "host4_flutter_demo.ios_tf_card.bookmark_data"
  private let pathKey = "host4_flutter_demo.ios_tf_card.last_path"
  private let defaults = UserDefaults.standard

  struct ResolvedBookmark {
    let url: URL
    let isStale: Bool
  }

  func save(url: URL) throws {
    let data = try url.bookmarkData(
      options: [],
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    )
    defaults.set(data, forKey: dataKey)
    defaults.set(url.path, forKey: pathKey)
  }

  func resolve() -> ResolvedBookmark? {
    guard let data = defaults.data(forKey: dataKey) else {
      return nil
    }

    do {
      var isStale = false
      let url = try URL(
        resolvingBookmarkData: data,
        options: [],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
      return ResolvedBookmark(url: url, isStale: isStale)
    } catch {
      clear()
      return nil
    }
  }

  func resolveWithoutSecurityScope() -> URL? {
    if let bookmark = resolve() {
      return bookmark.url
    }
    guard let path = defaults.string(forKey: pathKey), !path.isEmpty else {
      return nil
    }
    return URL(fileURLWithPath: path)
  }

  func clear() {
    defaults.removeObject(forKey: dataKey)
    defaults.removeObject(forKey: pathKey)
  }
}

private final class IosTfCardRomScanner {
  private let fileManager = FileManager.default

  private let gameTypes: [IosTfCardGameType] = [
    .init(name: "NES", fullName: "Nintendo Entertainment System", directory: "nes", extensions: [".bin", ".fds", ".nes", ".nsf", ".qd", ".rom", ".unif", ".unf", ".zip", ".7z"]),
    .init(name: "SMS", fullName: "Master System", directory: "mastersystem", extensions: [".bin", ".sms", ".zip", ".7z"]),
    .init(name: "PCE", fullName: "PC Engine", directory: "pcengine", extensions: [".7z", ".ccd", ".chd", ".cue", ".pce", ".zip", ".bin"]),
    .init(name: "CPS1", fullName: "CPS-I", directory: "cps1", extensions: [".zip", ".7z"]),
    .init(name: "MD", fullName: "Mega Drive", directory: "megadrive", extensions: [".bin", ".gen", ".md", ".sg", ".smd", ".zip", ".7z"]),
    .init(name: "GB", fullName: "Game Boy", directory: "gb", extensions: [".gb", ".gbc", ".zip", ".7z"]),
    .init(name: "NEO", fullName: "Neo Geo", directory: "neogeo", extensions: [".7z", ".zip"]),
    .init(name: "SNES", fullName: "Super Nintendo", directory: "snes", extensions: [".smc", ".fig", ".sfc", ".swc", ".zip", ".7z"]),
    .init(name: "CPS2", fullName: "CPS-II", directory: "cps2", extensions: [".zip", ".7z"]),
    .init(name: "PSX", fullName: "PlayStation", directory: "psx", extensions: [".bin", ".cue", ".img", ".mdf", ".pbp", ".toc", ".cbn", ".m3u", ".ccd", ".chd", ".iso"]),
    .init(name: "SS", fullName: "SEGA SATURN", directory: "saturn", extensions: [".zip", ".cue", ".bin", ".iso", ".mds", ".ccd", ".chd", ".toc", ".m3u"]),
    .init(name: "N64", fullName: "Nintendo 64", directory: "n64", extensions: [".z64", ".n64", ".v64", ".zip", ".7z"]),
    .init(name: "CPS3", fullName: "CPS-III", directory: "cps3", extensions: [".zip", ".7z"]),
    .init(name: "MAME", fullName: "MAME", directory: "mame", extensions: [".7z", ".zip", ".chd", ".cmd"]),
    .init(name: "GBC", fullName: "Game Boy Color", directory: "gbc", extensions: [".gb", ".gbc", ".zip", ".7z"]),
    .init(name: "DC", fullName: "Dreamcast", directory: "dreamcast", extensions: [".cdi", ".gdi", ".chd", ".m3u", ".cue"]),
    .init(name: "NGP", fullName: "Neo Geo Pocket", directory: "ngp", extensions: [".ngp", ".ngc", ".zip", ".7z"]),
    .init(name: "NAOMI", fullName: "New Arcade Operation Machine Idea", directory: "naomi", extensions: [".lst", ".bin", ".dat", ".zip", ".7z"]),
    .init(name: "WSC", fullName: "Wonderswan", directory: "wonderswancolor", extensions: [".ws", ".wsc", ".zip", ".7z"]),
    .init(name: "PS2", fullName: "PlayStation 2", directory: "ps2", extensions: [".bin", ".iso", ".chd", ".cso", ".cue", ".elf", ".isz", ".img", ".ciso", ".nrg", ".mdf", ".m3u", ".gz", ".dump"]),
    .init(name: "FBN", fullName: "Final Burn Neo", directory: "fbneo", extensions: [".7z", ".zip"]),
    .init(name: "GBA", fullName: "Game Boy Advance", directory: "gba", extensions: [".gba", ".zip", ".7z"]),
    .init(name: "ATOM", fullName: "Atomiswave", directory: "atomiswave", extensions: [".lst", ".bin", ".dat", ".zip", ".7z"]),
    .init(name: "PSP", fullName: "PlayStation Portable", directory: "psp", extensions: [".iso", ".cso", ".pbp", ".chd"]),
    .init(name: "NDS", fullName: "Nintendo DS", directory: "nds", extensions: [".nds", ".zip", ".7z"]),
    .init(name: "WII", fullName: "Nintendo Wii", directory: "wii", extensions: [".ciso", ".dff", ".dol", ".elf", ".gcm", ".gcz", ".iso", ".m3u", ".rvz", ".tgc", ".wad", ".wbfs", ".wia"]),
    .init(name: "PS1", fullName: "PlayStation 1", directory: "ps1", extensions: [".chd", ".cue", ".cbn", ".img", ".iso", ".m3u", ".mdf", ".pbp", ".toc", ".z", ".znx", ".bin"]),
  ]

  func scan(selectedURL: URL) throws -> [String: Any] {
    let selectedDirectory = try directoryURL(from: selectedURL)
    let romsURL = try findRomsDirectory(from: selectedDirectory)
    let rootURL = romsURL.deletingLastPathComponent()

    var platforms: [[String: Any]] = []
    var games: [[String: Any]] = []

    for gameType in gameTypes {
      let platformURL = romsURL.appendingPathComponent(gameType.directory, isDirectory: true)
      guard isDirectory(platformURL) else {
        continue
      }

      let platformGames = try scanPlatform(gameType: gameType, platformURL: platformURL)
      guard !platformGames.isEmpty else {
        continue
      }

      platforms.append([
        "name": gameType.directory,
        "fullName": gameType.fullName,
        "directory": platformURL.path,
        "gameCount": platformGames.count,
      ])
      games.append(contentsOf: platformGames)
    }

    return [
      "rootPath": rootURL.path,
      "romsPath": romsURL.path,
      "platformCount": platforms.count,
      "gameCount": games.count,
      "platforms": platforms,
      "games": games,
    ]
  }

  private func directoryURL(from url: URL) throws -> URL {
    let values = try url.resourceValues(forKeys: [.isDirectoryKey])
    guard values.isDirectory == true else {
      throw IosTfCardScanError(
        code: "not_directory",
        message: "Please choose the TF card root folder or roms folder."
      )
    }
    return url
  }

  private func findRomsDirectory(from selectedURL: URL) throws -> URL {
    if selectedURL.lastPathComponent.lowercased() == "roms" {
      return selectedURL
    }

    let directRomsURL = selectedURL.appendingPathComponent("roms", isDirectory: true)
    if isDirectory(directRomsURL) {
      return directRomsURL
    }

    throw IosTfCardScanError(
      code: "roms_not_found",
      message: "No roms folder was found in the selected TF card folder."
    )
  }

  private func scanPlatform(
    gameType: IosTfCardGameType,
    platformURL: URL
  ) throws -> [[String: Any]] {
    let metadata = IosTfCardGameListParser.parse(
      fileURL: platformURL.appendingPathComponent("gamelist.xml")
    )
    let files = try romFiles(in: platformURL, allowedExtensions: gameType.extensions)

    return files.map { fileURL in
      let relativePath = relativePath(from: platformURL, to: fileURL)
      let gameMetadata = metadata[relativePath] ??
        metadata.first(where: { relativePath.hasSuffix($0.key) })?.value
      var game: [String: Any] = [
        "platform": gameType.directory,
        "platformName": gameType.fullName,
        "name": gameMetadata?.name ?? fileURL.deletingPathExtension().lastPathComponent,
        "fileName": fileURL.lastPathComponent,
        "relativePath": relativePath,
        "absolutePath": fileURL.path,
      ]

      if let image = gameMetadata?.image, !image.isEmpty {
        game["image"] = image
      }
      if let video = gameMetadata?.video, !video.isEmpty {
        game["video"] = video
      }
      if let desc = gameMetadata?.desc, !desc.isEmpty {
        game["desc"] = desc
      }
      return game
    }
  }

  private func romFiles(
    in directoryURL: URL,
    allowedExtensions: Set<String>
  ) throws -> [URL] {
    guard let enumerator = fileManager.enumerator(
      at: directoryURL,
      includingPropertiesForKeys: [.isRegularFileKey, .isHiddenKey],
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }

    var files: [URL] = []
    for case let fileURL as URL in enumerator {
      let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .isHiddenKey])
      guard values.isRegularFile == true, values.isHidden != true else {
        continue
      }

      let fileExtension = ".\(fileURL.pathExtension.lowercased())"
      if allowedExtensions.contains(fileExtension) {
        files.append(fileURL)
      }
    }
    return files.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
  }

  private func isDirectory(_ url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) &&
      isDirectory.boolValue
  }

  private func relativePath(from rootURL: URL, to fileURL: URL) -> String {
    let rootPath = rootURL.standardizedFileURL.path
    let filePath = fileURL.standardizedFileURL.path
    let prefix = rootPath.hasSuffix("/") ? rootPath : "\(rootPath)/"
    if filePath.hasPrefix(prefix) {
      return String(filePath.dropFirst(prefix.count))
    }
    return fileURL.lastPathComponent
  }
}

private final class IosTfCardGameListParser: NSObject, XMLParserDelegate {
  private var games: [String: IosTfCardGameMetadata] = [:]
  private var currentGame: [String: String]?
  private var currentElement: String?
  private var currentText = ""

  static func parse(fileURL: URL) -> [String: IosTfCardGameMetadata] {
    guard FileManager.default.fileExists(atPath: fileURL.path),
          let parser = XMLParser(contentsOf: fileURL) else {
      return [:]
    }

    let delegate = IosTfCardGameListParser()
    parser.delegate = delegate
    _ = parser.parse()
    return delegate.games
  }

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String] = [:]
  ) {
    if elementName == "game" {
      currentGame = [:]
    } else if currentGame != nil {
      currentElement = elementName
      currentText = ""
    }
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    if currentElement != nil {
      currentText += string
    }
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    if elementName == "game" {
      if let game = buildGameMetadata() {
        games[game.path] = game
      }
      currentGame = nil
      currentElement = nil
      currentText = ""
      return
    }

    guard currentGame != nil, currentElement == elementName else {
      return
    }

    currentGame?[elementName] = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
    currentElement = nil
    currentText = ""
  }

  private func buildGameMetadata() -> IosTfCardGameMetadata? {
    guard let currentGame else {
      return nil
    }

    let path = cleanPath(currentGame["path"] ?? "")
    guard !path.isEmpty else {
      return nil
    }

    return IosTfCardGameMetadata(
      path: path,
      name: currentGame["name"] ?? URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent,
      image: currentGame["image"],
      video: currentGame["video"],
      desc: currentGame["desc"]
    )
  }

  private func cleanPath(_ path: String) -> String {
    var result = path.trimmingCharacters(in: .whitespacesAndNewlines)
    while result.hasPrefix("./") {
      result.removeFirst(2)
    }
    return result
  }
}
