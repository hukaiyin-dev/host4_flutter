import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Gmacro API test page exposes every GmacroMethods entry', () {
    final methodsSource = File(
      '../../packages/host4_flutter_gmacro/lib/src/Models/gmacro_methods.dart',
    ).readAsStringSync();
    final pageSource = File(
      'lib/pages/gmacro/gmacro_api_test_page.dart',
    ).readAsStringSync();

    final methods = RegExp(
      r"static const \w+ = '([^']+)';",
    ).allMatches(methodsSource).map((match) => match.group(1)!).toSet();

    expect(methods, isNotEmpty);
    expect(
      methods.difference(_apiPageMethodMentions(pageSource)),
      isEmpty,
      reason: 'Every GmacroMethods value should have a visible test entry.',
    );
  });
}

Set<String> _apiPageMethodMentions(String source) {
  final quoted = RegExp(
    r"'([^']+)'",
  ).allMatches(source).map((match) => match.group(1)!).toSet();
  final invoked = RegExp(
    r'\b([A-Za-z]\w*)\(',
  ).allMatches(source).map((match) => match.group(1)!).toSet();
  return {...quoted, ...invoked};
}
