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

/// Application settings grouped independently from statistics.
class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PassCard(),
        SizedBox(height: 20),
        _ReminderToggle(),
        SizedBox(height: 20),
        LanguagePicker(),
        SizedBox(height: 20),
        _HelpLink(),
        SizedBox(height: 20),
        _LegalLinks(),
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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _open() {
    final movieId = ChallengeCode.decode(_controller.text);
    if (movieId == null) {
      setState(() => _invalid = true);
      _focusNode.requestFocus();
      return;
    }
    setState(() => _invalid = false);
    _controller.clear();
    context.push('/challenge/$movieId');
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
            final compact = constraints.maxWidth < 360;
            final field = TextField(
              controller: _controller,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.go,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z\-]')),
                LengthLimitingTextInputFormatter(12),
              ],
              style: AppTypography.mono.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.challengeCodeHint,
                errorText: _invalid ? l10n.challengeInvalid : null,
              ),
              onChanged: (_) {
                if (_invalid) setState(() => _invalid = false);
              },
              onSubmitted: (_) => _open(),
            );
            final button = SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _open,
                icon: const Icon(Icons.login_rounded, size: 18),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: state.enabled,
            onChanged: state.busy
                ? null
                : (value) =>
                    ref.read(reminderNotifierProvider.notifier).toggle(value),
            activeThumbColor: AppColors.gold300,
            title: Text(
              l10n.reminderSettingTitle,
              style: AppTypography.titleSmall.copyWith(fontSize: 14),
            ),
            subtitle: Text(
              l10n.reminderSettingSubtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            secondary: state.busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gold300,
                    ),
                  )
                : const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.gold300,
                  ),
          ),
        ),
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
              Icon(
                state.passActive
                    ? Icons.workspace_premium_rounded
                    : Icons.local_movies_outlined,
                color:
                    state.passActive ? AppColors.gold300 : AppColors.blue300,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.passTitle,
                  style: AppTypography.titleMedium,
                ),
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
                      : Text(
                          l10n.passGet(state.passDisplayPrice ?? ''),
                        ),
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
          icon: Icons.help_outline_rounded,
          label: context.l10n.semHelp,
          onTap: () => context.push('/how-to-play'),
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
              icon: Icons.info_outline_rounded,
              label: copy.aboutLabel,
              onTap: () => context.push('/about'),
            ),
            const Divider(height: 1),
            _SettingsLink(
              icon: Icons.privacy_tip_outlined,
              label: copy.privacyLabel,
              onTap: () => context.push('/privacy'),
            ),
            const Divider(height: 1),
            _SettingsLink(
              icon: Icons.gavel_outlined,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  final IconData icon;
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
      leading: Icon(icon, color: AppColors.gold300, size: 20),
      title: Text(label, style: AppTypography.titleSmall.copyWith(fontSize: 13)),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }
}