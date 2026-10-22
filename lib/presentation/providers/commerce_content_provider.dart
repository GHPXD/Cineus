import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/commerce_content.dart';
import '../../domain/entities/player_collection.dart';
import '../../data/services/commerce_content_service.dart';
import 'commercial_provider.dart';
import 'providers.dart';

final commerceContentServiceProvider = FutureProvider<CommerceContentService?>((
  ref,
) async {
  final sync = ref.watch(commerceSynchronizerProvider);
  if (kIsWeb ||
      sync == null ||
      !const bool.fromEnvironment('CINEUS_CONTENT_UPDATES')) {
    return null;
  }
  return CommerceContentService(
    sync,
    ref.read(databaseProvider),
    Directory('${await getDatabasesPath()}/cineus_content'),
  );
});
final commerceContentProvider = FutureProvider<CommerceContent>((ref) async {
  final bundled = CommerceContent.parse(
    jsonDecode(
      await rootBundle.loadString(
        'assets/commerce/catalog_v1.json',
        cache: false,
      ),
    ),
  );
  final service = await ref.watch(commerceContentServiceProvider.future);
  if (service == null) return bundled;
  final cached = await service.cached();
  return cached != null && cached.revision >= bundled.revision
      ? cached
      : bundled;
});
final contentAssetBytesProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>((ref, item) async {
      // Keep this collection's approved art bundled: older signed downloads
      // must not restore retired portraits, frames or card backgrounds.
      if (PlayerCollectionCatalog.items.any((i) => i.id == item)) {
        return null;
      }
      final service = await ref.watch(commerceContentServiceProvider.future);
      if (service == null) return null;
      final content = await ref.watch(commerceContentProvider.future);
      final asset = content.assets.where((a) => a.item == item).firstOrNull;
      return asset == null ? null : service.bytes(asset);
    });
