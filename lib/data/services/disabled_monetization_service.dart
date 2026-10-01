import '../../domain/entities/monetization.dart';
import '../../domain/services/monetization_service.dart';

/// Safe production fallback.
///
/// No placeholder/test ad or fake purchase entitlement is ever exposed to real
/// users. A real adapter can override the provider once store/ad credentials are
/// configured for the release environment.
class DisabledMonetizationService implements MonetizationService {
  const DisabledMonetizationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isRewardedAvailable() async => false;

  @override
  Future<bool> showRewarded() async => false;

  @override
  Future<PassEntitlement> loadPassEntitlement() async =>
      const PassEntitlement();

  @override
  Future<void> purchasePass() async {}

  @override
  Future<void> restorePass() async {}
}
