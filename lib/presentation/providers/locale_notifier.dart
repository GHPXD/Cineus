import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/app_meta_repository.dart';
import '../../l10n/app_l10n.dart';
import 'providers.dart';

/// The language the app renders in.
///
/// The bundled gameplay catalogue is currently Portuguese. Shipping English or
/// Spanish UI by default would make the shell look translated while 5,000 clue
/// texts remained Portuguese, so production exposes PT until localized content
/// exists. Developers can opt into the interface-only locales with:
///
/// --dart-define=CINEUS_ENABLE_INTERFACE_ONLY_LOCALES=true
class LocaleNotifier extends StateNotifier<Locale?> {
  final AppMetaRepository _meta;

  static const _key = 'locale';
  static const bool enableInterfaceOnlyLocales = bool.fromEnvironment(
    'CINEUS_ENABLE_INTERFACE_ONLY_LOCALES',
    defaultValue: false,
  );

  LocaleNotifier(this._meta) : super(null) {
    _load();
  }

  static List<Locale> get supportedLocales => enableInterfaceOnlyLocales
      ? AppL10n.supportedLocales
      : const [Locale('pt')];

  static List<Locale?> get options => [
        null,
        ...supportedLocales,
      ];

  Future<void> _load() async {
    final stored = await _meta.read(_key);
    if (stored == null || stored.isEmpty) return;
    final locale = Locale(stored);
    if (isSupported(locale)) {
      state = locale;
    } else {
      // A previous development build may have persisted EN/ES. Do not keep a
      // stale override once production returns to PT-only gameplay content.
      await _meta.write(_key, '');
    }
  }

  /// Sets the language, or clears the override when [locale] is null.
  Future<void> select(Locale? locale) async {
    if (locale != null && !isSupported(locale)) return;
    state = locale;
    await _meta.write(_key, locale?.languageCode ?? '');
  }

  static bool isSupported(Locale locale) => supportedLocales
      .any((l) => l.languageCode == locale.languageCode);

  /// Endonym for [locale] — a language is always listed in its own language.
  static String nameOf(Locale locale) => switch (locale.languageCode) {
        'pt' => 'Português',
        'en' => 'English',
        'es' => 'Español',
        _ => locale.languageCode,
      };
}

final localeNotifierProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref.read(appMetaRepositoryProvider));
});
