import '../gmacro_session.dart';
import 'gmacro_input_service.dart';

/// 输入绑定中心。
///
/// 这个类的作用是把：
/// - 当前绑定的 `GmacroSession`
/// - 统一输入服务 `GmacroInputService`
///
/// 收口在一起。
///
/// 它是 SDK 级能力，不应该再用 Demo 语义命名。
///
/// ## 全局访问
///
/// [currentService] 提供静态全局读取入口。
/// 任意页面无需构造函数传参即可读取当前输入状态：
///
/// ```dart
/// GmacroInputHub.currentService?.latestState
/// GmacroInputHub.currentService?.buttonEvents.listen(...)
/// ```
///
/// 生命周期仍由创建此 hub 的页面管理（bindSession / dispose）。
class GmacroInputHub {
  GmacroInputHub({GmacroInputService? inputService})
    : inputService = inputService ?? GmacroInputService();

  /// 当前 hub 使用的统一输入服务。
  final GmacroInputService inputService;

  /// 全局统一输入服务。
  ///
  /// - 在 [bindSession] 被调用时自动设置。
  /// - 在 [dispose] 被调用时自动清空。
  /// - 未连接设备时为 `null`。
  static GmacroInputService? currentService;

  GmacroSession? _session;

  /// 当前绑定的 session。
  GmacroSession? get session => _session;

  /// 绑定 session。
  ///
  /// attach 成功后调用一次即可。
  /// 后续所有页面都可以通过 `inputService` 或 [currentService] 读取统一输入状态。
  void bindSession(GmacroSession session) {
    if (identical(_session, session)) {
      return;
    }

    _session = session;
    inputService.bindSession(session);
    currentService = inputService;
  }

  /// 释放输入服务并清空全局引用。
  Future<void> dispose() {
    currentService = null;
    return inputService.dispose();
  }
}
