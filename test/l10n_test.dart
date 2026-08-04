// Guards the localisation setup itself (D9).
//
// The failure mode is silent: a key added to the Portuguese template but not to
// the other locales still compiles — gen_l10n falls back to the template — so a
// player on English or Spanish sees stray Portuguese. These tests compare the ARB
// files directly.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/l10n/app_l10n.dart';

/// Reads an ARB at load time, so the key sets are available to `group` bodies.
///
/// Throws rather than using `expect`, which is only legal inside a test.
Map<String, dynamic> loadArb(String locale) {
  final file = File('lib/l10n/app_$locale.arb');
  if (!file.existsSync()) {
    throw StateError('faltando ${file.path}');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// Message keys only — `@@locale` and the `@key` metadata entries are not copy.
Set<String> messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  const locales = ['pt', 'en', 'es'];
  final arbs = {for (final l in locales) l: loadArb(l)};

  test('as três línguas estão registradas no app', () {
    expect(
      AppL10n.supportedLocales.map((l) => l.languageCode).toSet(),
      locales.toSet(),
    );
  });

  test('cada ARB declara seu próprio @@locale', () {
    for (final l in locales) {
      expect(arbs[l]!['@@locale'], l);
    }
  });

  group('paridade de chaves com o template português', () {
    final template = messageKeys(arbs['pt']!);

    test('o template tem conteúdo', () {
      expect(template.length, greaterThan(100));
    });

    for (final locale in ['en', 'es']) {
      test('$locale não tem chave faltando', () {
        final missing = template.difference(messageKeys(arbs[locale]!));
        expect(missing, isEmpty,
            reason: 'faltam em $locale: ${missing.toList()..sort()}');
      });

      test('$locale não tem chave sobrando', () {
        final extra = messageKeys(arbs[locale]!).difference(template);
        expect(extra, isEmpty,
            reason: 'sobrando em $locale: ${extra.toList()..sort()}');
      });
    }
  });

  group('nenhuma tradução ficou vazia ou igual por esquecimento', () {
    for (final locale in ['en', 'es']) {
      test('$locale sem valores vazios', () {
        final empty = <String>[];
        for (final key in messageKeys(arbs[locale]!)) {
          final value = arbs[locale]![key];
          if (value is String && value.trim().isEmpty) empty.add(key);
        }
        expect(empty, isEmpty);
      });
    }

    test('en difere do pt na maior parte das mensagens', () {
      // Algumas são legitimamente idênticas (emoji, "Cineus", "1 🎫", "min"),
      // mas se a maioria coincidir é sinal de tradução não feita.
      final pt = arbs['pt']!;
      final en = arbs['en']!;
      final keys = messageKeys(pt);
      final identical = keys.where((k) => pt[k] == en[k]).length;
      expect(identical / keys.length, lessThan(0.25),
          reason: '$identical de ${keys.length} mensagens idênticas ao pt');
    });
  });

  group('placeholders combinam entre as línguas', () {
    final placeholder = RegExp(r'\{(\w+)');

    Set<String> placeholdersOf(String value) =>
        placeholder.allMatches(value).map((m) => m.group(1)!).toSet();

    for (final locale in ['en', 'es']) {
      test('$locale usa os mesmos placeholders que o pt', () {
        final problems = <String>[];
        for (final key in messageKeys(arbs['pt']!)) {
          final ptValue = arbs['pt']![key];
          final other = arbs[locale]![key];
          if (ptValue is! String || other is! String) continue;

          final expected = placeholdersOf(ptValue);
          final actual = placeholdersOf(other);
          if (expected.difference(actual).isNotEmpty ||
              actual.difference(expected).isNotEmpty) {
            problems.add('$key: pt=$expected $locale=$actual');
          }
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  });

  group('as mensagens resolvem em runtime', () {
    for (final locale in ['pt', 'en', 'es']) {
      testWidgets('$locale carrega e devolve texto', (tester) async {
        late AppL10n l10n;
        await tester.pumpWidget(
          Localizations(
            locale: Locale(locale),
            delegates: AppL10n.localizationsDelegates.toList(),
            child: Builder(
              builder: (context) {
                l10n = AppL10n.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(l10n.appTitle, 'Cineus');
        expect(l10n.appTagline, isNotEmpty);
        // Interpolação e plural funcionam
        expect(l10n.stageNumber('3'), contains('3'));
        expect(l10n.ticketsEarned(1), contains('1'));
        expect(l10n.ticketsEarned(5), contains('5'));
        expect(l10n.errorCount(1), isNot(l10n.errorCount(2)));
      });
    }
  });
}
