import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../Input/gmacro_input_hub.dart';
import '../Input/gmacro_input_state.dart';

/// 自由光标覆盖层。
///
/// 叠加在任何页面上，显示一个可拖动的圆形光标。
/// 光标由摇杆实时控制移动（平滑模拟模式）。
///
/// 这是一个独立的组件，不依赖 [GmacroCursorController]。
/// 两者互补关系：
/// - [GmacroCursorController] → 网格焦点导航（A/B 确认/返回 + 方向键自动重复）
/// - [GmacroCursorOverlay]   → 自由光标层（摇杆实时定位）
///
/// 使用方式：
/// ```dart
/// GmacroCursorOverlay(
///   child: YourPage(),
/// )
/// ```
class GmacroCursorOverlay extends StatefulWidget {
  const GmacroCursorOverlay({
    super.key,
    required this.child,
    this.deadZone = 0.18,
    this.baseSpeed = 12.0,
  });

  final Widget child;
  final double deadZone;
  final double baseSpeed;

  @override
  State<GmacroCursorOverlay> createState() => _GmacroCursorOverlayState();
}

class _GmacroCursorOverlayState extends State<GmacroCursorOverlay>
    with SingleTickerProviderStateMixin {
  Offset _position = const Offset(200, 200);
  Size _viewportSize = const Size(390, 844);

  StreamSubscription<GmacroInputState>? _stateSub;
  late Ticker _ticker;
  GmacroInputState _latestState = GmacroInputState.empty();

  @override
  void initState() {
    super.initState();

    final service = GmacroInputHub.currentService;
    if (service != null) {
      _stateSub = service.states.listen((s) {
        if (mounted) setState(() => _latestState = s);
      });
    }

    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stateSub?.cancel();
    super.dispose();
  }

  void _onTick(Duration _) {
    final dx = _latestState.leftStickDx;
    final dy = _latestState.leftStickDy;

    if (dx.abs() <= widget.deadZone && dy.abs() <= widget.deadZone) return;

    setState(() {
      _position = Offset(
        (_position.dx + dx * widget.baseSpeed)
            .clamp(0, _viewportSize.width),
        (_position.dy + dy * widget.baseSpeed)
            .clamp(0, _viewportSize.height),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            widget.child,
            IgnorePointer(
              child: Positioned(
                left: _position.dx,
                top: _position.dy,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(blurRadius: 8, color: Color(0x55000000)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
