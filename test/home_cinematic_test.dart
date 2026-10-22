import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cineus/core/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cineus/presentation/providers/color_providers.dart';
import 'package:cineus/presentation/screens/home_screen.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/providers/play_notifier.dart';
import 'package:cineus/presentation/widgets/home_cinematic_deck.dart';
import 'package:cineus/presentation/routes/app_router.dart';
import 'package:cineus/presentation/screens/color_training_screen.dart';
import 'sprint2_home_test.dart' show withHome, settleData;
import 'color_persistence_ui_test.dart' show ColorUiFixture, settleColors;
import 'color_integration_ui_test.dart' show warmColorIntegration;

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'swiping selects a movie card without starting a game or debiting tickets',
    (tester) async {
      await withHome(tester, (f) async {
        expect(
          find.byKey(const ValueKey('daily-poster')).hitTestable(),
          findsOneWidget,
        );
        final before = f.container.read(ticketNotifierProvider).total;
        await tester.drag(
          find.byKey(const ValueKey('home-mode-carousel')),
          const Offset(-220, 0),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.byKey(const ValueKey('home-colors-daily')).hitTestable(),
          findsOneWidget,
        );
        await tester.drag(
          find.byKey(const ValueKey('home-mode-carousel')),
          const Offset(220, 0),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('daily-poster')).hitTestable(),
          findsOneWidget,
        );
        expect(f.container.read(posterGameProvider).session, isNull);
        expect(f.container.read(ticketNotifierProvider).total, before);
        await settleData(tester);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const ValueKey('daily-poster')))
              .onPressed,
          isNotNull,
          reason: 'O diário deve terminar de carregar antes de ser aberto',
        );
        await tester.tap(find.byKey(const ValueKey('daily-poster')));
        await settleData(tester);
        for (
          var i = 0;
          i < 8 && f.container.read(posterGameProvider).isLoading;
          i++
        ) {
          await settleData(tester);
        }
        expect(f.container.read(posterGameProvider).error, isNull);
        expect(find.text('ROUTE /visual/play'), findsOneWidget);
        expect(f.container.read(posterGameProvider).session!.isDaily, true);
        expect(f.container.read(ticketNotifierProvider).total, before);
      }, seededCatalog: true);
    },
  );

  testWidgets(
    'Cores retry reloads the repository and the daily CTA starts the real game',
    (tester) async {
      late ColorUiFixture f;
      await tester.runAsync(() async {
        f = await ColorUiFixture.create();
      });
      f.repo.failLoad = true;
      await warmColorIntegration(tester, f);
      final router = AppRouter.create(initialLocation: '/home');
      await tester.pumpWidget(f.routedApp(router));
      await settleColors(tester);
      try {
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomeScreen)),
        );
        Future<void> tapDaily() async {
          final button = find.byKey(const ValueKey('home-colors-daily'));
          await tester.scrollUntilVisible(
            button,
            160,
            scrollable: find
                .descendant(
                  of: find.byKey(const ValueKey('home-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await Scrollable.ensureVisible(tester.element(button), alignment: .5);
          await tester.pump();
          expect(button.hitTestable(), findsOneWidget);
          await tester.tap(button);
          await settleColors(tester);
        }

        final dot = find.byKey(const ValueKey('home-select-colors'));
        await Scrollable.ensureVisible(tester.element(dot), alignment: .8);
        await settleColors(tester);
        await tester.tap(dot);
        await tester.pump(const Duration(milliseconds: 400));
        await settleColors(tester);
        expect(find.text('Não foi possível carregar.'), findsOneWidget);
        f.repo.failLoad = false;
        await tapDaily();
        await tester.runAsync(
          () => container.read(colorHomeOverviewProvider.future),
        );
        await settleColors(tester);
        expect(find.text('Não foi possível carregar.'), findsNothing);
        await tapDaily();
        for (
          var i = 0;
          i < 8 && find.byType(ColorTrainingScreen).evaluate().isEmpty;
          i++
        ) {
          await settleColors(tester);
        }
        expect(find.byType(ColorTrainingScreen), findsOneWidget);
        final record = await tester.runAsync(
          () => f.repo.load('daily:2026-10-13'),
        );
        expect(record, isNotNull);
        expect(record!.game.answers, isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        await tester.runAsync(f.db.close);
      }
    },
  );

  testWidgets('carousel and indicators share Dicas, Poster, Cores order', (
    tester,
  ) async {
    await withHome(tester, (f) async {
      final carousel = find.byKey(const ValueKey('home-mode-carousel'));
      final deck = tester.widget<HomeCinematicDeck>(
        find.byType(HomeCinematicDeck),
      );
      expect(deck.cards.map((card) => card.id), ['clues', 'poster', 'colors']);
      void check(String active) {
        final dots = [
          'clues',
          'poster',
          'colors',
        ].map((id) => find.byKey(ValueKey('home-select-$id'))).toList();
        expect(
          tester.getCenter(dots[0]).dx,
          lessThan(tester.getCenter(dots[1]).dx),
        );
        expect(
          tester.getCenter(dots[1]).dx,
          lessThan(tester.getCenter(dots[2]).dx),
        );
        for (final id in ['clues', 'poster', 'colors']) {
          final dot = find.byKey(ValueKey('home-select-$id'));
          final semantic = tester.widget<Semantics>(
            find.ancestor(of: dot, matching: find.byType(Semantics)).first,
          );
          expect(semantic.properties.selected, id == active);
          final indicator = tester.widget<Container>(
            find.descendant(of: dot, matching: find.byType(Container)).first,
          );
          expect(
            (indicator.decoration as BoxDecoration).color,
            id == active ? AppColors.gold300 : AppColors.obsidian600,
          );
        }
        final action = active == 'colors'
            ? 'home-colors-daily'
            : active == 'clues'
            ? 'daily-clue'
            : 'daily-poster';
        expect(find.byKey(ValueKey(action)).hitTestable(), findsOneWidget);
      }

      check('poster');
      await tester.drag(carousel, const Offset(220, 0));
      await tester.pumpAndSettle();
      check('clues');
      final colors = find.byKey(const ValueKey('home-select-colors'));
      await Scrollable.ensureVisible(tester.element(colors), alignment: .8);
      await tester.pumpAndSettle();
      await tester.tap(colors);
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(tester.element(carousel), alignment: .5);
      await tester.pumpAndSettle();
      check('colors');
      await tester.drag(carousel, const Offset(220, 0));
      await tester.pumpAndSettle();
      check('poster');
      expect(f.container.read(clueGameProvider).session, isNull);
      expect(f.container.read(posterGameProvider).session, isNull);
    });
  });

  for (final config in [
    (360.0, 1.0, 'pt'),
    (390.0, 1.0, 'pt'),
    (430.0, 1.0, 'pt'),
    (1024.0, 1.0, 'pt'),
    (320.0, 2.0, 'pt'),
    (320.0, 2.0, 'en'),
    (320.0, 2.0, 'es'),
  ]) {
    testWidgets(
      'Home shortcuts have equal bounds and unwrapped titles $config',
      (tester) async {
        await withHome(
          tester,
          (f) async {
            final challenge = find.byKey(const ValueKey('home-open-challenge'));
            final stats = find.byKey(const ValueKey('home-open-stats'));
            await tester.scrollUntilVisible(
              challenge,
              160,
              scrollable: find
                  .descendant(
                    of: find.byKey(const ValueKey('home-scroll')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await Scrollable.ensureVisible(
              tester.element(challenge),
              alignment: .2,
            );
            await tester.pumpAndSettle();
            expect(tester.getSize(challenge), tester.getSize(stats));
            expect(tester.getSize(challenge).height, greaterThanOrEqualTo(48));
            for (final tile in [challenge, stats]) {
              final title = find
                  .descendant(of: tile, matching: find.byType(Text))
                  .first;
              final paragraph = tester.renderObject<RenderParagraph>(title);
              final boxes = paragraph.getBoxesForSelection(
                TextSelection(
                  baseOffset: 0,
                  extentOffset: tester.widget<Text>(title).data!.length,
                ),
              );
              expect(boxes.map((box) => box.top).toSet(), hasLength(1));
              expect(paragraph.didExceedMaxLines, false);
            }
            if (config.$3 == 'pt') {
              expect(find.text('Abrir desafio'), findsOneWidget);
              expect(find.text('Abrir um desafio'), findsNothing);
            }
          },
          width: config.$1,
          scale: config.$2,
          locale: Locale(config.$3),
        );
      },
    );
  }

  for (final language in ['pt', 'en', 'es']) {
    testWidgets('large text uses readable stacked cards in $language', (
      tester,
    ) async {
      await withHome(
        tester,
        (f) async {
          expect(find.byType(PageView), findsNothing);
          expect(find.byType(HomeCinematicCard), findsNWidgets(3));
          for (final key in [
            'daily-clue',
            'daily-poster',
            'home-colors-daily',
          ]) {
            final button = find.byKey(ValueKey(key));
            await tester.scrollUntilVisible(
              button,
              160,
              scrollable: find
                  .descendant(
                    of: find.byKey(const ValueKey('home-scroll')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await Scrollable.ensureVisible(
              tester.element(button),
              alignment: .5,
            );
            await tester.pump();
            expect(button.hitTestable(), findsOneWidget);
            expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          }
        },
        width: 320,
        scale: 2,
        locale: Locale(language),
      );
    });
  }
}
