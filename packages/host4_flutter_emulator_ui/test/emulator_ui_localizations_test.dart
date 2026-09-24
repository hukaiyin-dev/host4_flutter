import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';

void main() {
  test('generated delegate loads all six languages and formats placeholders', () async {
    final expected = {
      Locale('zh'): '快速存档',
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'): '快速存檔',
      Locale('ja'): 'クイックセーブ',
      Locale('en'): 'Quick Save',
      Locale('es'): 'Guardado rápido',
      Locale('id'): 'Simpan Cepat',
    };
    expect(EmulatorUiLocalizations.supportedLocales.toSet(), expected.keys.toSet());
    for (final entry in expected.entries) {
      final strings = await EmulatorUiLocalizations.delegate.load(entry.key);
      expect(strings.menuQuickSave, entry.value);
      expect(strings.menuSaveManagerUsed(2, 5), contains('2/5'));
      expect(strings.saveSlotName(3), contains('3'));
    }
  });
}
