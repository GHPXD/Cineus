import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/app_meta_repository.dart';
import '../../l10n/app_l10n.dart';
import 'providers.dart';

/// The language the app renders in (D9).
///
/// `null` means "follow the device", which is the default and what most players
/// will want. An explicit choice is persisted in `app_meta` so it survives
/// restarts.
///
/// Scope note: this localises the interface only. Clues, clue categories and
/// film titles come from the bundled catalogue, which is Portuguese (plus the
/// original — usually English — title). Translating 500 films and 5.000 clues is
/// content work, not a code change.
class LocaleNotifier extends StateNotifier<Locale?> {
  final AppMetaRepository _meta;

  static const _key = 'locale';

  LocaleNotifier(this._meta) : super(null) {
    _load();
  }

  Future<void> _load() async {
    final stored = await _meta.read(_key);
    if (stored == null || stored.isEmpty) return;
    final locale = Locale(stored);
    if (isSupported(locale)) state = locale;
  }

  /// Sets the language, or clears the override when [locale] is null.
  Future<void> select(Locale? locale) async {
    if (locale != null && !isSupported(locale)) return;
    state = locale;
    await _meta.write(_key, locale?.languageCode ?? '');
  }

  static bool isSupported(Locale locale) => AppL10n.supportedLocales
      .any((l) => l.languageCode == locale.languageCode);

  /// Languages offered in the picker, in display order.
  static const options = <Locale?>[
    null, // system
    Locale('pt'),
    Locale('en'),
    Locale('es'),
  ];

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
