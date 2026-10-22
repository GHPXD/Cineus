import '../../domain/entities/commercial_configuration.dart';
import '../../domain/entities/monetization.dart';
import '../../domain/services/monetization_service.dart';

/// Legacy integration boundary. Permanent Plus and Club will use distinct
/// products; the old untyped Pass cannot be offered as either product.
class ConfiguredMonetizationService
    implements MonetizationService, ServerCreditedRewards {
  final CommercialConfiguration configuration;
  final MonetizationService delegate;
  const ConfiguredMonetizationService(this.configuration, this.delegate);
  @override
  bool get creditsRewards =>
      delegate is ServerCreditedRewards &&
      (delegate as ServerCreditedRewards).creditsRewards;
  @override
  int get confirmedUsedToday => creditsRewards
      ? (delegate as ServerCreditedRewards).confirmedUsedToday
      : 0;

  @override
  Future<void> initialize() async {
    if (configuration.rewarded) await delegate.initialize();
  }

  @override
  Future<bool> isRewardedAvailable() async =>
      configuration.rewarded && await delegate.isRewardedAvailable();
  @override
  Future<bool> showRewarded() async =>
      configuration.rewarded && await delegate.showRewarded();
  @override
  Future<PassEntitlement> loadPassEntitlement() async =>
      const PassEntitlement();
  @override
  Future<void> purchasePass() async {}
  @override
  Future<void> restorePass() async {}
}
