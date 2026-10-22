import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/core/utils/challenge_code.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/providers/play_notifier.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/providers/result_share_service.dart';
import 'package:cineus/presentation/providers/player_collection_provider.dart';
import 'package:cineus/presentation/screens/generic_result_screen.dart';
import 'package:cineus/presentation/screens/challenge_loader.dart';
import 'package:cineus/presentation/screens/challenge_entry_screen.dart';
import 'package:cineus/presentation/widgets/result_share_card.dart';
import 'package:cineus/presentation/widgets/share_grid_widget.dart';
import 'package:cineus/presentation/widgets/cineus_poster.dart';
import 'support/test_database.dart';
import 'sprint3_ui_test.dart' show settleData;

class FakeShare implements ResultShareService {
  int shares = 0, copies = 0;
  ShareResultStatus status = ShareResultStatus.dismissed;
  bool throwsShare = false, throwsCopy = false;
  Completer<void>? gate;
  String? text;
  Uint8List? png;
  Rect? origin;
  @override
  Future<ShareResultStatus> share(
    String text,
    Rect origin, {
    Uint8List? png,
  }) async {
    shares++;
    this.text = text;
    this.png = png;
    this.origin = origin;
    if (gate != null) await gate!.future;
    if (throwsShare) throw StateError('Unavailable platform');
    return status;
  }

  @override
  Future<void> copy(String text) async {
    copies++;
    this.text = text;
    if (throwsCopy) throw StateError('Clipboard unavailable');
  }
}

Future<void> fixture(
  WidgetTester tester,
  Future<void> Function(ProviderContainer, Database, FakeShare, GoRouter)
  action, {
  GameMode mode = GameMode.clue,
  GameStatus status = GameStatus.won,
  SessionKind kind = SessionKind.stage,
  double scale = 1,
  double width = 390,
  bool missing = false,
}) async {
  late Database db;
  late ProviderContainer c;
  final fake = FakeShare();
  await tester.runAsync(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    const seed = DatabaseSeeder();
    await seed.ensureCanonicalSchema(db);
    await seed.seedFromJsonAsset(db);
    await seed.syncStages(db);
    c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(TestDatabaseProvider(db)),
        resultShareServiceProvider.overrideWithValue(fake),
      ],
    );
    await c.read(ticketNotifierProvider.notifier).ready;
    await c.read(playerCollectionProvider.notifier).ready;
    if (!missing) {
      final n = c.read(
        (mode == GameMode.clue ? clueGameProvider : posterGameProvider)
            .notifier,
      );
      if (kind == SessionKind.daily) {
        await n.loadDaily();
      } else if (kind == SessionKind.challenge) {
        await n.loadChallenge(1);
      } else {
        await n.loadStageFilm(1, 1, [1, 2, 3]);
      }
      if (status == GameStatus.won) {
        await n.submitGuess(
          c
              .read(
                mode == GameMode.clue ? clueGameProvider : posterGameProvider,
              )
              .movie!
              .title,
        );
      }
      if (status == GameStatus.lost) {
        while (c
            .read(mode == GameMode.clue ? clueGameProvider : posterGameProvider)
            .canRevealMore) {
          await n.revealNext();
        }
        await n.submitGuess('O Rei Leão');
      }
    }
    for (final entry in {
      'Nunito': 'Nunito-400.ttf',
      'Fredoka': 'Fredoka-700.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load('assets/fonts/${entry.value}'))).load();
    }
  });
  final router = GoRouter(
    initialLocation: '/result',
    routes: [
      GoRoute(
        path: '/result',
        builder: (_, __) => GenericResultScreen(
          mode: mode,
          config: ResultConfig.victory,
          onNavigateToStats: () {},
          onNavigateHome: () {},
        ),
      ),
      GoRoute(path: '/entry', builder: (_, __) => const ChallengeEntryScreen()),
      GoRoute(
        path: '/challenge/:code',
        builder: (_, state) {
          final value = state.pathParameters['code']!;
          final target = ChallengeCode.decodeTarget(value);
          return ChallengeLoader(
            key: ValueKey(value),
            movieId: target?.movieId,
            mode: target?.mode ?? GameMode.clue,
          );
        },
      ),
      for (final path in [
        '/home',
        '/game',
        '/visual/play',
        '/visual/victory',
        '/victory',
        '/visual/defeat',
        '/defeat',
        '/stages/1',
        '/visual/stage/1',
        '/challenge-entry',
      ])
        GoRoute(
          path: path,
          builder: (_, __) => Scaffold(body: Text('ROUTE $path')),
        ),
    ],
  );
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  try {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          theme: AppTheme.dark,
          locale: const Locale('pt'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
      ),
    );
    await settleChanges(tester);
    await action(c, db, fake, router);
    expect(tester.takeException(), isNull);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      router.dispose();
      c.dispose();
      await db.close();
    });
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

Future<void> settleChanges(WidgetTester tester) async {
  for (var n = 0; n < 3; n++) {
    await settleData(tester);
  }
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('two preview taps open one card without duplicate GlobalKey', (
    tester,
  ) async {
    await fixture(tester, (c, db, f, r) async {
      final button = find.byKey(const ValueKey('preview-result-card'));
      if (button.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          button,
          300,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.ensureVisible(button);
      await tester.pump();
      expect(button.hitTestable(), findsOneWidget);
      final position = tester.getCenter(button);
      await tester.tapAt(position);
      // The first pointer may insert a modal barrier before the next frame.
      // Repeat the physical tap at the same position, as a user would.
      await tester.tapAt(position);
      await tester.pumpAndSettle();
      expect(find.byType(ResultShareCard), findsOneWidget);
    });
  });
  for (final mode in GameMode.values) {
    for (final status in [GameStatus.won, GameStatus.lost]) {
      testWidgets(
        '$mode $status compact 200%: one answer metadata and correct grid/outcome',
        (tester) async {
          await fixture(
            tester,
            (c, db, f, r) async {
              expect(
                find.byKey(const ValueKey('answer-title')),
                findsOneWidget,
              );
              expect(
                find.text(
                  status == GameStatus.won ? 'Acertou!' : 'Não foi desta vez',
                ),
                findsOneWidget,
              );
              if (status == GameStatus.lost) {
                expect(find.text('0 pontos'), findsOneWidget);
              }
              await tester.scrollUntilVisible(
                find.byType(ShareGrid),
                300,
                scrollable: find.byType(Scrollable).first,
              );
              expect(
                tester.widget<ShareGrid>(find.byType(ShareGrid)).totalSteps,
                mode == GameMode.clue ? 10 : 5,
              );
              await tester.scrollUntilVisible(
                find.byKey(const ValueKey('invite-friend')),
                300,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.pump();
            },
            mode: mode,
            status: status,
            width: 320,
            scale: 2,
          );
        },
      );
    }
  }
  testWidgets(
    'missing/unfinished result offers exit instead of indefinite spinner',
    (tester) async {
      await fixture(tester, (c, db, f, r) async {
        expect(
          find.textContaining('resultado não está disponível'),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
      }, missing: true);
    },
  );
  testWidgets('active session has recoverable return to game', (tester) async {
    await fixture(tester, (c, db, f, r) async {
      await tester.tap(find.text('Voltar ao jogo'));
      await tester.pumpAndSettle();
      expect(find.text('ROUTE /game'), findsOneWidget);
    }, status: GameStatus.playing);
  });
  testWidgets(
    'cancelled share does not copy or report success; duplicate share blocked',
    (tester) async {
      await fixture(tester, (c, db, f, r) async {
        f.gate = Completer<void>();
        await tapVisible(
          tester,
          find.byKey(const ValueKey('preview-result-card')),
        );
        await settleChanges(tester);
        await tapVisible(
          tester,
          find.byKey(const ValueKey('share-result-image')),
        );
        await settleChanges(tester);
        await tester.tap(find.byKey(const ValueKey('share-result-image')));
        await tester.pump();
        expect(f.shares, 1);
        f.gate!.complete();
        await tester.pump();
        expect(f.copies, 0);
        expect(find.text('Resultado compartilhado!'), findsNothing);
        expect(f.origin!.width, greaterThan(0));
        expect(f.origin!.height, greaterThan(0));
      });
    },
  );
  testWidgets(
    'unavailable image share permits retry and never copies result text',
    (tester) async {
      await fixture(tester, (c, db, f, r) async {
        f.status = ShareResultStatus.unavailable;
        await tapVisible(
          tester,
          find.byKey(const ValueKey('preview-result-card')),
        );
        await settleChanges(tester);
        await tapVisible(
          tester,
          find.byKey(const ValueKey('share-result-image')),
        );
        await settleChanges(tester);
        expect(
          find.textContaining('Não foi possível abrir o compartilhamento'),
          findsOneWidget,
        );
        expect(f.copies, 0);
        expect(find.text('Copiar resultado em texto'), findsNothing);
        f.status = ShareResultStatus.success;
        await tapVisible(
          tester,
          find.byKey(const ValueKey('share-result-image')),
        );
        await settleChanges(tester);
        expect(f.shares, 2);
        expect(f.copies, 0);
      });
    },
  );
  testWidgets(
    'poster preview excludes stage and steps, emits real PNG and handles failure in sheet',
    (tester) async {
      await fixture(tester, (c, db, f, r) async {
        await tapVisible(
          tester,
          find.byKey(const ValueKey('preview-result-card')),
        );
        final card = find.byType(ResultShareCard);
        final poster = tester.widget<CineusPoster>(
          find.descendant(of: card, matching: find.byType(CineusPoster)),
        );
        expect(poster.movieId, c.read(clueGameProvider).movie!.id);
        for (final label in [
          'Estágio 1',
          'Acertou!',
          'Passos: 1/10',
          'Copiar resultado em texto',
        ]) {
          expect(
            find.descendant(of: card, matching: find.text(label)),
            findsNothing,
          );
        }

        expect(
          find.descendant(
            of: card,
            matching: find.textContaining('Interestelar'),
          ),
          findsNothing,
        );
        f.throwsShare = true;
        await tapVisible(
          tester,
          find.byKey(const ValueKey('share-result-image')),
        );
        await settleChanges(tester);
        expect(f.png, isNotNull);
        expect(f.png!.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
        expect(
          find
              .textContaining('Não foi possível abrir o compartilhamento')
              .hitTestable(),
          findsOneWidget,
        );
        expect(f.text, isNot(contains('Interestelar')));
      });
    },
  );
  testWidgets(
    'result offers only next, card, invitation and home in that order',
    (tester) async {
      await fixture(tester, (c, db, f, r) async {
        final list = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('invite-friend')),
          300,
          scrollable: list,
        );
        await tester.pump();
        expect(find.byKey(const ValueKey('share-result-text')), findsNothing);
        expect(find.text('Copiar resultado em texto'), findsNothing);
        expect(find.text('Voltar aos Estágios'), findsNothing);
        expect(find.text('Próximo · 1 ticket'), findsNothing);
        expect(find.text('Próximo'), findsOneWidget);
        expect(
          tester.getTopLeft(find.byKey(const ValueKey('next-stage-film'))).dy,
          lessThan(
            tester
                .getTopLeft(find.byKey(const ValueKey('preview-result-card')))
                .dy,
          ),
        );
        expect(
          tester
              .getTopLeft(find.byKey(const ValueKey('preview-result-card')))
              .dy,
          lessThan(
            tester.getTopLeft(find.byKey(const ValueKey('invite-friend'))).dy,
          ),
        );
      });
    },
  );
  testWidgets('Poster invite preserves mode and code; copy is explicit', (
    tester,
  ) async {
    await fixture(tester, (c, db, f, r) async {
      await tapVisible(tester, find.byKey(const ValueKey('invite-friend')));
      final code = tester
          .widget<SelectableText>(find.byKey(const ValueKey('invite-code')))
          .data!;
      expect(ChallengeCode.decodeTarget(code)!.mode, GameMode.poster);
      expect(f.shares, 0);
      expect(f.copies, 0);
      await tapVisible(tester, find.text('Copiar convite'));
      expect(f.copies, 1);
      expect(f.text, contains('CINP-'));
    }, mode: GameMode.poster);
  });
  testWidgets(
    'next film costs one ticket despite rapid taps; returns to correct Poster stage',
    (tester) async {
      await fixture(tester, (c, db, f, r) async {
        final next = find.byKey(const ValueKey('next-stage-film'));
        if (next.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            next,
            300,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.tap(next);
        await tester.pump();
        await settleChanges(tester);
        expect(c.read(ticketNotifierProvider).total, 9);
        expect(c.read(posterGameProvider).movie!.id, 2);
        expect(find.text('ROUTE /visual/play'), findsOneWidget);
      }, mode: GameMode.poster);
    },
  );
  testWidgets('daily starts other mode for free', (tester) async {
    await fixture(tester, (c, db, f, r) async {
      await tapVisible(tester, find.byKey(const ValueKey('next-daily-mode')));
      await settleChanges(tester);
      expect(c.read(posterGameProvider).session!.kind, SessionKind.daily);
      expect(c.read(ticketNotifierProvider).total, 10);
      expect(find.text('ROUTE /visual/play'), findsOneWidget);
    }, kind: SessionKind.daily);
  });
  testWidgets(
    'clipboard read only on Paste; full Poster link opens correct challenge',
    (tester) async {
      var reads = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            reads++;
            return {
              'text': ChallengeCode.linkFor(
                1,
                mode: GameMode.poster,
              ).toString(),
            };
          }
          return null;
        },
      );
      try {
        await fixture(tester, (c, db, f, r) async {
          r.go('/entry');
          await tester.pumpAndSettle();
          expect(reads, 0);
          await tester.tap(find.text('Colar código ou link'));
          await tester.pump();
          expect(reads, 1);
          await tester.tap(find.text('Abrir'));
          await settleChanges(tester);
          expect(
            c.read(posterGameProvider).session!.kind,
            SessionKind.challenge,
          );
          expect(find.text('ROUTE /visual/play'), findsOneWidget);
        });
      } finally {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      }
    },
  );
  testWidgets(
    'loader distinguishes malformed code, absent film and storage failure with retry',
    (tester) async {
      await fixture(tester, (c, db, f, r) async {
        r.go('/challenge/invalid');
        await settleChanges(tester);
        expect(find.textContaining('Código inválido'), findsOneWidget);
        r.go('/challenge/${ChallengeCode.encode(32767)}');
        await settleChanges(tester);
        expect(find.textContaining('não está nesta versão'), findsOneWidget);
        await tester.runAsync(
          () => db.execute('ALTER TABLE movies RENAME TO hidden_movies'),
        );
        r.go('/challenge/${ChallengeCode.encode(3, mode: GameMode.poster)}');
        await settleChanges(tester);
        expect(
          find.text('Não foi possível carregar o desafio. Tente novamente.'),
          findsOneWidget,
        );
        await tester.runAsync(
          () => db.execute('ALTER TABLE hidden_movies RENAME TO movies'),
        );
        await tester.tap(find.text('Tentar novamente'));
        await settleChanges(tester);
        expect(find.text('ROUTE /visual/play'), findsOneWidget);
      });
    },
  );
}
