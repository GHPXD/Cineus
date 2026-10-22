enum CollectionItemKind { avatar, frame, appearance }

class CollectionItem {
  final String id, asset;
  final CollectionItemKind kind;
  final bool starter;
  final double frameWidth;
  final String? collectionId;
  const CollectionItem({
    required this.id,
    required this.asset,
    required this.kind,
    this.starter = false,
    this.frameWidth = 640,
    this.collectionId,
  });
}

abstract final class PlayerCollectionCatalog {
  static const version = 6;
  static const premiereId = 'premiere_v1';
  static const items = [
    CollectionItem(
      id: 'mission_avatar_capybara_v1',
      asset: 'assets/collection/cinema_pilot.png',
      kind: CollectionItemKind.avatar,
      collectionId: 'weekly_v2',
    ),
    CollectionItem(
      id: 'mission_avatar_axolotl_v1',
      asset: 'assets/collection/cinema_archaeologist.png',
      kind: CollectionItemKind.avatar,
      collectionId: 'weekly_v2',
    ),
    CollectionItem(
      id: 'mission_avatar_penguin_v1',
      asset: 'assets/collection/cinema_creature.png',
      kind: CollectionItemKind.avatar,
      collectionId: 'weekly_v2',
    ),
    CollectionItem(
      id: 'night_avatar_raccoon_v1',
      asset: 'assets/collection/cinema_cartographer.png',
      kind: CollectionItemKind.avatar,
      collectionId: 'night_v1',
    ),
    CollectionItem(
      id: 'night_avatar_otter_v1',
      asset: 'assets/collection/cinema_archivist.png',
      kind: CollectionItemKind.avatar,
      collectionId: 'night_v1',
    ),
    CollectionItem(
      id: 'night_frame_orbit_v1',
      asset: 'assets/collection/night_frame_orbit.png',
      kind: CollectionItemKind.frame,
      collectionId: 'night_v1',
    ),
    CollectionItem(
      id: 'night_frame_comet_v1',
      asset: 'assets/collection/night_frame_comet.png',
      kind: CollectionItemKind.frame,
      collectionId: 'night_v1',
    ),
    CollectionItem(
      id: 'night_frame_observatory_v1',
      asset: 'assets/collection/night_frame_observatory.png',
      kind: CollectionItemKind.frame,
      collectionId: 'night_v1',
    ),
    CollectionItem(
      id: 'night_appearance_sky_v1',
      asset: 'assets/collection/night_appearance_sky.png',
      kind: CollectionItemKind.appearance,
      collectionId: 'night_v1',
    ),
    CollectionItem(
      id: 'city_avatar_panda_v1',
      asset: 'assets/collection/cinema_courier.png',
      kind: CollectionItemKind.avatar,
      collectionId: 'city_v1',
    ),
    CollectionItem(
      id: 'city_avatar_hummingbird_v1',
      asset: 'assets/collection/cinema_director.png',
      kind: CollectionItemKind.avatar,
      collectionId: 'city_v1',
    ),
    CollectionItem(
      id: 'city_frame_skyline_v1',
      asset: 'assets/collection/city_frame_skyline.png',
      kind: CollectionItemKind.frame,
      collectionId: 'city_v1',
    ),
    CollectionItem(
      id: 'city_frame_bridge_v1',
      asset: 'assets/collection/city_frame_bridge.png',
      kind: CollectionItemKind.frame,
      collectionId: 'city_v1',
    ),
    CollectionItem(
      id: 'city_frame_rain_v1',
      asset: 'assets/collection/city_frame_rain.png',
      kind: CollectionItemKind.frame,
      collectionId: 'city_v1',
    ),
    CollectionItem(
      id: 'city_appearance_night_v1',
      asset: 'assets/collection/city_appearance_night.png',
      kind: CollectionItemKind.appearance,
      collectionId: 'city_v1',
    ),
    CollectionItem(
      id: 'aurora_event_frame_v1',
      asset: 'assets/collection/aurora_event_frame.png',
      kind: CollectionItemKind.frame,
      collectionId: 'event_aurora_v1',
    ),
    CollectionItem(
      id: 'mission_avatar_firefly_v1',
      asset: 'assets/collection/cinema_editor.png',
      kind: CollectionItemKind.avatar,
      collectionId: 'weekly_v1',
    ),
    CollectionItem(
      id: 'mission_frame_projector_v1',
      asset: 'assets/collection/mission_frame_projector.png',
      kind: CollectionItemKind.frame,
      collectionId: 'weekly_v1',
      frameWidth: 533,
    ),
    CollectionItem(
      id: 'mission_appearance_constellation_v1',
      asset: 'assets/collection/mission_appearance_constellation.png',
      kind: CollectionItemKind.appearance,
      collectionId: 'weekly_v1',
    ),
    CollectionItem(
      id: 'plus_frame_crown_v1',
      asset: 'assets/collection/plus_frame_crown.png',
      kind: CollectionItemKind.frame,
      collectionId: 'plus_v1',
      frameWidth: 533,
    ),
    CollectionItem(
      id: 'plus_appearance_premiere_v1',
      asset: 'assets/collection/plus_appearance_premiere.png',
      kind: CollectionItemKind.appearance,
      collectionId: 'plus_v1',
    ),
    CollectionItem(
      id: 'avatar_owl_v1',
      asset: 'assets/collection/cinema_projectionist.png',
      kind: CollectionItemKind.avatar,
      starter: true,
    ),
    CollectionItem(
      id: 'avatar_fox_v1',
      asset: 'assets/collection/cinema_detective.png',
      kind: CollectionItemKind.avatar,
      starter: true,
    ),
    CollectionItem(
      id: 'frame_premiere_v1',
      asset: 'assets/collection/frame_premiere.png',
      kind: CollectionItemKind.frame,
      starter: true,
    ),
    CollectionItem(
      id: 'frame_blue_reel_v1',
      asset: 'assets/collection/frame_blue_reel.png',
      kind: CollectionItemKind.frame,
      starter: true,
    ),
    CollectionItem(
      id: 'appearance_noir_v1',
      asset: 'assets/collection/appearance_noir.png',
      kind: CollectionItemKind.appearance,
      starter: true,
    ),
    CollectionItem(
      id: 'premiere_avatar_cat_v1',
      asset: 'assets/collection/cinema_robot.png',
      kind: CollectionItemKind.avatar,
      collectionId: premiereId,
    ),
    CollectionItem(
      id: 'premiere_avatar_hare_v1',
      asset: 'assets/collection/cinema_knight.png',
      kind: CollectionItemKind.avatar,
      collectionId: premiereId,
    ),
    CollectionItem(
      id: 'premiere_frame_marquee_v1',
      asset: 'assets/collection/premiere_frame_marquee.png',
      kind: CollectionItemKind.frame,
      collectionId: premiereId,
    ),
    CollectionItem(
      id: 'premiere_frame_deco_v1',
      asset: 'assets/collection/premiere_frame_deco.png',
      kind: CollectionItemKind.frame,
      collectionId: premiereId,
    ),
    CollectionItem(
      id: 'premiere_frame_spotlight_v1',
      asset: 'assets/collection/premiere_frame_spotlight.png',
      kind: CollectionItemKind.frame,
      collectionId: premiereId,
    ),
    CollectionItem(
      id: 'premiere_appearance_velvet_v1',
      asset: 'assets/collection/premiere_appearance_velvet.png',
      kind: CollectionItemKind.appearance,
      collectionId: premiereId,
    ),
  ];

  static Map<CollectionItemKind, String> get premierePreview => {
    for (final kind in CollectionItemKind.values)
      kind: items
          .firstWhere((i) => i.kind == kind && i.collectionId == premiereId)
          .id,
  };
}

/// Preview overrides are ephemeral and may include unowned items. Export callers
/// omit them: only owned equipment (or a free fallback) can reach a shared card.
class CollectionLook {
  final CollectionItem? avatar, frame, appearance;
  final String displayName;
  final bool showIdentity;
  const CollectionLook({
    this.avatar,
    this.frame,
    this.appearance,
    this.displayName = '',
    this.showIdentity = false,
  });
  factory CollectionLook.resolve(
    PlayerCollection? profile,
    List<CollectionItem> catalog, {
    Map<CollectionItemKind, String> preview = const {},
  }) {
    CollectionItem? pick(CollectionItemKind kind) {
      final candidates = catalog.where((i) => i.kind == kind);
      final proposed = candidates
          .where((i) => i.id == preview[kind])
          .firstOrNull;
      if (proposed != null) return proposed;
      return candidates
              .where(
                (i) =>
                    i.id == profile?.equipped[kind] &&
                    (profile?.owned.contains(i.id) ?? false),
              )
              .firstOrNull ??
          candidates.where((i) => i.starter).firstOrNull;
    }

    return CollectionLook(
      avatar: pick(CollectionItemKind.avatar),
      frame: pick(CollectionItemKind.frame),
      appearance: pick(CollectionItemKind.appearance),
      displayName: profile?.displayName ?? '',
      showIdentity: profile?.showIdentity ?? false,
    );
  }
  Iterable<CollectionItem> get artwork sync* {
    if (frame != null) yield frame!;
    if (appearance != null) yield appearance!;
    if (showIdentity && avatar != null) yield avatar!;
  }
}

class PlayerCollection {
  final String displayName;
  final bool showIdentity;
  final Set<String> owned;
  final Map<CollectionItemKind, String> equipped;
  PlayerCollection({
    required this.displayName,
    required this.showIdentity,
    required Set<String> owned,
    required Map<CollectionItemKind, String> equipped,
  }) : owned = Set.unmodifiable(owned),
       equipped = Map.unmodifiable(equipped);
}
