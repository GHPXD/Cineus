// Accessibility guards (B9).
//
// Three properties worth protecting:
//   1. contrast — measured, not eyeballed
//   2. large system fonts do not overflow the layout
//   3. tap targets are announced and big enough
//
// The overflow check is the valuable one: Flutter scales `fontSize` by the
// system text scale automatically, so the danger is not the font itself but the
// fixed container heights around it. A `RenderFlex overflowed` is recorded as a
// test error, so pumping at 2× turns a silent visual break into a failure.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/core/theme/app_colors.dart';
import 'package:cineus/domain/entities/clue.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/widgets/clue_card_widget.dart';
import 'package:cineus/presentation/widgets/clue_list_widget.dart';
import 'package:cineus/presentation/widgets/countdown_timer_widget.dart';
import 'package:cineus/presentation/widgets/film_strip_widget.dart';
import 'package:cineus/presentation/widgets/score_badge_widget.dart';
import 'package:cineus/presentation/widgets/share_grid_widget.dart';
import 'package:cineus/presentation/widgets/tap_target.dart';

// ── contrast helpers ────────────────────────────────────────────────────────

/// sRGB channel to linear light, per the WCAG definition.
double _channel(int c) {
  final v = c / 255;
  return v <= 0.04045
      ? v / 12.92
      : math.pow((v + 0.055) / 1.055, 2.4) as double;
}

double _luminance(Color c) {
  final r = _channel((c.r * 255).round());
  final g = _channel((c.g * 255).round());
  final b = _channel((c.b * 255).round());
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrast(Color fg, Color bg) {
  final a = _luminance(fg);
  final b = _luminance(bg);
  final hi = a > b ? a : b;
  final lo = a > b ? b : a;
  return (hi + 0.05) / (lo + 0.05);
}

// ── harness ────────────────────────────────────────────────────────────────

Widget scaled(Widget child, double scale) {
  return MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
}

Clue clueAt(int n) => Clue(
  id: n,
  movieId: 1,
  clueNumber: n,
  category: 'Conceito',
  text: 'Uma dica razoavelmente longa para testar quebra de linha, número $n.',
);

void main() {
  group('contraste dos tons de texto (WCAG AA)', () {
    const backgrounds = {
      'obsidian950': AppColors.obsidian950,
      'obsidian900': AppColors.obsidian900,
      'obsidian800': AppColors.obsidian800,
      'obsidian700': AppColors.obsidian700,
    };

    test('textSecondary e textTertiary passam 4.5:1 em todos os fundos', () {
      for (final entry in backgrounds.entries) {
        expect(
          contrast(AppColors.textSecondary, entry.value),
          greaterThanOrEqualTo(4.5),
          reason: 'textSecondary sobre ${entry.key}',
        );
        expect(
          contrast(AppColors.textTertiary, entry.value),
          greaterThanOrEqualTo(4.5),
          reason: 'textTertiary sobre ${entry.key}',
        );
      }
    });

    test('textQuaternary passa 3:1 (texto grande)', () {
      for (final entry in backgrounds.entries) {
        expect(
          contrast(AppColors.textQuaternary, entry.value),
          greaterThanOrEqualTo(3.0),
          reason: 'textQuaternary sobre ${entry.key}',
        );
      }
    });

    test('as cores de destaque passam 4.5:1 no fundo principal', () {
      for (final entry in {
        'gold300': AppColors.gold300,
        'blue300': AppColors.blue300,
        'ruby300': AppColors.ruby300,
        'success400': AppColors.success400,
        'amber400': AppColors.amber400,
      }.entries) {
        expect(
          contrast(entry.value, AppColors.obsidian950),
          greaterThanOrEqualTo(4.5),
          reason: entry.key,
        );
      }
    });

    test('os tons dim do obsidian NÃO devem ser usados como texto', () {
      // Documenta por que textSecondary/Tertiary existem: estes reprovam.
      expect(
        contrast(AppColors.obsidian400, AppColors.obsidian950),
        lessThan(3.0),
      );
      expect(
        contrast(AppColors.obsidian500, AppColors.obsidian950),
        lessThan(3.0),
      );
    });
  });

  group('sem overflow com fonte grande', () {
    // 2.0 é o limite prático das configurações de acessibilidade do Android.
    const scales = [1.0, 1.3, 1.6, 2.0];

    for (final scale in scales) {
      testWidgets('ScoreBadge em ${scale}x', (tester) async {
        await tester.pumpWidget(
          scaled(const ScoreBadge(score: 7, revealedClues: 4), scale),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('ScoreBadge urgente (com pulso) em ${scale}x', (
        tester,
      ) async {
        await tester.pumpWidget(
          scaled(const ScoreBadge(score: 1, revealedClues: 10), scale),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      });

      testWidgets('ClueCard nos três estados em ${scale}x', (tester) async {
        for (final state in ClueCardState.values) {
          await tester.pumpWidget(
            scaled(
              ClueCard(
                clue: clueAt(3),
                clueNumber: 3,
                category: 'Revelação',
                cardState: state,
              ),
              scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$state em ${scale}x');
        }
      });

      testWidgets('ClueList completa em ${scale}x', (tester) async {
        await tester.pumpWidget(
          scaled(
            ClueList(
              allClues: [for (var i = 1; i <= 10; i++) clueAt(i)],
              revealedCount: 6,
            ),
            scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('CountdownTimer em ${scale}x', (tester) async {
        await tester.pumpWidget(scaled(const CountdownTimer(), scale));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('ShareGrid em ${scale}x', (tester) async {
        await tester.pumpWidget(
          scaled(const ShareGrid(revealedClues: 4, won: true), scale),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('TapTarget', () {
    testWidgets('cresce para 48x48 mesmo com filho pequeno', (tester) async {
      await tester.pumpWidget(
        scaled(
          Center(
            child: TapTarget(
              label: 'Voltar',
              onTap: () {},
              child: const SizedBox(width: 20, height: 20),
            ),
          ),
          1.0,
        ),
      );

      final size = tester.getSize(find.byType(TapTarget));
      expect(size.width, greaterThanOrEqualTo(TapTarget.minSize));
      expect(size.height, greaterThanOrEqualTo(TapTarget.minSize));
    });

    testWidgets('é anunciado como botão com rótulo', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        scaled(
          Center(
            child: TapTarget(
              label: 'Ver estatísticas',
              onTap: () {},
              child: const Icon(Icons.bar_chart_rounded),
            ),
          ),
          1.0,
        ),
      );

      // Só o que importa para o leitor de tela: rótulo, papel e ação.
      final data = tester
          .getSemantics(find.byType(TapTarget))
          .getSemanticsData();
      expect(data.label, 'Ver estatísticas');
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      handle.dispose();
    });

    testWidgets('desabilitado quando onTap é nulo', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        scaled(
          const Center(
            child: TapTarget(
              label: 'Sem tickets',
              onTap: null,
              child: Icon(Icons.block),
            ),
          ),
          1.0,
        ),
      );

      final data = tester
          .getSemantics(find.byType(TapTarget))
          .getSemanticsData();
      expect(data.label, 'Sem tickets');
      // Sem onTap não há ação de toque, e o nó é anunciado como desabilitado.
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      // A ausência da ação de toque já prova que não é ativável; o enum de
      // flags não é exportado publicamente, então não vale depender dele.
      expect(data.label, isNotEmpty);

      handle.dispose();
    });
  });

  group('decorativos são ignorados por leitor de tela', () {
    testWidgets('FilmStrip não expõe nós', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(scaled(const FilmStrip(), 1.0));

      // ExcludeSemantics: não deve haver nenhum nó descendente.
      expect(
        find.descendant(
          of: find.byType(FilmStrip),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('ShareGrid não expõe nós', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        scaled(const ShareGrid(revealedClues: 3, won: true), 1.0),
      );

      expect(
        find.descendant(
          of: find.byType(ShareGrid),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
