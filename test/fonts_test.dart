// Guards the bundled-font setup.
//
// The failure mode being prevented is silent: if a family name stops matching
// the pubspec declaration, or an asset goes missing, Flutter falls back to the
// platform font with no error — which is exactly how the release build lost its
// entire type design while debug looked fine.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/core/theme/app_fonts.dart';
import 'package:cineus/core/theme/app_typography.dart';

/// Every family + asset declared under `flutter: fonts:` in pubspec.yaml.
Map<String, List<String>> _declaredFonts() {
  final lines = File('pubspec.yaml').readAsLinesSync();
  final result = <String, List<String>>{};
  String? family;
  var inFonts = false;

  for (final line in lines) {
    if (line.startsWith('  fonts:')) {
      inFonts = true;
      continue;
    }
    if (!inFonts) continue;
    final familyMatch = RegExp(r'^\s{4}- family:\s*(.+)$').firstMatch(line);
    if (familyMatch != null) {
      family = familyMatch.group(1)!.trim();
      result[family] = [];
      continue;
    }
    final assetMatch = RegExp(r'^\s+- asset:\s*(.+)$').firstMatch(line);
    if (assetMatch != null && family != null) {
      result[family]!.add(assetMatch.group(1)!.trim());
    }
  }
  return result;
}

void main() {
  final declared = _declaredFonts();

  test('pubspec declara exatamente as três famílias do design system', () {
    expect(
      declared.keys.toSet(),
      {AppFonts.playfair, AppFonts.inter, AppFonts.mono},
    );
  });

  test('todo asset declarado existe e é um TTF válido', () {
    expect(declared, isNotEmpty);
    for (final entry in declared.entries) {
      expect(entry.value, isNotEmpty, reason: '${entry.key} sem assets');
      for (final asset in entry.value) {
        final file = File(asset);
        expect(file.existsSync(), isTrue, reason: 'faltando: $asset');

        final header = file.openSync().readSync(4);
        // sfnt version 1.0 — TTF. Flutter não carrega woff/woff2/eot.
        expect(
          header,
          orderedEquals([0x00, 0x01, 0x00, 0x00]),
          reason: '$asset não é TTF',
        );
        expect(file.lengthSync(), greaterThan(5000), reason: '$asset truncado');
      }
    }
  });

  test('nenhum arquivo órfão em assets/fonts', () {
    final onDisk = Directory('assets/fonts')
        .listSync()
        .whereType<File>()
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toSet();
    final referenced = declared.values.expand((e) => e).toSet();
    expect(onDisk, equals(referenced));
  });

  group('AppTypography usa as famílias bundladas, nunca a fonte do sistema',
      () {
    final expectations = <String, List<TextStyle>>{
      AppFonts.playfair: [
        AppTypography.displayLarge,
        AppTypography.displayMedium,
        AppTypography.displaySmall,
        AppTypography.headlineLarge,
        AppTypography.headlineMedium,
      ],
      AppFonts.inter: [
        AppTypography.titleLarge,
        AppTypography.titleMedium,
        AppTypography.titleSmall,
        AppTypography.bodyLarge,
        AppTypography.bodyMedium,
        AppTypography.bodySmall,
        AppTypography.labelLarge,
        AppTypography.labelSmall,
        AppTypography.overline,
      ],
      AppFonts.mono: [
        AppTypography.scoreLarge,
        AppTypography.scoreMedium,
        AppTypography.scoreSmall,
        AppTypography.mono,
        AppTypography.monoSmall,
      ],
    };

    for (final entry in expectations.entries) {
      test('${entry.key}: ${entry.value.length} estilos', () {
        for (final style in entry.value) {
          expect(style.fontFamily, entry.key);
        }
      });
    }
  });

  test('todo peso usado pelos estilos está declarado no pubspec', () {
    // Extrai os pesos declarados por família a partir dos nomes de arquivo.
    final weightsByFamily = <String, Set<int>>{};
    for (final entry in declared.entries) {
      weightsByFamily[entry.key] = entry.value
          .map((a) => RegExp(r'-(\d{3})').firstMatch(a)?.group(1))
          .whereType<String>()
          .map(int.parse)
          .toSet();
    }

    final styles = <String, List<TextStyle>>{
      AppFonts.playfair: [
        AppTypography.displayLarge,
        AppTypography.displayMedium,
        AppTypography.headlineMedium,
      ],
      AppFonts.inter: [
        AppTypography.bodyMedium,
        AppTypography.labelLarge,
        AppTypography.titleLarge,
      ],
    };

    for (final entry in styles.entries) {
      for (final style in entry.value) {
        final weight = int.parse(style.fontWeight!.toString().split('.w').last);
        expect(
          weightsByFamily[entry.key],
          contains(weight),
          reason: '${entry.key} w$weight não declarado',
        );
      }
    }
  });
}
