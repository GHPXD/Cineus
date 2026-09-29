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
