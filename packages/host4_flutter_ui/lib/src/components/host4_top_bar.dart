import 'package:flutter/material.dart';

import '../foundation/host4_icon_assets.dart';
import '../foundation/host4_svg_icon.dart';
import '../foundation/theme/host4_theme_scope.dart';
import 'host4_button.dart';

/// 子页面顶部标题栏。
///
/// 支持三种内容模式（左侧互斥，[leading] 优先）：
/// - [leading]：左侧放任意 widget（如多图标按钮组）
/// - 面包屑（传 [parent]）："[parent] › [title]"
/// - 纯标题（省略 [parent]）：只显示 [title]
///
/// 传入 [searchPlaceholder] 后，标题栏右侧自动出现搜索图标；
/// 点击展开搜索输入栏，点击「返回」收起并清空输入。
/// 搜索确认时通过 [onSearch] 回调通知父级，无需父级管理状态。
///
/// [safeAreaTop] 为顶部安全区高度，由调用方在运行时传入；
/// 演示场景传 0，真机通常传 20。
class Host4TopBar extends StatefulWidget {
  const Host4TopBar({
    required this.safeAreaTop,
    this.safeAreaLeft = 0,
    this.title,
    this.parent,
    this.titleKey,
    this.leading,
    this.trailing,
    this.status,
    this.searchPlaceholder,
    this.onSearch,
    super.key,
  });

  /// 顶部安全区高度，单位 dp。
  final double safeAreaTop;

  /// 左侧安全区宽度，单位 dp。默认 0。
  final double safeAreaLeft;

  /// 面包屑前缀；为 null 时退化为纯标题模式。
  final String? parent;

  /// 主标题。
  final String? title;
  final Key? titleKey;

  /// 左侧自定义内容，替代 [title]/[parent] 位置；与文字模式互斥，优先级更高。
  final Widget? leading;

  /// 右侧操作区，渲染在 [searchPlaceholder] 搜索图标和 [status] 左侧。
  final Widget? trailing;

  /// 系统状态区，渲染在最右侧，如 [Host4SystemStatus]。
  final Widget? status;

  /// 若不为 null，右侧自动出现搜索图标，点击展开搜索模式。
  final String? searchPlaceholder;

  /// 用户点击「搜索」按钮时触发，参数为当前输入文字。
  final ValueChanged<String>? onSearch;

  @override
  State<Host4TopBar> createState() => _Host4TopBarState();
}

class _Host4TopBarState extends State<Host4TopBar> {
  bool _searchActive = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openSearch() => setState(() => _searchActive = true);

  void _closeSearch() => setState(() {
    _searchActive = false;
    _ctrl.clear();
  });

  void _confirmSearch() {
    widget.onSearch?.call(_ctrl.text);
    _closeSearch();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.host4Theme.components.topBar;
    return _searchActive
        ? _buildSearchBar(context, tokens)
        : _buildNormal(context, tokens);
  }

  // ── 普通模式 ────────────────────────────────────────────────────────────────

  Widget _buildNormal(BuildContext context, dynamic tokens) {
    final topBarTokens = context.host4Theme.components.topBar;
    final titleStyle = topBarTokens.titleStyle
        .toTextStyle(topBarTokens.title)
        .copyWith(fontFamily: topBarTokens.fontFamily);

    return SizedBox(
      height: widget.safeAreaTop + topBarTokens.barHeight,
      child: ColoredBox(
        color: topBarTokens.background,
        child: Column(
          children: [
            SizedBox(height: widget.safeAreaTop),
            SizedBox(
              height: topBarTokens.barHeight,
              child: Padding(
                padding: EdgeInsets.only(
                  left: topBarTokens.paddingHorizontal + widget.safeAreaLeft,
                  right: topBarTokens.paddingHorizontal,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── 左侧 ───────────────────────────────────────────────
                    if (widget.leading != null)
                      widget.leading!
                    else ...[
                      if (widget.parent != null) ...[
                        Text(widget.parent!, style: titleStyle),
                        const SizedBox(width: 6),
                        Host4SvgIcon(
                          assetPath: Host4IconAssets.topBarEnter,
                          size: 24,
                          color: topBarTokens.chevron,
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          key: widget.titleKey,
                          style: titleStyle,
                        ),
                    ],
                    const Spacer(),
                    // ── 右侧 ───────────────────────────────────────────────
                    if (widget.trailing != null) ...[
                      widget.trailing!,
                      const SizedBox(width: 8),
                    ],
                    if (widget.searchPlaceholder != null) ...[
                      _IconBtn(
                        icon: Icons.search_rounded,
                        color: topBarTokens.title,
                        onTap: _openSearch,
                      ),
                      if (widget.status != null) const SizedBox(width: 12),
                    ],
                    ?widget.status,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 搜索模式 ────────────────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context, dynamic _) {
    final topBarTokens = context.host4Theme.components.topBar;
    final colors = context.host4Theme.colors;
    final navTokens = context.host4Theme.components.navigationBar;
    final fieldTokens = context.host4Theme.components.textField;
    final gap = navTokens.paddingBottom;

    return SizedBox(
      height: widget.safeAreaTop + topBarTokens.barHeight,
      child: ColoredBox(
        color: topBarTokens.background,
        child: Column(
          children: [
            SizedBox(height: widget.safeAreaTop),
            SizedBox(
              height: topBarTokens.barHeight,
              child: Padding(
                padding: EdgeInsets.only(
                  left: topBarTokens.paddingHorizontal + widget.safeAreaLeft,
                  right: topBarTokens.paddingHorizontal,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 返回按钮
                    _IconBtn(
                      icon: Icons.arrow_back_rounded,
                      color: topBarTokens.title,
                      onTap: _closeSearch,
                    ),
                    SizedBox(width: gap),
                    // 搜索 pill 输入框
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surfaceMuted,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 24,
                                  color: colors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _ctrl,
                                    autofocus: true,
                                    style: fieldTokens.textStyle.toTextStyle(
                                      fieldTokens.defaultState.text,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: widget.searchPlaceholder,
                                      hintStyle: fieldTokens.placeholderStyle
                                          .toTextStyle(
                                            fieldTokens
                                                .defaultState
                                                .placeholder,
                                          ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onSubmitted: (_) => _confirmSearch(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: gap),
                    // 搜索确认按钮
                    Host4Button(
                      label: '搜索',
                      onPressed: _confirmSearch,
                      variant: Host4ButtonVariant.primary,
                      size: Host4ButtonSize.sm,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 内部图标按钮 ─────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(child: Icon(icon, size: 22, color: color)),
      ),
    );
  }
}
