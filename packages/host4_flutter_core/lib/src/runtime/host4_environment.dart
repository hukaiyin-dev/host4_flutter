/// Describes the execution environment the SDK is running in.
///
/// Concrete implementations are provided by the integration layer and
/// injected into modules at composition time. The SDK itself never reads
/// platform globals — it only depends on this interface.
///
/// Example integration-layer implementation:
/// ```dart
/// class ReleaseEnvironment implements Host4Environment {
///   @override
///   bool get isDebug => false;
///
///   @override
///   String get platformName => Platform.isIOS ? 'ios' : 'android';
/// }
/// ```
abstract interface class Host4Environment {
  /// Whether the app is running in debug mode.
  ///
  /// Modules may use this to enable verbose logging or disable sampling.
  bool get isDebug;

  /// The host platform identifier, e.g. `'ios'` or `'android'`.
  String get platformName;
}
