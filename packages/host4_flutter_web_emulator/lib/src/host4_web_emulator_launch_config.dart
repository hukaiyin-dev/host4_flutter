import 'host4_web_emulator_core_cache.dart';
import 'host4_web_emulator_system.dart';

class Host4WebEmulatorLaunchConfig {
  Host4WebEmulatorLaunchConfig({
    required this.system,
    required this.romName,
    this.romFileUrl,
    this.romBase64,
    this.sramBase64,
    this.launchTimeout,
    this.outputProbeEnabled = false,
    this.webRtcPreviewRole,
    this.webRtcSignalUrl,
    this.webRtcRoomId,
    this.webRtcTransport = 'media',
    this.webRtcControlProfile,
    this.webRtcLatencyProbeEnabled = false,
    this.externalWebGlPreviewEnabled = false,
    this.semanticScreenshotPreviewEnabled = false,
    this.inWebViewCanvasMirrorPreviewEnabled = false,
  }) {
    if (webRtcPreviewRole != 'viewer' &&
        romFileUrl == null &&
        romBase64 == null) {
      throw ArgumentError('Either romFileUrl or romBase64 is required.');
    }
  }

  final Host4WebEmulatorSystem system;
  final Uri? romFileUrl;
  final String? romBase64;
  final String? sramBase64;
  final String romName;

  /// 仅用于首次加载核心，其他模拟器操作继续使用控制器的默认超时。
  final Duration? launchTimeout;

  /// Enables aggregate-only runtime diagnostics for the Web emulator POC.
  ///
  /// Kept off by default so production launches do not transform Core JS or
  /// emit diagnostic traffic.
  final bool outputProbeEnabled;

  /// Local-development WebRTC role. `publisher` sends the verified Core-frame
  /// canvas; `viewer` starts no emulator and displays only the received track.
  /// This is deliberately opt-in and has no production default.
  final String? webRtcPreviewRole;
  final String? webRtcSignalUrl;
  final String? webRtcRoomId;

  /// Debug-only transport selector. `media` uses a WebRTC video track;
  /// `data` is reserved for a latest-frame data-channel experiment.
  final String webRtcTransport;

  /// Platform-specific control profile announced by a publisher to its
  /// receiver. It is only used by the debug local WebRTC flow.
  final String? webRtcControlProfile;

  /// Development-only optical marker used to measure decoded-video latency.
  /// It is false by default and must never be enabled for a user session.
  final bool webRtcLatencyProbeEnabled;

  /// Captures the texture selected by RetroArch's final WebGL draw through
  /// public runtime objects. This leaves the supplied core JS/Wasm untouched.
  final bool externalWebGlPreviewEnabled;

  /// Requests a bounded-cadence screenshot from Nostalgist/RetroArch itself.
  /// This is separate from WebGL observation and leaves Core bytes untouched.
  final bool semanticScreenshotPreviewEnabled;

  /// Adds an in-WebView preview canvas. The frame remains in the WebView;
  /// no PNG/Base64 conversion or Flutter platform-channel transfer occurs.
  final bool inWebViewCanvasMirrorPreviewEnabled;

  Map<String, Object?> toJson({ResolvedCoreData? resolvedCoreData}) {
    final core = system.core;
    return <String, Object?>{
      'system': system.name,
      'launcherType': system.launcherType,
      'core': core.name,
      if (romFileUrl != null) 'romFileUrl': romFileUrl.toString(),
      if (romBase64 != null) 'romBase64': romBase64,
      if (sramBase64 != null) 'sramBase64': sramBase64,
      if (outputProbeEnabled) 'outputProbeEnabled': true,
      if (webRtcPreviewRole != null) 'webRtcPreviewRole': webRtcPreviewRole,
      if (webRtcSignalUrl != null) 'webRtcSignalUrl': webRtcSignalUrl,
      if (webRtcRoomId != null) 'webRtcRoomId': webRtcRoomId,
      if (webRtcPreviewRole != null) 'webRtcTransport': webRtcTransport,
      if (webRtcControlProfile != null)
        'webRtcControlProfile': webRtcControlProfile,
      if (webRtcLatencyProbeEnabled) 'webRtcLatencyProbeEnabled': true,
      if (externalWebGlPreviewEnabled) 'externalWebGlPreviewEnabled': true,
      if (semanticScreenshotPreviewEnabled)
        'semanticScreenshotPreviewEnabled': true,
      if (inWebViewCanvasMirrorPreviewEnabled)
        'inWebViewCanvasMirrorPreviewEnabled': true,
      'romName': romName,
      if (resolvedCoreData != null) ...{
        'coreJsBase64': resolvedCoreData.jsBase64,
        'coreWasmBase64': resolvedCoreData.wasmBase64,
      } else
        'coreZipUrl': core.zipUrl,
    };
  }
}
