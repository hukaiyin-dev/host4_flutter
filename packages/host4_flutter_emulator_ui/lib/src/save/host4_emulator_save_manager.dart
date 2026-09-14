import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/emulator_ui_strings.dart';
import '../model/host4_emulator_save_entry.dart';
import '../session/host4_emulator_session_actions.dart';

class Host4EmulatorSaveManager extends StatefulWidget {
  const Host4EmulatorSaveManager({
    required this.actions,
    required this.dataSource,
    required this.onBack,
    super.key,
  });

  final Host4EmulatorSessionActions actions;
  final Host4EmulatorSaveDataSource dataSource;
  final VoidCallback onBack;

  @override
  State<Host4EmulatorSaveManager> createState() =>
      _Host4EmulatorSaveManagerState();
}

class _Host4EmulatorSaveManagerState extends State<Host4EmulatorSaveManager> {
  Host4EmulatorSaveCatalog? _catalog;
  String? _error;
  bool _busy = false;
  int _loadEpoch = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant Host4EmulatorSaveManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataSource != widget.dataSource) _reload();
  }

  Future<void> _reload() async {
    final epoch = ++_loadEpoch;
    try {
      final catalog = await widget.dataSource.load();
      if (!mounted || epoch != _loadEpoch) return;
      setState(() {
        _catalog = catalog;
        _error = null;
      });
    } catch (error) {
      if (!mounted || epoch != _loadEpoch) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _reload();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete({required int slot, required bool quick}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(EmulatorUiStrings.t('save.deleteTitle')),
        content: Text(EmulatorUiStrings.t('save.deleteMessage')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(EmulatorUiStrings.t('save.cancel')),
          ),
          FilledButton(
            key: const ValueKey<String>('save.delete.confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(EmulatorUiStrings.t('save.delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      quick
          ? widget.actions.deleteQuickSave
          : () => widget.actions.deleteSlot(slot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    return Material(
      color: const Color(0xF211141A),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _Header(onBack: widget.onBack),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  key: const ValueKey<String>('save.error'),
                  style: const TextStyle(color: Color(0xFFFF7B7B)),
                ),
              ),
            Expanded(
              child: catalog == null
                  ? const Center(child: CircularProgressIndicator())
                  : IgnorePointer(
                      ignoring: _busy,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: <Widget>[
                          _SectionTitle(EmulatorUiStrings.t('save.quickSection')),
                          if (catalog.quick case final quick?)
                            _SaveCard(
                              key: const ValueKey<String>('save.quick'),
                              title: EmulatorUiStrings.t('save.quickLabel'),
                              entry: quick,
                              actions: <Widget>[
                                _ActionButton(
                                  keyName: 'save.quick.load',
                                  icon: Icons.play_arrow,
                                  label: EmulatorUiStrings.t('save.load'),
                                  onTap: () => _run(widget.actions.quickLoad),
                                ),
                                _ActionButton(
                                  keyName: 'save.quick.delete',
                                  icon: Icons.delete_outline,
                                  label: EmulatorUiStrings.t('save.delete'),
                                  onTap: () =>
                                      _confirmDelete(slot: 0, quick: true),
                                ),
                              ],
                            )
                          else
                            const _EmptyQuickSave(),
                          const SizedBox(height: 18),
                          _SectionTitle(EmulatorUiStrings.t('save.manualSection')),
                          for (
                            var slot = 1;
                            slot <= host4EmulatorManualSaveSlotCount;
                            slot++
                          )
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildSlot(catalog, slot),
                            ),
                        ],
                      ),
                    ),
            ),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(Host4EmulatorSaveCatalog catalog, int slot) {
    final entry = catalog.manualAt(slot);
    return _SaveCard(
      key: ValueKey<String>('save.slot.$slot'),
      title: EmulatorUiStrings.t('save.slotName', {'slot': slot}),
      entry: entry,
      actions: entry == null
          ? <Widget>[
              _ActionButton(
                keyName: 'save.slot.$slot.save',
                icon: Icons.add,
                label: EmulatorUiStrings.t('save.save'),
                onTap: () => _run(() => widget.actions.saveSlot(slot)),
              ),
            ]
          : <Widget>[
              _ActionButton(
                keyName: 'save.slot.$slot.load',
                icon: Icons.play_arrow,
                label: EmulatorUiStrings.t('save.load'),
                onTap: () => _run(() => widget.actions.loadSlot(slot)),
              ),
              _ActionButton(
                keyName: 'save.slot.$slot.overwrite',
                icon: Icons.save_outlined,
                label: EmulatorUiStrings.t('save.overwrite'),
                onTap: () => _run(() => widget.actions.saveSlot(slot)),
              ),
              _ActionButton(
                keyName: 'save.slot.$slot.delete',
                icon: Icons.delete_outline,
                label: EmulatorUiStrings.t('save.delete'),
                onTap: () => _confirmDelete(slot: slot, quick: false),
              ),
            ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          IconButton(
            key: const ValueKey<String>('save.back'),
            onPressed: onBack,
            color: Colors.white,
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              EmulatorUiStrings.t('save.title'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFB8BDC8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyQuickSave extends StatelessWidget {
  const _EmptyQuickSave();

  @override
  Widget build(BuildContext context) {
    return _SaveCard(
      key: const ValueKey<String>('save.quick.empty'),
      title: EmulatorUiStrings.t('save.noQuickSave'),
      actions: <Widget>[],
    );
  }
}

class _SaveCard extends StatelessWidget {
  const _SaveCard({
    required this.title,
    required this.actions,
    super.key,
    this.entry,
  });

  final String title;
  final Host4EmulatorSaveEntry? entry;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF292E38),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          _Thumbnail(bytes: entry?.thumbnailBytes),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (entry != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(entry!.modifiedAt),
                    style: const TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                ],
              ],
            ),
          ),
          Wrap(spacing: 6, children: actions),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.bytes});

  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: ColoredBox(
        color: const Color(0xFF171A20),
        child: SizedBox(
          width: 88,
          height: 56,
          child: bytes == null
              ? const Icon(Icons.videogame_asset, color: Color(0xFF5E6572))
              : Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: ValueKey<String>(keyName),
      tooltip: label,
      onPressed: onTap,
      color: Colors.white,
      icon: Icon(icon),
    );
  }
}

String _formatDate(DateTime value) {
  String two(int part) => part.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}
