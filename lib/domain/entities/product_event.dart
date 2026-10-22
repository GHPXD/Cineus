import 'player_collection.dart';

/// Explicit schemas keep guesses, names and receipt tokens out of diagnostics.
abstract final class ProductEvents {
  static const _fields = <String, Set<String>>{
    'app_active': {},
    'tutorial_completed': {'mode'},
    'game_opened': {'mode', 'kind'},
    'game_completed': {
      'mode',
      'kind',
      'outcome',
      'score',
      'score_cents',
      'revealed_steps',
    },
    'daily_opened': {'mode'},
    'extra_hint_bought': {'mode', 'hint', 'ticket_cost'},
    'rewarded_help_delivered': {'outcome'},
    'tickets_insufficient': {'requested'},
    'rewarded_requested': {},
    'ad_available': {'placement'},
    'ad_load_started': {'placement'},
    'ad_load_failed': {'placement'},
    'video_completed': {},
    'reward_verification_pending': {},
    'ad_shown': {'placement'},
    'ad_value': {'placement', 'currency', 'value_micros', 'precision'},
    'reward_credit_delivered': {'amount'},
    'rewarded_completed': {'reward', 'amount'},
    'pass_purchase_started': {},
    'pass_entitlement_active': {},
    'pass_restore_started': {},
    'collection_opened': {},
    'item_previewed': {'product_id', 'item_id'},
    'collection_item_equipped': {'item_id'},
    'purchase_started': {'product_id'},
    'purchase_verified': {'product_id'},
    'purchase_restored': {'product_id'},
    'purchase_revoked': {'product_id'},
    'mission_claimed': {'amount'},
    'experiment_exposed': {'variant'},
    'archive_opened': {'mode'},
    'invite_created': {'mode'},
    'invite_joined': {'mode'},
    'backup_saved': {},
    'backup_restored': {},
  };
  static final _strings = <String, Set<String>>{
    'item_id': {
      ...PlayerCollectionCatalog.items.map((i) => i.id),
      'avatar_owl_v1',
      'avatar_fox_v1',
      'frame_premiere_v1',
      'frame_blue_reel_v1',
      'appearance_noir_v1',
      'premiere_avatar_cat_v1',
      'premiere_avatar_hare_v1',
      'premiere_frame_marquee_v1',
      'premiere_frame_deco_v1',
      'premiere_frame_spotlight_v1',
      'premiere_appearance_velvet_v1',
    },
    'mode': {'clue', 'poster', 'colors'},
    'kind': {'daily', 'stage', 'challenge', 'training', 'archive'},
    'outcome': {'won', 'lost', 'finished', 'help_and_ticket', 'tickets'},
    'hint': {'director', 'year', 'runtime', 'guidance'},
    'reward': {'tickets'},
    'placement': {'rewarded', 'interstitial', 'banner', 'native'},
    'variant': {'control', 'economy_v2'},
    'product_id': {
      'cineus.tickets.20.v1',
      'cineus.tickets.60.v1',
      'cineus.collection.premiere.v1',
      'cineus.plus.permanent.v1',
      'cineus.club.monthly.v1',
      'cineus.collection.night.v1',
      'cineus.collection.city.v1',
    },
    'currency': {'BRL', 'USD', 'EUR'},
    'precision': {'unknown', 'estimated', 'publisherProvided', 'precise'},
  };

  static Map<String, Object?>? sanitize(
    String event,
    Map<String, Object?> input,
  ) {
    final fields = _fields[event];
    if (fields == null) return null;
    return {
      for (final entry in input.entries)
        if (fields.contains(entry.key) && _valid(entry.key, entry.value))
          entry.key: entry.value,
    };
  }

  static bool _valid(String key, Object? value) {
    if (key == 'value_micros') {
      return value is int && value >= 0 && value <= 1000000000000;
    }
    if (_strings.containsKey(key)) return _strings[key]!.contains(value);
    return value is int && value >= 0 && value <= 1000;
  }
}
