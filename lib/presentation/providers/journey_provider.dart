import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/journey_repository.dart';
import 'providers.dart';
import 'app_clock.dart';

final journeyRepositoryProvider = Provider<JourneyRepository>(
  (ref) =>
      JourneyRepository(ref.read(databaseProvider), ref.read(appClockProvider)),
);
final journeyProgressProvider = FutureProvider<JourneyProgress>((ref) async {
  final repository = ref.watch(journeyRepositoryProvider);
  final tickets = ref.read(ticketNotifierProvider.notifier);
  await repository.deliver(
    (key, amount) => tickets.creditOnce(
      key: key,
      amount: amount,
      verify: (db) async {
        final grant = await db.query(
          'mission_ticket_grants',
          where: 'reward_key=? AND amount=?',
          whereArgs: [key, amount],
        );
        if (grant.isEmpty) throw StateError('Mission grant missing');
      },
    ),
  );
  return repository.load();
});
