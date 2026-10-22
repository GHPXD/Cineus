import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/mobile_ads_service.dart';
import '../../l10n/app_l10n.dart';
import '../providers/monetization_notifier.dart';
import '../providers/commercial_provider.dart';
import '../providers/providers.dart';
import '../providers/app_clock.dart';
import '../../domain/entities/commercial_product.dart';

class AdPrivacyOptions extends ConsumerWidget {
  const AdPrivacyOptions({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(monetizationServiceProvider);
    if (service is! VerifiedMobileAdsService) return const SizedBox.shrink();
    final rights = ref.watch(commercialEntitlementsProvider).asData?.value;
    final paid =
        rights?.any(
          (e) => e.grants(
            CommercialBenefit.removeInterruptions,
            ref.read(appClockProvider)(),
          ),
        ) ??
        false;
    return Column(
      children: [
        if (paid)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppL10n.of(context).commerceHideRewarded),
            value: ref.watch(hideVideoOffersProvider).asData?.value ?? false,
            onChanged: (value) async {
              await ref
                  .read(appMetaRepositoryProvider)
                  .write('hide_optional_video_offers', value ? '1' : '0');
              ref.invalidate(hideVideoOffersProvider);
            },
          ),
        FutureBuilder<bool>(
          future: service.privacyOptionsRequired(),
          builder: (context, state) => state.data != true
              ? const SizedBox.shrink()
              : TextButton(
                  onPressed: () async {
                    await service.showPrivacyOptions();
                    await ref
                        .read(monetizationNotifierProvider.notifier)
                        .load();
                  },
                  child: Text(AppL10n.of(context).commercePrivacy),
                ),
        ),
      ],
    );
  }
}
