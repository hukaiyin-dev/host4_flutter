# Shared emulator UI

## Localization

Menu, save manager, layout picker and key locator strings use Flutter `gen_l10n`.
Edit all six `lib/l10n/emulator_ui_*.arb` files, then run `flutter gen-l10n` from this package. Generated Dart sources live in `lib/l10n/generated` and are included in the repository; do not edit them manually.

Consumers must register `EmulatorUiLocalizations.delegate` alongside their app delegates and configure `locale` / `supportedLocales`. Standalone consumers can use `EmulatorUiLocalizations.localizationsDelegates` and `EmulatorUiLocalizations.supportedLocales` directly.

Widgets read `EmulatorUiLocalizations.of(context)` and rebuild through Flutter `Localizations`. There is no global locale setter. Layout variant labels use `variant.title(context)`.

Supported languages: Simplified Chinese (`zh`), Traditional Chinese (`zh_Hant`), English, Japanese, Spanish and Indonesian. Save-count and slot-name arguments are typed ARB placeholders.
