import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_utils/host4_flutter_utils.dart';

void main() {
  test('reads nested json values by dot path', () {
    const json = {
      'meta': {
        'name': 'Demo Theme',
        'modes': ['light', 'dark'],
      },
      'primitive': {
        'spacing': {'md': 12},
      },
    };

    expect(readJsonString(json, 'meta.name'), 'Demo Theme');
    expect(readJsonStringList(json, 'meta.modes'), ['light', 'dark']);
    expect(readJsonDouble(json, 'primitive.spacing.md'), 12);
  });

  test('throws a clear error for missing json path', () {
    const json = {
      'meta': {'name': 'Demo Theme'},
    };

    expect(
      () => readJsonString(json, 'meta.id'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Missing json path: meta.id'),
        ),
      ),
    );
  });

  test('resolves brace references from a shared root map', () {
    const json = {
      'primitive': {
        'color': {
          'blue': {'500': '#335CFF'},
        },
      },
      'alias': {
        'shared': {
          'brand': '{primitive.color.blue.500}',
        },
      },
    };

    final resolved = const Host4ReferenceResolver(json).resolveMap(json);

    expect(readJsonString(resolved, 'alias.shared.brand'), '#335CFF');
  });

  test('throws a clear error for circular references', () {
    const json = {
      'alias': {
        'shared': {
          'primary': '{alias.shared.secondary}',
          'secondary': '{alias.shared.primary}',
        },
      },
    };

    expect(
      () => const Host4ReferenceResolver(json).resolveMap(json),
      throwsA(
        isA<FormatException>()
            .having(
              (error) => error.message,
              'message',
              contains('Circular token reference detected:'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('alias.shared.primary'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('alias.shared.secondary'),
            ),
      ),
    );
  });
}
