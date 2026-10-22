import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cineus/data/repositories/player_collection_repository.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/domain/entities/player_collection.dart';
import 'package:cineus/presentation/providers/player_collection_provider.dart';
import 'package:cineus/presentation/providers/result_share_service.dart';
import 'package:cineus/presentation/screens/player_collection_screen.dart';
import 'package:cineus/presentation/widgets/collection_artwork.dart';
import 'package:cineus/presentation/widgets/result_share_card.dart';
import 'package:cineus/presentation/widgets/color_share_card.dart';
import 'package:cineus/presentation/widgets/personalized_share_panel.dart';
import 'package:cineus/presentation/visuals/poster_assets.dart';
import 'support/test_database.dart';
import 'player_collection_ui_test.dart'
    show warmCollection, settleCollection, collectionApp;
import 'sprint4_ui_test.dart' show FakeShare;
import 'color_integration_test.dart' show statisticFixture;

ResultShareData filmData(GameMode mode) => ResultShareData(
  mode: mode,
  kind: SessionKind.stage,
  won: true,
  score: mode == GameMode.clue ? 9 : 4,
  steps: 2,
  total: mode == GameMode.clue ? 10 : 5,
  movieId: 1,
  stage: 1,
);

Widget cardFor(int mode, CollectionLook look) => mode == 2
    ? ColorShareCard(
        data: ColorShareData.fromSession(
          statisticFixture(id: 'private-session'),
        ),
        look: look,
      )
    : ResultShareCard(
        data: filmData(mode == 0 ? GameMode.clue : GameMode.poster),
        look: look,
      );

Future<void> tapCollection(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  final scrollRoot = find.byType(PlayerCollectionScreen).evaluate().isNotEmpty
      ? find.byKey(const ValueKey('collection-scroll'))
      : find.byType(PersonalizedSharePanel);
  await tester.scrollUntilVisible(
    target,
    180,
    scrollable: find
        .descendant(of: scrollRoot, matching: find.byType(Scrollable))
        .first,
  );
  await Scrollable.ensureVisible(tester.element(target), alignment: .35);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await settleCollection(tester);
}

Future<(Database, PlayerCollectionRepository, ProviderContainer)> fixture(
  WidgetTester tester, {
  FakeShare? share,
  bool premium = false,
}) async {
  final db = (await tester.runAsync(() => openTestDatabase()))!;
  final repo = PlayerCollectionRepository(TestDatabaseProvider(db));
  await tester.runAsync(() async {
    await repo.saveIdentity('Marina de Albuquerque', true);
    if (premium) {
      for (final item in PlayerCollectionCatalog.items.where(
        (i) => !i.starter,
      )) {
        // Test fixture only. Commercial verification is not implemented in sprint 3.
        await db.insert('collection_ownership', {
          'item_id': item.id,
          'source_id': 'verified_fixture',
          'granted_at': '2026-10-14T00:00:00Z',
        });
      }
      await repo.equip('premiere_avatar_hare_v1');
      await repo.equip('premiere_appearance_velvet_v1');
    }
  });
  final c = ProviderContainer(
    overrides: [
      playerCollectionRepositoryProvider.overrideWithValue(repo),
      if (share != null) resultShareServiceProvider.overrideWithValue(share),
    ],
  );
  await tester.runAsync(() => c.read(playerCollectionProvider.notifier).ready);
  await warmCollection(tester);
  return (db, repo, c);
}

void main() {
  test(
    'Premiere is exactly six unowned items; previews never grant or alter scores',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final repo = PlayerCollectionRepository(TestDatabaseProvider(db));
      final initial = await repo.load();
      final premiere = PlayerCollectionCatalog.items.where(
        (i) => i.collectionId == PlayerCollectionCatalog.premiereId,
      );
      expect(premiere, hasLength(6));
      expect(
        premiere.where((i) => i.kind == CollectionItemKind.frame),
        hasLength(3),
      );
      expect(
        premiere.where((i) => i.kind == CollectionItemKind.avatar),
        hasLength(2),
      );
      final look = CollectionLook.resolve(
        initial,
        PlayerCollectionCatalog.items,
        preview: PlayerCollectionCatalog.premierePreview,
      );
      expect(look.frame!.id, 'premiere_frame_marquee_v1');
      for (final item in premiere) {
        await expectLater(repo.equip(item.id), throwsStateError);
      }
      final reloaded = await repo.load();
      expect(reloaded.owned, hasLength(5));
      expect(reloaded.equipped, initial.equipped);
      final invalid = PlayerCollection(
        displayName: '',
        showIdentity: false,
        owned: initial.owned,
        equipped: {CollectionItemKind.frame: look.frame!.id},
      );
      expect(
        CollectionLook.resolve(
          invalid,
          PlayerCollectionCatalog.items,
        ).frame!.starter,
        isTrue,
      );
    },
  );

  testWidgets(
    'real-result preview is temporary; closing it exports equipped artwork only',
    (tester) async {
      final share = FakeShare();
      final (db, repo, c) = await fixture(tester, share: share);
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await tester.pumpWidget(
        collectionApp(
          c,
          child: Scaffold(
            body: PersonalizedSharePanel(
              text: 'Cineus',
              movieId: 1,
              cardBuilder: (look) => cardFor(0, look),
            ),
          ),
        ),
      );
      await settleCollection(tester);
      await tapCollection(tester, 'personalize-result-card');
      expect(find.byType(PlayerCollectionScreen), findsOneWidget);
      await tapCollection(tester, 'collection-preview-premiere');
      final preview = tester.widget<ResultShareCard>(
        find.byType(ResultShareCard).last,
      );
      expect(
        preview.look!.frame!.collectionId,
        PlayerCollectionCatalog.premiereId,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('collection-apply')),
            )
            .onPressed,
        isNull,
      );
      expect(find.textContaining('R\$'), findsNothing);
      expect((await tester.runAsync(repo.load))!.owned, hasLength(5));
      Navigator.of(tester.element(find.byType(PlayerCollectionScreen))).pop();
      await tester.pumpAndSettle();
      await settleCollection(tester);
      final restored = tester.widget<ResultShareCard>(
        find.byType(ResultShareCard),
      );
      expect(restored.look!.frame!.starter, isTrue);
      await tapCollection(tester, 'personalize-result-card');
      await tapCollection(tester, 'collection-tab-frame');
      await tapCollection(tester, 'collection-item-frame_blue_reel_v1');
      await tester.tap(find.byKey(const ValueKey('collection-apply')));
      await settleCollection(tester);
      Navigator.of(tester.element(find.byType(PlayerCollectionScreen))).pop();
      await tester.pumpAndSettle();
      await settleCollection(tester);
      expect(
        tester
            .widget<ResultShareCard>(find.byType(ResultShareCard))
            .look!
            .frame!
            .id,
        'frame_blue_reel_v1',
      );
      expect(share.shares, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (var mode = 0; mode < 3; mode++) {
    testWidgets('mode $mode exports the exact decorated preview pixels', (
      tester,
    ) async {
      final share = FakeShare();
      final (db, repo, c) = await fixture(tester, share: share, premium: true);
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final frame = ['marquee', 'deco', 'spotlight'][mode];
      await tester.runAsync(() => repo.equip('premiere_frame_${frame}_v1'));
      if (mode == 1) {
        await tester.runAsync(
          () => repo.saveIdentity('Marina de Albuquerque', false),
        );
      }
      await tester.runAsync(
        () => c.read(playerCollectionProvider.notifier).load(),
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        collectionApp(
          c,
          child: Scaffold(
            body: PersonalizedSharePanel(
              colors: mode == 2,
              text: 'Cineus',
              movieId: mode == 2 ? null : 1,
              cardBuilder: (look) => cardFor(mode, look),
            ),
          ),
        ),
      );
      await settleCollection(tester);
      expect(
        find.text('Marina de Albuquerque'),
        mode == 1 ? findsNothing : findsOneWidget,
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(CollectionCardSurface));
        for (final item
            in c.read(playerCollectionProvider).profile!.equipped.values) {
          final art = PlayerCollectionCatalog.items.firstWhere(
            (i) => i.id == item,
          );
          if (art.asset.endsWith('.png')) {
            await precacheImage(
              ExactAssetImage(
                art.asset,
                scale: art.kind == CollectionItemKind.frame ? 2 : 1,
              ),
              context,
            );
          }
        }
        if (mode != 2) {
          await precacheImage(
            ResizeImage.resizeIfNeeded(
              PosterAssets.decodeWidth(160, 2),
              null,
              AssetImage(PosterAssets.path(1)),
            ),
            context,
            onError: (_, __) {},
          );
        }
      });
      await settleCollection(tester);
      final repaint = tester.renderObject<RenderRepaintBoundary>(
        find.byWidgetPredicate(
          (w) =>
              w is RepaintBoundary &&
              (w.child is ResultShareCard || w.child is ColorShareCard),
        ),
      );
      final before = await tester.runAsync(() async {
        final image = await repaint.toImage(pixelRatio: 2);
        try {
          return (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
        } finally {
          image.dispose();
        }
      });
      await tapCollection(
        tester,
        mode == 2 ? 'colors-share-image' : 'share-result-image',
      );
      await settleCollection(tester);
      expect(share.png, isNotNull);
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(share.png!);
        final image = (await codec.getNextFrame()).image;
        final actual = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        expect(actual!.buffer.asUint8List(), orderedEquals(before!));
        image.dispose();
        codec.dispose();
        if (const bool.fromEnvironment('CAPTURE_PERSONALIZED')) {
          final path = File('docs/preview/collection/sprint-03-mode-$mode.png');
          await path.parent.create(recursive: true);
          await path.writeAsBytes(share.png!);
        }
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final frame in ['marquee', 'deco', 'spotlight']) {
    for (var mode = 0; mode < 3; mode++) {
      testWidgets(
        '$frame / mode $mode fits 320px at 200% without cutting content',
        (tester) async {
          final (db, repo, c) = await fixture(tester, premium: true);
          addTearDown(() async {
            c.dispose();
            await db.close();
          });
          final profile = await tester.runAsync(repo.load);
          final look = CollectionLook.resolve(
            profile,
            PlayerCollectionCatalog.items,
            preview: {CollectionItemKind.frame: 'premiere_frame_${frame}_v1'},
          );
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
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
          expect(find.byType(CollectionCardSurface), findsOneWidget);
          expect(find.text('Marina de Albuquerque'), findsOneWidget);
          expect(
            tester.getBottomRight(find.text('Marina de Albuquerque')).dy,
            lessThan(
              tester.getBottomRight(find.byType(CollectionCardSurface)).dy - 56,
            ),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
