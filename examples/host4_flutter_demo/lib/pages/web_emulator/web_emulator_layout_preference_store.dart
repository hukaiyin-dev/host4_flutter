import 'package:flutter/material.dart';
import 'package:host4_flutter_emulator_ui/host4_flutter_emulator_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class WebEmulatorLayoutPreferencePersistence {
  Future<Host4EmulatorControlLayoutStyle> load();

  Future<void> save(Host4EmulatorControlLayoutStyle style);
}

class WebEmulatorLayoutPreferenceStore
    implements WebEmulatorLayoutPreferencePersistence {
  const WebEmulatorLayoutPreferenceStore(this.preferences);

  static const String preferenceKey = 'host4.web_emulator.layout.v1';

  final SharedPreferences preferences;

  @override
  Future<Host4EmulatorControlLayoutStyle> load() async {
    return switch (preferences.getString(preferenceKey)) {
      'modern' => Host4EmulatorControlLayoutStyle.modern,
      _ => Host4EmulatorControlLayoutStyle.silicone,
    };
  }

  @override
  Future<void> save(Host4EmulatorControlLayoutStyle style) async {
    await preferences.setString(preferenceKey, style.name);
  }
}

class WebEmulatorSiliconeLayoutPreferenceStore {
  const WebEmulatorSiliconeLayoutPreferenceStore(this.preferences);

  static const String preferenceKey = 'host4.web_emulator.silicone_layout.v1';

  final SharedPreferences preferences;

  Future<Host4EmulatorSiliconeLayoutVariant> load() async {
    return switch (preferences.getString(preferenceKey)) {
      'retro_traditional' =>
        Host4EmulatorSiliconeLayoutVariant.retroTraditional,
      'modern_symmetric' => Host4EmulatorSiliconeLayoutVariant.modernSymmetric,
      'modern_asymmetric' =>
        Host4EmulatorSiliconeLayoutVariant.modernAsymmetric,
      _ => Host4EmulatorSiliconeLayoutVariant.silicone,
    };
  }

  Future<void> save(Host4EmulatorSiliconeLayoutVariant variant) async {
    await preferences.setString(preferenceKey, variant.wireName);
  }
}

class WebEmulatorLayoutPreferenceCoordinator {
  WebEmulatorLayoutPreferenceCoordinator(
    this._persistence, {
    this.onLog,
    this.currentStyle = Host4EmulatorControlLayoutStyle.silicone,
  });

  final Future<WebEmulatorLayoutPreferencePersistence> _persistence;
  final ValueChanged<String>? onLog;

  Host4EmulatorControlLayoutStyle currentStyle;
  int _selectionRevision = 0;

  Future<Host4EmulatorControlLayoutStyle?> load() async {
    final loadRevision = _selectionRevision;
    onLog?.call(
      'preference_load_started revision=$loadRevision '
      'current=${currentStyle.name}',
    );
    final persistence = await _persistence;
    final storedStyle = await persistence.load();
    onLog?.call(
      'preference_load_completed revision=$loadRevision '
      'stored=${storedStyle.name}',
    );
    if (loadRevision != _selectionRevision) {
      onLog?.call(
        'preference_load_ignored stale_revision=$loadRevision '
        'current_revision=$_selectionRevision '
        'current=${currentStyle.name}',
      );
      return null;
    }
    currentStyle = storedStyle;
    onLog?.call('preference_load_applied layout=${storedStyle.name}');
    return storedStyle;
  }

  Future<void> select(Host4EmulatorControlLayoutStyle style) async {
    final previousStyle = currentStyle;
    _selectionRevision += 1;
    currentStyle = style;
    onLog?.call(
      'selection_requested previous=${previousStyle.name} '
      'selected=${style.name} revision=$_selectionRevision',
    );
    final persistence = await _persistence;
    await persistence.save(style);
    onLog?.call(
      'selection_saved selected=${style.name} revision=$_selectionRevision',
    );
  }
}

class WebEmulatorLayoutSelector extends StatelessWidget {
  const WebEmulatorLayoutSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final Host4EmulatorControlLayoutStyle value;
  final ValueChanged<Host4EmulatorControlLayoutStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Host4EmulatorControlLayoutStyle>(
      segments: const <ButtonSegment<Host4EmulatorControlLayoutStyle>>[
        ButtonSegment<Host4EmulatorControlLayoutStyle>(
          value: Host4EmulatorControlLayoutStyle.modern,
          label: Text('通用布局'),
        ),
        ButtonSegment<Host4EmulatorControlLayoutStyle>(
          value: Host4EmulatorControlLayoutStyle.silicone,
          label: Text('硅胶布局'),
        ),
      ],
      selected: <Host4EmulatorControlLayoutStyle>{value},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}
