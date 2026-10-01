/// Monetization rules are deliberately separated from gameplay rules.
///
/// Cineus remains fully playable without payment. Monetization can only add
/// convenience/cosmetics or exchange an explicitly opted-in rewarded ad for a
/// small ticket grant.
abstract final class MonetizationPolicy {
  static const int rewardedTicketAmount = 2;
  static const int rewardedDailyLimit = 3;

  /// A Pass must never be required to access Daily, Poster, stages, friend
  /// challenges, achievements or the bundled catalogue.
  static const bool coreGameplayAlwaysFree = true;

  /// Rewarded ads are always initiated by the player.
  static const bool rewardedAdsAreOptional = true;

  /// If non-rewarded ad placements are introduced later, an active Pass
  /// suppresses them. Opt-in rewarded ads remain a player choice.
  static bool shouldShowNonRewardedAds({required bool passActive}) =>
      !passActive;
}

class PassEntitlement {
  final bool storeAvailable;
  final bool active;
  final String? displayPrice;

  const PassEntitlement({
    this.storeAvailable = false,
    this.active = false,
    this.displayPrice,
  });
}
