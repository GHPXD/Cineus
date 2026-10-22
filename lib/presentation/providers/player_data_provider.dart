import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'growth_provider.dart';

class CloudBackupStatus {
  final int revision;
  final DateTime? savedAt;
  bool get exists => revision > 0;
  const CloudBackupStatus(this.revision, this.savedAt);
  factory CloudBackupStatus.parse(Map<String, dynamic> data) {
    final revision = data['revision'], stamp = data['updated_at'];
    if (revision is! int ||
        revision < 0 ||
        (revision == 0 && stamp != null) ||
        (revision > 0 &&
            (stamp is! int || stamp < 0 || stamp > 253402300799))) {
      throw const FormatException('Invalid backup status');
    }
    return CloudBackupStatus(
      revision,
      stamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (stamp as int) * 1000,
              isUtc: true,
            ),
    );
  }
}

final cloudBackupStatusProvider =
    FutureProvider.autoDispose<CloudBackupStatus?>((ref) async {
      final gateway = ref.watch(growthGatewayProvider);
      if (gateway == null) return null;
      return CloudBackupStatus.parse(await gateway.command('backup_status'));
    });
