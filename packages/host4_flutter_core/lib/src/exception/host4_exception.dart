/// Base exception type for all host4_flutter SDK errors.
///
/// Catch [Host4Exception] to handle any SDK-originated error uniformly.
/// Catch a specific subclass for targeted recovery.
class Host4Exception implements Exception {
  const Host4Exception(this.message, {this.cause});

  final String message;

  /// The underlying error that caused this exception, if any.
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer('Host4Exception: $message');
    if (cause != null) buffer.write('\nCaused by: $cause');
    return buffer.toString();
  }
}

/// Thrown when a module method is called before [Host4Module.attach].
class Host4ModuleNotAttachedException extends Host4Exception {
  const Host4ModuleNotAttachedException(String moduleName)
      : super('Module "$moduleName" is not attached.');
}

/// Thrown when a required dependency is missing at composition time.
class Host4DependencyNotFoundException extends Host4Exception {
  const Host4DependencyNotFoundException(String dependencyName)
      : super('Required dependency not found: "$dependencyName".');
}
