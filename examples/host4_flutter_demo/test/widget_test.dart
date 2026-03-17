import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:host4_flutter_demo/main.dart';

void main() {
  testWidgets('renders AI theme demo shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      Host4DemoBootstrap(
        bundle: _FakeAssetBundle({
          'assets/themes/default/manifest.json': json.encode(
            _defaultManifestJson,
          ),
          'assets/themes/default/tokens.json': json.encode(_defaultThemeJson),
          'assets/themes/grassland/manifest.json': json.encode(
            _grasslandManifestJson,
          ),
          'assets/themes/grassland/tokens.json': json.encode(
            _grasslandThemeJson,
          ),
        }),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Featured Modules'), findsOneWidget);
    expect(find.text('Default Aurora · Light'), findsOneWidget);

    await tester.tap(find.text('List').first);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Component Inventory'), findsOneWidget);
  });
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

const _defaultManifestJson = {
  'id': 'default',
  'name': 'Default Aurora',
  'version': '1.0.0',
  'min_sdk': '1.0.0',
  'defaultMode': 'light',
  'modes': ['light', 'dark'],
  'preview': 'preview.png',
};

const _grasslandManifestJson = {
  'id': 'grassland',
  'name': 'Grassland Drift',
  'version': '1.0.0',
  'min_sdk': '1.0.0',
  'defaultMode': 'light',
  'modes': ['light', 'dark'],
  'preview': 'preview.png',
};

const _defaultThemeJson = {
  'schema': '1.0',
  'primitive': {
    'color': {
      'blue': {'300': '#8CA4FF', '400': '#5C7CFA', '500': '#2F5BFF'},
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

const _grasslandThemeJson = {
  'schema': '1.0',
  'primitive': {
    'color': {
      'green': {'400': '#7CB14E', '500': '#5E9732'},
      'sage': {'500': '#DDE9C9'},
      'sun': {'500': '#F0B95F'},
      'earth': {'500': '#6D4C2D'},
      'mist': {
        '50': '#F4F8EE',
        '100': '#E5F0DB',
        '200': '#CDDDBA',
        '400': '#61725A',
        '700': '#2F4423',
        '900': '#18220F',
      },
      'white': {'500': '#FFFFFF'},
      'teal': {'500': '#2E8E7E'},
      'amber': {'500': '#AA7A27'},
    },
    'spacing': {'xs': 4, 'sm': 8, 'md': 12, 'lg': 16, 'xl': 24, 'xxl': 32},
    'radius': {'sm': 12, 'md': 18, 'lg': 26, 'pill': 999},
    'blur': {'card': 20, 'banner': 28, 'chrome': 22},
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
          'primary': '{primitive.color.green.500}',
          'secondary': '{primitive.color.green.400}',
          'accent': '{primitive.color.sun.500}',
        },
        'status': {
          'success': '{primitive.color.teal.500}',
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
            'page': '{primitive.color.mist.50}',
            'surface': '{primitive.color.white.500}',
            'muted': '{primitive.color.sage.500}',
            'elevated': '{primitive.color.mist.100}',
          },
          'text': {
            'primary': '{primitive.color.mist.900}',
            'secondary': '{primitive.color.mist.400}',
            'inverse': '{primitive.color.white.500}',
          },
          'border': {
            'default': '{primitive.color.mist.200}',
            'strong': '{primitive.color.mist.400}',
          },
          'interactive': {'focus': '{primitive.color.green.400}'},
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
            'page': '{primitive.color.mist.900}',
            'surface': '{primitive.color.earth.500}',
            'muted': '{primitive.color.mist.700}',
            'elevated': '{primitive.color.mist.700}',
          },
          'text': {
            'primary': '{primitive.color.white.500}',
            'secondary': '{primitive.color.mist.200}',
            'inverse': '{primitive.color.mist.900}',
          },
          'border': {
            'default': '{primitive.color.mist.700}',
            'strong': '{primitive.color.mist.200}',
          },
          'interactive': {'focus': '{primitive.color.green.400}'},
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
          'overlay': '#18220FCC',
          'title': '{alias.modes.light.color.text.inverse}',
          'subtitle': '#F4F8EE',
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
          'overlay': '#081106D9',
          'title': '{alias.modes.dark.color.text.primary}',
          'subtitle': '#E5F0DB',
          'badgeBackground': '#7CB14E33',
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
