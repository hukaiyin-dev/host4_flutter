import 'dart:math' as math;

import 'package:display_metrics/display_metrics.dart';
import 'package:flutter/widgets.dart';

enum Host4EmulatorSiliconePadSide { single, left, right }

enum Host4EmulatorSiliconePadSlot {
  dpad,
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,
  actionTop,
  actionLeft,
  actionRight,
  actionBottom,
  innerTop,
  innerBottom,
}

class Host4EmulatorSiliconeMetrics {
  const Host4EmulatorSiliconeMetrics({
    required this.logicalPixelsPerMillimeter,
  });

  final double logicalPixelsPerMillimeter;

  static Host4EmulatorSiliconeMetrics of(BuildContext context) {
    final DisplayMetricsData? data = DisplayMetrics.maybeOf(context);
    final double lpPerInch = data?.inchesToLogicalPixelRatio ?? 0;
    if (lpPerInch > 0) {
      return Host4EmulatorSiliconeMetrics(
        logicalPixelsPerMillimeter: lpPerInch / 25.4,
      );
    }
    return const Host4EmulatorSiliconeMetrics(
      logicalPixelsPerMillimeter: 160 / 25.4,
    );
  }

  double mm(double value) => value * logicalPixelsPerMillimeter;
}

class Host4EmulatorSiliconeResolvedControl {
  const Host4EmulatorSiliconeResolvedControl({
    required this.semanticsIdentifier,
    required this.center,
    required this.visualSize,
    required this.hitRect,
    this.borderRadius,
  });

  final String semanticsIdentifier;
  final Offset center;
  final Size visualSize;
  final Rect hitRect;
  final double? borderRadius;

  Rect get visualRect => Rect.fromCenter(
    center: center,
    width: visualSize.width,
    height: visualSize.height,
  );
}

class Host4EmulatorSiliconeResolvedLayout {
  const Host4EmulatorSiliconeResolvedLayout({
    required this.controls,
    required this.padSlots,
    required this.padBounds,
    this.systemButtonsAtTop = false,
    this.gameViewportTop = 0,
    this.minimumPadTop = 0,
    this.maximumPadTop = 0,
  });

  final Map<String, Host4EmulatorSiliconeResolvedControl> controls;
  final Map<
    Host4EmulatorSiliconePadSide,
    Map<Host4EmulatorSiliconePadSlot, Host4EmulatorSiliconeResolvedControl>
  >
  padSlots;
  final Map<Host4EmulatorSiliconePadSide, Rect> padBounds;
  final bool systemButtonsAtTop;
  final double gameViewportTop;
  final double minimumPadTop;
  final double maximumPadTop;

  Host4EmulatorSiliconeResolvedControl control(String semanticsIdentifier) {
    final Host4EmulatorSiliconeResolvedControl? c =
        controls[semanticsIdentifier];
    if (c == null) {
      throw StateError('Missing silicone control: $semanticsIdentifier');
    }
    return c;
  }

  Host4EmulatorSiliconeResolvedControl slot(
    Host4EmulatorSiliconePadSide side,
    Host4EmulatorSiliconePadSlot slot,
  ) {
    final Host4EmulatorSiliconeResolvedControl? c = padSlots[side]?[slot];
    if (c == null) {
      throw StateError('Missing silicone slot: $side.$slot');
    }
    return c;
  }
}

class Host4EmulatorSiliconeLayoutResolver {
  const Host4EmulatorSiliconeLayoutResolver._();

  static const double padWidthMm = 63.9;
  static const double padHeightMm = 30.5;
  static const Size landscapeSystemButtonSize = Size.square(42);

  static Rect landscapeSetButtonRect(Size screenSize) {
    return Rect.fromCenter(
      center: Offset(
        screenSize.width / 2 - _landscapeSystemButtonCenterOffset,
        screenSize.height - _landscapeSystemButtonBottomMargin,
      ),
      width: landscapeSystemButtonSize.width,
      height: landscapeSystemButtonSize.height,
    );
  }

  static Rect landscapeHideToggleRect(Size screenSize) {
    return Rect.fromCenter(
      center: Offset(
        screenSize.width / 2 + _landscapeSystemButtonCenterOffset,
        screenSize.height - _landscapeSystemButtonBottomMargin,
      ),
      width: landscapeSystemButtonSize.width,
      height: landscapeSystemButtonSize.height,
    );
  }

  static Host4EmulatorSiliconeResolvedLayout portrait({
    required Size screenSize,
    required Host4EmulatorSiliconeMetrics metrics,
    double topInset = 0,
    double bottomInset = 0,
    double? padPosition,
    bool systemButtonsAtTop = false,
    bool hasShoulderButtons = true,
  }) {
    final Size padSize = Size(metrics.mm(padWidthMm), metrics.mm(padHeightMm));
    final double left = (screenSize.width - padSize.width) / 2;
    final double preferredTop =
        topInset + (screenSize.height - topInset - bottomInset) / 2;
    final double scale = screenSize.width / _portraitBaseWidth;
    final double shoulderH = padSize.height * _portraitShoulderHeightRatio;
    final double lowerSlotCenterY =
        screenSize.height -
        _portraitLowerSlotBottomMargin * scale -
        shoulderH / 2;
    final double gap = 12 * scale;
    final double buttonSize = _portraitBottomButtonSize * scale;
    final double buttonBottomTop = screenSize.height - bottomInset -
        _portraitBottomButtonBottomMargin * scale - buttonSize;
    final double maximumTop = math.max(topInset,
        screenSize.height - bottomInset - padSize.height);
    final double minimumTop = math.min(maximumTop,
        topInset + buttonSize + gap * 2);
    final double defaultTop = math.min(
        lowerSlotCenterY - padSize.height / 2,
        buttonBottomTop - gap - padSize.height)
        .clamp(minimumTop, maximumTop).toDouble();
    final double shoulderDefaultCenter = math.min(
        preferredTop + padSize.height / 2,
        defaultTop - gap - shoulderH / 2);
    double top = (padPosition == null
        ? defaultTop : padPosition * screenSize.height)
        .clamp(minimumTop, maximumTop).toDouble();
    // Only the pad crossing the bottom toolbar moves that toolbar to the top.
    // Keep a small return margin to avoid toggling at the collision boundary.
    final bool buttonsAtTop = top + padSize.height >
        buttonBottomTop - (systemButtonsAtTop ? 8 * scale : 0);
    final bool shouldersBelow = hasShoulderButtons && !buttonsAtTop &&
        top < shoulderDefaultCenter + shoulderH / 2;
    if (shouldersBelow) {
      top = top.clamp(minimumTop, math.max(minimumTop,
          buttonBottomTop - gap * 2 - shoulderH - padSize.height))
          .toDouble();
    }
    final double shoulderCenter = shouldersBelow
        ? top + padSize.height + gap + shoulderH / 2
        : top - gap - shoulderH / 2;
    final double buttonTop = buttonsAtTop ? topInset + gap : buttonBottomTop;

    final Offset origin = Offset(left, top);
    final Map<String, Host4EmulatorSiliconeResolvedControl> controls =
        <String, Host4EmulatorSiliconeResolvedControl>{};
    final Map<
      Host4EmulatorSiliconePadSlot,
      Host4EmulatorSiliconeResolvedControl
    >
    slots = _buildPadSlots(metrics: metrics, origin: origin);

    _addControlFromSlot(
      controls,
      semanticsIdentifier: 'game.controls.dpad',
      control: slots[Host4EmulatorSiliconePadSlot.dpad]!,
    );
    _addControlFromSlot(
      controls,
      semanticsIdentifier: 'game.controls.btn_x',
      control: slots[Host4EmulatorSiliconePadSlot.actionTop]!,
    );
    _addControlFromSlot(
      controls,
      semanticsIdentifier: 'game.controls.btn_y',
      control: slots[Host4EmulatorSiliconePadSlot.actionLeft]!,
    );
    _addControlFromSlot(
      controls,
      semanticsIdentifier: 'game.controls.btn_a',
      control: slots[Host4EmulatorSiliconePadSlot.actionRight]!,
    );
    _addControlFromSlot(
      controls,
      semanticsIdentifier: 'game.controls.btn_b',
      control: slots[Host4EmulatorSiliconePadSlot.actionBottom]!,
    );
    _addControlFromSlot(
      controls,
      semanticsIdentifier: 'game.controls.btn_start',
      control: slots[Host4EmulatorSiliconePadSlot.innerTop]!,
    );
    _addControlFromSlot(
      controls,
      semanticsIdentifier: 'game.controls.btn_select',
      control: slots[Host4EmulatorSiliconePadSlot.innerBottom]!,
    );

    final Rect padBounds = origin & padSize;
    _addVirtualPortraitControls(
      controls,
      screenSize,
      padBounds,
      shoulderCenterY: shoulderCenter,
      systemButtonTop: buttonTop,
    );

    return Host4EmulatorSiliconeResolvedLayout(
      systemButtonsAtTop: buttonsAtTop,
      gameViewportTop: buttonsAtTop ? buttonTop + buttonSize + gap : 0,
      minimumPadTop: minimumTop,
      maximumPadTop: maximumTop,
      controls: controls,
      padSlots:
          <
            Host4EmulatorSiliconePadSide,
            Map<
              Host4EmulatorSiliconePadSlot,
              Host4EmulatorSiliconeResolvedControl
            >
          >{Host4EmulatorSiliconePadSide.single: slots},
      padBounds: <Host4EmulatorSiliconePadSide, Rect>{
        Host4EmulatorSiliconePadSide.single: padBounds,
      },
    );
  }

  static Host4EmulatorSiliconeResolvedLayout landscape({
    required Size screenSize,
    required Host4EmulatorSiliconeMetrics metrics,
  }) {
    final Size rotatedPadSize = Size(
      metrics.mm(padHeightMm),
      metrics.mm(padWidthMm),
    );
    final double sideInset = math.max(8, screenSize.width * 0.075);
    final double top = math.max(
      0,
      (screenSize.height - rotatedPadSize.height) / 2,
    );
    final Rect screenLeftPad = Offset(sideInset, top) & rotatedPadSize;
    final Rect screenRightPad =
        Offset(screenSize.width - sideInset - rotatedPadSize.width, top) &
        rotatedPadSize;

    final Map<String, Host4EmulatorSiliconeResolvedControl> controls =
        <String, Host4EmulatorSiliconeResolvedControl>{};
    final Map<
      Host4EmulatorSiliconePadSlot,
      Host4EmulatorSiliconeResolvedControl
    >
    leftSlots = _buildPadSlots(
      metrics: metrics,
      origin: screenLeftPad.topLeft,
      clockwise: true,
    );
    final Map<
      Host4EmulatorSiliconePadSlot,
      Host4EmulatorSiliconeResolvedControl
    >
    rightSlots = _buildPadSlots(
      metrics: metrics,
      origin: screenRightPad.topLeft,
      clockwise: false,
    );
    _addLandscapePadControls(
      controls,
      slots: leftSlots,
      metrics: metrics,
      dpadIdentifier: 'landscape.controls.dpad_left',
      actionIdentifier: 'landscape.controls.action_cluster_left',
      primaryInnerIdentifier: 'landscape.controls.btn_l1',
      secondaryInnerIdentifier: 'landscape.controls.btn_select',
    );
    _addLandscapePadControls(
      controls,
      slots: rightSlots,
      metrics: metrics,
      dpadIdentifier: 'landscape.controls.dpad_right',
      actionIdentifier: 'landscape.controls.action_cluster',
      primaryInnerIdentifier: 'landscape.controls.btn_r1',
      secondaryInnerIdentifier: 'landscape.controls.btn_start',
    );
    _addLandscapeVirtualControls(controls, screenSize, metrics);

    return Host4EmulatorSiliconeResolvedLayout(
      controls: controls,
      padSlots:
          <
            Host4EmulatorSiliconePadSide,
            Map<
              Host4EmulatorSiliconePadSlot,
              Host4EmulatorSiliconeResolvedControl
            >
          >{
            Host4EmulatorSiliconePadSide.left: leftSlots,
            Host4EmulatorSiliconePadSide.right: rightSlots,
          },
      padBounds: <Host4EmulatorSiliconePadSide, Rect>{
        Host4EmulatorSiliconePadSide.left: screenLeftPad,
        Host4EmulatorSiliconePadSide.right: screenRightPad,
      },
    );
  }

  static Rect _rect(String id, Host4EmulatorSiliconeMetrics metrics) {
    final _HotZoneMm zone = _zones[id]!;
    return Rect.fromLTWH(
      metrics.mm(zone.left),
      metrics.mm(zone.top),
      metrics.mm(zone.width),
      metrics.mm(zone.height),
    );
  }

  static void _addLandscapePadControls(
    Map<String, Host4EmulatorSiliconeResolvedControl> controls, {
    required Map<
      Host4EmulatorSiliconePadSlot,
      Host4EmulatorSiliconeResolvedControl
    >
    slots,
    required Host4EmulatorSiliconeMetrics metrics,
    required String dpadIdentifier,
    required String actionIdentifier,
    required String primaryInnerIdentifier,
    required String secondaryInnerIdentifier,
  }) {
    _addControlFromSlot(
      controls,
      semanticsIdentifier: dpadIdentifier,
      control: slots[Host4EmulatorSiliconePadSlot.dpad]!,
    );
    _addBoundsControl(
      controls,
      semanticsIdentifier: actionIdentifier,
      rects: <Rect>[
        slots[Host4EmulatorSiliconePadSlot.actionBottom]!.hitRect,
        slots[Host4EmulatorSiliconePadSlot.actionRight]!.hitRect,
        slots[Host4EmulatorSiliconePadSlot.actionLeft]!.hitRect,
        slots[Host4EmulatorSiliconePadSlot.actionTop]!.hitRect,
      ],
    );
    _addControlFromSlot(
      controls,
      semanticsIdentifier: primaryInnerIdentifier,
      control: slots[Host4EmulatorSiliconePadSlot.innerTop]!,
    );
    _addControlFromSlot(
      controls,
      semanticsIdentifier: secondaryInnerIdentifier,
      control: slots[Host4EmulatorSiliconePadSlot.innerBottom]!,
    );
  }

  static Map<Host4EmulatorSiliconePadSlot, Host4EmulatorSiliconeResolvedControl>
  _buildPadSlots({
    required Host4EmulatorSiliconeMetrics metrics,
    required Offset origin,
    bool? clockwise,
  }) {
    Rect rect(String id) {
      final Rect base = _rect(id, metrics);
      return (clockwise == null ? base : _rotateRect(base, metrics, clockwise))
          .shift(origin);
    }

    Host4EmulatorSiliconeResolvedControl rectControl(
      Host4EmulatorSiliconePadSlot slot,
      Rect rect, {
      double? borderRadius,
    }) {
      return Host4EmulatorSiliconeResolvedControl(
        semanticsIdentifier: 'silicone.slot.${slot.name}',
        center: rect.center,
        visualSize: rect.size,
        hitRect: rect,
        borderRadius: borderRadius,
      );
    }

    final Rect dpadBounds = _bounds(<Rect>[
      rect('up'),
      rect('down'),
      rect('left'),
      rect('right'),
    ]);
    final Host4EmulatorSiliconeResolvedControl physicalActionTop = rectControl(
      Host4EmulatorSiliconePadSlot.actionTop,
      rect('actionTop'),
      borderRadius: rect('actionTop').shortestSide / 2,
    );
    final Host4EmulatorSiliconeResolvedControl physicalActionLeft = rectControl(
      Host4EmulatorSiliconePadSlot.actionLeft,
      rect('actionLeft'),
      borderRadius: rect('actionLeft').shortestSide / 2,
    );
    final Host4EmulatorSiliconeResolvedControl physicalActionRight =
        rectControl(
          Host4EmulatorSiliconePadSlot.actionRight,
          rect('actionRight'),
          borderRadius: rect('actionRight').shortestSide / 2,
        );
    final Host4EmulatorSiliconeResolvedControl physicalActionBottom =
        rectControl(
          Host4EmulatorSiliconePadSlot.actionBottom,
          rect('actionBottom'),
          borderRadius: rect('actionBottom').shortestSide / 2,
        );

    final Map<
      Host4EmulatorSiliconePadSlot,
      Host4EmulatorSiliconeResolvedControl
    >
    actionSlots = switch (clockwise) {
      null =>
        <Host4EmulatorSiliconePadSlot, Host4EmulatorSiliconeResolvedControl>{
          Host4EmulatorSiliconePadSlot.actionTop: physicalActionTop,
          Host4EmulatorSiliconePadSlot.actionLeft: physicalActionLeft,
          Host4EmulatorSiliconePadSlot.actionRight: physicalActionRight,
          Host4EmulatorSiliconePadSlot.actionBottom: physicalActionBottom,
        },
      true =>
        <Host4EmulatorSiliconePadSlot, Host4EmulatorSiliconeResolvedControl>{
          Host4EmulatorSiliconePadSlot.actionTop: physicalActionLeft,
          Host4EmulatorSiliconePadSlot.actionLeft: physicalActionBottom,
          Host4EmulatorSiliconePadSlot.actionRight: physicalActionTop,
          Host4EmulatorSiliconePadSlot.actionBottom: physicalActionRight,
        },
      false =>
        <Host4EmulatorSiliconePadSlot, Host4EmulatorSiliconeResolvedControl>{
          Host4EmulatorSiliconePadSlot.actionTop: physicalActionRight,
          Host4EmulatorSiliconePadSlot.actionLeft: physicalActionTop,
          Host4EmulatorSiliconePadSlot.actionRight: physicalActionBottom,
          Host4EmulatorSiliconePadSlot.actionBottom: physicalActionLeft,
        },
    };

    return <Host4EmulatorSiliconePadSlot, Host4EmulatorSiliconeResolvedControl>{
      Host4EmulatorSiliconePadSlot.dpad: rectControl(
        Host4EmulatorSiliconePadSlot.dpad,
        dpadBounds,
      ),
      Host4EmulatorSiliconePadSlot.dpadUp: rectControl(
        Host4EmulatorSiliconePadSlot.dpadUp,
        rect('up'),
        borderRadius: metrics.mm(2.1),
      ),
      Host4EmulatorSiliconePadSlot.dpadDown: rectControl(
        Host4EmulatorSiliconePadSlot.dpadDown,
        rect('down'),
        borderRadius: metrics.mm(2.1),
      ),
      Host4EmulatorSiliconePadSlot.dpadLeft: rectControl(
        Host4EmulatorSiliconePadSlot.dpadLeft,
        rect('left'),
        borderRadius: metrics.mm(2.1),
      ),
      Host4EmulatorSiliconePadSlot.dpadRight: rectControl(
        Host4EmulatorSiliconePadSlot.dpadRight,
        rect('right'),
        borderRadius: metrics.mm(2.1),
      ),
      ...actionSlots,
      Host4EmulatorSiliconePadSlot.innerTop: rectControl(
        Host4EmulatorSiliconePadSlot.innerTop,
        rect('innerTop'),
        borderRadius: metrics.mm(1.7),
      ),
      Host4EmulatorSiliconePadSlot.innerBottom: rectControl(
        Host4EmulatorSiliconePadSlot.innerBottom,
        rect('innerBottom'),
        borderRadius: metrics.mm(1.7),
      ),
    };
  }

  static Rect _rotateRect(
    Rect rect,
    Host4EmulatorSiliconeMetrics metrics,
    bool clockwise,
  ) {
    final double width = metrics.mm(padWidthMm);
    final double height = metrics.mm(padHeightMm);
    if (clockwise) {
      return Rect.fromLTWH(
        height - rect.bottom,
        rect.left,
        rect.height,
        rect.width,
      );
    }
    return Rect.fromLTWH(rect.top, width - rect.right, rect.height, rect.width);
  }

  static void _addRectControl(
    Map<String, Host4EmulatorSiliconeResolvedControl> controls, {
    required String semanticsIdentifier,
    required Rect rect,
  }) {
    controls[semanticsIdentifier] = Host4EmulatorSiliconeResolvedControl(
      semanticsIdentifier: semanticsIdentifier,
      center: rect.center,
      visualSize: rect.size,
      hitRect: rect,
    );
  }

  static void _addControlFromSlot(
    Map<String, Host4EmulatorSiliconeResolvedControl> controls, {
    required String semanticsIdentifier,
    required Host4EmulatorSiliconeResolvedControl control,
  }) {
    controls[semanticsIdentifier] = Host4EmulatorSiliconeResolvedControl(
      semanticsIdentifier: semanticsIdentifier,
      center: control.center,
      visualSize: control.visualSize,
      hitRect: control.hitRect,
    );
  }

  static void _addBoundsControl(
    Map<String, Host4EmulatorSiliconeResolvedControl> controls, {
    required String semanticsIdentifier,
    required List<Rect> rects,
  }) {
    final Rect bounds = _bounds(rects);
    controls[semanticsIdentifier] = Host4EmulatorSiliconeResolvedControl(
      semanticsIdentifier: semanticsIdentifier,
      center: bounds.center,
      visualSize: bounds.size,
      hitRect: bounds,
    );
  }

  static Rect _bounds(List<Rect> rects) {
    Rect bounds = rects.first;
    for (final Rect rect in rects.skip(1)) {
      bounds = bounds.expandToInclude(rect);
    }
    return bounds;
  }

  static void _addVirtualPortraitControls(
    Map<String, Host4EmulatorSiliconeResolvedControl> controls,
    Size screenSize,
    Rect padBounds, {
    required double shoulderCenterY,
    required double systemButtonTop,
  }) {
    final double scale = screenSize.width / _portraitBaseWidth;
    final double shoulderW = padBounds.width * _portraitShoulderWidthRatio;
    final double shoulderH = padBounds.height * _portraitShoulderHeightRatio;
    final double bottomButtonSize = _portraitBottomButtonSize * scale;
    final double bottomButtonTop = systemButtonTop;
    final double bottomButtonCenterY = bottomButtonTop + bottomButtonSize / 2;
    _addRectControl(
      controls,
      semanticsIdentifier: 'game.controls.btn_l',
      rect: Rect.fromCenter(
        center: Offset(
          padBounds.left + padBounds.width * _portraitLeftShoulderCenterXRatio,
          shoulderCenterY,
        ),
        width: shoulderW,
        height: shoulderH,
      ),
    );
    _addRectControl(
      controls,
      semanticsIdentifier: 'game.controls.btn_r',
      rect: Rect.fromCenter(
        center: Offset(
          padBounds.left + padBounds.width * _portraitRightShoulderCenterXRatio,
          shoulderCenterY,
        ),
        width: shoulderW,
        height: shoulderH,
      ),
    );
    _addSystemControl(
      controls,
      semanticsIdentifier: 'game.controls.btn_set',
      center: Offset(screenSize.width / 2, bottomButtonCenterY),
      size: Size.square(bottomButtonSize),
    );
    _addSystemControl(
      controls,
      semanticsIdentifier: 'game.controls.btn_locate_placeholder',
      center: Offset(
        _portraitBottomButtonSideMargin * scale + bottomButtonSize / 2,
        bottomButtonCenterY,
      ),
      size: Size.square(bottomButtonSize),
    );
    _addSystemControl(
      controls,
      semanticsIdentifier: 'game.controls.btn_hide_toggle',
      center: Offset(
        screenSize.width -
            _portraitBottomButtonSideMargin * scale -
            bottomButtonSize / 2,
        bottomButtonCenterY,
      ),
      size: Size.square(bottomButtonSize),
    );
  }

  static void _addLandscapeVirtualControls(
    Map<String, Host4EmulatorSiliconeResolvedControl> controls,
    Size screenSize,
    Host4EmulatorSiliconeMetrics metrics,
  ) {
    final double shoulderW = metrics.mm(11.43);
    final double shoulderH = metrics.mm(5);
    _addRectControl(
      controls,
      semanticsIdentifier: 'landscape.controls.btn_l2',
      rect: Rect.fromCenter(
        center: Offset(screenSize.width * 0.384, 52),
        width: shoulderW,
        height: shoulderH,
      ),
    );
    _addRectControl(
      controls,
      semanticsIdentifier: 'landscape.controls.btn_r2',
      rect: Rect.fromCenter(
        center: Offset(screenSize.width * 0.616, 52),
        width: shoulderW,
        height: shoulderH,
      ),
    );
    _addSystemControl(
      controls,
      semanticsIdentifier: 'landscape.controls.btn_set',
      rect: landscapeSetButtonRect(screenSize),
    );
    _addSystemControl(
      controls,
      semanticsIdentifier: 'landscape.controls.hide_toggle',
      rect: landscapeHideToggleRect(screenSize),
    );
  }

  static void _addSystemControl(
    Map<String, Host4EmulatorSiliconeResolvedControl> controls, {
    required String semanticsIdentifier,
    Offset? center,
    Rect? rect,
    Size size = const Size.square(42),
  }) {
    final Rect resolvedRect =
        rect ??
        Rect.fromCenter(
          center: center!,
          width: size.width,
          height: size.height,
        );
    controls[semanticsIdentifier] = Host4EmulatorSiliconeResolvedControl(
      semanticsIdentifier: semanticsIdentifier,
      center: resolvedRect.center,
      visualSize: resolvedRect.size,
      hitRect: resolvedRect,
    );
  }
}

class _HotZoneMm {
  const _HotZoneMm(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;
}

const Map<String, _HotZoneMm> _zones = <String, _HotZoneMm>{
  'up': _HotZoneMm(12.38, 4.52, 6.22, 7.49),
  'down': _HotZoneMm(12.13, 17.60, 6.10, 7.49),
  'left': _HotZoneMm(4.89, 11.50, 7.62, 6.22),
  'right': _HotZoneMm(18.10, 11.88, 7.62, 6.10),
  'innerTop': _HotZoneMm(27.62, 4.01, 9.02, 3.94),
  'innerBottom': _HotZoneMm(27.24, 22.42, 9.02, 3.94),
  'actionLeft': _HotZoneMm(37.28, 11.63, 7.49, 7.62),
  'actionTop': _HotZoneMm(44.90, 4.26, 7.49, 7.62),
  'actionRight': _HotZoneMm(52.26, 12.01, 7.62, 7.62),
  'actionBottom': _HotZoneMm(44.64, 19.38, 7.49, 7.62),
};

const double _portraitPadUiWidth = 345.8;
const double _portraitPadUiHeight = 142.9;
const double _portraitBaseWidth = 390;
const double _portraitBaseHeight = 844;
const double _portraitLeftShoulderCenterXRatio =
    (105.0 - 27.2) / _portraitPadUiWidth;
const double _portraitRightShoulderCenterXRatio =
    (301.0 - 27.2) / _portraitPadUiWidth;
const double _portraitShoulderWidthRatio = 72.0 / _portraitPadUiWidth;
const double _portraitShoulderHeightRatio = 31.5 / _portraitPadUiHeight;
const double _portraitLowerSlotBottomMargin =
    _portraitBaseHeight - 676.0 - 31.5;
const double _portraitBottomButtonSize = 42;
const double _portraitBottomButtonBottomMargin =
    _portraitBaseHeight - 778.0 - _portraitBottomButtonSize;
const double _portraitBottomButtonSideMargin = 32;
const double _landscapeSystemButtonCenterOffset = 98;
const double _landscapeSystemButtonBottomMargin = 33;
