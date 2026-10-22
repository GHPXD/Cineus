import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../l10n_mappers.dart';
import '../providers/external_links.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';

class SupportCard extends ConsumerStatefulWidget {
  const SupportCard({super.key});
  @override
  ConsumerState<SupportCard> createState() => _SupportCardState();
}

class _SupportCardState extends ConsumerState<SupportCard> {
  bool _busy = false;
  String? _message;
  bool _error = false;
  Future<void> _action(bool copy) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final service = ref.read(externalLinksProvider);
    final l = context.l10n;
    try {
      final bool success;
      if (copy) {
        await service.copySupport();
        success = true;
      } else {
        success = await service.openSupport();
      }
      if (!mounted) return;
      setState(() {
        _error = !success;
        _message = copy
            ? l.supportCopied
            : success
            ? null
            : l.supportOpenFailed;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _message = copy ? l.supportCopyFailed : l.supportOpenFailed;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.obsidian800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.obsidian600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.supportTitle, style: AppTypography.titleMedium),
          const SizedBox(height: 10),
          Text(l.supportBody, style: AppTypography.bodySmall),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            key: const ValueKey('support-open'),
            onPressed: _busy ? null : () => _action(false),
            icon: const CineusIcon(CineusAssetId.help),
            label: Text(l.supportOpen),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('support-copy'),
            onPressed: _busy ? null : () => _action(true),
            icon: const CineusIcon(CineusAssetId.copy),
            label: Text(l.supportCopy),
          ),
          const SizedBox(height: 14),
          SelectableText(
            PlatformExternalLinks.supportUrl,
            style: AppTypography.bodySmall.copyWith(color: AppColors.blue300),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                _message!,
                style: AppTypography.bodySmall.copyWith(
                  color: _error ? AppColors.ruby300 : AppColors.success400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
