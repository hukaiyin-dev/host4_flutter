import 'package:flutter/widgets.dart';

/// Localized chrome for the built-in [Host4WebView] error page.
class Host4WebViewCopy {
  const Host4WebViewCopy({
    required this.loadFailed,
    required this.retry,
    required this.errorCodeLabel,
  });

  final String loadFailed;
  final String retry;
  final String errorCodeLabel;

  String errorDetail({required String description, int? code}) {
    final trimmed = description.trim();
    if (code == null) {
      return trimmed;
    }
    if (trimmed.isEmpty) {
      return '$errorCodeLabel: $code';
    }
    return '$trimmed ($errorCodeLabel: $code)';
  }

  static Host4WebViewCopy of(BuildContext context) {
    return resolve(
      Localizations.maybeLocaleOf(context) ??
          View.of(context).platformDispatcher.locale,
    );
  }

  static Host4WebViewCopy resolve(Locale locale) {
    final language = locale.languageCode.toLowerCase();
    final script = locale.scriptCode?.toLowerCase();
    final country = locale.countryCode?.toUpperCase();
    if (language == 'zh') {
      final isHant = script == 'hant' ||
          country == 'TW' ||
          country == 'HK' ||
          country == 'MO';
      if (isHant) {
        return const Host4WebViewCopy(
          loadFailed: '頁面載入失敗',
          retry: '重試',
          errorCodeLabel: '錯誤碼',
        );
      }
      return const Host4WebViewCopy(
        loadFailed: '页面加载失败',
        retry: '重试',
        errorCodeLabel: '错误码',
      );
    }
    if (language == 'es') {
      return const Host4WebViewCopy(
        loadFailed: 'Error al cargar la página',
        retry: 'Reintentar',
        errorCodeLabel: 'Código de error',
      );
    }
    if (language == 'id') {
      return const Host4WebViewCopy(
        loadFailed: 'Gagal memuat halaman',
        retry: 'Coba lagi',
        errorCodeLabel: 'Kode error',
      );
    }
    return const Host4WebViewCopy(
      loadFailed: 'Failed to load page',
      retry: 'Retry',
      errorCodeLabel: 'Error code',
    );
  }
}
