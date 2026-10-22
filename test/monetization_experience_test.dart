import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/domain/entities/monetization.dart';
import 'package:cineus/domain/services/monetization_service.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/providers/app_clock.dart';
import 'package:cineus/presentation/providers/commerce_content_provider.dart';
import 'package:cineus/presentation/providers/monetization_notifier.dart';
import 'package:cineus/presentation/providers/player_collection_provider.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/routes/app_router.dart';
import 'package:cineus/presentation/screens/seasons_screen.dart';
import 'package:cineus/presentation/widgets/collection_artwork.dart';
import 'package:cineus/presentation/widgets/commerce_placeholders.dart';
import 'package:cineus/presentation/widgets/rewarded_tickets_card.dart';
import 'package:cineus/presentation/widgets/ticket_details_sheet.dart';
import 'player_collection_ui_test.dart'
    show collectionApp, warmCollection, settleCollection;
import 'support/test_database.dart';

class ExperienceAds implements MonetizationService {
  bool available = false;
  bool completed = false;
  int initialized = 0;
  @override
  Future<void> initialize() async {
    initialized++;
  }

  @override
  Future<bool> isRewardedAvailable() async => available;
  @override
  Future<bool> showRewarded() async => completed;
  @override
  Future<PassEntitlement> loadPassEntitlement() async =>
      const PassEntitlement();
  @override
  Future<void> purchasePass() async {}
  @override
  Future<void> restorePass() async {}
}

Future<ProviderContainer> experience(
  WidgetTester tester, {
  List<Override> overrides = const [],
  bool movies = false,
}) async {
  final db = (await tester.runAsync(openTestDatabase))!;
  await tester.runAsync(() async {
    const seeder = DatabaseSeeder();
    await seeder.ensureCanonicalSchema(db);
    if (movies) {
      await seeder.seedFromJsonAsset(db);
      await seeder.syncStages(db);
    }
  });
  final c = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(TestDatabaseProvider(db)),
      appClockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 15, 18)),
      ...overrides,
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
    await db.close();
  });
  await tester.runAsync(() async {
    await c.read(ticketNotifierProvider.notifier).ready;
    await c.read(playerCollectionProvider.notifier).ready;
    c.read(monetizationNotifierProvider);
    for (
      var i = 0;
      c.read(monetizationNotifierProvider).isLoading && i < 100;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  });
  return c;
}

Future<void> warmExperience(WidgetTester tester) async {
  await warmCollection(tester);
  await tester.runAsync(() async {
    for (final name in [
      'video',
      'ticket',
      'inProgress',
      'close',
      'homeStats',
      'information',
    ]) {
      for (final suffix in ['', '_ink']) {
        await SvgAssetLoader(
          'assets/generated/icons/$name$suffix.svg',
        ).loadBytes(null);
      }
    }
  });
}

Future<void> captureExperience(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CINEUS_CAPTURE_UI')) return;
  await settleCollection(tester);
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('experience-capture')),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/preview/monetization-ux/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets(
    'unconfigured placements stay visible and cannot grant or sell tickets',
    (tester) async {
      final c = await experience(tester);
      await tester.pumpWidget(
        collectionApp(
          c,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [RewardedTicketsCard(), TicketPacksPlaceholder()],
              ),
            ),
          ),
        ),
      );
      await settleCollection(tester);
      final before = c.read(ticketNotifierProvider).total;
      expect(
        find.byKey(const ValueKey('rewarded-ticket-placement')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('rewarded-watch')))
            .onPressed,
        isNull,
      );
      expect(find.text('Em breve'), findsNWidgets(3));
      for (final button in tester.widgetList<OutlinedButton>(
        find.byType(OutlinedButton),
      )) {
        expect(button.onPressed, isNull);
      }
      expect(c.read(ticketNotifierProvider).total, before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'no-fill keeps the placement visible and retryable; incomplete video grants nothing',
    (tester) async {
      final ads = ExperienceAds();
      final c = await experience(
        tester,
        overrides: [
          monetizationServiceProvider.overrideWithValue(ads),
          rewardedConfigurationReadyProvider.overrideWithValue(true),
        ],
      );
      await tester.pumpWidget(
        collectionApp(c, child: const Scaffold(body: RewardedTicketsCard())),
      );
      await settleCollection(tester);
      expect(find.text('Nenhum vídeo disponível agora.'), findsOneWidget);
      final initial = ads.initialized;
      await tester.tap(find.byKey(const ValueKey('rewarded-watch')));
      await settleCollection(tester);
      expect(ads.initialized, greaterThan(initial));
      ads.available = true;
      await tester.runAsync(
        () => c.read(monetizationNotifierProvider.notifier).load(),
      );
      await settleCollection(tester);
      final balance = c.read(ticketNotifierProvider).total;
      await tester.tap(find.byKey(const ValueKey('rewarded-watch')));
      await settleCollection(tester);
      expect(c.read(ticketNotifierProvider).total, balance);
      expect(find.text('Recompensa ainda não confirmada.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'season preview is bounded, selectable and never equips or grants a locked item',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = await experience(tester);
      await warmExperience(tester);
      final before = c.read(playerCollectionProvider).profile!;
      await tester.pumpWidget(collectionApp(c, child: const SeasonsScreen()));
      await settleCollection(tester);
      expect(find.text('10 / 10'), findsNothing);
      final hero = find.byKey(const ValueKey('season-card-night_2026_10'));
      expect(tester.getSize(hero).height, lessThan(500));
      await tester.tap(
        find.byKey(const ValueKey('season-explore-night_2026_10')),
      );
      await settleCollection(tester);
      final candidate = find.byKey(
        const ValueKey('season-item-night_avatar_otter_v1'),
      );
      await tester.ensureVisible(candidate);
      await tester.tap(candidate);
      await settleCollection(tester);
      final preview = tester.widget<CollectionCardSurface>(
        find.byType(CollectionCardSurface),
      );
      expect(preview.look!.avatar!.id, 'night_avatar_otter_v1');
      expect(c.read(playerCollectionProvider).profile!.owned, before.owned);
      expect(
        c.read(playerCollectionProvider).profile!.equipped,
        before.equipped,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final lang in ['pt', 'en', 'es']) {
    testWidgets(
      'wallet and seasons scroll without overflow at 320px and 200% in $lang',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final c = await experience(tester);
        await warmExperience(tester);
        final content = (await tester.runAsync(
          () => c.read(commerceContentProvider.future),
        ))!;
        for (final screen in [
          const Scaffold(body: TicketDetailsSheet()),
          const SeasonsScreen(),
          Scaffold(
            body: SeasonPreviewSheet(
              collection: content.collections.first,
              now: DateTime.utc(2026, 10, 15, 18),
            ),
          ),
        ]) {
          await tester.pumpWidget(
            collectionApp(c, child: screen, language: lang, scale: 2),
          );
          await settleCollection(tester);
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -600),
          );
          await settleCollection(tester);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets(
    'capture the actual routed wallet, seasons and collection preview',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = await experience(tester, movies: true);
      await warmExperience(tester);
      final router = AppRouter.create(initialLocation: '/home');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('experience-capture'),
          child: UncontrolledProviderScope(
            container: c,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              locale: const Locale('pt'),
              supportedLocales: AppL10n.supportedLocales,
              localizationsDelegates: AppL10n.localizationsDelegates,
              routerConfig: router,
            ),
          ),
        ),
      );
      await settleCollection(tester);
      await tester.tap(find.byKey(const ValueKey('ticket-balance')));
      await settleCollection(tester);
      expect(find.byType(TicketDetailsSheet), findsOneWidget);
      await captureExperience(tester, '01-tickets-video');
      await tester.drag(
        find.byKey(const ValueKey('ticket-details-scroll')),
        const Offset(0, -520),
      );
      await settleCollection(tester);
      await captureExperience(tester, '02-tickets-packs-plus');
      Navigator.of(tester.element(find.byType(TicketDetailsSheet))).pop();
      await settleCollection(tester);
      router.go('/seasons');
      await settleCollection(tester);
      await captureExperience(tester, '03-seasons');
      await tester.tap(
        find.byKey(const ValueKey('season-explore-night_2026_10')),
      );
      await settleCollection(tester);
      await captureExperience(tester, '04-season-preview');
      Navigator.of(tester.element(find.byType(SeasonPreviewSheet))).pop();
      router.go('/home');
      await settleCollection(tester);
      await tester.drag(
        find.byKey(const ValueKey('home-scroll')),
        const Offset(0, -1100),
      );
      await settleCollection(tester);
      await captureExperience(tester, '05-home-placements');
      for (final entry in [
        ('/stages', '06-films-ad-space'),
        ('/visual', '07-posters-ad-space'),
        ('/colors', '08-colors-ad-space'),
      ]) {
        router.go(entry.$1);
        await settleCollection(tester);
        await captureExperience(tester, entry.$2);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
