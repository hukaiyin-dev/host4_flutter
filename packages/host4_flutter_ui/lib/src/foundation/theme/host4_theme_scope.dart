import 'package:flutter/widgets.dart';

import 'host4_runtime_theme.dart';
import 'host4_theme_manager.dart';

class Host4ThemeScope extends InheritedNotifier<Host4ThemeManager> {
  const Host4ThemeScope({
    required Host4ThemeManager manager,
    required super.child,
    super.key,
  }) : super(notifier: manager);

  static Host4ThemeManager managerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<Host4ThemeScope>();
    if (scope?.notifier == null) {
      throw FlutterError('Host4ThemeScope not found in context.');
    }
    return scope!.notifier!;
  }

  static Host4RuntimeTheme of(BuildContext context) {
    return managerOf(context).theme;
  }
}

extension Host4ThemeContext on BuildContext {
  Host4RuntimeTheme get host4Theme => Host4ThemeScope.of(this);
  Host4ThemeManager get host4ThemeManager => Host4ThemeScope.managerOf(this);
}
