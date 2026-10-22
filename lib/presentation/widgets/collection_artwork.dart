import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/commerce_content_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/player_collection.dart';
import '../../l10n/app_l10n.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_brand.dart';
import 'cineus_icon.dart';

String collectionItemName(AppL10n l, CollectionItem item) => switch (item.id) {
  'avatar_owl_v1' => l.collectionAvatarOwl,
  'avatar_fox_v1' => l.collectionAvatarFox,
  'frame_premiere_v1' => l.collectionFrameGold,
  'frame_blue_reel_v1' => l.collectionFrameBlue,
  'appearance_noir_v1' => l.collectionAppearanceNoir,
  'premiere_avatar_cat_v1' => l.collectionAvatarCat,
  'premiere_avatar_hare_v1' => l.collectionAvatarHare,
  'premiere_frame_marquee_v1' => l.collectionFrameMarquee,
  'premiere_frame_deco_v1' => l.collectionFrameDeco,
  'premiere_frame_spotlight_v1' => l.collectionFrameSpotlight,
  'premiere_appearance_velvet_v1' => l.collectionAppearanceVelvet,
  'mission_avatar_firefly_v1' => l.itemMissionFirefly,
  'mission_avatar_capybara_v1' => l.itemMissionCapybara,
  'mission_avatar_axolotl_v1' => l.itemMissionAxolotl,
  'mission_avatar_penguin_v1' => l.itemMissionPenguin,
  'mission_frame_projector_v1' => l.itemMissionProjector,
  'mission_appearance_constellation_v1' => l.itemMissionConstellation,
  'plus_frame_crown_v1' => l.itemPlusCrown,
  'plus_appearance_premiere_v1' => l.itemPlusPremiere,
  'night_avatar_raccoon_v1' => l.itemNightRaccoon,
  'night_avatar_otter_v1' => l.itemNightOtter,
  'night_frame_orbit_v1' => l.itemNightOrbit,
  'night_frame_comet_v1' => l.itemNightComet,
  'night_frame_observatory_v1' => l.itemNightObservatory,
  'night_appearance_sky_v1' => l.itemNightSky,
  'city_avatar_panda_v1' => l.itemCityPanda,
  'city_avatar_hummingbird_v1' => l.itemCityHummingbird,
  'city_frame_skyline_v1' => l.itemCitySkyline,
  'city_frame_bridge_v1' => l.itemCityBridge,
  'city_frame_rain_v1' => l.itemCityRain,
  'city_appearance_night_v1' => l.itemCityNight,
  'aurora_event_frame_v1' => l.itemAuroraFrame,
  _ => l.collectionUnavailable,
};

class CollectionArtwork extends ConsumerWidget {
  final CollectionItem item;
  final BoxFit fit;
  final bool frameOverlay;
  const CollectionArtwork(
    this.item, {
    super.key,
    this.fit = BoxFit.contain,
    this.frameOverlay = false,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = const Center(child: CineusIcon(CineusAssetId.error));
    final bytes = ref.watch(contentAssetBytesProvider(item.id)).asData?.value;
    if (bytes != null) {
      return ExcludeSemantics(
        child: item.asset.endsWith('.svg')
            ? SvgPicture.memory(
                bytes,
                fit: fit,
                errorBuilder: (_, __, ___) => fallback,
              )
            : Image.memory(
                bytes,
                fit: fit,
                scale: frameOverlay ? 2 : 1,
                centerSlice: frameOverlay
                    ? Rect.fromLTRB(
                        item.frameWidth * .2,
                        160,
                        item.frameWidth * .8,
                        640,
                      )
                    : null,
                errorBuilder: (_, __, ___) => fallback,
              ),
      );
    }
    return ExcludeSemantics(
      child: item.asset.endsWith('.svg')
          ? SvgPicture.asset(
              item.asset,
              fit: fit,
              placeholderBuilder: (_) => const SizedBox.shrink(),
              errorBuilder: (_, error, stack) => fallback,
            )
          : Image.asset(
              item.asset,
              cacheWidth: item.kind == CollectionItemKind.avatar ? 512 : null,
              scale: frameOverlay ? 2 : 1,
              centerSlice: frameOverlay
                  ? Rect.fromLTRB(
                      item.frameWidth * .2,
                      160,
                      item.frameWidth * .8,
                      640,
                    )
                  : null,
              fit: fit,
              errorBuilder: (_, error, stack) => fallback,
            ),
    );
  }
}

/// The exact same decorative surface surrounds live preview and exported data.
/// Ornament stays outside a padded content area; layout grows with text scaling.
class CollectionCardSurface extends StatelessWidget {
  final CollectionLook? look;
  final List<Widget> children;
  final double identityAvatarSize;
  const CollectionCardSurface({
    super.key,
    this.look,
    required this.children,
    this.identityAvatarSize = 44,
  });
  @override
  Widget build(BuildContext context) {
    final style =
        look ?? CollectionLook.resolve(null, PlayerCollectionCatalog.items);
    return LayoutBuilder(
      builder: (context, constraints) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxWidth * 1.25),
          child: Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: AppColors.obsidian950),
              ),
              if (style.appearance != null)
                Positioned.fill(
                  child: CollectionArtwork(
                    style.appearance!,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(36, 36, 36, 72),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...children,
                    if (style.showIdentity) ...[
                      const SizedBox(height: 20),
                      if (style.avatar != null)
                        Center(
                          child: SizedBox.square(
                            dimension: identityAvatarSize,
                            child: CollectionArtwork(style.avatar!),
                          ),
                        ),
                      if (style.displayName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          style.displayName,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (style.frame != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CollectionArtwork(
                      style.frame!,
                      fit: BoxFit.fill,
                      frameOverlay: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collection-only preview. Result personalization supplies the real card instead.
class CollectionPreview extends StatelessWidget {
  final PlayerCollection profile;
  final List<CollectionItem> catalog;
  final CollectionItem? candidate;
  final Map<CollectionItemKind, String> preview;
  const CollectionPreview({
    super.key,
    required this.profile,
    required this.catalog,
    this.candidate,
    this.preview = const {},
  });
  @override
  Widget build(BuildContext context) {
    final style = CollectionLook.resolve(
      profile,
      catalog,
      preview: {
        ...preview,
        if (candidate != null) candidate!.kind: candidate!.id,
      },
    );
    return Semantics(
      label: AppL10n.of(context).collectionPreview,
      child: CollectionCardSurface(
        look: style,
        identityAvatarSize: 160,
        children: const [
          Center(
            child: CineusWordmark(
              fontSize: 26,
              showSymbol: true,
              symbolSize: 30,
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
