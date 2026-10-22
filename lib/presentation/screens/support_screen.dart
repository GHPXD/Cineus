import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_typography.dart';
import '../l10n_mappers.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/support_card.dart';

class SupportScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const SupportScreen({super.key, this.onBack});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: context.l10n.semBack,
                    onPressed:
                        onBack ??
                        () => context.canPop()
                            ? context.pop()
                            : context.go('/home'),
                    icon: const CineusIcon(CineusAssetId.back),
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.supportTitle,
                      style: AppTypography.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SupportCard(),
            ],
          ),
        ),
      ),
    ),
  );
}
