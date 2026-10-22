import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/repositories/color_repository.dart';
import '../../domain/entities/color_training_session.dart';
import '../../domain/services/product_telemetry.dart';
import '../../data/services/disabled_product_telemetry.dart';

/// Draft writes serialize; confirmed transitions publish only after SQLite commits.
class ColorSessionController extends ChangeNotifier {
  final ColorRepository repository;
  final ProductTelemetry telemetry;
  SavedColorSession record;
  late ColorTrainingSession game;
  Object? error;
  bool busy = false, saving = false, dirty = false, _disposed = false;
  int _generation = 0;
  Timer? _timer;
  Future<bool>? _write;
  ColorSessionController(
    this.repository,
    this.record, {
    this.telemetry = const DisabledProductTelemetry(),
  }) {
    game = record.game.clone();
  }
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool choose(ColorSelection value, String id) {
    if (busy || !game.choose(value, id)) return false;
    dirty = true;
    _generation++;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 250), flush);
    _notify();
    return true;
  }

  Future<bool> flush() {
    _timer?.cancel();
    if (_write != null) return _write!;
    if (!dirty) return Future.value(error == null);
    final future = _saveDraft();
    _write = future;
    return future.whenComplete(() => _write = null);
  }

  Future<bool> _saveDraft() async {
    saving = true;
    _notify();
    try {
      while (dirty) {
        final generation = _generation;
        record = await repository.save(record, game.clone());
        dirty = generation != _generation;
      }
      error = null;
      return true;
    } catch (e) {
      error = e;
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<bool> act(bool Function(ColorTrainingSession game) action) async {
    if (_disposed || busy || error != null) return false;
    busy = true;
    _notify();
    try {
      if (!await flush()) return false;
      if (_disposed) return false;
      final next = game.clone();
      if (!action(next)) return false;
      final wasFinished = record.status == 'completed';
      record = await repository.save(record, next);
      game = next;
      if (!wasFinished && record.status == 'completed') {
        unawaited(
          telemetry.record(
            'game_completed',
            properties: {
              'mode': 'colors',
              'kind': record.isStage
                  ? 'stage'
                  : record.isArchive
                  ? 'archive'
                  : record.kind.name,
              'outcome': 'finished',
              'score_cents': next.averageCents,
            },
          ),
        );
      }
      error = null;
      return true;
    } catch (e) {
      error = e;
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> retry() async {
    if (busy) return false;
    if (error is ColorWriteConflict) {
      busy = true;
      _notify();
      try {
        final latest = await repository.load(record.id);
        if (latest == null || latest.status == 'abandoned') {
          throw StateError('Session unavailable');
        }
        record = latest;
        game = latest.game.clone();
        dirty = false;
        error = null;
        return true;
      } catch (e) {
        error = e;
        return false;
      } finally {
        busy = false;
        _notify();
      }
    }
    error = null;
    dirty = true;
    return flush();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disposed = true;
    super.dispose();
  }
}
