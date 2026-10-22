import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/challenge_code.dart';
import '../../l10n/release_legal_l10n.dart';
import '../l10n_mappers.dart';
import '../providers/monetization_notifier.dart';
import '../providers/reminder_notifier.dart';
import 'language_picker.dart';
import 'cineus_icon.dart';
import '../visuals/cineus_assets.dart';
import 'ad_privacy_options.dart';
import 'ticket_details_sheet.dart';

/// Application settings grouped independently from statistics.
class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.settingsPreferences,
          style: AppTypography.sectionTitle,
        ),
        const SizedBox(height: 12),
        const _PassCard(),
        const AdPrivacyOptions(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CineusIcon(CineusAssetId.privacy, size: 30),
          title: Text(
            context.l10n.playerDataTitle,
            style: AppTypography.titleMedium,
          ),
          trailing: const CineusIcon(CineusAssetId.chevron),
          onTap: () => context.push('/data'),
        ),
        ListTile(
          key: const ValueKey('settings-tickets'),
          contentPadding: EdgeInsets.zero,
          leading: const CineusIcon(CineusAssetId.ticket, size: 30),
          title: Text(
            context.l10n.earnTickets,
            style: AppTypography.titleMedium,
          ),
          trailing: const CineusIcon(CineusAssetId.chevron),
          onTap: () => showTicketDetails(context),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CineusIcon(CineusAssetId.badgeFirstWin, size: 30),
          title: Text(
            context.l10n.missionsTitle,
            style: AppTypography.titleMedium,
          ),
          trailing: const CineusIcon(CineusAssetId.chevron),
          onTap: () => context.push('/journey'),
        ),
        ListTile(
          key: const ValueKey('settings-collection'),
          contentPadding: EdgeInsets.zero,
          leading: const CineusIcon(CineusAssetId.premium, size: 30),
          title: Text(
            context.l10n.collectionTitle,
            style: AppTypography.titleMedium,
          ),
          trailing: const CineusIcon(CineusAssetId.chevron),
          onTap: () => context.push('/collection'),
        ),
        SizedBox(height: 20),
        const _ReminderToggle(),
        SizedBox(height: 20),
        const LanguagePicker(),
        SizedBox(height: 20),
        Text(
          context.l10n.settingsHelpSection,
          key: const ValueKey('settings-help'),
          style: AppTypography.sectionTitle,
        ),
        const SizedBox(height: 12),
        const _HelpLink(),
        SizedBox(height: 20),
        const _LegalLinks(),
      ],
    );
  }
}

/// Reusable entry point for a code received from another Cineus player.
///
/// Kept public so Home can make this social action discoverable without hiding
/// it below statistics/settings.
class ChallengeCodeOpener extends ConsumerStatefulWidget {
  final bool showHeading;

  const ChallengeCodeOpener({super.key, this.showHeading = true});

  @override
  ConsumerState<ChallengeCodeOpener> createState() =>
      _ChallengeCodeOpenerState();
}

class _ChallengeCodeOpenerState extends ConsumerState<ChallengeCodeOpener> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _invalid = false;
  bool _opening = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_opening) return;
    final target = ChallengeCode.parseInput(_controller.text);
    if (target == null) {
      setState(() => _invalid = true);
      _focusNode.requestFocus();
      return;
    }
    setState(() {
      _invalid = false;
      _opening = true;
    });
    _focusNode.unfocus();
    await context.push(
      '/challenge/${ChallengeCode.encode(target.movieId, mode: target.mode)}',
    );
    if (mounted) setState(() => _opening = false);
  }

  Future<void> _paste() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      final text = data?.text ?? '';
      if (text.isEmpty || text.length > 2048) {
        setState(() => _invalid = true);
        return;
      }
      _controller.text = text.trim();
      setState(() => _invalid = false);
    } catch (_) {
      if (mounted) setState(() => _invalid = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeading) ...[
          Text(
            l10n.challengeOpenTitle.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(15) > 20;
            final field = TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !_opening,
              textCapitalization: TextCapitalization.none,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.go,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: [LengthLimitingTextInputFormatter(2048)],
              style: AppTypography.mono.copyWith(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n.challengeInputLabel,
                hintText: l10n.challengeCodeHint,
                errorText: _invalid ? l10n.challengeInvalid : null,
              ),
              onChanged: (_) {
                if (_invalid) setState(() => _invalid = false);
              },
              onSubmitted: (_) => _open(),
            );
            final button = ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: ElevatedButton.icon(
                onPressed: _opening ? null : _open,
                icon: const CineusIcon(CineusAssetId.enter, size: 18),
                label: Text(l10n.challengeOpen),
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [field, const SizedBox(height: 10), button],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: field),
                const SizedBox(width: 10),
                button,
              ],
            );
          },
        ),
        TextButton.icon(
          onPressed: _opening ? null : _paste,
          icon: const CineusIcon(CineusAssetId.paste),
          label: Text(l10n.pasteChallenge),
        ),
      ],
    );
  }
}

class _ReminderToggle extends ConsumerWidget {
  const _ReminderToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(reminderNotifierProvider);
    final toggle = state.busy
        ? null
        : (bool value) =>
              ref.read(reminderNotifierProvider.notifier).toggle(value);
    final title = Text(
      l10n.reminderSettingTitle,
      style: AppTypography.titleSmall.copyWith(fontSize: 14),
    );
    final subtitle = Text(
      l10n.reminderSettingSubtitle,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
    );
    final leading = state.busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold300,
            ),
          )
        : const CineusIcon(CineusAssetId.clock, color: AppColors.gold300);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: AppColors.obsidian800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.obsidian600),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (MediaQuery.textScalerOf(context).scale(14) > 20) {
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: leading,
                        title: title,
                        subtitle: subtitle,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Semantics(
                          label: l10n.reminderSettingTitle,
                          child: Switch.adaptive(
                            value: state.enabled,
                            onChanged: toggle,
                            activeThumbColor: AppColors.gold300,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: state.enabled,
                  onChanged: toggle,
                  activeThumbColor: AppColors.gold300,
                  title: title,
                  subtitle: subtitle,
                  secondary: leading,
                );
              },
            ),
          ),
        ),
        if (state.hasError) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.reminderFailed,
              style: AppTypography.bodySmall.copyWith(color: AppColors.ruby300),
            ),
          ),
          TextButton.icon(
            key: const ValueKey('reminder-retry'),
            onPressed: state.busy
                ? null
                : () => ref.read(reminderNotifierProvider.notifier).retry(),
            icon: const CineusIcon(CineusAssetId.retry),
            label: Text(l10n.retryAction),
          ),
        ],
        if (state.permissionDenied) ...[
          const SizedBox(height: 6),
          Text(
            l10n.reminderDenied,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.ruby300,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _PassCard extends ConsumerWidget {
  const _PassCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monetizationNotifierProvider);
    if (state.isLoading || (!state.storeAvailable && !state.passActive)) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: state.passActive
            ? AppColors.goldDimGradient
            : AppColors.blueDimGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (state.passActive ? AppColors.gold300 : AppColors.blue300)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CineusIcon(
                state.passActive
                    ? CineusAssetId.premium
                    : CineusAssetId.modeClues,
                color: state.passActive ? AppColors.gold300 : AppColors.blue300,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.passTitle, style: AppTypography.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state.passActive ? l10n.passActive : l10n.passBody,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (!state.passActive && state.storeAvailable) ...[
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final buy = FilledButton(
                  onPressed: state.busy
                      ? null
                      : () => ref
                            .read(monetizationNotifierProvider.notifier)
                            .purchasePass(),
                  child: state.busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.passGet(state.passDisplayPrice ?? '')),
                );
                final restore = TextButton(
                  onPressed: state.busy
                      ? null
                      : () => ref
                            .read(monetizationNotifierProvider.notifier)
                            .restorePass(),
                  child: Text(l10n.passRestore),
                );

                if (constraints.maxWidth < 360) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [buy, restore],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: buy),
                    const SizedBox(width: 8),
                    restore,
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _HelpLink extends StatelessWidget {
  const _HelpLink();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      children: [
        _SettingsLink(
          icon: CineusAssetId.help,
          label: context.l10n.semHelp,
          onTap: () => context.push('/how-to-play'),
        ),
        const Divider(height: 1),
        _SettingsLink(
          icon: CineusAssetId.modeColors,
          label: context.l10n.colorGuideTitle,
          onTap: () => context.push('/how-to-play/colors'),
        ),
        const Divider(height: 1),
        _SettingsLink(
          icon: CineusAssetId.help,
          label: context.l10n.supportTitle,
          onTap: () => context.push('/support'),
        ),
      ],
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks();

  @override
  Widget build(BuildContext context) {
    final copy = ReleaseLegalL10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy.settingsSection.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        _SettingsCard(
          children: [
            _SettingsLink(
              icon: CineusAssetId.information,
              label: copy.aboutLabel,
              onTap: () => context.push('/about'),
            ),
            const Divider(height: 1),
            _SettingsLink(
              icon: CineusAssetId.privacy,
              label: copy.privacyLabel,
              onTap: () => context.push('/privacy'),
            ),
            const Divider(height: 1),
            _SettingsLink(
              icon: CineusAssetId.terms,
              label: copy.termsLabel,
              onTap: () => context.push('/terms'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.obsidian800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.obsidian600),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  final CineusAssetId icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 52,
      leading: CineusIcon(icon, color: AppColors.gold300, size: 20),
      title: Text(
        label,
        style: AppTypography.titleSmall.copyWith(fontSize: 13),
      ),
      trailing: const CineusIcon(
        CineusAssetId.chevron,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }
}
