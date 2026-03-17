import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

void main() {
  test(
    'loads runtime theme from manifest plus multi-mode tokens json',
    () async {
      final bundle = _FakeAssetBundle({
        'assets/themes/default/manifest.json': json.encode(_manifestJson),
        'assets/themes/default/tokens.json': json.encode(_themeJson),
      });

      final theme = await Host4ThemeLoader.loadFromAsset(
        bundle,
        'assets/themes/default/tokens.json',
      );

      expect(theme.meta.id, 'default');
      expect(theme.meta.name, 'Demo Theme');
      expect(theme.meta.mode, 'light');
      expect(theme.meta.supportedModes, ['light', 'dark']);
      expect(theme.colors.brandPrimary, const Color(0xFF335CFF));
      expect(theme.spacing.page, 24);
      expect(theme.spacing.inputVertical, 12);
      expect(
        theme.images.heroBanner,
        'assets/themes/default/images/hero_banner_light.png',
      );
    },
  );

  test(
    'resolves explicit alias.shared and alias.modes.dark references',
    () async {
      final bundle = _FakeAssetBundle({
        'assets/themes/default/manifest.json': json.encode(_manifestJson),
        'assets/themes/default/tokens.json': json.encode(_themeJson),
      });

      final theme = await Host4ThemeLoader.loadFromAsset(
        bundle,
        'assets/themes/default/tokens.json',
        mode: 'dark',
      );

      expect(theme.meta.mode, 'dark');
      expect(theme.colors.pageBackground, const Color(0xFF121A29));
      expect(theme.colors.textPrimary, const Color(0xFFFFFFFF));
      expect(theme.colors.brandPrimary, const Color(0xFF335CFF));
      expect(theme.components.card.background, const Color(0xFF1A2436));
      expect(
        theme.components.button.primary.background,
        const Color(0xFF6787FF),
      );
      expect(
        theme.components.button.primary.foreground,
        const Color(0xFFFFFFFF),
      );
      expect(
        theme.images.heroBanner,
        'assets/themes/default/images/hero_banner_dark.png',
      );
    },
  );
}

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.values);

  final Map<String, String> values;

  @override
  Future<ByteData> load(String key) async {
    final value = values[key];
    if (value == null) {
      throw StateError('Missing fake asset: $key');
    }
    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = values[key];
    if (value == null) {
      throw StateError('Missing fake asset: $key');
    }
    return value;
  }
}

const _manifestJson = {
  'id': 'default',
  'name': 'Demo Theme',
  'version': '1.0.0',
  'min_sdk': '1.0.0',
  'defaultMode': 'light',
  'modes': ['light', 'dark'],
  'preview': 'preview.png',
};

const _themeJson = {
  'schema': '1.0',
  'primitive': {
    'color': {
      'blue': {'300': '#8CA4FF', '400': '#6787FF', '500': '#335CFF'},
      'coral': {'500': '#FF8B5E'},
      'slate': {
        '50': '#F4F7FC',
        '100': '#E7EDF8',
        '200': '#D4DEEF',
        '300': '#9BA8C3',
        '400': '#6A7691',
        '700': '#243147',
        '800': '#1A2436',
        '900': '#121A29',
      },
      'white': {'500': '#FFFFFF'},
      'green': {'500': '#2D9C62'},
      'amber': {'500': '#B7791F'},
    },
    'spacing': {'xs': 4, 'sm': 8, 'md': 12, 'lg': 16, 'xl': 24, 'xxl': 32},
    'radius': {'sm': 10, 'md': 16, 'lg': 24, 'pill': 999},
    'blur': {'card': 18, 'banner': 24, 'chrome': 20},
    'typography': {
      'display': {
        'fontSize': 32,
        'lineHeight': 38,
        'fontWeight': 700,
        'letterSpacing': -0.4,
      },
      'title': {
        'fontSize': 24,
        'lineHeight': 30,
        'fontWeight': 700,
        'letterSpacing': -0.3,
      },
      'heading': {
        'fontSize': 18,
        'lineHeight': 24,
        'fontWeight': 600,
        'letterSpacing': -0.1,
      },
      'body': {
        'fontSize': 15,
        'lineHeight': 22,
        'fontWeight': 400,
        'letterSpacing': 0,
      },
      'label': {
        'fontSize': 14,
        'lineHeight': 18,
        'fontWeight': 600,
        'letterSpacing': 0.1,
      },
      'caption': {
        'fontSize': 12,
        'lineHeight': 16,
        'fontWeight': 500,
        'letterSpacing': 0.2,
      },
    },
  },
  'alias': {
    'shared': {
      'color': {
        'brand': {
          'primary': '{primitive.color.blue.500}',
          'secondary': '{primitive.color.blue.400}',
          'accent': '{primitive.color.coral.500}',
        },
        'status': {
          'success': '{primitive.color.green.500}',
          'warning': '{primitive.color.amber.500}',
        },
      },
      'spacing': {
        'page': '{primitive.spacing.xl}',
        'section': '{primitive.spacing.xl}',
        'card': '{primitive.spacing.lg}',
        'button': {
          'horizontal': '{primitive.spacing.lg}',
          'vertical': '{primitive.spacing.md}',
        },
        'input': {
          'horizontal': '{primitive.spacing.lg}',
          'vertical': '{primitive.spacing.md}',
        },
        'list': {'gap': '{primitive.spacing.sm}'},
      },
      'radius': {
        'button': '{primitive.radius.md}',
        'card': '{primitive.radius.lg}',
        'input': '{primitive.radius.md}',
        'banner': '{primitive.radius.lg}',
      },
      'image': {
        'pageOverlay': 'images/page_overlay.png',
        'spotIllustration': 'images/spot_illustration.png',
      },
    },
    'modes': {
      'light': {
        'color': {
          'bg': {
            'page': '{primitive.color.slate.50}',
            'surface': '{primitive.color.white.500}',
            'muted': '{primitive.color.slate.100}',
            'elevated': '{primitive.color.slate.100}',
          },
          'text': {
            'primary': '{primitive.color.slate.900}',
            'secondary': '{primitive.color.slate.400}',
            'inverse': '{primitive.color.white.500}',
          },
          'border': {
            'default': '{primitive.color.slate.200}',
            'strong': '{primitive.color.slate.400}',
          },
          'interactive': {'focus': '{primitive.color.blue.400}'},
        },
        'image': {
          'pageBackground': 'images/page_background_light.png',
          'heroBanner': 'images/hero_banner_light.png',
          'promoBanner': 'images/promo_banner_light.png',
        },
      },
      'dark': {
        'color': {
          'bg': {
            'page': '{primitive.color.slate.900}',
            'surface': '{primitive.color.slate.800}',
            'muted': '{primitive.color.slate.700}',
            'elevated': '{primitive.color.slate.700}',
          },
          'text': {
            'primary': '{primitive.color.white.500}',
            'secondary': '{primitive.color.slate.300}',
            'inverse': '{primitive.color.slate.900}',
          },
          'border': {
            'default': '{primitive.color.slate.700}',
            'strong': '{primitive.color.slate.300}',
          },
          'interactive': {'focus': '{primitive.color.blue.300}'},
        },
        'image': {
          'pageBackground': 'images/page_background_dark.png',
          'heroBanner': 'images/hero_banner_dark.png',
          'promoBanner': 'images/promo_banner_dark.png',
        },
      },
    },
  },
  'component': {
    'modes': {
      'light': {
        'button': {
          'primary': {
            'background': '{alias.shared.color.brand.primary}',
            'foreground': '{alias.modes.light.color.text.inverse}',
            'border': '{alias.shared.color.brand.primary}',
          },
          'secondary': {
            'background': '{alias.modes.light.color.bg.surface}',
            'foreground': '{alias.modes.light.color.text.primary}',
            'border': '{alias.modes.light.color.border.default}',
          },
          'ghost': {
            'background': '#00000000',
            'foreground': '{alias.modes.light.color.text.secondary}',
            'border': '#00000000',
          },
        },
        'card': {
          'background': '{alias.modes.light.color.bg.surface}',
          'border': '{alias.modes.light.color.border.default}',
          'title': '{alias.modes.light.color.text.primary}',
          'subtitle': '{alias.modes.light.color.text.secondary}',
        },
        'navigationBar': {
          'background': '{alias.modes.light.color.bg.page}',
          'title': '{alias.modes.light.color.text.primary}',
          'subtitle': '{alias.modes.light.color.text.secondary}',
          'icon': '{alias.modes.light.color.text.secondary}',
        },
        'textField': {
          'background': '{alias.modes.light.color.bg.surface}',
          'border': '{alias.modes.light.color.border.default}',
          'focusBorder': '{alias.modes.light.color.interactive.focus}',
          'text': '{alias.modes.light.color.text.primary}',
          'placeholder': '{alias.modes.light.color.text.secondary}',
          'icon': '{alias.modes.light.color.text.secondary}',
        },
        'banner': {
          'background': '{alias.shared.color.brand.primary}',
          'overlay': '#121A29CC',
          'title': '{alias.modes.light.color.text.inverse}',
          'subtitle': '#F4F7FC',
          'badgeBackground': '#FFFFFF29',
          'badgeForeground': '{alias.modes.light.color.text.inverse}',
        },
        'listCell': {
          'background': '{alias.modes.light.color.bg.surface}',
          'title': '{alias.modes.light.color.text.primary}',
          'subtitle': '{alias.modes.light.color.text.secondary}',
          'trailing': '{alias.modes.light.color.text.secondary}',
          'divider': '{alias.modes.light.color.border.default}',
        },
      },
      'dark': {
        'button': {
          'primary': {
            'background': '{alias.shared.color.brand.secondary}',
            'foreground': '{alias.modes.dark.color.text.primary}',
            'border': '{alias.shared.color.brand.secondary}',
          },
          'secondary': {
            'background': '{alias.modes.dark.color.bg.surface}',
            'foreground': '{alias.modes.dark.color.text.primary}',
            'border': '{alias.modes.dark.color.border.default}',
          },
          'ghost': {
            'background': '#00000000',
            'foreground': '{alias.modes.dark.color.text.secondary}',
            'border': '#00000000',
          },
        },
        'card': {
          'background': '{alias.modes.dark.color.bg.surface}',
          'border': '{alias.modes.dark.color.border.default}',
          'title': '{alias.modes.dark.color.text.primary}',
          'subtitle': '{alias.modes.dark.color.text.secondary}',
        },
        'navigationBar': {
          'background': '{alias.modes.dark.color.bg.page}',
          'title': '{alias.modes.dark.color.text.primary}',
          'subtitle': '{alias.modes.dark.color.text.secondary}',
          'icon': '{alias.modes.dark.color.text.secondary}',
        },
        'textField': {
          'background': '{alias.modes.dark.color.bg.surface}',
          'border': '{alias.modes.dark.color.border.default}',
          'focusBorder': '{alias.modes.dark.color.interactive.focus}',
          'text': '{alias.modes.dark.color.text.primary}',
          'placeholder': '{alias.modes.dark.color.text.secondary}',
          'icon': '{alias.modes.dark.color.text.secondary}',
        },
        'banner': {
          'background': '{alias.modes.dark.color.bg.surface}',
          'overlay': '#0A1020D9',
          'title': '{alias.modes.dark.color.text.primary}',
          'subtitle': '#D8E0F0',
          'badgeBackground': '#2F5BFF2E',
          'badgeForeground': '{alias.modes.dark.color.text.primary}',
        },
        'listCell': {
          'background': '{alias.modes.dark.color.bg.surface}',
          'title': '{alias.modes.dark.color.text.primary}',
          'subtitle': '{alias.modes.dark.color.text.secondary}',
          'trailing': '{alias.modes.dark.color.text.secondary}',
          'divider': '{alias.modes.dark.color.border.default}',
        },
      },
    },
  },
};
