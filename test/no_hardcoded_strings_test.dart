// Keeps Portuguese copy out of the widget tree.
//
// Without this, the next feature quietly reintroduces a hardcoded string and
// only a Spanish-speaking player finds out. The check is a heuristic, so it has
// an explicit allow-list: things that are the same in every language (the brand,
// emoji, format separators) or that are not UI copy at all.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Accented characters or common Portuguese words that betray untranslated copy.
final _portuguese = RegExp(
  r'[áàâãéêíóôõúçÁÀÂÃÉÊÍÓÔÕÚÇ]'
  r'|\b(de|do|da|dos|das|em|para|com|não|você|seu|sua|dia|dias|filme|filmes'
  r'|ponto|pontos|dica|dicas|jogar|voltar|sem|mais|ver|acertou|sequência)\b',
  caseSensitive: false,
);

/// Single-quoted Dart string literals, ignoring escapes.
final _literal = RegExp(r"'((?:[^'\\\n]|\\.)*)'");

/// Values that are legitimately the same in every language, or are not copy.
const _allowed = {
  'Cineus',
  'Cine',
  'us',
  'Playfair Display',
  'Inter',
  'DM Mono',
  ' · ',
  '· ',
  ' · Posters',
};

/// Files that hold data or matching logic rather than UI copy.
const _skipFiles = {
  // Genre keywords matched against the catalogue, which is Portuguese data.
  'poster_card_widget.dart',
  // Clue categories: keys of the emoji map, mirroring database values.
  'app_constants.dart',
  // Accent-folding tables.
  'string_normalizer.dart',
  // Language endonyms, deliberately not translated.
  'locale_notifier.dart',
};

void main() {
  test('nenhuma string em português fora do ARB nas telas e widgets', () {
    final offenders = <String>[];

    final dirs = [
      Directory('lib/presentation/screens'),
      Directory('lib/presentation/widgets'),
    ];

    for (final dir in dirs) {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final name = entity.uri.pathSegments.last;
        if (_skipFiles.contains(name)) continue;

        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Skip imports, comments and asset paths.
          final trimmed = line.trimLeft();
          if (trimmed.startsWith('import ') ||
              trimmed.startsWith('//') ||
              trimmed.startsWith('///') ||
              trimmed.startsWith('*')) {
            continue;
          }

          for (final match in _literal.allMatches(line)) {
            final value = match.group(1)!;
            if (value.length < 3) continue;
            if (_allowed.contains(value)) continue;
            if (value.startsWith('assets/')) continue;
            // Identifiers and route paths.
            if (RegExp(r'^[a-z_/]+$').hasMatch(value)) continue;
            if (!_portuguese.hasMatch(value)) continue;

            offenders.add('$name:${i + 1}  $value');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Use AppL10n para estas:\n${offenders.join('\n')}',
    );
  });

  test('as entidades de domínio não carregam texto visível', () {
    // Achievement, TicketReward and ExtraHint used to hold Portuguese labels,
    // which made them impossible to localise. They carry ids and enums now.
    for (final path in [
      'lib/domain/entities/achievement.dart',
      'lib/domain/entities/ticket_reward.dart',
      'lib/domain/entities/extra_hint.dart',
    ]) {
      final source = File(path).readAsStringSync();
      final code = source
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');

      for (final match in _literal.allMatches(code)) {
        final value = match.group(1)!;
        if (value.length < 3) continue;
        expect(
          _portuguese.hasMatch(value),
          isFalse,
          reason: '$path ainda tem copy: "$value"',
        );
      }
    }
  });
}
