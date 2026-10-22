import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cineus/core/theme/app_colors.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/domain/entities/clue.dart';
import 'package:cineus/domain/entities/extra_hint.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/domain/entities/movie.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/providers/play_notifier.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/screens/about_screen.dart';
import 'package:cineus/presentation/screens/challenge_entry_screen.dart';
import 'package:cineus/presentation/screens/settings_screen.dart';
import 'package:cineus/presentation/visuals/cineus_assets.dart';
import 'package:cineus/presentation/widgets/cineus_icon.dart';
import 'package:cineus/presentation/widgets/clue_card_widget.dart';
import 'package:cineus/presentation/widgets/extra_hints_bar.dart';
import 'package:cineus/presentation/widgets/tap_target.dart';
import 'support/test_database.dart';
import 'accessibility_test.dart' show contrast;

Widget localized(Widget child, {double scale = 1}) => MaterialApp(
  theme: AppTheme.dark,
  locale: const Locale('pt'),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Future<ProviderContainer> fixtures(WidgetTester tester) async {
  final container = await tester.runAsync(() async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await const DatabaseSeeder().ensureCanonicalSchema(db);
    final result = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(TestDatabaseProvider(db))],
    );
    // Await initial ticket persistence before pumping any widget.
    await result.read(ticketNotifierProvider.notifier).consumeTicket();
    addTearDown(() async {
      result.dispose();
      await db.close();
    });
    return result;
  });
  return container!;
}

const sampleMovie = Movie(
  id: 1,
  title: 'Filme',
  year: 2014,
  director: 'Um nome de diretor bastante longo para verificar quebra de linha',
  runtime: 169,
  genres: ['Drama'],
);

PlayState hintState({List<String> purchased = const []}) => PlayState(
  mode: GameMode.clue,
  isLoading: false,
  movie: sampleMovie,
  session: GameSession.stage(
    mode: GameMode.clue,
    stageId: 1,
    movieId: 1,
  ).copyWith(id: 1, extraHints: purchased),
);

void main() {
  testWidgets('loose Wrap keeps targets compact and independently tappable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var selected = -1;
      await tester.pumpWidget(
        localized(
          Wrap(
            spacing: 8,
            children: List.generate(
              3,
              (index) => TapTarget(
                label: 'Action $index',
                onTap: () => selected = index,
                child: const SizedBox(width: 70, height: 28),
              ),
            ),
          ),
        ),
      );
      final targets = find.byType(TapTarget);
      for (var i = 0; i < 3; i++) {
        final size = tester.getSize(targets.at(i));
        expect(size.width, 70);
        expect(size.height, 48);
        expect(
          tester.getTopLeft(targets.at(i)).dy,
          tester.getTopLeft(targets.first).dy,
        );
        await tester.tap(targets.at(i));
        expect(selected, i);
        expect(
          tester
              .getSemantics(targets.at(i))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('tight targets still fill their assigned area', (tester) async {
    await tester.pumpWidget(
      localized(
        SizedBox(
          width: 100,
          height: 64,
          child: TapTarget(
            label: 'Action',
            onTap: () {},
            child: const Icon(Icons.check),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(TapTarget)), const Size(100, 64));
  });

  testWidgets('help has one accessible entry without inline purchase clutter', (
    tester,
  ) async {
    final container = await fixtures(tester);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: localized(ExtraHintsBar(state: hintState())),
        ),
      );
      final entry = find.byKey(const ValueKey('round-help-entry'));
      expect(entry, findsOneWidget);
      expect(tester.getSize(entry).height, greaterThanOrEqualTo(48));
      expect(
        tester
            .getSemantics(entry)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(find.text('Diretor'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('purchased long hint wraps at 320px and 200% without clipping', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = await fixtures(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localized(
          Padding(
            padding: const EdgeInsets.all(16),
            child: ExtraHintsBar(state: hintState(purchased: ['director'])),
          ),
          scale: 2,
        ),
      ),
    );
    expect(find.textContaining(sampleMovie.director), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final state in ClueCardState.values) {
    testWidgets('long category at 320px and 200% in $state', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const category = 'Uma categoria de cinema com um nome muito longo';
      await tester.pumpWidget(
        localized(
          ClueCard(
            clue: const Clue(
              id: 1,
              movieId: 1,
              clueNumber: 1,
              category: category,
              text: 'Texto da dica.',
            ),
            clueNumber: 1,
            category: category,
            cardState: state,
            isLatest: true,
          ),
          scale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final screen in ['settings', 'about', 'challenge']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '$screen at 320px / ${scale}x has no layout or ink assertions',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final container = await fixtures(tester);
          final router = GoRouter(
            initialLocation: '/$screen',
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
              ),
              GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
              GoRoute(
                path: '/challenge',
                builder: (_, __) => const ChallengeEntryScreen(),
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                theme: AppTheme.dark,
                locale: const Locale('pt'),
                localizationsDelegates: AppL10n.localizationsDelegates,
                supportedLocales: AppL10n.supportedLocales,
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
              ),
            ),
          );
          await tester.runAsync(
            () async => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          if (screen == 'challenge') {
            final button = find.widgetWithText(ElevatedButton, 'Abrir');
            await tester.ensureVisible(button);
            await tester.pump();
            final labelRect = tester.getRect(find.text('Abrir'));
            final buttonRect = tester.getRect(button);
            expect(buttonRect.contains(labelRect.topLeft), isTrue);
            expect(buttonRect.contains(labelRect.bottomRight), isTrue);
            expect(buttonRect.height, greaterThanOrEqualTo(52));
          }
          if (screen == 'settings') {
            final note = find.text(
              'As dicas e os títulos dos filmes vêm do catálogo em português.',
            );
            expect(
              contrast(
                tester.widget<Text>(note).style!.color!,
                AppColors.obsidian700,
              ),
              greaterThanOrEqualTo(4.5),
            );
          }
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets('vector art exposes only explicit semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        localized(
          const Row(
            children: [
              CineusIcon(CineusAssetId.hintYear),
              CineusIcon(CineusAssetId.ticket, semanticLabel: 'Ticket'),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Ticket'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  test('hint category color passes contrast for small informative text', () {
    expect(
      contrast(AppColors.textSecondary, AppColors.obsidian700),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppColors.textTertiary, AppColors.obsidian700),
      greaterThanOrEqualTo(4.5),
    );
    expect(ExtraHint.values.map(CineusAssets.forHint).toSet().length, 3);
  });
}
