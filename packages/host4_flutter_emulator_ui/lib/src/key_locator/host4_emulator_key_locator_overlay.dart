import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/emulator_ui_strings.dart';

class Host4EmulatorKeyLocatorOverlay extends StatefulWidget {
  const Host4EmulatorKeyLocatorOverlay({
    this.visibleDuration = const Duration(seconds: 3),
    super.key,
  });

  final Duration visibleDuration;

  @override
  State<Host4EmulatorKeyLocatorOverlay> createState() =>
      _Host4EmulatorKeyLocatorOverlayState();
}

class _Host4EmulatorKeyLocatorOverlayState
    extends State<Host4EmulatorKeyLocatorOverlay> {
  Timer? _timer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.visibleDuration, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Material(
      key: const ValueKey<String>('key_locate.guidance_overlay'),
      color: const Color(0xCC121A29),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final landscape = constraints.maxWidth > constraints.maxHeight;
          final designSize = landscape
              ? const Size(844, 390)
              : const Size(390, 844);
          return Semantics(
            container: true,
            explicitChildNodes: true,
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox.fromSize(
                size: designSize,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      top: landscape ? 48 : 73,
                      left: 0,
                      right: 0,
                      child: _LocatorHeader(landscape: landscape),
                    ),
                    Positioned(
                      top: landscape ? 120 : 138,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Image.asset(
                          landscape
                              ? 'assets/key_locator/instruction_landscape.png'
                              : 'assets/key_locator/instruction_portrait.png',
                          package: 'host4_flutter_emulator_ui',
                          width: landscape ? 432 : 336,
                          height: landscape ? 148 : 211,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    Positioned(
                      top: landscape ? 276 : 363,
                      left: 0,
                      right: 0,
                      child: _LocatorFooter(landscape: landscape),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LocatorHeader extends StatelessWidget {
  const _LocatorHeader({required this.landscape});

  final bool landscape;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          identifier: landscape
              ? 'landscape.key_locate.title'
              : 'key_locate.title',
          child: Text(
            EmulatorUiStrings.t('keyLocator.title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Alibaba PuHuiTi 2.0',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 22 / 20,
              letterSpacing: 0.1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          EmulatorUiStrings.t('keyLocator.instruction'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFF4F7FC),
            fontFamily: 'Alibaba PuHuiTi 2.0',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 18 / 14,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _LocatorFooter extends StatelessWidget {
  const _LocatorFooter({required this.landscape});

  final bool landscape;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          EmulatorUiStrings.t(landscape ? 'keyLocator.landscapeHint' : 'keyLocator.portraitHint'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFF4F7FC),
            fontFamily: 'Alibaba PuHuiTi 2.0',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 18 / 14,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          identifier: 'key_locate.status_text',
          child: Text(
            EmulatorUiStrings.t('keyLocator.gamepatchHint'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9BA8C3),
              fontFamily: 'Alibaba PuHuiTi 2.0',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 16 / 12,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
