import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:host4_flutter_utils/host4_flutter_utils.dart';

import 'host4_runtime_theme.dart';

class Host4ThemeLoader {
  const Host4ThemeLoader._();

  static Future<Host4RuntimeTheme> loadFromAsset(
    AssetBundle bundle,
    String assetPath, {
    String? mode,
  }) async {
    // AssetBundle is not isolate-safe; load raw strings on the main thread.
    debugPrint('[Host4ThemeLoader] step1: loading strings for $assetPath');
    final tokensJson = await bundle.loadString(assetPath);
    debugPrint(
      '[Host4ThemeLoader] step2: tokens loaded (${tokensJson.length} chars)',
    );
    final assetJson = await _loadAssetFileString(bundle, assetPath);
    debugPrint('[Host4ThemeLoader] step3: asset loaded');
    final manifestJson = await _loadManifestString(bundle, assetPath);
    debugPrint('[Host4ThemeLoader] step4: manifest loaded');

    // Decode, normalize and resolve token references in a background isolate
    // so the main thread (and Flutter's frame scheduler) stays unblocked.
    _ThemeParseOutput result;
    final _ThemeParseInput input = (
      tokensJson: tokensJson,
      assetJson: assetJson,
      manifestJson: manifestJson,
      mode: mode,
    );
    try {
      debugPrint('[Host4ThemeLoader] step5: starting compute()');
      result = await compute<_ThemeParseInput, _ThemeParseOutput>(
        _parseThemeInBackground,
        input,
      );
      debugPrint('[Host4ThemeLoader] step6: compute() done');
    } catch (e, stack) {
      debugPrint(
        '[Host4ThemeLoader] compute() failed ($e), falling back to main-thread parse.\n$stack',
      );
      result = _parseThemeInBackground(input);
      debugPrint('[Host4ThemeLoader] step6b: main-thread parse done');
    }

    final resolved = result.resolved;
    final sourceTokens = result.sourceTokens;
    final selectedMode = result.selectedMode;
    final assetDirectory = assetPath.substring(
      0,
      assetPath.lastIndexOf('/') + 1,
    );

    return Host4RuntimeTheme(
      meta: Host4ThemeMeta(
        id: _readString(resolved, 'meta.id'),
        name: _readString(resolved, 'meta.name'),
        schema: _readString(resolved, 'schema'),
        mode: _readString(resolved, 'meta.mode'),
        defaultMode: _readString(resolved, 'meta.defaultMode'),
        supportedModes: _readStringList(resolved, 'meta.modes'),
        brightness: _parseBrightness(_readString(resolved, 'meta.mode')),
      ),
      colors: Host4ThemeColors(
        brandPrimary: _readColor(resolved, 'semantic.color.brand.primary'),
        brandSecondary: _readColor(resolved, 'semantic.color.brand.secondary'),
        brandAccent: _readColor(resolved, 'semantic.color.brand.accent'),
        pageBackground: _readColor(resolved, 'semantic.color.background.page'),
        surface: _readColor(resolved, 'semantic.color.surface.default'),
        surfaceMuted: _readColor(resolved, 'semantic.color.surface.muted'),
        surfaceElevated: _readColor(
          resolved,
          'semantic.color.surface.elevated',
        ),
        textPrimary: _readColor(resolved, 'semantic.color.text.primary'),
        textSecondary: _readColor(resolved, 'semantic.color.text.secondary'),
        textInverse: _readColor(resolved, 'semantic.color.text.inverse'),
        borderDefault: _readColor(resolved, 'semantic.color.border.default'),
        borderStrong: _readColor(resolved, 'semantic.color.border.strong'),
        focus: _readColor(resolved, 'semantic.color.interactive.focus'),
        interactivePressed: _readColor(
          resolved,
          'semantic.color.interactive.pressed',
        ),
        interactiveDisabled: _readColor(
          resolved,
          'semantic.color.interactive.disabled',
        ),
        interactiveSelected: _readColor(
          resolved,
          'semantic.color.interactive.selected',
        ),
        success: _readColor(resolved, 'semantic.color.status.success'),
        warning: _readColor(resolved, 'semantic.color.status.warning'),
      ),
      typography: Host4ThemeTypography(
        display: _readTextToken(resolved, 'semantic.typography.display'),
        title: _readTextToken(resolved, 'semantic.typography.title'),
        titleRegular: _readTextToken(
          resolved,
          'semantic.typography.title-regular',
        ),
        heading: _readTextToken(resolved, 'semantic.typography.heading'),
        body: _readTextToken(resolved, 'semantic.typography.body'),
        bodyMedium: _readTextToken(resolved, 'semantic.typography.body-medium'),
        bodyRegular: _readTextToken(
          resolved,
          'semantic.typography.body-regular',
        ),
        label: _readTextToken(resolved, 'semantic.typography.label'),
        labelMedium: _readTextToken(
          resolved,
          'semantic.typography.label-medium',
        ),
        labelRegular: _readTextToken(
          resolved,
          'semantic.typography.label-regular',
        ),
        caption: _readTextToken(resolved, 'semantic.typography.caption'),
      ),
      spacing: Host4ThemeSpacing(
        xs: _readDouble(resolved, 'primitive.spacing.xs'),
        sm: _readDouble(resolved, 'primitive.spacing.sm'),
        md: _readDouble(resolved, 'primitive.spacing.md'),
        lg: _readDouble(resolved, 'primitive.spacing.lg'),
        xl: _readDouble(resolved, 'primitive.spacing.xl'),
        xxl: _readDouble(resolved, 'primitive.spacing.xxl'),
        page: _readDouble(resolved, 'semantic.spacing.page'),
        section: _readDouble(resolved, 'semantic.spacing.section'),
        card: _readDouble(resolved, 'semantic.spacing.card.md.horizontal'),
        buttonHorizontal: _readDouble(
          resolved,
          'semantic.spacing.interactive.horizontal',
        ),
        buttonVertical: _readDouble(
          resolved,
          'semantic.spacing.interactive.vertical',
        ),
        inputHorizontal: _readDouble(
          resolved,
          'semantic.spacing.interactive.horizontal',
        ),
        inputVertical: _readDouble(
          resolved,
          'semantic.spacing.interactive.vertical',
        ),
        listGap: _readDouble(resolved, 'semantic.spacing.list.gap'),
      ),
      sizes: Host4ThemeSizes(
        iconMd: _readDouble(resolved, 'semantic.size.icon.md'),
        iconLg: _readDouble(resolved, 'semantic.size.icon.lg'),
      ),
      radius: Host4ThemeRadius(
        sm: _readDouble(resolved, 'primitive.radius.sm'),
        md: _readDouble(resolved, 'primitive.radius.md'),
        lg: _readDouble(resolved, 'primitive.radius.lg'),
        pill: _readDouble(resolved, 'primitive.radius.pill'),
        button: _readDouble(resolved, 'semantic.radius.default'),
        card: _readDouble(resolved, 'semantic.radius.prominent'),
        input: _readDouble(resolved, 'semantic.radius.default'),
      ),
      blur: Host4ThemeBlur(
        card: _readDouble(resolved, 'primitive.effect.blur-card'),
      ),
      images: Host4ThemeImages(
        pageBackground: _resolveAssetPath(
          assetDirectory,
          _readString(resolved, 'asset.image.page-background'),
        ),
        heroBanner: _resolveAssetPath(
          assetDirectory,
          _readString(resolved, 'asset.image.hero-banner'),
        ),
        spotIllustration: _resolveAssetPath(
          assetDirectory,
          _readString(resolved, 'asset.image.spot-illustration'),
        ),
        tabItems: _readTabItemImages(
          resolved,
          sourceTokens,
          assetDirectory,
          selectedMode,
        ),
      ),
      components: Host4ThemeComponents(
        pageShell: Host4PageShellComponentTokens(
          pageColor: _readColor(resolved, 'component.page-shell.page-color'),
          image: _resolveAssetPath(
            assetDirectory,
            _readString(resolved, 'asset.image.page-background'),
          ),
          accentGlowColor: _readColor(
            resolved,
            'component.page-shell.accent-glow-color',
          ),
          accentGlowOpacity: _readDouble(
            resolved,
            'component.page-shell.accent-glow-opacity',
          ),
        ),
        button: Host4ButtonComponentTokens(
          focusedRing: Host4ButtonFocusedRingTokens(
            color: _readColor(resolved, 'component.button.focused-ring.color'),
            width: _readDouble(resolved, 'component.button.focused-ring.width'),
            offsetWidth: _readDouble(
              resolved,
              'component.button.focused-ring.offset-width',
            ),
            radius: _readDouble(
              resolved,
              'component.button.focused-ring.radius',
              fallback: 0,
            ),
          ),
          selectedIndicator: Host4ButtonSelectedIndicatorTokens(
            color: _readColor(
              resolved,
              'component.button.selected-indicator.color',
            ),
            width: _readDouble(
              resolved,
              'component.button.selected-indicator.width',
            ),
            height: _readDouble(
              resolved,
              'component.button.selected-indicator.height',
            ),
            gap: _readDouble(
              resolved,
              'component.button.selected-indicator.gap',
            ),
          ),
          sizes: Host4ButtonSizeGroupTokens(
            xs: Host4ButtonSizeTokens(
              minHeight: _readDouble(
                resolved,
                'component.button.size.xs.min-height',
              ),
              iconOnlyExtent: _readDouble(
                resolved,
                'component.button.size.xs.icon-only-extent',
              ),
            ),
            sm: Host4ButtonSizeTokens(
              minHeight: _readDouble(
                resolved,
                'component.button.size.sm.min-height',
              ),
              iconOnlyExtent: _readDouble(
                resolved,
                'component.button.size.sm.icon-only-extent',
              ),
            ),
            md: Host4ButtonSizeTokens(
              minHeight: _readDouble(
                resolved,
                'component.button.size.md.min-height',
              ),
              iconOnlyExtent: _readDouble(
                resolved,
                'component.button.size.md.icon-only-extent',
              ),
            ),
          ),
          spacing: Host4ButtonSpacingTokens(
            horizontal: _readDouble(
              resolved,
              'component.button.spacing.horizontal',
            ),
            vertical: _readDouble(
              resolved,
              'component.button.spacing.vertical',
            ),
            iconOnlyHorizontal: _readDouble(
              resolved,
              'component.button.spacing.icon-only.horizontal',
            ),
            iconOnlyVertical: _readDouble(
              resolved,
              'component.button.spacing.icon-only.vertical',
            ),
            iconGap: _readDouble(resolved, 'component.button.spacing.icon-gap'),
            xsHorizontal: _readDouble(
              resolved,
              'component.button.spacing.xs.horizontal',
              fallback: _readDouble(
                resolved,
                'component.button.spacing.sm.horizontal',
              ),
            ),
            xsVertical: _readDouble(
              resolved,
              'component.button.spacing.xs.vertical',
              fallback: _readDouble(
                resolved,
                'component.button.spacing.sm.vertical',
              ),
            ),
            smHorizontal: _readDouble(
              resolved,
              'component.button.spacing.sm.horizontal',
            ),
            smVertical: _readDouble(
              resolved,
              'component.button.spacing.sm.vertical',
            ),
            mdHorizontal: _readDouble(
              resolved,
              'component.button.spacing.md.horizontal',
            ),
            mdVertical: _readDouble(
              resolved,
              'component.button.spacing.md.vertical',
            ),
          ),
          labelStyle: _readTextToken(resolved, 'component.button.label-style'),
          minHeight: _readDouble(resolved, 'component.button.min-height'),
          leadingIconSize: _readDouble(
            resolved,
            'component.button.leading-icon-size',
          ),
          iconOnlySize: _readDouble(
            resolved,
            'component.button.icon-only-size',
          ),
          primary: _readButtonVariant(resolved, 'component.button.primary'),
          secondary: _readButtonVariant(resolved, 'component.button.secondary'),
          popoverPrimary: _readButtonVariant(
            resolved,
            'component.button.popover-primary',
            'component.button.tertiary',
          ),
          popoverSecondary: _readButtonVariant(
            resolved,
            'component.button.popover-secondary',
            'component.button.secondary',
          ),
          tertiary: _readButtonVariant(resolved, 'component.button.tertiary'),
          ghost: _readButtonVariant(resolved, 'component.button.ghost'),
          dangerHigh: _readButtonVariant(
            resolved,
            'component.button.danger-high',
          ),
          dangerSoft: _readButtonVariant(
            resolved,
            'component.button.danger-soft',
          ),
          loading: Host4ButtonLoadingTokens(
            spinnerSize: _readDouble(
              resolved,
              'component.button.loading.spinner-size',
            ),
            spinnerGap: _readDouble(
              resolved,
              'component.button.loading.spinner-gap',
            ),
            opacity: _readDouble(resolved, 'component.button.loading.opacity'),
          ),
        ),
        card: Host4CardComponentTokens(
          padding: _readDouble(resolved, 'component.card.padding'),
          radius: _readDouble(resolved, 'component.card.radius'),
          background: _readColor(resolved, 'component.card.background'),
          border: _readColor(resolved, 'component.card.border'),
          title: _readColor(resolved, 'component.card.title'),
          subtitle: _readColor(resolved, 'component.card.subtitle'),
          shadowColor: _readColor(resolved, 'component.card.shadow-color'),
          shadowOpacity: _readDouble(resolved, 'component.card.shadow-opacity'),
          shadowBlur: _readDouble(resolved, 'component.card.shadow-blur'),
          shadowOffsetY: _readDouble(
            resolved,
            'component.card.shadow-offset-y',
          ),
        ),
        navigationBar: Host4NavigationBarComponentTokens(
          paddingHorizontal: _readDouble(
            resolved,
            'component.navigation-bar.padding-horizontal',
          ),
          paddingTop: _readDouble(
            resolved,
            'component.navigation-bar.padding-top',
          ),
          paddingBottom: _readDouble(
            resolved,
            'component.navigation-bar.padding-bottom',
          ),
          leadingGap: _readDouble(
            resolved,
            'component.navigation-bar.leading-gap',
          ),
          background: _readColor(
            resolved,
            'component.navigation-bar.background',
          ),
          titleStyle: _readTextToken(
            resolved,
            'component.navigation-bar.title-style',
          ),
          subtitleStyle: _readTextToken(
            resolved,
            'component.navigation-bar.subtitle-style',
          ),
          title: _readColor(resolved, 'component.navigation-bar.title'),
          subtitle: _readColor(resolved, 'component.navigation-bar.subtitle'),
          icon: _readColor(resolved, 'component.navigation-bar.icon'),
        ),
        searchBar: Host4SearchBarComponentTokens(
          shortcutHorizontal: _readDouble(
            resolved,
            'component.search-bar.shortcut.horizontal',
          ),
          shortcutVertical: _readDouble(
            resolved,
            'component.search-bar.shortcut.vertical',
          ),
          shortcutBackground: _readColor(
            resolved,
            'component.search-bar.shortcut.background',
          ),
          shortcutRadius: _readDouble(
            resolved,
            'component.search-bar.shortcut.radius',
          ),
          shortcutStyle: _readTextToken(
            resolved,
            'component.search-bar.shortcut.text-style',
          ),
          shortcutTextColor: _readColor(
            resolved,
            'component.search-bar.shortcut.text-color',
          ),
        ),
        sectionHeader: Host4SectionHeaderComponentTokens(
          titleStyle: _readTextToken(
            resolved,
            'component.section-header.title-style',
          ),
          titleColor: _readColor(
            resolved,
            'component.section-header.title-color',
          ),
          subtitleGap: _readDouble(
            resolved,
            'component.section-header.subtitle-gap',
          ),
          actionGap: _readDouble(
            resolved,
            'component.section-header.action-gap',
          ),
          subtitleStyle: _readTextToken(
            resolved,
            'component.section-header.subtitle-style',
          ),
          subtitleColor: _readColor(
            resolved,
            'component.section-header.subtitle-color',
          ),
        ),
        textField: Host4TextFieldComponentTokens(
          paddingHorizontal: _readDouble(
            resolved,
            'component.text-field.padding-horizontal',
          ),
          paddingVertical: _readDouble(
            resolved,
            'component.text-field.padding-vertical',
          ),
          radius: _readDouble(resolved, 'component.text-field.radius'),
          minHeight: _readDouble(resolved, 'component.text-field.min-height'),
          prefixIconSize: _readDouble(
            resolved,
            'component.text-field.prefix-icon-size',
          ),
          suffixGap: _readDouble(resolved, 'component.text-field.suffix-gap'),
          textStyle: _readTextToken(
            resolved,
            'component.text-field.text-style',
          ),
          placeholderStyle: _readTextToken(
            resolved,
            'component.text-field.placeholder-style',
          ),
          defaultState: _readTextFieldState(
            resolved,
            'component.text-field.state.default',
          ),
          focusedState: _readTextFieldState(
            resolved,
            'component.text-field.state.focused',
          ),
          disabledState: _readTextFieldState(
            resolved,
            'component.text-field.state.disabled',
          ),
          readOnlyState: _readTextFieldState(
            resolved,
            'component.text-field.state.read-only',
          ),
          errorState: _readTextFieldState(
            resolved,
            'component.text-field.state.error',
          ),
          successState: _readTextFieldState(
            resolved,
            'component.text-field.state.success',
          ),
        ),
        listCell: Host4ListCellComponentTokens(
          radius: _readDouble(resolved, 'component.list-cell.radius'),
          paddingHorizontal: _readDouble(
            resolved,
            'component.list-cell.padding-horizontal',
          ),
          paddingVertical: _readDouble(
            resolved,
            'component.list-cell.padding-vertical',
          ),
          minHeight: _readDouble(resolved, 'component.list-cell.min-height'),
          leadingGap: _readDouble(resolved, 'component.list-cell.leading-gap'),
          subtitleGap: _readDouble(
            resolved,
            'component.list-cell.subtitle-gap',
          ),
          trailingGap: _readDouble(
            resolved,
            'component.list-cell.trailing-gap',
          ),
          chevronGap: _readDouble(resolved, 'component.list-cell.chevron-gap'),
          titleStyle: _readTextToken(
            resolved,
            'component.list-cell.title-style',
          ),
          subtitleStyle: _readTextToken(
            resolved,
            'component.list-cell.subtitle-style',
          ),
          trailingStyle: _readTextToken(
            resolved,
            'component.list-cell.trailing-style',
          ),
          defaultState: _readListCellState(
            resolved,
            'component.list-cell.state.default',
          ),
          pressedState: _readListCellState(
            resolved,
            'component.list-cell.state.pressed',
          ),
          disabledState: _readListCellState(
            resolved,
            'component.list-cell.state.disabled',
          ),
          selectedState: _readListCellState(
            resolved,
            'component.list-cell.state.selected',
          ),
        ),
        tabBar: Host4TabBarComponentTokens(
          background: _readColor(resolved, 'component.tab-bar.background'),
          height: _readDouble(resolved, 'component.tab-bar.height'),
          iconSize: _readDouble(resolved, 'component.tab-bar.icon-size'),
          featuredIconSize: _readDouble(
            resolved,
            'component.tab-bar.featured-icon-size',
          ),
          labelStyle: _readTextToken(resolved, 'component.tab-bar.label-style'),
          labelGap: _readDouble(resolved, 'component.tab-bar.label-gap'),
          bottomGap: _readDouble(resolved, 'component.tab-bar.bottom-gap'),
          itemStates: Host4TabBarItemStateSet(
            defaultState: _readTabBarItemState(
              resolved,
              'component.tab-bar.item.state.default',
            ),
            pressedState: _readTabBarItemState(
              resolved,
              'component.tab-bar.item.state.pressed',
            ),
            disabledState: _readTabBarItemState(
              resolved,
              'component.tab-bar.item.state.disabled',
            ),
            selectedState: _readTabBarItemState(
              resolved,
              'component.tab-bar.item.state.selected',
            ),
          ),
          items: _readTabItemImages(
            resolved,
            sourceTokens,
            assetDirectory,
            selectedMode,
          ),
        ),
        tag: Host4TagComponentTokens(
          radius: _readDouble(resolved, 'component.tag.radius'),
          paddingHorizontal: _readDouble(
            resolved,
            'component.tag.padding-horizontal',
          ),
          paddingVertical: _readDouble(
            resolved,
            'component.tag.padding-vertical',
          ),
          iconSize: _readDouble(resolved, 'component.tag.icon-size'),
          iconGap: _readDouble(resolved, 'component.tag.icon-gap'),
          labelStyle: _readTextToken(resolved, 'component.tag.label-style'),
          defaultState: _readTagState(resolved, 'component.tag.state.default'),
          selectedState: _readTagState(
            resolved,
            'component.tag.state.selected',
          ),
          disabledState: _readTagState(
            resolved,
            'component.tag.state.disabled',
          ),
        ),
        emptyState: Host4EmptyStateComponentTokens(
          iconSize: _readDouble(resolved, 'component.empty-state.icon-size'),
          iconGap: _readDouble(resolved, 'component.empty-state.icon-gap'),
          textGap: _readDouble(resolved, 'component.empty-state.text-gap'),
          actionGap: _readDouble(resolved, 'component.empty-state.action-gap'),
          iconColor: _readColor(resolved, 'component.empty-state.icon-color'),
          titleStyle: _readTextToken(
            resolved,
            'component.empty-state.title-style',
          ),
          titleColor: _readColor(resolved, 'component.empty-state.title-color'),
          subtitleStyle: _readTextToken(
            resolved,
            'component.empty-state.subtitle-style',
          ),
          subtitleColor: _readColor(
            resolved,
            'component.empty-state.subtitle-color',
          ),
        ),
        banner: Host4BannerComponentTokens(
          paddingHorizontal: _readDouble(
            resolved,
            'component.banner.padding-horizontal',
          ),
          paddingVertical: _readDouble(
            resolved,
            'component.banner.padding-vertical',
          ),
          radius: _readDouble(resolved, 'component.banner.radius'),
          iconSize: _readDouble(resolved, 'component.banner.icon-size'),
          iconGap: _readDouble(resolved, 'component.banner.icon-gap'),
          titleBodyGap: _readDouble(
            resolved,
            'component.banner.title-body-gap',
          ),
          titleStyle: _readTextToken(resolved, 'component.banner.title-style'),
          bodyStyle: _readTextToken(resolved, 'component.banner.body-style'),
          info: _readBannerVariant(resolved, 'component.banner.variant.info'),
          success: _readBannerVariant(
            resolved,
            'component.banner.variant.success',
          ),
          warning: _readBannerVariant(
            resolved,
            'component.banner.variant.warning',
          ),
          error: _readBannerVariant(resolved, 'component.banner.variant.error'),
        ),
        progressBar: Host4ProgressBarComponentTokens(
          height: _readDouble(resolved, 'component.progress-bar.height'),
          radius: _readDouble(resolved, 'component.progress-bar.radius'),
          track: _readColor(resolved, 'component.progress-bar.track'),
          fill: _readColor(resolved, 'component.progress-bar.fill'),
          fillSuccess: _readColor(
            resolved,
            'component.progress-bar.fill-success',
          ),
          fillWarning: _readColor(
            resolved,
            'component.progress-bar.fill-warning',
          ),
          fillError: _readColor(resolved, 'component.progress-bar.fill-error'),
        ),
        segmentedFilter: Host4SegmentedFilterComponentTokens(
          paddingHorizontal: _readDouble(
            resolved,
            'component.segmented-filter.padding-horizontal',
          ),
          paddingVertical: _readDouble(
            resolved,
            'component.segmented-filter.padding-vertical',
          ),
          radius: _readDouble(resolved, 'component.segmented-filter.radius'),
          containerRadius: _readDouble(
            resolved,
            'component.segmented-filter.container-radius',
          ),
          gap: _readDouble(resolved, 'component.segmented-filter.gap'),
          iconSize: _readDouble(
            resolved,
            'component.segmented-filter.icon-size',
          ),
          iconGap: _readDouble(resolved, 'component.segmented-filter.icon-gap'),
          labelStyle: _readTextToken(
            resolved,
            'component.segmented-filter.label-style',
          ),
          containerBackground: _readColor(
            resolved,
            'component.segmented-filter.container.background',
          ),
          containerBorder: _readColor(
            resolved,
            'component.segmented-filter.container.border',
          ),
          defaultState: _readSegmentedFilterItemState(
            resolved,
            'component.segmented-filter.item.state.default',
          ),
          selectedState: _readSegmentedFilterItemState(
            resolved,
            'component.segmented-filter.item.state.selected',
          ),
          disabledState: _readSegmentedFilterItemState(
            resolved,
            'component.segmented-filter.item.state.disabled',
          ),
        ),
        infoChip: Host4InfoChipComponentTokens(
          paddingHorizontal: _readDouble(
            resolved,
            'component.info-chip.padding-horizontal',
          ),
          paddingVertical: _readDouble(
            resolved,
            'component.info-chip.padding-vertical',
          ),
          radius: _readDouble(resolved, 'component.info-chip.radius'),
          iconSize: _readDouble(resolved, 'component.info-chip.icon-size'),
          iconGap: _readDouble(resolved, 'component.info-chip.icon-gap'),
          labelStyle: _readTextToken(
            resolved,
            'component.info-chip.label-style',
          ),
          background: _readColor(resolved, 'component.info-chip.background'),
          foreground: _readColor(resolved, 'component.info-chip.foreground'),
          border: _readColor(resolved, 'component.info-chip.border'),
          iconColor: _readColor(resolved, 'component.info-chip.icon-color'),
        ),
        toolbar: Host4ToolbarComponentTokens(
          paddingHorizontal: _readDouble(
            resolved,
            'component.toolbar.padding-horizontal',
          ),
          paddingVertical: _readDouble(
            resolved,
            'component.toolbar.padding-vertical',
          ),
          gap: _readDouble(resolved, 'component.toolbar.gap'),
          background: _readColor(resolved, 'component.toolbar.background'),
          borderBottom: _readColor(resolved, 'component.toolbar.border-bottom'),
        ),
        topBar: Host4TopBarComponentTokens(
          barHeight: _readDouble(resolved, 'component.top-bar.bar-height'),
          paddingHorizontal: _readDouble(
            resolved,
            'component.top-bar.padding-horizontal',
          ),
          fontFamily: _readString(resolved, 'component.top-bar.font-family'),
          titleStyle: _readTextToken(resolved, 'component.top-bar.title-style'),
          background: _readColor(resolved, 'component.top-bar.background'),
          title: _readColor(resolved, 'component.top-bar.title'),
          chevron: _readColor(resolved, 'component.top-bar.chevron'),
        ),
      ),
    );
  }

  /// Load a [Host4RuntimeTheme] directly from an in-memory [tokensMap].
  ///
  /// Reuses all existing parsing logic. Pass [fallbackImages] to keep the
  /// current theme's images while only switching colors (Phase 2).
  static Future<Host4RuntimeTheme> loadFromMap(
    Map<String, dynamic> tokensMap, {
    String mode = 'light',
    Host4ThemeImages? fallbackImages,
  }) async {
    final syntheticManifest = <String, dynamic>{
      'id': 'generated',
      'name': 'Generated',
      'defaultMode': mode,
      'modes': ['light', 'dark'],
    };

    final normalized = _normalizeTheme(tokensMap, syntheticManifest, mode);
    final resolved = Host4ReferenceResolver(normalized).resolveMap(normalized);

    final images =
        fallbackImages ??
        const Host4ThemeImages(
          pageBackground: '',
          heroBanner: '',
          spotIllustration: '',
          tabItems: [],
        );

    return Host4RuntimeTheme(
      meta: Host4ThemeMeta(
        id: 'generated',
        name: 'Generated',
        schema: _readString(resolved, 'schema'),
        mode: mode,
        defaultMode: mode,
        supportedModes: const ['light', 'dark'],
        brightness: _parseBrightness(mode),
      ),
      colors: Host4ThemeColors(
        brandPrimary: _readColor(resolved, 'semantic.color.brand.primary'),
        brandSecondary: _readColor(resolved, 'semantic.color.brand.secondary'),
        brandAccent: _readColor(resolved, 'semantic.color.brand.accent'),
        pageBackground: _readColor(resolved, 'semantic.color.background.page'),
        surface: _readColor(resolved, 'semantic.color.surface.default'),
        surfaceMuted: _readColor(resolved, 'semantic.color.surface.muted'),
        surfaceElevated: _readColor(
          resolved,
          'semantic.color.surface.elevated',
        ),
        textPrimary: _readColor(resolved, 'semantic.color.text.primary'),
        textSecondary: _readColor(resolved, 'semantic.color.text.secondary'),
        textInverse: _readColor(resolved, 'semantic.color.text.inverse'),
        borderDefault: _readColor(resolved, 'semantic.color.border.default'),
        borderStrong: _readColor(resolved, 'semantic.color.border.strong'),
        focus: _readColor(resolved, 'semantic.color.interactive.focus'),
        interactivePressed: _readColor(
          resolved,
          'semantic.color.interactive.pressed',
        ),
        interactiveDisabled: _readColor(
          resolved,
          'semantic.color.interactive.disabled',
        ),
        interactiveSelected: _readColor(
          resolved,
          'semantic.color.interactive.selected',
        ),
        success: _readColor(resolved, 'semantic.color.status.success'),
        warning: _readColor(resolved, 'semantic.color.status.warning'),
      ),
      typography: Host4ThemeTypography(
        display: _readTextToken(resolved, 'semantic.typography.display'),
        title: _readTextToken(resolved, 'semantic.typography.title'),
        titleRegular: _readTextToken(
          resolved,
          'semantic.typography.title-regular',
        ),
        heading: _readTextToken(resolved, 'semantic.typography.heading'),
        body: _readTextToken(resolved, 'semantic.typography.body'),
        bodyMedium: _readTextToken(resolved, 'semantic.typography.body-medium'),
        bodyRegular: _readTextToken(
          resolved,
          'semantic.typography.body-regular',
        ),
        label: _readTextToken(resolved, 'semantic.typography.label'),
        labelMedium: _readTextToken(
          resolved,
          'semantic.typography.label-medium',
        ),
        labelRegular: _readTextToken(
          resolved,
          'semantic.typography.label-regular',
        ),
        caption: _readTextToken(resolved, 'semantic.typography.caption'),
      ),
      spacing: Host4ThemeSpacing(
        xs: _readDouble(resolved, 'primitive.spacing.xs'),
        sm: _readDouble(resolved, 'primitive.spacing.sm'),
        md: _readDouble(resolved, 'primitive.spacing.md'),
        lg: _readDouble(resolved, 'primitive.spacing.lg'),
        xl: _readDouble(resolved, 'primitive.spacing.xl'),
        xxl: _readDouble(resolved, 'primitive.spacing.xxl'),
        page: _readDouble(resolved, 'semantic.spacing.page'),
        section: _readDouble(resolved, 'semantic.spacing.section'),
        card: _readDouble(resolved, 'semantic.spacing.card.md.horizontal'),
        buttonHorizontal: _readDouble(
          resolved,
          'semantic.spacing.interactive.horizontal',
        ),
        buttonVertical: _readDouble(
          resolved,
          'semantic.spacing.interactive.vertical',
        ),
        inputHorizontal: _readDouble(
          resolved,
          'semantic.spacing.interactive.horizontal',
        ),
        inputVertical: _readDouble(
          resolved,
          'semantic.spacing.interactive.vertical',
        ),
        listGap: _readDouble(resolved, 'semantic.spacing.list.gap'),
      ),
      sizes: Host4ThemeSizes(
        iconMd: _readDouble(resolved, 'semantic.size.icon.md'),
        iconLg: _readDouble(resolved, 'semantic.size.icon.lg'),
      ),
      radius: Host4ThemeRadius(
        sm: _readDouble(resolved, 'primitive.radius.sm'),
        md: _readDouble(resolved, 'primitive.radius.md'),
        lg: _readDouble(resolved, 'primitive.radius.lg'),
        pill: _readDouble(resolved, 'primitive.radius.pill'),
        button: _readDouble(resolved, 'semantic.radius.default'),
        card: _readDouble(resolved, 'semantic.radius.prominent'),
        input: _readDouble(resolved, 'semantic.radius.default'),
      ),
      blur: Host4ThemeBlur(
        card: _readDouble(resolved, 'primitive.effect.blur-card'),
      ),
      images: images,
      components: Host4ThemeComponents(
        pageShell: Host4PageShellComponentTokens(
          pageColor: _readColor(resolved, 'component.page-shell.page-color'),
          image:
              fallbackImages?.pageBackground ??
              _readString(resolved, 'asset.image.page-background'),
          accentGlowColor: _readColor(
            resolved,
            'component.page-shell.accent-glow-color',
          ),
          accentGlowOpacity: _readDouble(
            resolved,
            'component.page-shell.accent-glow-opacity',
          ),
        ),
        button: Host4ButtonComponentTokens(
          focusedRing: Host4ButtonFocusedRingTokens(
            color: _readColor(resolved, 'component.button.focused-ring.color'),
            width: _readDouble(resolved, 'component.button.focused-ring.width'),
            offsetWidth: _readDouble(
              resolved,
              'component.button.focused-ring.offset-width',
            ),
            radius: _readDouble(
              resolved,
              'component.button.focused-ring.radius',
              fallback: 0,
            ),
          ),
          selectedIndicator: Host4ButtonSelectedIndicatorTokens(
            color: _readColor(
              resolved,
              'component.button.selected-indicator.color',
            ),
            width: _readDouble(
              resolved,
              'component.button.selected-indicator.width',
            ),
            height: _readDouble(
              resolved,
              'component.button.selected-indicator.height',
            ),
            gap: _readDouble(
              resolved,
              'component.button.selected-indicator.gap',
            ),
          ),
          sizes: Host4ButtonSizeGroupTokens(
            xs: Host4ButtonSizeTokens(
              minHeight: _readDouble(
                resolved,
                'component.button.size.xs.min-height',
              ),
              iconOnlyExtent: _readDouble(
                resolved,
                'component.button.size.xs.icon-only-extent',
              ),
            ),
            sm: Host4ButtonSizeTokens(
              minHeight: _readDouble(
                resolved,
                'component.button.size.sm.min-height',
              ),
              iconOnlyExtent: _readDouble(
                resolved,
                'component.button.size.sm.icon-only-extent',
              ),
            ),
            md: Host4ButtonSizeTokens(
              minHeight: _readDouble(
                resolved,
                'component.button.size.md.min-height',
              ),
              iconOnlyExtent: _readDouble(
                resolved,
                'component.button.size.md.icon-only-extent',
              ),
            ),
          ),
          spacing: Host4ButtonSpacingTokens(
            horizontal: _readDouble(
              resolved,
              'component.button.spacing.horizontal',
            ),
            vertical: _readDouble(
              resolved,
              'component.button.spacing.vertical',
            ),
            iconOnlyHorizontal: _readDouble(
              resolved,
              'component.button.spacing.icon-only.horizontal',
            ),
            iconOnlyVertical: _readDouble(
              resolved,
              'component.button.spacing.icon-only.vertical',
            ),
            iconGap: _readDouble(resolved, 'component.button.spacing.icon-gap'),
            xsHorizontal: _readDouble(
              resolved,
              'component.button.spacing.xs.horizontal',
              fallback: _readDouble(
                resolved,
                'component.button.spacing.sm.horizontal',
              ),
            ),
            xsVertical: _readDouble(
              resolved,
              'component.button.spacing.xs.vertical',
              fallback: _readDouble(
                resolved,
                'component.button.spacing.sm.vertical',
              ),
            ),
            smHorizontal: _readDouble(
              resolved,
              'component.button.spacing.sm.horizontal',
            ),
            smVertical: _readDouble(
              resolved,
              'component.button.spacing.sm.vertical',
            ),
            mdHorizontal: _readDouble(
              resolved,
              'component.button.spacing.md.horizontal',
            ),
            mdVertical: _readDouble(
              resolved,
              'component.button.spacing.md.vertical',
            ),
          ),
          labelStyle: _readTextToken(resolved, 'component.button.label-style'),
          minHeight: _readDouble(resolved, 'component.button.min-height'),
          leadingIconSize: _readDouble(
            resolved,
            'component.button.leading-icon-size',
          ),
          iconOnlySize: _readDouble(
            resolved,
            'component.button.icon-only-size',
          ),
          primary: _readButtonVariant(resolved, 'component.button.primary'),
          secondary: _readButtonVariant(resolved, 'component.button.secondary'),
          popoverPrimary: _readButtonVariant(
            resolved,
            'component.button.popover-primary',
            'component.button.tertiary',
          ),
          popoverSecondary: _readButtonVariant(
            resolved,
            'component.button.popover-secondary',
            'component.button.secondary',
          ),
          tertiary: _readButtonVariant(resolved, 'component.button.tertiary'),
          ghost: _readButtonVariant(resolved, 'component.button.ghost'),
          dangerHigh: _readButtonVariant(
            resolved,
            'component.button.danger-high',
          ),
          dangerSoft: _readButtonVariant(
            resolved,
            'component.button.danger-soft',
          ),
          loading: Host4ButtonLoadingTokens(
            spinnerSize: _readDouble(
              resolved,
              'component.button.loading.spinner-size',
            ),
            spinnerGap: _readDouble(
              resolved,
              'component.button.loading.spinner-gap',
            ),
            opacity: _readDouble(resolved, 'component.button.loading.opacity'),
          ),
        ),
        card: Host4CardComponentTokens(
          padding: _readDouble(resolved, 'component.card.padding'),
          radius: _readDouble(resolved, 'component.card.radius'),
          background: _readColor(resolved, 'component.card.background'),
          border: _readColor(resolved, 'component.card.border'),
          title: _readColor(resolved, 'component.card.title'),
          subtitle: _readColor(resolved, 'component.card.subtitle'),
          shadowColor: _readColor(resolved, 'component.card.shadow-color'),
          shadowOpacity: _readDouble(resolved, 'component.card.shadow-opacity'),
          shadowBlur: _readDouble(resolved, 'component.card.shadow-blur'),
          shadowOffsetY: _readDouble(
            resolved,
            'component.card.shadow-offset-y',
          ),
        ),
        navigationBar: Host4NavigationBarComponentTokens(
          paddingHorizontal: _readDouble(
            resolved,
            'component.navigation-bar.padding-horizontal',
          ),
          paddingTop: _readDouble(
            resolved,
            'component.navigation-bar.padding-top',
          ),
          paddingBottom: _readDouble(
            resolved,
            'component.navigation-bar.padding-bottom',
          ),
          leadingGap: _readDouble(
            resolved,
            'component.navigation-bar.leading-gap',
          ),
          background: _readColor(
            resolved,
            'component.navigation-bar.background',
          ),
          titleStyle: _readTextToken(
            resolved,
            'component.navigation-bar.title-style',
          ),
          subtitleStyle: _readTextToken(
            resolved,
            'component.navigation-bar.subtitle-style',
          ),
          title: _readColor(resolved, 'component.navigation-bar.title'),
          subtitle: _readColor(resolved, 'component.navigation-bar.subtitle'),
          icon: _readColor(resolved, 'component.navigation-bar.icon'),
        ),
        searchBar: Host4SearchBarComponentTokens(
          shortcutHorizontal: _readDouble(
            resolved,
            'component.search-bar.shortcut.horizontal',
          ),
          shortcutVertical: _readDouble(
            resolved,
            'component.search-bar.shortcut.vertical',
          ),
          shortcutBackground: _readColor(
            resolved,
            'component.search-bar.shortcut.background',
          ),
          shortcutRadius: _readDouble(
            resolved,
            'component.search-bar.shortcut.radius',
          ),
          shortcutStyle: _readTextToken(
            resolved,
            'component.search-bar.shortcut.text-style',
          ),
          shortcutTextColor: _readColor(
            resolved,
            'component.search-bar.shortcut.text-color',
          ),
        ),
        sectionHeader: Host4SectionHeaderComponentTokens(
          titleStyle: _readTextToken(
            resolved,
            'component.section-header.title-style',
          ),
          titleColor: _readColor(
            resolved,
            'component.section-header.title-color',
          ),
          subtitleGap: _readDouble(
            resolved,
            'component.section-header.subtitle-gap',
          ),
          actionGap: _readDouble(
            resolved,
            'component.section-header.action-gap',
          ),
          subtitleStyle: _readTextToken(
            resolved,
            'component.section-header.subtitle-style',
          ),
          subtitleColor: _readColor(
            resolved,
            'component.section-header.subtitle-color',
          ),
        ),
        textField: Host4TextFieldComponentTokens(
          paddingHorizontal: _readDouble(
            resolved,
            'component.text-field.padding-horizontal',
          ),
          paddingVertical: _readDouble(
            resolved,
            'component.text-field.padding-vertical',
          ),
          radius: _readDouble(resolved, 'component.text-field.radius'),
          minHeight: _readDouble(resolved, 'component.text-field.min-height'),
          prefixIconSize: _readDouble(
            resolved,
            'component.text-field.prefix-icon-size',
          ),
          suffixGap: _readDouble(resolved, 'component.text-field.suffix-gap'),
          textStyle: _readTextToken(
            resolved,
            'component.text-field.text-style',
          ),
          placeholderStyle: _readTextToken(
            resolved,
            'component.text-field.placeholder-style',
          ),
          defaultState: _readTextFieldState(
            resolved,
            'component.text-field.state.default',
          ),
          focusedState: _readTextFieldState(
            resolved,
            'component.text-field.state.focused',
          ),
          disabledState: _readTextFieldState(
            resolved,
            'component.text-field.state.disabled',
          ),
          readOnlyState: _readTextFieldState(
            resolved,
            'component.text-field.state.read-only',
          ),
          errorState: _readTextFieldState(
            resolved,
            'component.text-field.state.error',
          ),
          successState: _readTextFieldState(
            resolved,
            'component.text-field.state.success',
          ),
        ),
        listCell: Host4ListCellComponentTokens(
          radius: _readDouble(resolved, 'component.list-cell.radius'),
          paddingHorizontal: _readDouble(
            resolved,
            'component.list-cell.padding-horizontal',
          ),
          paddingVertical: _readDouble(
            resolved,
            'component.list-cell.padding-vertical',
          ),
          minHeight: _readDouble(resolved, 'component.list-cell.min-height'),
          leadingGap: _readDouble(resolved, 'component.list-cell.leading-gap'),
          subtitleGap: _readDouble(
            resolved,
            'component.list-cell.subtitle-gap',
          ),
          trailingGap: _readDouble(
            resolved,
            'component.list-cell.trailing-gap',
          ),
          chevronGap: _readDouble(resolved, 'component.list-cell.chevron-gap'),
          titleStyle: _readTextToken(
            resolved,
            'component.list-cell.title-style',
          ),
          subtitleStyle: _readTextToken(
            resolved,
            'component.list-cell.subtitle-style',
          ),
          trailingStyle: _readTextToken(
            resolved,
            'component.list-cell.trailing-style',
          ),
          defaultState: _readListCellState(
            resolved,
            'component.list-cell.state.default',
          ),
          pressedState: _readListCellState(
            resolved,
            'component.list-cell.state.pressed',
          ),
          disabledState: _readListCellState(
            resolved,
            'component.list-cell.state.disabled',
          ),
          selectedState: _readListCellState(
            resolved,
            'component.list-cell.state.selected',
          ),
        ),
        tabBar: Host4TabBarComponentTokens(
          background: _readColor(resolved, 'component.tab-bar.background'),
          height: _readDouble(resolved, 'component.tab-bar.height'),
          iconSize: _readDouble(resolved, 'component.tab-bar.icon-size'),
          featuredIconSize: _readDouble(
            resolved,
            'component.tab-bar.featured-icon-size',
          ),
          labelStyle: _readTextToken(resolved, 'component.tab-bar.label-style'),
          labelGap: _readDouble(resolved, 'component.tab-bar.label-gap'),
          bottomGap: _readDouble(resolved, 'component.tab-bar.bottom-gap'),
          itemStates: Host4TabBarItemStateSet(
            defaultState: _readTabBarItemState(
              resolved,
              'component.tab-bar.item.state.default',
            ),
            pressedState: _readTabBarItemState(
              resolved,
              'component.tab-bar.item.state.pressed',
            ),
            disabledState: _readTabBarItemState(
              resolved,
              'component.tab-bar.item.state.disabled',
            ),
            selectedState: _readTabBarItemState(
              resolved,
              'component.tab-bar.item.state.selected',
            ),
          ),
          items: fallbackImages?.tabItems ?? const [],
        ),
        tag: Host4TagComponentTokens(
          radius: _readDouble(resolved, 'component.tag.radius'),
          paddingHorizontal: _readDouble(
            resolved,
            'component.tag.padding-horizontal',
          ),
          paddingVertical: _readDouble(
            resolved,
            'component.tag.padding-vertical',
          ),
          iconSize: _readDouble(resolved, 'component.tag.icon-size'),
          iconGap: _readDouble(resolved, 'component.tag.icon-gap'),
          labelStyle: _readTextToken(resolved, 'component.tag.label-style'),
          defaultState: _readTagState(resolved, 'component.tag.state.default'),
          selectedState: _readTagState(
            resolved,
            'component.tag.state.selected',
          ),
          disabledState: _readTagState(
            resolved,
            'component.tag.state.disabled',
          ),
        ),
        emptyState: Host4EmptyStateComponentTokens(
          iconSize: _readDouble(resolved, 'component.empty-state.icon-size'),
          iconGap: _readDouble(resolved, 'component.empty-state.icon-gap'),
          textGap: _readDouble(resolved, 'component.empty-state.text-gap'),
          actionGap: _readDouble(resolved, 'component.empty-state.action-gap'),
          iconColor: _readColor(resolved, 'component.empty-state.icon-color'),
          titleStyle: _readTextToken(
            resolved,
            'component.empty-state.title-style',
          ),
          titleColor: _readColor(resolved, 'component.empty-state.title-color'),
          subtitleStyle: _readTextToken(
            resolved,
            'component.empty-state.subtitle-style',
          ),
          subtitleColor: _readColor(
            resolved,
            'component.empty-state.subtitle-color',
          ),
        ),
        banner: Host4BannerComponentTokens(
          paddingHorizontal: _readDouble(
            resolved,
            'component.banner.padding-horizontal',
          ),
          paddingVertical: _readDouble(
            resolved,
            'component.banner.padding-vertical',
          ),
          radius: _readDouble(resolved, 'component.banner.radius'),
          iconSize: _readDouble(resolved, 'component.banner.icon-size'),
          iconGap: _readDouble(resolved, 'component.banner.icon-gap'),
          titleBodyGap: _readDouble(
            resolved,
            'component.banner.title-body-gap',
          ),
          titleStyle: _readTextToken(resolved, 'component.banner.title-style'),
          bodyStyle: _readTextToken(resolved, 'component.banner.body-style'),
          info: _readBannerVariant(resolved, 'component.banner.variant.info'),
          success: _readBannerVariant(
            resolved,
            'component.banner.variant.success',
          ),
          warning: _readBannerVariant(
            resolved,
            'component.banner.variant.warning',
          ),
          error: _readBannerVariant(resolved, 'component.banner.variant.error'),
        ),
        progressBar: Host4ProgressBarComponentTokens(
          height: _readDouble(resolved, 'component.progress-bar.height'),
          radius: _readDouble(resolved, 'component.progress-bar.radius'),
          track: _readColor(resolved, 'component.progress-bar.track'),
          fill: _readColor(resolved, 'component.progress-bar.fill'),
          fillSuccess: _readColor(
            resolved,
            'component.progress-bar.fill-success',
          ),
          fillWarning: _readColor(
            resolved,
            'component.progress-bar.fill-warning',
          ),
          fillError: _readColor(resolved, 'component.progress-bar.fill-error'),
        ),
        segmentedFilter: Host4SegmentedFilterComponentTokens(
          paddingHorizontal: _readDouble(
            resolved,
            'component.segmented-filter.padding-horizontal',
          ),
          paddingVertical: _readDouble(
            resolved,
            'component.segmented-filter.padding-vertical',
          ),
          radius: _readDouble(resolved, 'component.segmented-filter.radius'),
          containerRadius: _readDouble(
            resolved,
            'component.segmented-filter.container-radius',
          ),
          gap: _readDouble(resolved, 'component.segmented-filter.gap'),
          iconSize: _readDouble(
            resolved,
            'component.segmented-filter.icon-size',
          ),
          iconGap: _readDouble(resolved, 'component.segmented-filter.icon-gap'),
          labelStyle: _readTextToken(
            resolved,
            'component.segmented-filter.label-style',
          ),
          containerBackground: _readColor(
            resolved,
            'component.segmented-filter.container.background',
          ),
          containerBorder: _readColor(
            resolved,
            'component.segmented-filter.container.border',
          ),
          defaultState: _readSegmentedFilterItemState(
            resolved,
            'component.segmented-filter.item.state.default',
          ),
          selectedState: _readSegmentedFilterItemState(
            resolved,
            'component.segmented-filter.item.state.selected',
          ),
          disabledState: _readSegmentedFilterItemState(
            resolved,
            'component.segmented-filter.item.state.disabled',
          ),
        ),
        infoChip: Host4InfoChipComponentTokens(
          paddingHorizontal: _readDouble(
            resolved,
            'component.info-chip.padding-horizontal',
          ),
          paddingVertical: _readDouble(
            resolved,
            'component.info-chip.padding-vertical',
          ),
          radius: _readDouble(resolved, 'component.info-chip.radius'),
          iconSize: _readDouble(resolved, 'component.info-chip.icon-size'),
          iconGap: _readDouble(resolved, 'component.info-chip.icon-gap'),
          labelStyle: _readTextToken(
            resolved,
            'component.info-chip.label-style',
          ),
          background: _readColor(resolved, 'component.info-chip.background'),
          foreground: _readColor(resolved, 'component.info-chip.foreground'),
          border: _readColor(resolved, 'component.info-chip.border'),
          iconColor: _readColor(resolved, 'component.info-chip.icon-color'),
        ),
        toolbar: Host4ToolbarComponentTokens(
          paddingHorizontal: _readDouble(
            resolved,
            'component.toolbar.padding-horizontal',
          ),
          paddingVertical: _readDouble(
            resolved,
            'component.toolbar.padding-vertical',
          ),
          gap: _readDouble(resolved, 'component.toolbar.gap'),
          background: _readColor(resolved, 'component.toolbar.background'),
          borderBottom: _readColor(resolved, 'component.toolbar.border-bottom'),
        ),
        topBar: Host4TopBarComponentTokens(
          barHeight: _readDouble(resolved, 'component.top-bar.bar-height'),
          paddingHorizontal: _readDouble(
            resolved,
            'component.top-bar.padding-horizontal',
          ),
          fontFamily: _readString(resolved, 'component.top-bar.font-family'),
          titleStyle: _readTextToken(resolved, 'component.top-bar.title-style'),
          background: _readColor(resolved, 'component.top-bar.background'),
          title: _readColor(resolved, 'component.top-bar.title'),
          chevron: _readColor(resolved, 'component.top-bar.chevron'),
        ),
      ),
    );
  }

  static List<Host4TabItemImages> _readTabItemImages(
    Map<String, dynamic> resolved,
    Map<String, dynamic> sourceTokens,
    String assetDirectory,
    String mode,
  ) {
    final isLight = mode == 'light';
    final items = <Host4TabItemImages>[];
    const slots = <String>['home', 'list', 'settings', 'slot3', 'slot4'];
    for (final slot in slots) {
      try {
        final normal = _readString(resolved, 'asset.image.tab.$slot.default');
        final selected = _readString(
          resolved,
          'asset.image.tab.$slot.selected',
        );

        String? lightFallbackNormal;
        String? lightFallbackSelected;
        if (!isLight) {
          try {
            lightFallbackNormal = _resolveAssetPath(
              assetDirectory,
              _readString(sourceTokens, 'asset.image.tab.$slot.default.light'),
            );
            lightFallbackSelected = _resolveAssetPath(
              assetDirectory,
              _readString(sourceTokens, 'asset.image.tab.$slot.selected.light'),
            );
          } on FormatException {
            // No light fallback defined for this slot; leave null.
          }
        }

        items.add(
          Host4TabItemImages(
            normal: _resolveAssetPath(assetDirectory, normal),
            selected: _resolveAssetPath(assetDirectory, selected),
            lightFallbackNormal: lightFallbackNormal,
            lightFallbackSelected: lightFallbackSelected,
          ),
        );
      } on FormatException {
        break;
      }
    }
    return List.unmodifiable(items);
  }

  static Host4ButtonVariantTokens _readButtonVariant(
    Map<String, dynamic> json,
    String path, [
    String? fallbackPath,
  ]) {
    final resolvedPath = _hasTokenPath(json, path)
        ? path
        : (fallbackPath ?? path);
    return Host4ButtonVariantTokens(
      radius: _readDouble(json, '$resolvedPath.radius'),
      focusRingVisible: _readBool(
        json,
        '$resolvedPath.focus-ring-visible',
        fallback: true,
      ),
      defaultState: _readButtonState(json, '$resolvedPath.state.default'),
      hoverState: _readButtonState(json, '$resolvedPath.state.hover'),
      pressedState: _readButtonState(json, '$resolvedPath.state.pressed'),
      disabledState: _readButtonState(json, '$resolvedPath.state.disabled'),
      focusedState: _readButtonState(json, '$resolvedPath.state.focused'),
      selectedState: _readOptionalButtonState(
        json,
        '$resolvedPath.state.selected',
      ),
    );
  }

  static Host4ButtonStateTokens _readButtonState(
    Map<String, dynamic> json,
    String path,
  ) {
    // Figma exports use background-primary; fall back to background for older tokens.
    final backgroundKey = _hasTokenPath(json, '$path.background-primary')
        ? '$path.background-primary'
        : '$path.background';
    return Host4ButtonStateTokens(
      background: _readColor(json, backgroundKey),
      foreground: _readColor(json, '$path.foreground'),
      border: _readColor(json, '$path.border'),
      opacity: _readDouble(json, '$path.opacity', fallback: 1),
      bottomBorderWidth: _readDouble(
        json,
        '$path.bottom-border-width',
        fallback: 0,
      ),
    );
  }

  static Host4ButtonStateTokens? _readOptionalButtonState(
    Map<String, dynamic> json,
    String path,
  ) {
    if (!_hasTokenPath(json, path)) {
      return null;
    }
    return _readButtonState(json, path);
  }

  static Host4TextFieldStateTokens _readTextFieldState(
    Map<String, dynamic> json,
    String path,
  ) {
    return Host4TextFieldStateTokens(
      background: _readColor(json, '$path.background'),
      border: _readColor(json, '$path.border'),
      text: _readColor(json, '$path.text'),
      placeholder: _readColor(json, '$path.placeholder'),
      icon: _readColor(json, '$path.icon'),
    );
  }

  static Host4ListCellStateTokens _readListCellState(
    Map<String, dynamic> json,
    String path,
  ) {
    return Host4ListCellStateTokens(
      background: _readColor(json, '$path.background'),
      title: _readColor(json, '$path.title'),
      subtitle: _readColor(json, '$path.subtitle'),
      trailing: _readColor(json, '$path.trailing'),
      divider: _readColor(json, '$path.divider'),
    );
  }

  static Host4TabBarItemStateTokens _readTabBarItemState(
    Map<String, dynamic> json,
    String path,
  ) {
    return Host4TabBarItemStateTokens(
      labelColor: _readColor(json, '$path.label-color'),
      iconColor: _readColor(json, '$path.icon-color'),
    );
  }

  static Host4TagStateTokens _readTagState(
    Map<String, dynamic> json,
    String path,
  ) {
    return Host4TagStateTokens(
      background: _readColor(json, '$path.background'),
      foreground: _readColor(json, '$path.foreground'),
      border: _readColor(json, '$path.border'),
      icon: _readColor(json, '$path.icon'),
    );
  }

  static Host4BannerVariantTokens _readBannerVariant(
    Map<String, dynamic> json,
    String path,
  ) {
    return Host4BannerVariantTokens(
      background: _readColor(json, '$path.background'),
      foreground: _readColor(json, '$path.foreground'),
      border: _readColor(json, '$path.border'),
      icon: _readColor(json, '$path.icon'),
    );
  }

  static Host4SegmentedFilterItemStateTokens _readSegmentedFilterItemState(
    Map<String, dynamic> json,
    String path,
  ) {
    return Host4SegmentedFilterItemStateTokens(
      background: _readColor(json, '$path.background'),
      foreground: _readColor(json, '$path.foreground'),
      border: _readColor(json, '$path.border'),
    );
  }

  static Host4TextToken _readTextToken(Map<String, dynamic> json, String path) {
    return Host4TextToken(
      fontSize: _readDouble(json, '$path.font-size'),
      lineHeight: _readDouble(json, '$path.line-height'),
      fontWeight: _readFontWeight(json, '$path.font-weight'),
      letterSpacing: _readDouble(json, '$path.letter-spacing', fallback: 0),
    );
  }

  static String _resolveAssetPath(String directory, String assetPath) {
    if (assetPath.startsWith('packages/') || assetPath.startsWith('assets/')) {
      return assetPath;
    }
    return '$directory$assetPath';
  }

  static Future<String> _loadManifestString(
    AssetBundle bundle,
    String assetPath,
  ) async {
    final manifestPath = assetPath.replaceFirst(
      RegExp(r'tokens\.json$'),
      'manifest.json',
    );
    return bundle.loadString(manifestPath);
  }

  static Future<String?> _loadAssetFileString(
    AssetBundle bundle,
    String assetPath,
  ) async {
    final filePath = assetPath.replaceFirst(
      RegExp(r'tokens\.json$'),
      'asset.json',
    );
    try {
      return await bundle.loadString(filePath);
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Background isolate helpers for compute()
// ---------------------------------------------------------------------------

typedef _ThemeParseInput = ({
  String tokensJson,
  String? assetJson,
  String manifestJson,
  String? mode,
});

typedef _ThemeParseOutput = ({
  Map<String, dynamic> resolved,
  Map<String, dynamic> sourceTokens,
  String selectedMode,
});

/// Runs in a background isolate via [compute].
/// Decodes JSON, normalises the theme tree, and resolves all token references.
_ThemeParseOutput _parseThemeInBackground(_ThemeParseInput input) {
  final decoded = json.decode(input.tokensJson);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Theme tokens root must be a JSON object.');
  }

  if (input.assetJson != null) {
    final assetDecoded = json.decode(input.assetJson!);
    if (assetDecoded is Map<String, dynamic>) {
      decoded['asset'] = assetDecoded;
    }
  }

  final manifest = json.decode(input.manifestJson);
  if (manifest is! Map<String, dynamic>) {
    throw const FormatException('Theme manifest root must be a JSON object.');
  }

  final selectedMode = _resolveSelectedMode(manifest, input.mode);
  final normalized = _normalizeTheme(decoded, manifest, selectedMode);
  final resolved = Host4ReferenceResolver(normalized).resolveMap(normalized);
  return (
    resolved: resolved,
    sourceTokens: decoded,
    selectedMode: selectedMode,
  );
}

// ---------------------------------------------------------------------------

Map<String, dynamic> _normalizeTheme(
  Map<String, dynamic> tokens,
  Map<String, dynamic> manifest,
  String selectedMode,
) {
  final supportedModes = (manifest['modes'] as List<dynamic>? ?? const [])
      .map((item) => item.toString())
      .toList(growable: false);
  if (!supportedModes.contains(selectedMode)) {
    throw FormatException('Unsupported theme mode: $selectedMode');
  }

  return <String, dynamic>{
    'schema': tokens['schema'],
    'meta': <String, dynamic>{
      'id': manifest['id'],
      'name': manifest['name'],
      'defaultMode': manifest['defaultMode'],
      'mode': selectedMode,
      'modes': supportedModes,
    },
    'primitive': tokens['primitive'],
    'semantic': _selectModeBranches(
      readJsonMap(tokens, 'semantic'),
      supportedModes,
      selectedMode,
    ),
    'asset': _selectModeBranches(
      tokens['asset'] is Map<String, dynamic>
          ? tokens['asset'] as Map<String, dynamic>
          : const <String, dynamic>{},
      supportedModes,
      selectedMode,
    ),
    'component': readJsonMap(tokens, 'component'),
  };
}

dynamic _selectModeBranches(
  dynamic value,
  List<String> supportedModes,
  String selectedMode,
) {
  if (value is Map<String, dynamic>) {
    final keys = value.keys.toSet();
    if (keys.isNotEmpty &&
        keys.every(supportedModes.contains) &&
        value.containsKey(selectedMode)) {
      return _selectModeBranches(
        value[selectedMode],
        supportedModes,
        selectedMode,
      );
    }

    return value.map<String, dynamic>(
      (key, entry) => MapEntry(
        key,
        _selectModeBranches(entry, supportedModes, selectedMode),
      ),
    );
  }

  if (value is List<dynamic>) {
    return value
        .map(
          (entry) => _selectModeBranches(entry, supportedModes, selectedMode),
        )
        .toList(growable: false);
  }

  return value;
}

String _resolveSelectedMode(
  Map<String, dynamic> manifest,
  String? requestedMode,
) {
  if (requestedMode != null) {
    return requestedMode;
  }
  final defaultMode = manifest['defaultMode'];
  if (defaultMode is String && defaultMode.isNotEmpty) {
    return defaultMode;
  }
  throw const FormatException('manifest.defaultMode is required.');
}

Brightness _parseBrightness(String value) {
  return switch (value) {
    'dark' => Brightness.dark,
    _ => Brightness.light,
  };
}

dynamic _readPath(Map<String, dynamic> json, String path) {
  try {
    return readJsonPath(json, path);
  } on FormatException {
    throw FormatException('Missing token path: $path');
  }
}

String _readString(Map<String, dynamic> json, String path) {
  try {
    return readJsonString(json, path);
  } on FormatException catch (error) {
    if (error.message == 'Missing json path: $path') {
      throw FormatException('Missing token path: $path');
    }
    rethrow;
  }
}

bool _hasTokenPath(Map<String, dynamic> json, String path) {
  try {
    readJsonPath(json, path);
    return true;
  } on FormatException {
    return false;
  }
}

List<String> _readStringList(Map<String, dynamic> json, String path) {
  try {
    return readJsonStringList(json, path);
  } on FormatException catch (error) {
    if (error.message == 'Missing json path: $path') {
      throw FormatException('Missing token path: $path');
    }
    rethrow;
  }
}

double _readDouble(Map<String, dynamic> json, String path, {double? fallback}) {
  try {
    return readJsonDouble(json, path, fallback: fallback);
  } on FormatException catch (error) {
    if (error.message == 'Missing json path: $path' ||
        error.message == 'Missing token path: $path') {
      if (fallback != null) {
        return fallback;
      }
      throw FormatException('Missing token path: $path');
    }
    rethrow;
  }
}

bool _readBool(Map<String, dynamic> json, String path, {bool? fallback}) {
  try {
    final value = _readPath(json, path);
    if (value is bool) return value;
    throw FormatException('Expected bool at $path.');
  } on FormatException catch (error) {
    if (error.message == 'Missing json path: $path' ||
        error.message == 'Missing token path: $path') {
      if (fallback != null) {
        return fallback;
      }
      throw FormatException('Missing token path: $path');
    }
    rethrow;
  }
}

Color _readColor(Map<String, dynamic> json, String path) {
  final value = _readString(json, path);
  final normalized = value.replaceFirst('#', '');
  // Figma exports 8-digit hex as RRGGBBAA; Flutter Color uses AARRGGBB.
  // Swap alpha from tail to head for 8-digit values.
  final String hex;
  if (normalized.length == 6) {
    hex = 'FF$normalized';
  } else if (normalized.length == 8) {
    hex = normalized.substring(6) + normalized.substring(0, 6);
  } else {
    throw FormatException('Expected hex color at $path.');
  }
  return Color(int.parse(hex, radix: 16));
}

FontWeight _readFontWeight(Map<String, dynamic> json, String path) {
  final value = _readPath(json, path);
  if (value is! num) {
    throw FormatException('Expected numeric fontWeight at $path.');
  }

  return switch (value.toInt()) {
    100 => FontWeight.w100,
    200 => FontWeight.w200,
    300 => FontWeight.w300,
    400 => FontWeight.w400,
    500 => FontWeight.w500,
    600 => FontWeight.w600,
    700 => FontWeight.w700,
    800 => FontWeight.w800,
    900 => FontWeight.w900,
    _ => FontWeight.w400,
  };
}
