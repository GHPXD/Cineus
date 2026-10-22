import '../entities/monetization.dart';

/// Platform/store seam for ads and the Cineus Pass.
///
/// The default app uses a disabled implementation until real App Store / Google
/// Play product IDs and ad-unit IDs are supplied. This keeps gameplay and CI
/// independent from monetization credentials.
abstract class MonetizationService {
  Future<void> initialize();

  Future<bool> isRewardedAvailable();

  /// Returns true only after the ad SDK confirms the reward callback.
  Future<bool> showRewarded();

  Future<PassEntitlement> loadPassEntitlement();

  Future<void> purchasePass();

  Future<void> restorePass();
}

/// Marker for adapters whose boolean confirms a server receipt already credited
/// atomically. Callers must never credit a second time from the SDK callback.
abstract interface class ServerCreditedRewards {
  bool get creditsRewards;
  int get confirmedUsedToday;
}

/// Persists the server attempt before the ad opens. A delayed signed receipt can
/// then recover the same help after a process restart without showing a new ad.
abstract interface class TrackedRewardedAds {
  Future<bool> showRewardedTracked(
    Future<void> Function(String attempt) started,
  );
  bool get rewardPending;
}
