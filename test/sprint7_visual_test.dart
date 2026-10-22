import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/core/theme/app_fonts.dart';
import 'package:cineus/domain/entities/clue.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/visuals/category_assets.dart';
import 'package:cineus/presentation/visuals/cineus_assets.dart';
import 'package:cineus/presentation/widgets/cineus_icon.dart';
import 'package:cineus/presentation/widgets/cineus_state_art.dart';
import 'package:cineus/presentation/widgets/clue_card_widget.dart';
import 'package:cineus/presentation/widgets/cineus_poster.dart';
import 'sprint5_progression_test.dart' show progressionFixture;

final emoji = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u2600-\u27BF\uFE0F]',
  unicode: true,
);

Future<void> pump7(
  WidgetTester tester,
  Widget child, {
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('pt'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test(
    'every frozen category and every catalog clue has an explicit destination',
    () {
      final baseline = File('docs/artwork/categories.csv')
          .readAsLinesSync()
          .skip(1)
          .where((r) => r.isNotEmpty)
          .map((r) => r.split(',').first.replaceAll('\uFEFF', ''))
          .toSet();
      expect(baseline.length, 170);
      expect(categoryAssetRegistry.keys.toSet(), baseline);
      final seed =
          jsonDecode(File('assets/cineus_v1_seed.json').readAsStringSync())
              as Map<String, dynamic>;
      for (final clue in seed['clues'] as List) {
        expect(
          categoryAssetRegistry.containsKey(clue['category']),
          isTrue,
          reason: 'Unresolved catalog category: ${clue['category']}',
        );
      }
      expect(
        CineusAssets.forCategory('  TECNOLOGIA '),
        CineusAssetId.categoryTechnology,
      );
      expect(
        CineusAssets.forCategory('unknown future category'),
        CineusAssetId.categoryFallback,
      );
      expect(CineusAssets.forCategory('Drama'), CineusAssetId.categoryEmotion);
    },
  );

  test(
    'presentation uses own icons and retains emojis only in sharing copy',
    () {
      for (final file
          in Directory('lib/presentation')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final source = file
            .readAsLinesSync()
            .where((l) => !l.trimLeft().startsWith('//'))
            .join('\n');
        expect(
          RegExp(r'\b(?:Icons|CupertinoIcons)\.').hasMatch(source),
          isFalse,
          reason: file.path,
        );
        // The grid's serializer produces the plain-text share payload. Its
        // build method paints widgets and contains no emoji glyphs.
        final renderedSource = file.path.endsWith('share_grid_widget.dart')
            ? source.split('String toEmojiGrid()').first
            : source;
        expect(emoji.hasMatch(renderedSource), isFalse, reason: file.path);
        expect(
          source.contains('emojiForCategory('),
          isFalse,
          reason: file.path,
        );
      }
      for (final file in Directory(
        'lib/l10n',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.arb'))) {
        final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        for (final entry in arb.entries) {
          if (entry.key.startsWith('share') ||
              entry.key == 'challengeShareText' ||
              entry.value is! String) {
            continue;
          }
          expect(
            emoji.hasMatch(entry.value as String),
            isFalse,
            reason: '${file.path}: ${entry.key}',
          );
        }
        expect(emoji.hasMatch(arb['shareWin'] as String), isTrue);
      }
    },
  );

  testWidgets(
    'the entire family paints at small and large sizes with muted/highlight states',
    (tester) async {
      for (final size in [17.0, 24.0, 64.0]) {
        await pump7(
          tester,
          Wrap(
            children: [
              for (final id in CineusAssetId.values)
                CineusIcon(
                  id,
                  size: size,
                  state: id.index.isEven
                      ? CineusIconState.muted
                      : CineusIconState.highlighted,
                ),
            ],
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          find.byType(CineusIcon),
          findsNWidgets(CineusAssetId.values.length),
        );
      }
    },
  );

  for (final category in [
    'Transformação',
    'Tagline Oficial',
    'Trilha Sonora',
    'unknown future category',
  ]) {
    testWidgets('latest clue $category keeps icon, text and badge at 200%', (
      tester,
    ) async {
      final asset = CineusAssets.forCategory(category);
      await pump7(
        tester,
        ClueCard(
          clue: Clue(
            id: 1,
            movieId: 1,
            clueNumber: 10,
            category: category,
            text: 'Uma pista preservada.',
          ),
          clueNumber: 10,
          category: category,
          cardState: ClueCardState.revealed,
          isLatest: true,
        ),
        scale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(
        find.byWidgetPredicate((w) => w is CineusIcon && w.asset == asset),
        findsOneWidget,
      );
      expect(find.text(category.toUpperCase()), findsOneWidget);
      expect(find.text('Uma pista preservada.'), findsOneWidget);
      expect(find.text('NOVO'), findsOneWidget);
    });
  }

  testWidgets('missing poster is neutral at large and compact sizes', (
    tester,
  ) async {
    await pump7(
      tester,
      const SizedBox(
        width: 220,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: CineusPoster(movieId: 999999),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(PosterPlaceholder), findsOneWidget);
    await pump7(
      tester,
      const SizedBox(width: 30, height: 45, child: PosterPlaceholder()),
      scale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty/error/recovery artwork fits compact layout', (
    tester,
  ) async {
    await pump7(
      tester,
      Column(
        children: [
          for (final kind in CineusStateKind.values) CineusStateArt(kind),
          const CineusStateArt(
            CineusStateKind.empty,
            symbol: CineusAssetId.search,
          ),
        ],
      ),
      scale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(CineusStateArt), findsNWidgets(4));
  });
  testWidgets(
    'Statistics title stays on one line at 200% using the actual font',
    (tester) async {
      await tester.runAsync(() async {
        await (FontLoader(
          AppFonts.display,
        )..addFont(rootBundle.load('assets/fonts/Fredoka-700.ttf'))).load();
      });
      await progressionFixture(
        tester,
        (c, db, router, ids) async {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text('Estatísticas'),
          );
          final boxes = paragraph.getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 12),
          );
          expect(boxes.map((b) => b.top).toSet().length, 1);
          expect(find.byType(Icon), findsNothing);
        },
        initial: '/stats',
        width: 320,
        scale: 2,
      );
    },
  );
}
