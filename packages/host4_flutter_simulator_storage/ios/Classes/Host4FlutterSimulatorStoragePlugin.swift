import Flutter
import Foundation
import UIKit
import UniformTypeIdentifiers

/// Keeps the selected TF-card directory available for the current app session.
/// It deliberately stores no game data, so an app restart still drops TF games.
public enum Host4TfCardFileAccessRegistry {
  private static var activeDirectoryURL: URL?
  private static var activeDirectoryAccess: Host4TfCardRetainedFileAccess?
  private static var activeDirectoryURLs: [String: URL] = [:]
  private static var activeDirectoryAccesses: [String: Host4TfCardRetainedFileAccess] = [:]

  @discardableResult
  public static func activate(
    directoryURL: URL,
    ownsExistingSecurityScope: Bool = false
  ) -> Bool {
    let normalizedURL = directoryURL.standardizedFileURL
    guard let access = Host4TfCardRetainedFileAccess(
      directoryURL: normalizedURL,
      ownsExistingSecurityScope: ownsExistingSecurityScope
    ) else {
      return activeDirectoryAccesses[normalizedURL.path] != nil
    }
    activeDirectoryURL = normalizedURL
    activeDirectoryAccess = access
    activeDirectoryURLs[normalizedURL.path] = normalizedURL
    activeDirectoryAccesses[normalizedURL.path] = access
    return true
  }

  public static func clearActiveDirectory() {
    activeDirectoryAccess = nil
    activeDirectoryURL = nil
    activeDirectoryAccesses = [:]
    activeDirectoryURLs = [:]
  }

  public static func clearActiveDirectory(at directoryURL: URL) {
    let normalizedURL = directoryURL.standardizedFileURL
    activeDirectoryAccesses[normalizedURL.path] = nil
    activeDirectoryURLs[normalizedURL.path] = nil
    if activeDirectoryURL?.path == normalizedURL.path {
      activeDirectoryURL = nil
      activeDirectoryAccess = nil
    }
  }

  public static func retainAccess(forROMPath romPath: String) -> AnyObject? {
    let romURL = URL(fileURLWithPath: romPath).standardizedFileURL
    let matchingRoot = activeDirectoryURLs.values
      .filter { directoryURL in
        let rootPath = directoryURL.path
        return romURL.path == rootPath || romURL.path.hasPrefix(rootPath + "/")
      }
      .max { $0.path.count < $1.path.count }
    guard let matchingRoot else { return nil }
    return activeDirectoryAccesses[matchingRoot.path]
  }

  /// Checks the directory through the scope already retained for this session.
  /// Returning nil means this URL is not the active directory and callers may
  /// fall back to resolving a bookmark.
  public static func isActiveDirectoryAccessible(at directoryURL: URL) -> Bool? {
    let normalizedURL = directoryURL.standardizedFileURL
    guard
      let activeDirectoryURL = activeDirectoryURLs[normalizedURL.path],
      activeDirectoryAccesses[normalizedURL.path] != nil
    else {
      return nil
    }
    return isDirectoryReadable(at: activeDirectoryURL)
  }

  public static func hasAccessibleActiveDirectory() -> Bool {
    activeDirectoryURLs.values.contains { directoryURL in
      isDirectoryReadable(at: directoryURL)
    }
  }

  /// `fileExists` can return false for a mounted external volume even while
  /// its security-scoped directory is readable. Probe the directory contents
  /// instead, which also turns false once the card has actually been removed.
  public static func isDirectoryReadable(at directoryURL: URL) -> Bool {
    do {
      _ = try FileManager.default.contentsOfDirectory(
        at: directoryURL,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
      )
      return true
    } catch {
      return false
    }
  }
}

private final class Host4TfCardRetainedFileAccess: NSObject {
  private let directoryURL: URL
  private let didStartAccessing: Bool

  init?(
    directoryURL: URL,
    ownsExistingSecurityScope: Bool = false
  ) {
    self.directoryURL = directoryURL
    didStartAccessing = ownsExistingSecurityScope
      || directoryURL.startAccessingSecurityScopedResource()
    super.init()
    guard didStartAccessing else { return nil }
  }

  deinit {
    if didStartAccessing {
      directoryURL.stopAccessingSecurityScopedResource()
    }
  }
}

public final class Host4FlutterSimulatorStoragePlugin: NSObject, FlutterPlugin, FlutterStreamHandler, UIDocumentPickerDelegate {
  private let bookmarkStore = Host4TfCardBookmarkStore()
  private let simulatorFolderBookmarkStore = Host4SimulatorRomFolderBookmarkStore()
  private var pendingResult: FlutterResult?
  private var pendingSystems: [Host4RomSystemSpec] = []
  private var pendingStreamingResult: FlutterResult?
  private var pendingStreamingSystems: [Host4RomSystemSpec] = []
  private var pendingStreamingScanId = ""
  private var pendingSimulatorFolderResult: FlutterResult?
  private var pendingSimulatorFolderSystemType: Int?
  private var pendingSimulatorFolderReplacingPath: String?
  private var pendingSimulatorFolderMaximumCount: Int?
  private var eventSink: FlutterEventSink?
  private var bufferedStreamingEvents: [[String: Any]] = []
  private var streamingScanActive = false
  private var activeTfCardURL: URL?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "host4_flutter_simulator_storage",
      binaryMessenger: registrar.messenger()
    )
    let instance = Host4FlutterSimulatorStoragePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    let eventChannel = FlutterEventChannel(
      name: "host4_flutter_simulator_storage/tf_card_scan_events",
      binaryMessenger: registrar.messenger()
    )
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "scanTfCardRoms":
      handleScanTfCardRoms(call: call, result: result)
    case "startTfCardRomScan":
      handleStartTfCardRomScan(call: call, result: result)
    case "isTfCardAccessible":
      result(isStoredTfCardAccessible())
    case "loadSimulatorRomFolders":
      handleLoadSimulatorRomFolders(call: call, result: result)
    case "pickSimulatorRomFolder":
      handlePickSimulatorRomFolder(call: call, result: result)
    case "removeSimulatorRomFolder":
      handleRemoveSimulatorRomFolder(call: call, result: result)
    case "startSimulatorRomFolderScan":
      handleStartSimulatorRomFolderScan(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func isStoredTfCardAccessible() -> Bool {
    if Host4TfCardFileAccessRegistry.hasAccessibleActiveDirectory() {
      return true
    }
    guard let url = activeTfCardURL ?? bookmarkStore.resolve()?.url else {
      return false
    }

    if let isAccessible = Host4TfCardFileAccessRegistry.isActiveDirectoryAccessible(at: url) {
      return isAccessible
    }

    let didStartAccessing = url.startAccessingSecurityScopedResource()
    defer {
      if didStartAccessing { url.stopAccessingSecurityScopedResource() }
    }
    guard didStartAccessing else { return false }
    return Host4TfCardFileAccessRegistry.isDirectoryReadable(at: url)
  }

  private func hasUsableTfCardRomsDirectory(at url: URL) -> Bool {
    let didStartAccessing = url.startAccessingSecurityScopedResource()
    defer {
      if didStartAccessing {
        url.stopAccessingSecurityScopedResource()
      }
    }
    guard didStartAccessing else { return false }

    var isDirectory: ObjCBool = false
    let selectedDirectory = url.standardizedFileURL
    guard FileManager.default.fileExists(
      atPath: selectedDirectory.path,
      isDirectory: &isDirectory
    ), isDirectory.boolValue else {
      return false
    }

    if selectedDirectory.lastPathComponent.lowercased() == "roms" {
      return true
    }

    var hasRomsDirectory: ObjCBool = false
    let directRomsURL = selectedDirectory.appendingPathComponent("roms", isDirectory: true)
    return FileManager.default.fileExists(atPath: directRomsURL.path, isDirectory: &hasRomsDirectory) && hasRomsDirectory.boolValue
  }

  private func resolveUsableStoredTfCardURL() -> URL? {
    guard let resolved = bookmarkStore.resolve() else { return nil }
    if !hasUsableTfCardRomsDirectory(at: resolved.url) {
      bookmarkStore.clear()
      return nil
    }
    return resolved.url
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    let bufferedEvents = bufferedStreamingEvents
    bufferedStreamingEvents = []
    for event in bufferedEvents {
      events(event)
    }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func handleStartTfCardRomScan(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard !streamingScanActive, pendingStreamingResult == nil else {
      result(FlutterError(code: "scan_in_progress", message: "Another TF card scan is already active.", details: nil))
      return
    }

    let arguments = call.arguments as? [String: Any]
    let systems = parseSystems(arguments?["systems"] as? [Any] ?? [])
    guard !systems.isEmpty else {
      result(FlutterError(code: "systems_required", message: "At least one simulator system spec is required.", details: nil))
      return
    }

    let scanId = "ios_tf_scan_\(Int(Date().timeIntervalSince1970))"
    let forcePick = arguments?["forcePick"] as? Bool ?? false
    if !forcePick, let resolved = resolveUsableStoredTfCardURL() {
      setActiveTfCardURL(resolved)
      streamingScanActive = true
      result(["scanId": scanId])
      beginStreamingScan(url: resolved, systems: systems, scanId: scanId)
      return
    }

    guard let presenter = topViewController() else {
      result(FlutterError(code: "unavailable", message: "Unable to present folder picker.", details: nil))
      return
    }
    pendingStreamingResult = result
    pendingStreamingSystems = systems
    pendingStreamingScanId = scanId
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder], asCopy: false)
    picker.delegate = self
    picker.allowsMultipleSelection = false
    if let lastURL = bookmarkStore.lastURL() {
      picker.directoryURL = lastURL
    }
    presenter.present(picker, animated: true)
  }

  private func beginStreamingScan(url: URL, systems: [Host4RomSystemSpec], scanId: String) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }
      let didStartAccessing = url.startAccessingSecurityScopedResource()
      let didTransferSecurityScope = didStartAccessing &&
        Host4TfCardFileAccessRegistry.activate(
          directoryURL: url,
          ownsExistingSecurityScope: true
        )
      defer {
        if didStartAccessing && !didTransferSecurityScope {
          url.stopAccessingSecurityScopedResource()
        }
      }
      do {
        try Host4TfCardRomScanner(systems: systems).scanStreaming(selectedURL: url, scanId: scanId) { event in
          self.emitStreamingEvent(event)
        }
      } catch let error as Host4TfCardScanError {
        self.emitStreamingEvent([
          "phase": "failed", "scanId": scanId, "message": error.message,
        ])
      } catch {
        self.emitStreamingEvent([
          "phase": "failed", "scanId": scanId, "message": error.localizedDescription,
        ])
      }
      DispatchQueue.main.async {
        self.streamingScanActive = false
      }
    }
  }

  private func setActiveTfCardURL(_ url: URL) {
    let normalizedURL = url.standardizedFileURL
    activeTfCardURL = normalizedURL
    Host4TfCardFileAccessRegistry.activate(directoryURL: normalizedURL)
  }

  private func emitStreamingEvent(_ event: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      if let eventSink = self.eventSink {
        eventSink(event)
      } else {
        self.bufferedStreamingEvents.append(event)
      }
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

  private func handleLoadSimulatorRomFolders(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let systemType = simulatorSystemType(from: call.arguments) else {
      result(FlutterError(code: "system_type_required", message: "A simulator system type is required.", details: nil))
      return
    }
    result(simulatorFolderPayloads(for: systemType))
  }

  private func handlePickSimulatorRomFolder(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard pendingResult == nil, pendingStreamingResult == nil, pendingSimulatorFolderResult == nil,
      !streamingScanActive else {
      result(FlutterError(code: "scan_in_progress", message: "Another folder request is already active.", details: nil))
      return
    }
    guard let systemType = simulatorSystemType(from: call.arguments) else {
      result(FlutterError(code: "system_type_required", message: "A simulator system type is required.", details: nil))
      return
    }
    let arguments = call.arguments as? [String: Any]
    let replacingPath = (arguments?["replacingPath"] as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let maximumFolderCount = simulatorMaximumFolderCount(from: call.arguments)
    if (replacingPath?.isEmpty ?? true) &&
      simulatorFolderBookmarkStore.count(for: systemType, maximumFolderCount: maximumFolderCount) >= maximumFolderCount {
      result(FlutterError(code: "folder_limit_reached", message: "The maximum additional ROM folder count has been reached for this simulator.", details: nil))
      return
    }
    guard let presenter = topViewController() else {
      result(FlutterError(code: "unavailable", message: "Unable to present folder picker.", details: nil))
      return
    }

    pendingSimulatorFolderResult = result
    pendingSimulatorFolderSystemType = systemType
    pendingSimulatorFolderReplacingPath = replacingPath?.isEmpty == false ? replacingPath : nil
    pendingSimulatorFolderMaximumCount = maximumFolderCount
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder], asCopy: false)
    picker.delegate = self
    picker.allowsMultipleSelection = false
    if let replacingPath,
      let directoryURL = simulatorFolderBookmarkStore.lastURL(
        for: systemType,
        matchingPath: replacingPath
      ) {
      picker.directoryURL = directoryURL
    }
    presenter.present(picker, animated: true)
  }

  private func handleRemoveSimulatorRomFolder(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let systemType = simulatorSystemType(from: call.arguments),
      let arguments = call.arguments as? [String: Any],
      let path = arguments["path"] as? String,
      !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      result(FlutterError(code: "invalid_folder", message: "A simulator system type and folder path are required.", details: nil))
      return
    }
    let normalizedURL = URL(fileURLWithPath: path).standardizedFileURL
    simulatorFolderBookmarkStore.remove(
      for: systemType,
      matchingPath: normalizedURL.path
    )
    result(simulatorFolderPayloads(for: systemType))
  }

  private func handleStartSimulatorRomFolderScan(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard !streamingScanActive, pendingStreamingResult == nil, pendingSimulatorFolderResult == nil else {
      result(FlutterError(code: "scan_in_progress", message: "Another ROM scan is already active.", details: nil))
      return
    }
    let arguments = call.arguments as? [String: Any]
    let rawSystems: [Any]
    if let system = arguments?["system"] {
      rawSystems = [system]
    } else {
      rawSystems = []
    }
    let systems = parseSystems(rawSystems)
    guard let system = systems.first else {
      result(FlutterError(code: "system_required", message: "A complete simulator system spec is required.", details: nil))
      return
    }
    let folderURLs = simulatorFolderBookmarkStore.resolvedURLs(for: system.type)
    if system.type == 5 {
      print("[IOS_GB_SCAN_DEBUG] native start folder scan type=\(system.type) name=\(system.name) dir=\(system.dir) extensions=\(system.extensions.sorted()) resolvedFolderCount=\(folderURLs.count)")
      for folderURL in folderURLs {
        print("[IOS_GB_SCAN_DEBUG] native resolved folder url=\"\(folderURL.path)\"")
      }
    }
    guard !folderURLs.isEmpty else {
      result(FlutterError(code: "no_folders", message: "No ROM folder is configured for this simulator.", details: nil))
      return
    }

    let scanId = "ios_simulator_path_scan_\(Int(Date().timeIntervalSince1970))"
    streamingScanActive = true
    result(["scanId": scanId])
    beginSimulatorRomFolderStreamingScan(
      folderURLs: folderURLs,
      system: system,
      scanId: scanId
    )
  }

  private func beginSimulatorRomFolderStreamingScan(
    folderURLs: [URL],
    system: Host4RomSystemSpec,
    scanId: String
  ) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }
      self.emitStreamingEvent([
        "phase": "started",
        "scanId": scanId,
      ])
      var gameCount = 0
      for folderURL in folderURLs {
        let hasRetainedAccess = Host4TfCardFileAccessRegistry
          .isActiveDirectoryAccessible(at: folderURL) == true
        let didStartAccessing = !hasRetainedAccess &&
          folderURL.startAccessingSecurityScopedResource()
        let didTransferSecurityScope = didStartAccessing &&
          Host4TfCardFileAccessRegistry.activate(
            directoryURL: folderURL,
            ownsExistingSecurityScope: true
          )
        if system.type == 5 {
          print("[IOS_GB_SCAN_DEBUG] native access folder=\"\(folderURL.path)\" didStartAccessing=\(didStartAccessing) didTransferSecurityScope=\(didTransferSecurityScope)")
        }
        defer {
          if didStartAccessing && !didTransferSecurityScope {
            folderURL.stopAccessingSecurityScopedResource()
          }
        }
        guard hasRetainedAccess || didStartAccessing else {
          self.emitStreamingEvent([
            "phase": "platformError",
            "scanId": scanId,
            "type": system.type,
            "platformName": system.name,
            "message": "Unable to access the selected ROM folder.",
          ])
          continue
        }
        do {
          let foundCount = try Host4TfCardRomScanner(systems: [system])
            .scanPlatformDirectoryStreaming(
              selectedURL: folderURL,
              system: system,
              scanId: scanId,
              onEvent: { event in self.emitStreamingEvent(event) }
            )
          gameCount += foundCount
        } catch let error as Host4TfCardScanError {
          self.emitStreamingEvent([
            "phase": "platformError",
            "scanId": scanId,
            "type": system.type,
            "platformName": system.name,
            "message": error.message,
          ])
        } catch {
          self.emitStreamingEvent([
            "phase": "platformError",
            "scanId": scanId,
            "type": system.type,
            "platformName": system.name,
            "message": error.localizedDescription,
          ])
        }
      }
      self.emitStreamingEvent([
        "phase": "completed",
        "scanId": scanId,
        "platformCount": folderURLs.count,
        "gameCount": gameCount,
      ])
      DispatchQueue.main.async {
        self.streamingScanActive = false
      }
    }
  }

  private func simulatorSystemType(from arguments: Any?) -> Int? {
    guard let arguments = arguments as? [String: Any] else { return nil }
    if let type = arguments["systemType"] as? Int { return type }
    if let type = arguments["systemType"] as? NSNumber { return type.intValue }
    return nil
  }

  private func simulatorMaximumFolderCount(from arguments: Any?) -> Int {
    guard let arguments = arguments as? [String: Any] else {
      return Host4SimulatorRomFolderBookmarkStore.defaultMaximumFolderCount
    }
    let rawValue: Int?
    if let value = arguments["maximumFolderCount"] as? Int {
      rawValue = value
    } else if let value = arguments["maximumFolderCount"] as? NSNumber {
      rawValue = value.intValue
    } else {
      rawValue = nil
    }
    guard let rawValue, rawValue > 0 else {
      return Host4SimulatorRomFolderBookmarkStore.defaultMaximumFolderCount
    }
    return rawValue
  }

  private func simulatorFolderPayloads(for systemType: Int) -> [[String: Any]] {
    let payloads = simulatorFolderBookmarkStore.entries(for: systemType).map { entry in
      let payload: [String: Any] = [
        "path": entry.path,
        "displayName": URL(fileURLWithPath: entry.path).lastPathComponent,
        "accessible": isSimulatorFolderAccessible(entry),
      ]
      if systemType == 5 {
        print("[IOS_GB_SCAN_DEBUG] native load folder path=\"\(entry.path)\" accessible=\(payload["accessible"] ?? false)")
      }
      return payload
    }
    if systemType == 5 {
      print("[IOS_GB_SCAN_DEBUG] native load folder count=\(payloads.count)")
    }
    return payloads
  }

  private func isSimulatorFolderAccessible(
    _ entry: Host4SimulatorRomFolderBookmarkStore.Entry
  ) -> Bool {
    guard let url = simulatorFolderBookmarkStore.resolvedURL(for: entry) else {
      return false
    }
    if let accessible = Host4TfCardFileAccessRegistry
      .isActiveDirectoryAccessible(at: url) {
      return accessible
    }
    let didStartAccessing = url.startAccessingSecurityScopedResource()
    defer {
      if didStartAccessing {
        url.stopAccessingSecurityScopedResource()
      }
    }
    guard didStartAccessing else { return false }
    return Host4TfCardFileAccessRegistry.isDirectoryReadable(at: url)
  }

  private func parseSystems(_ rawSystems: [Any]) -> [Host4RomSystemSpec] {
    var systems: [Host4RomSystemSpec] = []

    for rawSystem in rawSystems {
      guard let item = rawSystem as? [String: Any],
            let type = item["type"] as? Int else {
        continue
      }

      let name = item["name"] as? String ?? ""
      let fullName = item["fullName"] as? String ?? name
      let dir = (item["dir"] as? String ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      let rawExtensions = item["extensions"] as? [Any] ?? []
      var extensions: [String] = []
      for case let rawExtension as String in rawExtensions {
        let ext = rawExtension
          .trimmingCharacters(in: .whitespacesAndNewlines)
          .lowercased()
        guard !ext.isEmpty else { continue }
        let normalizedExt = ext.hasPrefix(".") ? ext : ".\(ext)"
        if normalizedExt.count > 1 {
          extensions.append(normalizedExt)
        }
      }

      guard !dir.isEmpty, !extensions.isEmpty else { continue }
      systems.append(
        Host4RomSystemSpec(
          type: type,
          name: name,
          fullName: fullName,
          dir: dir,
          extensions: Set(extensions)
        )
      )
    }
    return systems
  }

  private func scanStoredBookmark(systems: [Host4RomSystemSpec]) -> [String: Any]? {
    guard let resolved = bookmarkStore.resolve() else { return nil }
    setActiveTfCardURL(resolved.url)
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
    if let simulatorFolderResult = pendingSimulatorFolderResult {
      let systemType = pendingSimulatorFolderSystemType
      let replacingPath = pendingSimulatorFolderReplacingPath
      let maximumFolderCount = pendingSimulatorFolderMaximumCount
      pendingSimulatorFolderResult = nil
      pendingSimulatorFolderSystemType = nil
      pendingSimulatorFolderReplacingPath = nil
      pendingSimulatorFolderMaximumCount = nil
      guard let systemType, let url = urls.first else {
        simulatorFolderResult(FlutterError(code: "cancelled", message: "Folder selection was cancelled.", details: nil))
        return
      }
      let didStartAccessing = url.startAccessingSecurityScopedResource()
      var didTransferSecurityScope = false
      defer {
        if didStartAccessing && !didTransferSecurityScope {
          url.stopAccessingSecurityScopedResource()
        }
      }
      do {
        try simulatorFolderBookmarkStore.replaceOrAdd(
          url: url,
          for: systemType,
          replacingPath: replacingPath,
          maximumFolderCount: maximumFolderCount ?? Host4SimulatorRomFolderBookmarkStore.defaultMaximumFolderCount
        )
        didTransferSecurityScope = Host4TfCardFileAccessRegistry.activate(
          directoryURL: url,
          ownsExistingSecurityScope: didStartAccessing
        )
        simulatorFolderResult(simulatorFolderPayloads(for: systemType))
      } catch let error as Host4TfCardScanError {
        simulatorFolderResult(FlutterError(code: error.code, message: error.message, details: nil))
      } catch {
        simulatorFolderResult(FlutterError(code: "folder_save_failed", message: error.localizedDescription, details: nil))
      }
      return
    }

    if let streamingResult = pendingStreamingResult {
      let systems = pendingStreamingSystems
      let scanId = pendingStreamingScanId
      pendingStreamingResult = nil
      pendingStreamingSystems = []
      pendingStreamingScanId = ""
      guard let url = urls.first else {
        streamingResult(FlutterError(code: "cancelled", message: "Folder selection was cancelled.", details: nil))
        return
      }
      setActiveTfCardURL(url)
      bookmarkStore.save(url: url)
      streamingScanActive = true
      streamingResult(["scanId": scanId])
      beginStreamingScan(url: url, systems: systems, scanId: scanId)
      return
    }

    guard let result = pendingResult else { return }
    let systems = pendingSystems
    pendingResult = nil
    pendingSystems = []

    guard let url = urls.first else {
      result(FlutterError(code: "cancelled", message: "Folder selection was cancelled.", details: nil))
      return
    }
    setActiveTfCardURL(url)

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
    if let simulatorFolderResult = pendingSimulatorFolderResult {
      pendingSimulatorFolderResult = nil
      pendingSimulatorFolderSystemType = nil
      pendingSimulatorFolderReplacingPath = nil
      pendingSimulatorFolderMaximumCount = nil
      simulatorFolderResult(FlutterError(code: "cancelled", message: "Folder selection was cancelled.", details: nil))
      return
    }

    if let streamingResult = pendingStreamingResult {
      pendingStreamingResult = nil
      pendingStreamingSystems = []
      pendingStreamingScanId = ""
      streamingResult(FlutterError(code: "cancelled", message: "Folder selection was cancelled.", details: nil))
      return
    }

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
    // iOS has no .withSecurityScope bookmark option. Create the bookmark
    // while the document picker's temporary security scope is active.
    let didStartAccessing = normalizedURL.startAccessingSecurityScopedResource()
    defer {
      if didStartAccessing {
        normalizedURL.stopAccessingSecurityScopedResource()
      }
    }
    guard didStartAccessing else {
      clear()
      return
    }
    do {
      let data = try normalizedURL.bookmarkData(
        options: [],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      UserDefaults.standard.set(data, forKey: dataKey)
      UserDefaults.standard.set(normalizedURL.path, forKey: pathKey)
    } catch {
      clear()
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

private final class Host4SimulatorRomFolderBookmarkStore {
  static let defaultMaximumFolderCount = 2

  fileprivate struct Entry: Codable {
    let path: String
    let bookmarkData: Data
  }

  private let dataKey = "host4_flutter_simulator_storage.simulator_rom_folders"

  func entries(
    for systemType: Int,
    maximumFolderCount: Int = defaultMaximumFolderCount
  ) -> [Entry] {
    Array(
      (entriesBySystemType()[String(systemType)] ?? [])
        .prefix(maximumFolderCount)
    )
  }

  func count(
    for systemType: Int,
    maximumFolderCount: Int = defaultMaximumFolderCount
  ) -> Int {
    entries(for: systemType, maximumFolderCount: maximumFolderCount).count
  }

  func lastURL(for systemType: Int, matchingPath path: String) -> URL? {
    let normalizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
    guard let entry = entries(for: systemType).first(where: { $0.path == normalizedPath }) else {
      return nil
    }
    return resolve(entry)?.url
  }

  func resolvedURLs(for systemType: Int) -> [URL] {
    entries(for: systemType).compactMap { resolve($0)?.url }
  }

  func resolvedURL(for entry: Entry) -> URL? {
    resolve(entry)?.url
  }

  func replaceOrAdd(
    url: URL,
    for systemType: Int,
    replacingPath: String?,
    maximumFolderCount: Int = defaultMaximumFolderCount
  ) throws {
    let normalizedURL = url.standardizedFileURL
    // UIDocumentPicker already grants temporary access while this delegate is
    // running. Persist the folder choice even when a file provider declines a
    // second startAccessingSecurityScopedResource call.
    let bookmarkData = try normalizedURL.bookmarkData(
      options: [],
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    )
    let key = String(systemType)
    var allEntries = entriesBySystemType()
    var systemEntries = allEntries[key] ?? []
    let newEntry = Entry(path: normalizedURL.path, bookmarkData: bookmarkData)
    if let replacingPath = replacingPath?.trimmingCharacters(in: .whitespacesAndNewlines),
      !replacingPath.isEmpty {
      let normalizedReplacingPath = URL(fileURLWithPath: replacingPath).standardizedFileURL.path
      guard let index = systemEntries.firstIndex(where: { $0.path == normalizedReplacingPath }) else {
        throw Host4TfCardScanError(
          code: "folder_not_found",
          message: "The ROM folder to replace is no longer configured."
        )
      }
      if let duplicateIndex = systemEntries.firstIndex(where: { $0.path == normalizedURL.path }),
        duplicateIndex != index {
        throw Host4TfCardScanError(
          code: "folder_already_added",
          message: "This ROM folder is already configured for the simulator."
        )
      }
      systemEntries[index] = Entry(path: normalizedURL.path, bookmarkData: bookmarkData)
    } else if let index = systemEntries.firstIndex(where: { $0.path == normalizedURL.path }) {
      systemEntries[index] = newEntry
    } else if systemEntries.count >= maximumFolderCount {
      throw Host4TfCardScanError(
        code: "folder_limit_reached",
        message: "At most two additional ROM folders are allowed for each simulator."
      )
    } else {
      systemEntries.append(newEntry)
    }
    allEntries[key] = systemEntries
    save(allEntries)
  }

  func remove(for systemType: Int, matchingPath path: String) {
    let normalizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
    let key = String(systemType)
    var allEntries = entriesBySystemType()
    var systemEntries = allEntries[key] ?? []
    systemEntries.removeAll { $0.path == normalizedPath }
    if systemEntries.isEmpty {
      allEntries[key] = nil
    } else {
      allEntries[key] = systemEntries
    }
    save(allEntries)
  }

  private func resolve(_ entry: Entry) -> (url: URL, isStale: Bool)? {
    do {
      var isStale = false
      let url = try URL(
        resolvingBookmarkData: entry.bookmarkData,
        options: [],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
      return (url.standardizedFileURL, isStale)
    } catch {
      return nil
    }
  }

  private func entriesBySystemType() -> [String: [Entry]] {
    guard let data = UserDefaults.standard.data(forKey: dataKey) else {
      return [:]
    }
    return (try? JSONDecoder().decode([String: [Entry]].self, from: data)) ?? [:]
  }

  private func save(_ entries: [String: [Entry]]) {
    guard !entries.isEmpty, let data = try? JSONEncoder().encode(entries) else {
      UserDefaults.standard.removeObject(forKey: dataKey)
      return
    }
    UserDefaults.standard.set(data, forKey: dataKey)
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

  func scanStreaming(
    selectedURL: URL,
    scanId: String,
    onEvent: ([String: Any]) -> Void
  ) throws {
    let selectedDirectory = try directoryURL(from: selectedURL.standardizedFileURL)
    let romsURL: URL
    do {
      romsURL = try findRomsDirectory(from: selectedDirectory)
    } catch let error as Host4TfCardScanError where error.code == "roms_not_found" {
      onEvent([
        "phase": "skipped",
        "scanId": scanId,
        "message": error.message,
      ])
      return
    }
    let rootURL = romsURL.deletingLastPathComponent()
    var platformCount = 0
    var gameCount = 0

    onEvent([
      "phase": "started",
      "scanId": scanId,
      "rootPath": rootURL.standardizedFileURL.path,
      "romsPath": romsURL.standardizedFileURL.path,
    ])

    for system in systems {
      let platformURL = romsURL.appendingPathComponent(system.dir, isDirectory: true)
      guard isDirectory(platformURL) else { continue }
      platformCount += 1
      onEvent([
        "phase": "platformStarted",
        "scanId": scanId,
        "type": system.type,
        "platformName": system.name,
        "path": platformURL.standardizedFileURL.path,
      ])

      do {
        let metadata = Host4GameListParser.parse(
          fileURL: platformURL.appendingPathComponent("gamelist.xml")
        )
        var platformGameCount = 0
        try enumerateRomFiles(in: platformURL, allowedExtensions: system.extensions) { fileURL in
          let game = self.gamePayload(
            system: system,
            platformURL: platformURL,
            fileURL: fileURL,
            metadata: metadata
          )
          platformGameCount += 1
          gameCount += 1
          onEvent([
            "phase": "gameFound",
            "scanId": scanId,
            "type": system.type,
            "platformName": system.name,
            "game": game,
          ])
        }
        onEvent([
          "phase": "platformCompleted",
          "scanId": scanId,
          "type": system.type,
          "platformName": system.name,
          "gameCount": platformGameCount,
        ])
      } catch let error as Host4TfCardScanError {
        onEvent([
          "phase": "platformError",
          "scanId": scanId,
          "type": system.type,
          "platformName": system.name,
          "message": error.message,
        ])
        onEvent([
          "phase": "platformCompleted",
          "scanId": scanId,
          "type": system.type,
          "platformName": system.name,
          "gameCount": 0,
        ])
      } catch {
        onEvent([
          "phase": "platformError",
          "scanId": scanId,
          "type": system.type,
          "platformName": system.name,
          "message": error.localizedDescription,
        ])
        onEvent([
          "phase": "platformCompleted",
          "scanId": scanId,
          "type": system.type,
          "platformName": system.name,
          "gameCount": 0,
        ])
      }
    }

    onEvent([
      "phase": "completed",
      "scanId": scanId,
      "platformCount": platformCount,
      "gameCount": gameCount,
    ])
  }

  func scanPlatformDirectoryStreaming(
    selectedURL: URL,
    system: Host4RomSystemSpec,
    scanId: String,
    onEvent: ([String: Any]) -> Void
  ) throws -> Int {
    let platformURL = try directoryURL(from: selectedURL.standardizedFileURL)
    if system.type == 5 {
      print("[IOS_GB_SCAN_DEBUG] native platform directory=\"\(platformURL.path)\" allowedExtensions=\(system.extensions.sorted())")
      debugListDirectory(in: platformURL, allowedExtensions: system.extensions)
    }
    onEvent([
      "phase": "platformStarted",
      "scanId": scanId,
      "type": system.type,
      "platformName": system.name,
      "path": platformURL.path,
    ])
    let metadata = Host4GameListParser.parse(
      fileURL: platformURL.appendingPathComponent("gamelist.xml")
    )
    var gameCount = 0
    try enumerateRomFiles(in: platformURL, allowedExtensions: system.extensions) { fileURL in
      if system.type == 5 {
        print("[IOS_GB_SCAN_DEBUG] native game file=\"\(fileURL.path)\"")
      }
      let game = self.gamePayload(
        system: system,
        platformURL: platformURL,
        fileURL: fileURL,
        metadata: metadata
      )
      gameCount += 1
      onEvent([
        "phase": "gameFound",
        "scanId": scanId,
        "type": system.type,
        "platformName": system.name,
        "game": game,
      ])
    }
    onEvent([
      "phase": "platformCompleted",
      "scanId": scanId,
      "type": system.type,
      "platformName": system.name,
      "gameCount": gameCount,
    ])
    return gameCount
  }

  private func debugListDirectory(
    in directoryURL: URL,
    allowedExtensions: Set<String>
  ) {
    guard let enumerator = fileManager.enumerator(
      at: directoryURL,
      includingPropertiesForKeys: [.isRegularFileKey, .isHiddenKey],
      options: [.skipsHiddenFiles]
    ) else {
      print("[IOS_GB_SCAN_DEBUG] native debug enumerator nil directory=\"\(directoryURL.path)\"")
      return
    }

    var count = 0
    for case let fileURL as URL in enumerator {
      count += 1
      do {
        let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .isHiddenKey])
        let fileExtension = ".\(fileURL.pathExtension.lowercased())"
        print("[IOS_GB_SCAN_DEBUG] native debug entry path=\"\(fileURL.path)\" ext=\"\(fileExtension)\" regular=\(values.isRegularFile == true) hidden=\(values.isHidden == true) allowed=\(allowedExtensions.contains(fileExtension))")
      } catch {
        print("[IOS_GB_SCAN_DEBUG] native debug entry path=\"\(fileURL.path)\" resourceError=\"\(error.localizedDescription)\"")
      }
    }
    print("[IOS_GB_SCAN_DEBUG] native debug entryCount=\(count) directory=\"\(directoryURL.path)\"")
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
    return files.map {
      gamePayload(system: system, platformURL: platformURL, fileURL: $0, metadata: metadata)
    }
  }

  private func gamePayload(
    system: Host4RomSystemSpec,
    platformURL: URL,
    fileURL: URL,
    metadata: [String: Host4GameMetadata]
  ) -> [String: Any] {
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
    if let imagePath = gameMetadata?.imagePath, !imagePath.isEmpty { game["imagePath"] = imagePath }
    if let videoPath = gameMetadata?.videoPath, !videoPath.isEmpty { game["videoPath"] = videoPath }
    if let description = gameMetadata?.description, !description.isEmpty { game["description"] = description }
    return game
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
      guard !isAppleDoubleSidecar(fileURL) else { continue }
      let fileExtension = ".\(fileURL.pathExtension.lowercased())"
      if allowedExtensions.contains(fileExtension) {
        files.append(fileURL)
      }
    }
    return files.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
  }

  private func enumerateRomFiles(
    in directoryURL: URL,
    allowedExtensions: Set<String>,
    onFile: (URL) -> Void
  ) throws {
    guard let enumerator = fileManager.enumerator(
      at: directoryURL,
      includingPropertiesForKeys: [.isRegularFileKey, .isHiddenKey],
      options: [.skipsHiddenFiles]
    ) else { return }

    for case let fileURL as URL in enumerator {
      let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .isHiddenKey])
      guard values.isRegularFile == true, values.isHidden != true else { continue }
      guard !isAppleDoubleSidecar(fileURL) else { continue }
      if allowedExtensions.contains(".\(fileURL.pathExtension.lowercased())") {
        onFile(fileURL)
      }
    }
  }

  private func isAppleDoubleSidecar(_ fileURL: URL) -> Bool {
    fileURL.lastPathComponent.hasPrefix("._")
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
