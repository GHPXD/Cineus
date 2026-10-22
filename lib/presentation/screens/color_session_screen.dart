import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/color_repository.dart';
import '../../domain/entities/color_scoring.dart';
import '../../domain/entities/color_training_session.dart';
import '../../domain/entities/color_question.dart';
import '../../l10n/app_l10n.dart';
import '../providers/app_clock.dart';
import '../providers/color_providers.dart';
import '../providers/color_session_controller.dart';
import '../providers/telemetry_provider.dart';
import '../providers/game_actions.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/cineus_state_art.dart';
import 'color_training_screen.dart';
import 'color_tutorial_screen.dart';
import '../widgets/color_result_actions.dart';

class ColorSessionScreen extends ConsumerStatefulWidget {
  final ColorSessionKind kind;
  final String? sessionId;
  const ColorSessionScreen({
    super.key,
    this.kind = ColorSessionKind.training,
    this.sessionId,
  });
  @override
  ConsumerState<ColorSessionScreen> createState() => _ColorSessionScreenState();
}

class _ColorSessionScreenState extends ConsumerState<ColorSessionScreen> {
  late Future<ColorSessionController?> _loading;
  ColorSessionController? _controller;
  bool _guideRequired = false;
  ColorPilotCatalog? _guideCatalog;
  String? _publishedId;
  int? _publishedRevision;

  void _publishCommittedSession() {
    final record = _controller?.record;
    if (!mounted ||
        record == null ||
        (record.id == _publishedId && record.revision == _publishedRevision)) {
      return;
    }
    _publishedId = record.id;
    _publishedRevision = record.revision;
    ref.invalidate(colorSessionsProvider);
    ref.invalidate(colorHomeOverviewProvider);
    if (record.status == 'completed') ref.read(finishedGameRefreshProvider)();
  }

  @override
  void initState() {
    super.initState();
    _loading = _open();
  }

  Future<ColorSessionController?> _open({bool replace = false}) async {
    final repo = ref.read(colorRepositoryProvider);
    final telemetry = ref.read(productTelemetryProvider);
    SavedColorSession? record;
    if (widget.sessionId != null && !replace) {
      record = await repo.load(widget.sessionId!);
      if (record == null || record.status == 'abandoned') {
        throw StateError('Session unavailable');
      }
    } else if (!replace) {
      record = widget.kind == ColorSessionKind.training
          ? await repo.activeTraining()
          : await repo.load('daily:${_today()}');
    }
    if (!mounted) throw StateError('Screen closed');
    if (record == null && !replace && !await repo.guideSeen()) {
      if (!mounted) throw StateError('Screen closed');
      _guideCatalog = await ref.read(colorCatalogProvider.future);
      _guideRequired = true;
      return null;
    }
    if (!mounted) throw StateError('Screen closed');
    record ??= await repo.start(
      await ref.read(colorCatalogProvider.future),
      widget.kind,
      replaceTraining: replace,
    );
    if (record.game.phase != ColorRoundPhase.finished &&
        record.game.ruleVersion != ColorScoring.version) {
      throw const FormatException(
        'This saved rule needs a compatible app version',
      );
    }
    final controller = ColorSessionController(
      repo,
      record,
      telemetry: telemetry,
    );
    if (!mounted) {
      controller.dispose();
      throw StateError('Screen closed');
    }
    _controller?.dispose();
    _controller = controller;
    controller.addListener(_publishCommittedSession);
    _publishCommittedSession();
    if (record.status == 'active') {
      telemetry.record(
        'game_opened',
        properties: {
          'mode': 'colors',
          'kind': record.isStage ? 'stage' : record.kind.name,
        },
      );
    }
    return controller;
  }

  String _today() {
    final d = ref.read(appClockProvider)().toUtc();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _back() {
    ref.invalidate(colorSessionsProvider);
    ref.invalidate(colorHomeOverviewProvider);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        _controller?.record.isStage == true
            ? '/colors/stage/${_controller!.record.stageId}'
            : '/colors',
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ColorSessionController?>(
    future: _loading,
    builder: (context, snapshot) {
      if (_guideRequired &&
          snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return ColorTutorialScreen(
          catalog: _guideCatalog!,
          onBack: _back,
          onDone: () async {
            final repository = ref.read(colorRepositoryProvider);
            final telemetry = ref.read(productTelemetryProvider);
            await repository.markGuideSeen();
            await telemetry.record(
              'tutorial_completed',
              properties: {'mode': 'colors'},
            );
            if (mounted) {
              setState(() {
                _guideRequired = false;
                _loading = _open();
              });
            }
          },
        );
      }
      if (snapshot.connectionState != ConnectionState.done ||
          !snapshot.hasData) {
        return ColorLoadState(
          failed: snapshot.hasError,
          onBack: _back,
          onRetry: () {
            ref.invalidate(colorCatalogProvider);
            setState(() => _loading = _open());
          },
        );
      }
      final controller = snapshot.data!;
      return ColorTrainingScreen(
        key: ValueKey(controller.record.id),
        catalog: controller.record.catalog,
        controller: controller,
        onBack: _back,
        resultActionsBuilder: (record) => ColorResultActions(session: record),
        onNewTraining: () async {
          setState(() => _loading = _open(replace: true));
          try {
            await _loading;
          } catch (_) {
            /* FutureBuilder offers recovery. */
          }
        },
      );
    },
  );
}

class ColorLoadState extends StatelessWidget {
  final bool failed;
  final VoidCallback? onBack;
  final VoidCallback onRetry;
  const ColorLoadState({
    super.key,
    required this.failed,
    required this.onBack,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: onBack == null
            ? null
            : IconButton(
                onPressed: onBack,
                tooltip: l.semBack,
                icon: const CineusIcon(CineusAssetId.back),
              ),
        title: Text(l.colorModeTitle),
      ),
      body: failed
          ? ListView(
              key: const ValueKey('colors-load-scroll'),
              padding: const EdgeInsets.all(24),
              children: [
                const CineusStateArt(CineusStateKind.error),
                Text(l.colorLoadFailed, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('colors-load-retry'),
                  onPressed: onRetry,
                  child: Text(l.colorRetry),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(l.colorLoading),
                ],
              ),
            ),
    );
  }
}
