import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/challenge_code.dart';
import '../l10n_mappers.dart';
import '../providers/reminder_notifier.dart';
import 'language_picker.dart';

/// Settings block at the bottom of the statistics screen: language, the daily
/// reminder (D4) and opening a challenge code (D10).
class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReminderToggle(),
        SizedBox(height: 20),
        _ChallengeOpener(),
        SizedBox(height: 20),
        LanguagePicker(),
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
            // Flipping this is what triggers the OS permission prompt — the app
            // never asks unprompted.
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
              style: AppTypography.bodySmall.copyWith(fontSize: 11),
            ),
          ),
        ),
        if (state.permissionDenied) ...[
          const SizedBox(height: 6),
          Text(
            l10n.reminderDenied,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.ruby300,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

class _ChallengeOpener extends ConsumerStatefulWidget {
  const _ChallengeOpener();

  @override
  ConsumerState<_ChallengeOpener> createState() => _ChallengeOpenerState();
}

class _ChallengeOpenerState extends ConsumerState<_ChallengeOpener> {
  final _controller = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    final movieId = ChallengeCode.decode(_controller.text);
    if (movieId == null) {
      setState(() => _invalid = true);
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
        Text(
          l10n.challengeOpenTitle.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  // The code alphabet plus the separator; anything else is noise.
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z\-]')),
                  LengthLimitingTextInputFormatter(12),
                ],
                style: AppTypography.mono.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: l10n.challengeCodeHint,
                  isDense: true,
                  errorText: _invalid ? l10n.challengeInvalid : null,
                ),
                onChanged: (_) {
                  if (_invalid) setState(() => _invalid = false);
                },
                onSubmitted: (_) => _open(),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _open,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold300,
                foregroundColor: AppColors.obsidian900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(l10n.challengeOpen),
            ),
          ],
        ),
      ],
    );
  }
}
