import Flutter
import Foundation
import UIKit
import UniformTypeIdentifiers

public final class Host4FlutterSimulatorStoragePlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
  private let bookmarkStore = Host4TfCardBookmarkStore()
  private var pendingResult: FlutterResult?
  private var pendingSystems: [Host4RomSystemSpec] = []

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "host4_flutter_simulator_storage",
      binaryMessenger: registrar.messenger()
    )
    let instance = Host4FlutterSimulatorStoragePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "scanTfCardRoms":
      handleScanTfCardRoms(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleScanTfCardRoms(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(
        code: "scan_in_progress",
        message: "Another TF card scan is already active.",
        details: nil
      ))
      return
    }

    let arguments = call.arguments as? [String: Any]
    let systems = parseSystems(arguments?["systems"] as? [Any] ?? [])
    guard !systems.isEmpty else {
      result(FlutterError(
        code: "systems_required",
        message: "At least one simulator system spec is required.",
        details: nil
      ))
      return
    }

    let forcePick = arguments?["forcePick"] as? Bool ?? false
    if !forcePick, let payload = scanStoredBookmark(systems: systems) {
      result(payload)
      return
    }

    presentPicker(result: result, systems: systems)
  }

  private func parseSystems(_ rawSystems: [Any]) -> [Host4RomSystemSpec] {
    return rawSystems.compactMap { raw in
      guard let item = raw as? [String: Any],
        let type = item["type"] as? Int else { return nil }
      let name = item["name"] as? String ?? ""
      let fullName = item["fullName"] as? String ?? name
      let dir = (item["dir"] as? String ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      let rawExtensions = item["extensions"] as? [Any] ?? []
      let extensions = rawExtensions
        .compactMap { $0 as? String }
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        .filter { $0.hasPrefix(".") && $0.count > 1 }
      guard !dir.isEmpty, !extensions.isEmpty else { return nil }
      return Host4RomSystemSpec(
        type: type,
        name: name,
        fullName: fullName,
        dir: dir,
        extensions: Set(extensions)
      )
    }
  }

  private func scanStoredBookmark(systems: [Host4RomSystemSpec]) -> [String: Any]? {
    guard let resolved = bookmarkStore.resolve() else { return nil }
    let didStartAccessing = resolved.url.startAccessingSecurityScopedResource()
    defer {
      if didStartAccessing {
        resolved.url.stopAccessingSecurityScopedResource()
      }
    }

    do {
      let payload = try Host4TfCardRomScanner(systems: systems).scan(selectedURL: resolved.url)
      if resolved.isStale {
        bookmarkStore.save(url: resolved.url)
      }
      return payload
    } catch {
      bookmarkStore.clear()
      return nil
    }
  }

  private func presentPicker(result: @escaping FlutterResult, systems: [Host4RomSystemSpec]) {
    guard let presenter = topViewController() else {
      result(FlutterError(
        code: "unavailable",
        message: "Unable to present folder picker.",
        details: nil
      ))
      return
    }

    pendingResult = result
    pendingSystems = systems

    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: [UTType.folder],
      asCopy: false
    )
    picker.delegate = self
    picker.allowsMultipleSelection = false
    if let lastURL = bookmarkStore.lastURL() {
      picker.directoryURL = lastURL
    }
    presenter.present(picker, animated: true)
  }

  public func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    guard let result = pendingResult else { return }
    let systems = pendingSystems
    pendingResult = nil
    pendingSystems = []

    guard let url = urls.first else {
      result(FlutterError(code: "cancelled", message: "Folder selection was cancelled.", details: nil))
      return
    }

    let didStartAccessing = url.startAccessingSecurityScopedResource()
    defer {
      if didStartAccessing {
        url.stopAccessingSecurityScopedResource()
      }
    }

    do {
      let payload = try Host4TfCardRomScanner(systems: systems).scan(selectedURL: url)
      bookmarkStore.save(url: url)
      result(payload)
    } catch let error as Host4TfCardScanError {
      result(FlutterError(code: error.code, message: error.message, details: nil))
    } catch {
      result(FlutterError(code: "scan_failed", message: error.localizedDescription, details: nil))
    }
  }

  public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    guard let result = pendingResult else { return }
    pendingResult = nil
    pendingSystems = []
    result(FlutterError(code: "cancelled", message: "Folder selection was cancelled.", details: nil))
  }

  private func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    if let navigation = controller as? UINavigationController {
      return navigation.visibleViewController
    }
    if let tab = controller as? UITabBarController {
      return tab.selectedViewController
    }
    return controller
  }
}

private struct Host4RomSystemSpec {
  let type: Int
  let name: String
  let fullName: String
  let dir: String
  let extensions: Set<String>
}

private struct Host4TfCardScanError: Error {
  let code: String
  let message: String
}

private struct Host4GameMetadata {
  let name: String?
  let imagePath: String?
  let videoPath: String?
  let description: String?
}

private final class Host4TfCardBookmarkStore {
  private let dataKey = "host4_flutter_simulator_storage.tf_card.bookmark_data"
  private let pathKey = "host4_flutter_simulator_storage.tf_card.last_path"

  func save(url: URL) {
    let normalizedURL = url.standardizedFileURL
    UserDefaults.standard.set(normalizedURL.path, forKey: pathKey)
    do {
      let data = try normalizedURL.bookmarkData(
        options: [],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      UserDefaults.standard.set(data, forKey: dataKey)
    } catch {
      UserDefaults.standard.removeObject(forKey: dataKey)
    }
  }

  func resolve() -> (url: URL, isStale: Bool)? {
    guard let data = UserDefaults.standard.data(forKey: dataKey) else {
      return lastURL().map { ($0, false) }
    }
    do {
      var isStale = false
      let url = try URL(
        resolvingBookmarkData: data,
        options: [],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
      return (url.standardizedFileURL, isStale)
    } catch {
      clear()
      return nil
    }
  }

  func lastURL() -> URL? {
    guard let path = UserDefaults.standard.string(forKey: pathKey)?
      .trimmingCharacters(in: .whitespacesAndNewlines),
      !path.isEmpty else { return nil }
    return URL(fileURLWithPath: path, isDirectory: true)
  }

  func clear() {
    UserDefaults.standard.removeObject(forKey: dataKey)
    UserDefaults.standard.removeObject(forKey: pathKey)
  }
}

private final class Host4TfCardRomScanner {
  private let systems: [Host4RomSystemSpec]
  private let fileManager = FileManager.default

  init(systems: [Host4RomSystemSpec]) {
    self.systems = systems
  }

  func scan(selectedURL: URL) throws -> [String: Any] {
    let selectedDirectory = try directoryURL(from: selectedURL.standardizedFileURL)
    let romsURL = try findRomsDirectory(from: selectedDirectory)
    let rootURL = romsURL.deletingLastPathComponent()
    let scanId = "ios_tf_scan_\(Int(Date().timeIntervalSince1970))"

    var platforms: [[String: Any]] = []
    var games: [[String: Any]] = []

    for system in systems {
      let platformURL = romsURL.appendingPathComponent(system.dir, isDirectory: true)
      guard isDirectory(platformURL) else { continue }

      let platformGames = try scanPlatform(system: system, platformURL: platformURL)
      guard !platformGames.isEmpty else { continue }
      platforms.append([
        "type": system.type,
        "name": system.name,
        "fullName": system.fullName,
        "dir": system.dir,
        "path": platformURL.standardizedFileURL.path,
        "gameCount": platformGames.count,
      ])
      games.append(contentsOf: platformGames)
    }

    return [
      "scanId": scanId,
      "rootPath": rootURL.standardizedFileURL.path,
      "romsPath": romsURL.standardizedFileURL.path,
      "platformCount": platforms.count,
      "gameCount": games.count,
      "platforms": platforms,
      "games": games,
    ]
  }

  private func directoryURL(from url: URL) throws -> URL {
    let values = try url.resourceValues(forKeys: [.isDirectoryKey])
    guard values.isDirectory == true else {
      throw Host4TfCardScanError(
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
    throw Host4TfCardScanError(
      code: "roms_not_found",
      message: "No roms folder was found in the selected TF card folder."
    )
  }

  private func scanPlatform(
    system: Host4RomSystemSpec,
    platformURL: URL
  ) throws -> [[String: Any]] {
    let metadata = Host4GameListParser.parse(
      fileURL: platformURL.appendingPathComponent("gamelist.xml")
    )
    let files = try romFiles(in: platformURL, allowedExtensions: system.extensions)
    return files.map { fileURL in
      let resourcePath = relativePath(from: platformURL, to: fileURL)
      let gameMetadata = metadata[resourcePath] ??
        metadata["./\(resourcePath)"] ??
        metadata.first(where: { resourcePath.hasSuffix($0.key.trimmingPrefix("./")) })?.value
      var game: [String: Any] = [
        "type": system.type,
        "platformName": system.name,
        "platformFullName": system.fullName,
        "name": gameMetadata?.name ?? fileURL.deletingPathExtension().lastPathComponent,
        "fileName": fileURL.lastPathComponent,
        "rootPath": platformURL.standardizedFileURL.path,
        "resourcePath": resourcePath,
        "romPath": fileURL.standardizedFileURL.path,
      ]
      if let imagePath = gameMetadata?.imagePath, !imagePath.isEmpty {
        game["imagePath"] = imagePath
      }
      if let videoPath = gameMetadata?.videoPath, !videoPath.isEmpty {
        game["videoPath"] = videoPath
      }
      if let description = gameMetadata?.description, !description.isEmpty {
        game["description"] = description
      }
      return game
    }
  }

  private func romFiles(in directoryURL: URL, allowedExtensions: Set<String>) throws -> [URL] {
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
      guard values.isRegularFile == true, values.isHidden != true else { continue }
      let fileExtension = ".\(fileURL.pathExtension.lowercased())"
      if allowedExtensions.contains(fileExtension) {
        files.append(fileURL)
      }
    }
    return files.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
  }

  private func isDirectory(_ url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
      && isDirectory.boolValue
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

private final class Host4GameListParser: NSObject, XMLParserDelegate {
  private var games: [String: Host4GameMetadata] = [:]
  private var currentElement = ""
  private var currentText = ""
  private var inGame = false
  private var path = ""
  private var name = ""
  private var imagePath = ""
  private var videoPath = ""
  private var gameDescription = ""

  static func parse(fileURL: URL) -> [String: Host4GameMetadata] {
    guard FileManager.default.fileExists(atPath: fileURL.path),
      let parser = XMLParser(contentsOf: fileURL) else { return [:] }
    let delegate = Host4GameListParser()
    parser.delegate = delegate
    parser.parse()
    return delegate.games
  }

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String] = [:]
  ) {
    currentElement = elementName
    currentText = ""
    if elementName == "game" {
      inGame = true
      path = ""
      name = ""
      imagePath = ""
      videoPath = ""
      gameDescription = ""
    }
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    currentText += string
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    guard inGame else { return }
    let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
    switch elementName {
    case "path":
      path = text
    case "name":
      name = text
    case "image":
      imagePath = text
    case "video":
      videoPath = text
    case "desc":
      gameDescription = text
    case "game":
      if !path.isEmpty {
        games[path.trimmingPrefix("./")] = Host4GameMetadata(
          name: name.isEmpty ? nil : name,
          imagePath: imagePath.isEmpty ? nil : imagePath,
          videoPath: videoPath.isEmpty ? nil : videoPath,
          description: gameDescription.isEmpty ? nil : gameDescription
        )
        games[path] = games[path.trimmingPrefix("./")]
      }
      inGame = false
    default:
      break
    }
    currentText = ""
  }
}

private extension String {
  func trimmingPrefix(_ prefix: String) -> String {
    guard hasPrefix(prefix) else { return self }
    return String(dropFirst(prefix.count))
  }
}
