import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/domain/entities/color_question.dart';
import 'package:cineus/domain/entities/player_collection.dart';
import 'package:cineus/domain/entities/commercial_product.dart';
import 'package:cineus/domain/services/commercial_store.dart';
import 'package:cineus/presentation/providers/app_clock.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/providers/commercial_provider.dart';
import 'package:cineus/presentation/providers/commerce_content_provider.dart';
import 'package:cineus/presentation/screens/journey_screen.dart';
import 'package:cineus/presentation/screens/seasons_screen.dart';
import 'package:cineus/presentation/widgets/commercial_offers_panel.dart';
import 'package:cineus/presentation/widgets/color_character_art.dart';
import 'support/test_database.dart';
import 'player_collection_ui_test.dart'
    show collectionApp, warmCollection, settleCollection;
import 'color_training_screen_test.dart' show warmTrainingAssets;
import 'personalized_results_test.dart' show cardFor;

class CycleStore extends Fake implements CommercialStore {
  @override
  Future<List<CommercialEntitlement>> loadEntitlements() async => [];
}

Future<void> captureCycle(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('cycle-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1),
        bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/preview/commerce/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets(
    'all nine new frames fit the three real result cards at 320px and 200%',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await warmCollection(tester);
      final frames = PlayerCollectionCatalog.items
          .where(
            (i) =>
                i.kind == CollectionItemKind.frame &&
                !i.starter &&
                !i.id.startsWith('premiere_'),
          )
          .toList();
      expect(frames, hasLength(9));
      for (final frame in frames) {
        final look = CollectionLook(
          frame: frame,
          appearance: PlayerCollectionCatalog.items
              .where(
                (i) =>
                    i.kind == CollectionItemKind.appearance &&
                    i.collectionId == frame.collectionId,
              )
              .firstOrNull,
        );
        for (var mode = 0; mode < 3; mode++) {
          await tester.pumpWidget(
            collectionApp(
              c,
              scale: 2,
              language: ['pt', 'en', 'es'][mode],
              child: Scaffold(
                body: SingleChildScrollView(child: cardFor(mode, look)),
              ),
            ),
          );
          await settleCollection(tester);
          expect(
            tester.takeException(),
            isNull,
            reason: '${frame.id} mode $mode',
          );
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final lang in ['pt', 'en', 'es']) {
    testWidgets(
      'missions, seasons and commercial offers fit 320px at 200% in $lang',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = (await tester.runAsync(openTestDatabase))!;
        final c = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(TestDatabaseProvider(db)),
            appClockProvider.overrideWithValue(
              () => DateTime.utc(2026, 10, 15, 12),
            ),
            commercialStoreProvider.overrideWithValue(CycleStore()),
            commercialOffersProvider.overrideWith(
              (_) async => [
                for (final p in CommercialCatalog.products)
                  CommercialStoreOffer(
                    productId: p.id,
                    storeProductId: 'test.${p.id}',
                    localizedPrice: 'R\$ 9,90',
                  ),
              ],
            ),
          ],
        );
        addTearDown(() async {
          c.dispose();
          await db.close();
        });
        await warmCollection(tester);
        for (final screen in [
          const JourneyScreen(),
          const SeasonsScreen(),
          const Scaffold(
            body: SingleChildScrollView(child: CommercialOffersPanel()),
          ),
        ]) {
          await tester.pumpWidget(
            collectionApp(
              c,
              scale: 2,
              language: lang,
              child: RepaintBoundary(
                key: const ValueKey('cycle-capture'),
                child: screen,
              ),
            ),
          );
          await settleCollection(tester);
          for (
            var wait = 0;
            wait < 20 && find.byType(Scrollable).evaluate().isEmpty;
            wait++
          ) {
            await settleCollection(tester);
          }
          expect(
            find.byType(Scrollable),
            findsWidgets,
            reason:
                '${screen.runtimeType}: ${c.read(journeyProgressProvider)} / ${c.read(commerceContentProvider)}',
          );
          expect(tester.takeException(), isNull);
          if (screen is SeasonsScreen && lang == 'pt') {
            await captureCycle(tester, 'seasons_320_2x_pt');
          }
          for (var i = 0; i < 4; i++) {
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -550),
            );
            await settleCollection(tester);
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
    );
  }
  testWidgets(
    'twenty secondary regions render on real characters for visual review',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1550);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final catalog = ColorPilotCatalog.fromJson(
        jsonDecode(File('assets/colors/training_v1.json').readAsStringSync()),
      );
      final questions = catalog.questions.skip(90).toList();
      expect(questions, hasLength(20));
      await warmTrainingAssets(tester, catalog);
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: const ValueKey('cycle-capture'),
            child: Scaffold(
              backgroundColor: const Color(0xfff7f0dd),
              body: GridView.count(
                crossAxisCount: 4,
                childAspectRatio: 1,
                children: [
                  for (final q in questions)
                    Column(
                      children: [
                        Text(
                          '${q.text('character', 'pt')} · ${q.text('part', 'pt')}',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              for (final choice in [
                                q.target,
                                const SrgbColor(255, 0, 180),
                              ])
                                Expanded(
                                  child: ColorCharacterArt(
                                    question: q,
                                    choice: choice,
                                    palette: {
                                      for (final p in catalog.questions.where(
                                        (p) => p.characterId == q.characterId,
                                      ))
                                        p.artPart!: p.target,
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await captureCycle(tester, 'continuity-regions');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
