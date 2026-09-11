import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/emulator_ui_strings.dart';
import '../model/host4_emulator_silicone_layout_variant.dart';

class Host4EmulatorSiliconeLayoutPicker extends StatefulWidget {
  const Host4EmulatorSiliconeLayoutPicker({
    required this.selectedVariant,
    required this.onSelected,
    required this.onBack,
    super.key,
  });

  final Host4EmulatorSiliconeLayoutVariant selectedVariant;
  final ValueChanged<Host4EmulatorSiliconeLayoutVariant> onSelected;
  final VoidCallback onBack;

  @override
  State<Host4EmulatorSiliconeLayoutPicker> createState() =>
      _Host4EmulatorSiliconeLayoutPickerState();
}

class _Host4EmulatorSiliconeLayoutPickerState
    extends State<Host4EmulatorSiliconeLayoutPicker> {
  late Host4EmulatorSiliconeLayoutVariant _selected = widget.selectedVariant;

  @override
  void didUpdateWidget(covariant Host4EmulatorSiliconeLayoutPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedVariant != widget.selectedVariant) {
      _selected = widget.selectedVariant;
    }
  }

  void _select(Host4EmulatorSiliconeLayoutVariant variant) {
    setState(() => _selected = variant);
    widget.onSelected(variant);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _LayoutPickerColors.mask,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final landscape = constraints.maxWidth > constraints.maxHeight;
          final baseWidth = landscape ? 844.0 : 390.0;
          final scale = (constraints.maxWidth / baseWidth).clamp(0.0, 2.0);
          final panelWidth = (landscape ? 352.0 : 342.0) * scale;
          final top = (landscape ? 28.0 : 72.0) * scale;
          return Stack(
            children: <Widget>[
              Positioned(
                left: (constraints.maxWidth - panelWidth) / 2,
                top: top,
                width: panelWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _LayoutPickerHeader(scale: scale, onBack: widget.onBack),
                    SizedBox(height: 12 * scale),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: host4EmulatorSiliconeLayoutPickerOrder.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8 * scale,
                        crossAxisSpacing: 8 * scale,
                        childAspectRatio: landscape ? 172 / 115 : 1.44,
                      ),
                      itemBuilder: (context, index) {
                        final variant =
                            host4EmulatorSiliconeLayoutPickerOrder[index];
                        return _LayoutOptionCard(
                          variant: variant,
                          scale: scale,
                          selected: variant == _selected,
                          onTap: () => _select(variant),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LayoutPickerHeader extends StatelessWidget {
  const _LayoutPickerHeader({required this.scale, required this.onBack});

  final double scale;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey<String>('layout.back'),
      container: true,
      identifier: 'layout.back',
      button: true,
      child: InkWell(
        onTap: onBack,
        borderRadius: BorderRadius.circular(8 * scale),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2 * scale),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.arrow_back_ios_new,
                color: _LayoutPickerColors.radialEdge,
                size: 20 * scale,
              ),
              SizedBox(width: 8 * scale),
              Text(
                EmulatorUiStrings.t('layout.title'),
                style: TextStyle(
                  color: _LayoutPickerColors.label,
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w900,
                  height: 18 / 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayoutOptionCard extends StatelessWidget {
  const _LayoutOptionCard({
    required this.variant,
    required this.scale,
    required this.selected,
    required this.onTap,
  });

  final Host4EmulatorSiliconeLayoutVariant variant;
  final double scale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final identifier = 'layout.option.${variant.wireName}';
    return Semantics(
      key: ValueKey<String>(identifier),
      container: true,
      identifier: identifier,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8 * scale),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: selected
                ? _LayoutPickerColors.selected
                : _LayoutPickerColors.card,
            borderRadius: BorderRadius.circular(8 * scale),
            border: Border.all(
              color: selected
                  ? _LayoutPickerColors.selected
                  : _LayoutPickerColors.cardBorder,
              width: scale,
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 4 * scale,
                top: 4 * scale,
                width: 164 * scale,
                height: 107 * scale,
                child: SvgPicture.asset(
                  'assets/layout_picker/card_shape_${selected ? 'selected' : 'unselected'}.svg',
                  package: 'host4_flutter_emulator_ui',
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                left: 4 * scale,
                top: 4 * scale,
                right: 4 * scale,
                bottom: 31 * scale,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4 * scale),
                  child: Image.asset(
                    'assets/layout_picker/${variant.wireName}.png',
                    package: 'host4_flutter_emulator_ui',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              Positioned(
                left: 8 * scale,
                right: 64 * scale,
                bottom: 8 * scale,
                child: Text(
                  variant.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _LayoutPickerColors.label,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w900,
                    height: 18 / 14,
                  ),
                ),
              ),
              Positioned(
                right: 8 * scale,
                bottom: 8 * scale,
                child: Container(
                  width: 48 * scale,
                  height: 16 * scale,
                  decoration: BoxDecoration(
                    color: selected
                        ? _LayoutPickerColors.brand
                        : _LayoutPickerColors.pill,
                    borderRadius: BorderRadius.circular(8 * scale),
                    border: selected
                        ? null
                        : Border.all(
                            color: _LayoutPickerColors.label,
                            width: scale,
                          ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    selected ? Icons.check : Icons.swap_horiz,
                    color: selected
                        ? _LayoutPickerColors.radialEdge
                        : _LayoutPickerColors.label,
                    size: 14 * scale,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayoutPickerColors {
  const _LayoutPickerColors._();

  static const mask = Color(0xCC121A29);
  static const selected = Color(0xFF4A3097);
  static const card = Color(0xFF243147);
  static const cardBorder = Color(0xFF2A3A55);
  static const label = Color(0xFF9BA8C3);
  static const brand = Color(0xFF774FEF);
  static const radialEdge = Color(0xFFF1EDFD);
  static const pill = Color(0xFF0D1727);
}
