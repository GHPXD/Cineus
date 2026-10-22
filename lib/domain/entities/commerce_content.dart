import 'commercial_product.dart';
import 'player_collection.dart';

class ContentCollection {
  final String id, product;
  final DateTime from, until;
  final Map<String, String> name;
  final List<String> items;
  const ContentCollection(
    this.id,
    this.product,
    this.from,
    this.until,
    this.name,
    this.items,
  );
  bool visible(DateTime now) => !now.isBefore(from) && now.isBefore(until);
  String title(String language) => name[language] ?? name['en']!;
}

class ContentAsset {
  final String item, sha256, format;
  final int bytes;
  const ContentAsset(this.item, this.sha256, this.format, this.bytes);
}

class ContentEvent {
  final String id, reward;
  final bool demo;
  final Map<String, String> sponsor;
  final DateTime from, until;
  final int target;
  const ContentEvent(
    this.id,
    this.reward,
    this.demo,
    this.sponsor,
    this.from,
    this.until,
    this.target,
  );
  bool active(DateTime at) => !at.isBefore(from) && at.isBefore(until);
}

/// Only declarative content for IDs supported by this binary. Never code/URLs.
class CommerceContent {
  final int revision;
  final List<ContentCollection> collections;
  final List<ContentAsset> assets;
  final List<ContentEvent> events;
  final Map<String, String> cycles;
  const CommerceContent(
    this.revision,
    this.collections,
    this.assets,
    this.events,
    this.cycles,
  );
  factory CommerceContent.parse(Map<String, dynamic> j) {
    void check(bool ok) {
      if (!ok) throw const FormatException('Incompatible content');
    }

    check(
      j['schema'] == 1 &&
          j['revision'] is int &&
          j['revision'] > 0 &&
          j['min_catalog'] is int &&
          j['min_catalog'] <= PlayerCollectionCatalog.version,
    );
    DateTime date(dynamic v) {
      check(v is String && v.endsWith('Z'));
      return DateTime.parse(v).toUtc();
    }

    Map<String, String> localized(dynamic v) {
      final m = Map<String, String>.from(v as Map);
      check(
        m.keys.toSet().containsAll({'pt', 'en', 'es'}) &&
            m.values.every((s) => s.isNotEmpty && s.length <= 100),
      );
      return m;
    }

    final collections = <ContentCollection>[], ids = <String>{};
    check((j['collections'] as List).length <= 20);
    for (final c in j['collections']) {
      final product = CommercialCatalog.byId(c['product']);
      final items = List<String>.from(c['items']);
      final expected = PlayerCollectionCatalog.items
          .where((i) => i.collectionId == product?.collectionId)
          .map((i) => i.id)
          .toSet();
      final from = date(c['from']), until = date(c['until']);
      check(
        product?.kind == CommercialProductKind.permanentCollection &&
            items.length == 6 &&
            items.toSet().length == 6 &&
            expected.difference(items.toSet()).isEmpty &&
            items.toSet().difference(expected).isEmpty &&
            until.isAfter(from) &&
            ids.add(c['id']),
      );
      collections.add(
        ContentCollection(
          c['id'],
          product!.id,
          from,
          until,
          localized(c['name']),
          items,
        ),
      );
    }
    final assets = <ContentAsset>[];
    final itemIds = <String>{};
    var size = 0;
    check((j['assets'] as List).length <= 100);
    for (final a in j['assets']) {
      final item = PlayerCollectionCatalog.items
          .where((i) => i.id == a['item'])
          .firstOrNull;
      check(
        item != null &&
            itemIds.add(a['item']) &&
            a['sha256'] is String &&
            RegExp(r'^[a-f0-9]{64}$').hasMatch(a['sha256']) &&
            a['bytes'] is int &&
            a['bytes'] > 0 &&
            a['bytes'] <= 5 * 1024 * 1024 &&
            item.asset.endsWith('.${a['format']}'),
      );
      size += a['bytes'] as int;
      assets.add(ContentAsset(a['item'], a['sha256'], a['format'], a['bytes']));
    }
    check(
      size <= 30 * 1024 * 1024 &&
          itemIds.containsAll(
            PlayerCollectionCatalog.items
                .where(
                  (i) => j['min_catalog'] >= 4 || i.collectionId != 'weekly_v2',
                )
                .map((i) => i.id),
          ),
    );
    final cycles = Map<String, String>.from(j['club_cycles'] as Map);
    check(
      cycles.length <= 24 &&
          cycles.keys.every(
            (k) => RegExp(r'^20[0-9]{2}-(0[1-9]|1[0-2])$').hasMatch(k),
          ) &&
          cycles.values.every((p) => collections.any((c) => c.product == p)) &&
          cycles.values.toSet().length == cycles.length,
    );
    final events = <ContentEvent>[];
    final eventIds = <String>{};
    check((j['events'] as List).length <= 10);
    for (final e in j['events']) {
      final from = date(e['from']), until = date(e['until']);
      check(
        e['id'] is String &&
            RegExp(r'^[a-z0-9_]{1,64}$').hasMatch(e['id']) &&
            eventIds.add(e['id']) &&
            e['demo'] is bool &&
            e['authorized'] == true &&
            e['target'] is int &&
            e['target'] >= 1 &&
            e['target'] <= 10 &&
            itemIds.contains(e['reward']) &&
            until.isAfter(from),
      );
      events.add(
        ContentEvent(
          e['id'],
          e['reward'],
          e['demo'],
          localized(e['sponsor']),
          from,
          until,
          e['target'],
        ),
      );
    }
    return CommerceContent(j['revision'], collections, assets, events, cycles);
  }
  bool clubReady(DateTime now) {
    String month(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}';
    return cycles.containsKey(month(now.toUtc())) &&
        cycles.containsKey(month(DateTime.utc(now.year, now.month + 1)));
  }
}
