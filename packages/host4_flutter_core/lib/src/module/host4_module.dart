/// Lifecycle protocol for SDK modules in hybrid (native + Flutter) environments.
///
/// In a hybrid app the native host controls the FlutterEngine lifecycle.
/// Any module that holds resources must implement this interface so the
/// integration layer can coordinate attach / detach / reset without
/// coupling to concrete implementations.
///
/// Usage:
/// ```dart
/// class MyModule implements Host4Module {
///   @override
///   void attach() { /* initialize resources */ }
///
///   @override
///   void detach() { /* release resources */ }
///
///   @override
///   void reset() { /* clear state, stay detached */ }
/// }
/// ```
abstract interface class Host4Module {
  /// Called when the module is connected to a live Flutter environment.
  ///
  /// Initialize subscriptions, allocate resources, and register listeners
  /// here. Must be idempotent — calling [attach] on an already-attached
  /// module must not cause duplicate registrations.
  void attach();

  /// Called when the Flutter environment is going away.
  ///
  /// Release all held resources (streams, timers, listeners) to prevent
  /// memory leaks. After this call the module must behave as if it was
  /// never attached.
  void detach();

  /// Resets the module to its initial state without a full detach/attach cycle.
  ///
  /// Used in hot-restart and test scenarios. After reset the module is in the
  /// same state as after construction — not attached, all state cleared.
  void reset();
}
