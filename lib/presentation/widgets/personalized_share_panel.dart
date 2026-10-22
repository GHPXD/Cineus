import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/player_collection.dart';
import '../../l10n/app_l10n.dart';
import '../providers/player_collection_provider.dart';
import '../providers/result_share_service.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';
import 'result_card_capture.dart';
import 'result_card_personalize.dart';
import 'result_share_card.dart';

/// One sharing flow for all three modes. Preview and PNG use the same boundary.
class PersonalizedSharePanel extends ConsumerStatefulWidget {
  final Widget Function(CollectionLook) cardBuilder;
  final String text;
  final int? movieId;
  final bool colors;
  final ResultShareData? neutralData;
  const PersonalizedSharePanel({
    super.key,
    required this.cardBuilder,
    required this.text,
    this.movieId,
    this.colors = false,
    this.neutralData,
  });
  @override
  ConsumerState<PersonalizedSharePanel> createState() =>
      _PersonalizedSharePanelState();
}

class _PersonalizedSharePanelState
    extends ConsumerState<PersonalizedSharePanel> {
  final _card = GlobalKey();
  bool _busy = false;
  bool _neutral = false;
  String? _error;
  Future<void> _perform(
    BuildContext anchor,
    CollectionLook look, {
    bool image = false,
    bool copy = false,
  }) async {
    if (_busy) return;
    final l = AppL10n.of(context);
    final service = ref.read(resultShareServiceProvider);
    final box = anchor.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (copy) {
        await service.copy(widget.text);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.resultCopied)));
        }
      } else {
        final png = image
            ? await captureResultCard(
                _card,
                context,
                look,
                movieId: _neutral ? null : widget.movieId,
              )
            : null;
        if (!mounted) return;
        final status = await service.share(widget.text, origin, png: png);
        if (!mounted) return;
        if (status == ShareResultStatus.unavailable) {
          setState(() => _error = l.shareFailed);
        }
        if (status == ShareResultStatus.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.resultShared)));
        }
      }
    } catch (_) {
      if (mounted) setState(() => _error = copy ? l.copyFailed : l.shareFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final state = ref.watch(playerCollectionProvider);
    final look = CollectionLook.resolve(
      state.profile,
      ref.watch(collectionCatalogProvider),
    );
    final disabled = _busy || state.loading || state.saving;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: SingleChildScrollView(
          key: ValueKey(
            widget.colors ? 'colors-share-scroll' : 'share-result-scroll',
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.shareCardTitle, style: AppTypography.titleLarge),
              if (widget.neutralData != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.neutralCard),
                  value: _neutral,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _neutral = value),
                ),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: RepaintBoundary(
                    key: _card,
                    child: _neutral
                        ? ResultShareCard(
                            data: widget.neutralData!,
                            look: look,
                            revealMovie: false,
                          )
                        : widget.cardBuilder(look),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (state.loading) const LinearProgressIndicator(),
              if (state.hasError)
                TextButton(
                  onPressed: disabled
                      ? null
                      : () =>
                            ref.read(playerCollectionProvider.notifier).load(),
                  child: Text(l.collectionLoadFailed),
                ),
              if (_error != null)
                Text(
                  _error!,
                  key: ValueKey(
                    widget.colors ? 'colors-share-error' : 'share-result-error',
                  ),
                  style: AppTypography.bodySmall,
                ),
              Builder(
                builder: (anchor) => FilledButton.icon(
                  key: ValueKey(
                    widget.colors ? 'colors-share-image' : 'share-result-image',
                  ),
                  onPressed: disabled
                      ? null
                      : () => _perform(anchor, look, image: true),
                  icon: const CineusIcon(
                    CineusAssetId.share,
                    color: AppColors.obsidian900,
                  ),
                  label: Text(l.shareImage),
                ),
              ),
              const SizedBox(height: 8),
              ResultCardPersonalize(
                cardBuilder: widget.cardBuilder,
                enabled: !disabled,
              ),
              if (widget.colors) ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (anchor) => OutlinedButton.icon(
                    key: const ValueKey('colors-share-text'),
                    onPressed: disabled ? null : () => _perform(anchor, look),
                    icon: const CineusIcon(CineusAssetId.share, size: 20),
                    label: Text(l.colorShareText),
                  ),
                ),
                Builder(
                  builder: (anchor) => TextButton.icon(
                    key: const ValueKey('colors-copy-text'),
                    onPressed: disabled
                        ? null
                        : () => _perform(anchor, look, copy: true),
                    icon: const CineusIcon(CineusAssetId.copy, size: 20),
                    label: Text(l.copyResultText),
                  ),
                ),
              ],
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: Text(l.back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
