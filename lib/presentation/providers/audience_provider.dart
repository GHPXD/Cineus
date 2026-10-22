import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/player_audience.dart';
import 'providers.dart';

final playerAudienceProvider = FutureProvider<PlayerAudience>((ref) async {
  final legacy = PlayerAudience.parse(
    await ref.read(appMetaRepositoryProvider).read('player_audience_v1'),
  );
  return legacy == PlayerAudience.unknown
      ? PlayerAudience.unrestricted
      : legacy;
});
