import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/color_training_session.dart';
import '../../l10n/app_l10n.dart';
import '../providers/color_session_controller.dart';
import '../providers/providers.dart';
import '../providers/rewarded_help_provider.dart';
import '../providers/telemetry_provider.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';
import 'round_help_sheet.dart';

class ColorRoundHelpButton extends ConsumerWidget {
  final ColorSessionController controller;
  final String questionId;
  const ColorRoundHelpButton({
    super.key,
    required this.controller,
    required this.questionId,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final record = controller.record;
    return IconButton(
      key: const ValueKey('colors-use-hint'),
      tooltip: l.helpTitle,
      onPressed: controller.busy || controller.error != null
          ? null
          : () {
              final tickets = ref.read(ticketNotifierProvider.notifier);
              final telemetry = ref.read(productTelemetryProvider);
              showRoundHelp(
                context,
                gameKey: 'colors:${record.id}',
                options: [
                  RoundHelpOption(
                    id: 'guidance:$questionId',
                    title: l.helpColorGuidance,
                    detail: l.helpColorGuidanceBody,
                    asset: CineusAssetId.modeColors,
                    purchase: () => purchaseRoundHelp(tickets, () async {
                      final granted = await controller.act(
                        (game) => game.useGuidance(questionId),
                      );
                      if (granted) {
                        await telemetry.record(
                          'extra_hint_bought',
                          properties: {
                            'mode': 'colors',
                            'hint': 'guidance',
                            'ticket_cost': 1,
                          },
                        );
                      }
                      return granted;
                    }),
                  ),
                ],
                freeHint: () =>
                    controller.act((game) => game.useHint(questionId)),
              );
            },
      icon: const CineusIcon(CineusAssetId.help, size: 22),
    );
  }
}

/// A fixed suggestion based on the choice when help was requested. Moving the
/// sliders does not turn it into a live answer detector or expose exact HSB.
String colorRoundAdvice(AppL10n l, ColorTrainingSession game) {
  final source = game.guidanceAt!;
  final hsv = HSVColor.fromColor(Color(0xFF000000 | game.question.target.rgb));
  final family = hsv.saturation < .12
      ? l.helpFamilyNeutral
      : switch (hsv.hue) {
          < 15 || >= 345 => l.helpFamilyRed,
          < 45 => l.helpFamilyOrange,
          < 75 => l.helpFamilyYellow,
          < 165 => l.helpFamilyGreen,
          < 195 => l.helpFamilyCyan,
          < 255 => l.helpFamilyBlue,
          < 285 => l.helpFamilyPurple,
          _ => l.helpFamilyPink,
        };
  final brightness = hsv.value * 100 - source.brightness;
  final saturation = hsv.saturation * 100 - source.saturation;
  final adjustment = brightness > 8
      ? l.helpBrighter
      : brightness < -8
      ? l.helpDarker
      : saturation > 8
      ? l.helpMoreSaturation
      : saturation < -8
      ? l.helpLessSaturation
      : l.helpAdjustClose;
  return '${l.helpColorFamily(family)} $adjustment';
}
