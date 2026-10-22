import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/data/datasources/database_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cineus/data/repositories/player_collection_repository.dart';
import 'package:cineus/domain/entities/player_collection.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/providers/player_collection_provider.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/routes/app_router.dart';
import 'package:cineus/presentation/screens/player_collection_screen.dart';
import 'package:cineus/presentation/widgets/collection_artwork.dart';
import 'support/test_database.dart';

class RecoverableCollectionDatabase implements DatabaseProvider {
  final Database db;
  final ready = Completer<void>();
  bool unavailable = true;
  RecoverableCollectionDatabase(this.db);
  @override
  Future<Database> get database async {
    await ready.future;
    if (unavailable) throw StateError('Database temporarily unavailable');
    return db;
  }
}

Future<void> settleCollection(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 40));
  }
}

Future<void> warmCollection(WidgetTester tester) => tester.runAsync(() async {
  for (final item in PlayerCollectionCatalog.items.where(
    (i) => i.asset.endsWith('.svg'),
  )) {
    await SvgAssetLoader(item.asset).loadBytes(null);
  }
  for (final id in [
    'premium',
    'back',
    'completed',
    'lock',
    'error',
    'chevron',
  ]) {
    await SvgAssetLoader('assets/generated/icons/$id.svg').loadBytes(null);
  }
  for (final entry in {
    'Fredoka': ['Fredoka-600.ttf', 'Fredoka-700.ttf'],
    'Nunito': ['Nunito-400.ttf', 'Nunito-600.ttf'],
  }.entries) {
    final loader = FontLoader(entry.key);
    for (final file in entry.value) {
      loader.addFont(rootBundle.load('assets/fonts/$file'));
    }
    await loader.load();
  }
});

Widget collectionApp(
  ProviderContainer container, {
  double scale = 1,
  String language = 'pt',
  Widget? child,
}) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    locale: Locale(language),
    supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: child ?? const PlayerCollectionScreen(),
  ),
);

void main() {
  testWidgets('loading, failure and retry preserve the equipped item', (
    tester,
  ) async {
    final db = await tester.runAsync(() => openTestDatabase());
    final database = RecoverableCollectionDatabase(db!);
    final container = ProviderContainer(
      overrides: [
        playerCollectionRepositoryProvider.overrideWithValue(
          PlayerCollectionRepository(database),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await warmCollection(tester);
    await tester.pumpWidget(collectionApp(container));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    database.ready.complete();
    await settleCollection(tester);
    expect(find.text('Não foi possível abrir sua coleção.'), findsOneWidget);
    database.unavailable = false;
    await tester.tap(find.byType(TextButton).first);
    await settleCollection(tester);
    expect(find.byType(CollectionPreview), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('collection-item-avatar_fox_v1')),
      160,
    );
    await Scrollable.ensureVisible(
      tester.element(
        find.byKey(const ValueKey('collection-item-avatar_fox_v1')),
      ),
      alignment: .35,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('collection-item-avatar_fox_v1')),
    );
    await tester.pump();
    database.unavailable = true;
    await tester.tap(find.byKey(const ValueKey('collection-apply')));
    await settleCollection(tester);
    expect(container.read(playerCollectionProvider).hasError, isTrue);
    expect(
      container
          .read(playerCollectionProvider)
          .profile!
          .equipped[CollectionItemKind.avatar],
      'avatar_owl_v1',
    );
    database.unavailable = false;
    await tester.tap(find.byKey(const ValueKey('collection-apply')));
    await settleCollection(tester);
    expect(container.read(playerCollectionProvider).hasError, isFalse);
    expect(
      container
          .read(playerCollectionProvider)
          .profile!
          .equipped[CollectionItemKind.avatar],
      'avatar_fox_v1',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'selection previews without granting or equipping; applying and profile editing persist',
    (tester) async {
      late ProviderContainer container;
      late PlayerCollectionRepository repository;
      final db = await tester.runAsync(() => openTestDatabase());
      addTearDown(() async {
        container.dispose();
        await db!.close();
      });
      repository = PlayerCollectionRepository(TestDatabaseProvider(db!));
      container = ProviderContainer(
        overrides: [
          playerCollectionRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await warmCollection(tester);
      await tester.pumpWidget(collectionApp(container));
      await settleCollection(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('collection-item-avatar_fox_v1')),
        160,
      );
      await Scrollable.ensureVisible(
        tester.element(
          find.byKey(const ValueKey('collection-item-avatar_fox_v1')),
        ),
        alignment: .35,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('collection-item-avatar_fox_v1')),
      );
      await tester.pump();
      expect(
        container
            .read(playerCollectionProvider)
            .profile!
            .equipped[CollectionItemKind.avatar],
        'avatar_owl_v1',
      );
      await tester.scrollUntilVisible(find.byType(CollectionPreview), -200);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CollectionPreview>(find.byType(CollectionPreview))
            .candidate!
            .id,
        'avatar_fox_v1',
      );
      await tester.tap(find.byKey(const ValueKey('collection-apply')));
      await settleCollection(tester);
      expect(
        container
            .read(playerCollectionProvider)
            .profile!
            .equipped[CollectionItemKind.avatar],
        'avatar_fox_v1',
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('collection-edit-profile')),
        -200,
      );
      await tester.tap(find.byKey(const ValueKey('collection-edit-profile')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('collection-display-name')),
        'Marina',
      );
      await tester.tap(find.byKey(const ValueKey('collection-show-identity')));
      await tester.tap(find.byKey(const ValueKey('collection-save-profile')));
      await settleCollection(tester);
      expect(
        container.read(playerCollectionProvider).profile!.displayName,
        'Marina',
      );
      expect(
        container.read(playerCollectionProvider).profile!.showIdentity,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(collectionApp(container));
      await settleCollection(tester);
      expect(
        container
            .read(playerCollectionProvider)
            .profile!
            .equipped[CollectionItemKind.avatar],
        'avatar_fox_v1',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final config in [
    (320.0, 2.0, 'pt'),
    (390.0, 1.0, 'pt'),
    (320.0, 2.0, 'en'),
    (320.0, 2.0, 'es'),
    (840.0, 1.0, 'pt'),
  ]) {
    testWidgets('collection and editor fit $config', (tester) async {
      final db = await tester.runAsync(() => openTestDatabase());
      final repository = PlayerCollectionRepository(TestDatabaseProvider(db!));
      await tester.runAsync(
        () => repository.saveIdentity('Marina de Albuquerque', true),
      );
      final container = ProviderContainer(
        overrides: [
          playerCollectionRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      tester.view.physicalSize = Size(config.$1, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await warmCollection(tester);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: collectionApp(
            container,
            scale: config.$2,
            language: config.$3,
          ),
        ),
      );
      await settleCollection(tester);
      expect(find.byType(CollectionPreview), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_COLLECTION') &&
          config.$1 == 390) {
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final target = File('docs/preview/collection/sprint-02.png');
          await target.parent.create(recursive: true);
          await target.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.byKey(const ValueKey('collection-edit-profile')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('collection-display-name')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'production router exposes collection from settings without adding a tab',
    (tester) async {
      final db = await tester.runAsync(() => openTestDatabase());
      final router = AppRouter.create(initialLocation: '/settings');
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(TestDatabaseProvider(db!)),
        ],
      );
      var disposed = false;
      addTearDown(() async {
        if (!disposed) {
          container.dispose();
          router.dispose();
        }
        await db.close();
      });
      await warmCollection(tester);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            locale: const Locale('pt'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await settleCollection(tester);
      await tester.tap(find.byKey(const ValueKey('settings-collection')));
      await settleCollection(tester);
      expect(find.byType(PlayerCollectionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      router.dispose();
      disposed = true;
    },
  );
}
