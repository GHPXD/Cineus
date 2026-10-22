import '../../domain/entities/commerce_snapshot.dart';
import '../repositories/commerce_cache_repository.dart';
import 'commerce_gateway.dart';

/// Write-ahead local receipt journal, balance credit, then server acknowledgement.
/// Any crash between those steps is retried without issuing a second credit.
class CommerceSynchronizer {
  final CommerceGateway gateway;
  final CommerceIdentityStorage identityStorage;
  final CommerceCacheRepository cache;
  final Future<void> Function(
    CommerceIdentity identity,
    CommerceRewardReceipt receipt,
  )
  credit;
  final Future<void> Function() onChanged;
  Future<CommerceSnapshot?>? _pending;
  CommerceIdentity? _identity;
  CommerceSnapshot? current;
  bool lastRefreshSucceeded = false;
  CommerceSynchronizer({
    required this.gateway,
    required this.identityStorage,
    required this.cache,
    required this.credit,
    required this.onChanged,
  });
  CommerceIdentity? get identity => _identity;
  Future<CommerceSnapshot?> synchronize({bool reconcile = false}) {
    if (!gateway.configuration.enabled) return Future.value(null);
    return _pending ??= _synchronize(
      reconcile,
    ).whenComplete(() => _pending = null);
  }

  Future<CommerceSnapshot?> _synchronize(bool reconcile) async {
    lastRefreshSucceeded = false;
    var identity = await identityStorage.read();
    if (identity == null) {
      identity = newCommerceIdentity();
      // Commit identity before contacting the server, so response loss is safe.
      await identityStorage.write(identity);
    }
    _identity = identity;
    CommerceSnapshot? cached;
    try {
      cached = await cache.load(identity);
    } on FormatException {
      await cache.discardUntrusted();
      current = null;
      await onChanged();
    } on TypeError {
      await cache.discardUntrusted();
      current = null;
      await onChanged();
    }
    if (cached != null) {
      await cache.apply(cached, cached: true);
      current = cached;
      await onChanged();
      for (final receipt in cached.rewards) {
        await credit(identity, receipt);
      }
    }
    CommerceSnapshot fresh;
    try {
      fresh = identity.registered
          ? await gateway.snapshot(identity, reconcile: reconcile)
          : identity.recovering
          ? await gateway.recover(identity)
          : await gateway.register(identity);
    } on CommerceNetworkException catch (error) {
      if (error.status != 401 || !identity.registered) rethrow;
      // Keep the installation ID: pending reward delivery and offline cache stay
      // bound to the same device. Persist rotation before the recovery request.
      final generated = newCommerceIdentity();
      identity = CommerceIdentity(
        identity.owner,
        identity.device,
        generated.token,
        identity.recovery,
        recovering: true,
      );
      await identityStorage.write(identity);
      _identity = identity;
      fresh = await gateway.recover(identity);
    }
    await cache.apply(fresh);
    current = fresh;
    lastRefreshSucceeded = true;
    if (!identity.registered) {
      identity = identity.confirmed;
      await identityStorage.write(identity);
      _identity = identity;
    }
    await onChanged();
    await _deliver(fresh, identity);
    return fresh;
  }

  Future<void> _deliver(
    CommerceSnapshot snapshot,
    CommerceIdentity identity,
  ) async {
    for (final receipt in snapshot.rewards) {
      await credit(identity, receipt);
      await gateway.acknowledgeReward(identity, receipt.id);
    }
  }

  Future<CommerceSnapshot> verifyPurchase(String platform, String proof) async {
    if (_pending != null) await _pending;
    if (_identity == null || !_identity!.registered) await synchronize();
    final identity = _identity;
    if (identity == null) throw StateError('No commercial identity');
    final snapshot = await gateway.verifyPurchase(identity, platform, proof);
    await cache.apply(snapshot);
    current = snapshot;
    lastRefreshSucceeded = true;
    await onChanged();
    await _deliver(snapshot, identity);
    return snapshot;
  }

  /// Optional recovery for reinstall/device change. Never associates a receipt
  /// with a different owner merely because the client says it was restored.
  Future<void> recoverIdentity(String code) async {
    if (_pending != null) await _pending;
    final parts = code.trim().split('.');
    if (parts.length != 2) throw const FormatException('Invalid recovery key');
    final generated = newCommerceIdentity();
    final candidate = CommerceIdentity.fromJson({
      'owner': parts[0],
      'device': generated.device,
      'token': generated.token,
      'recovery': parts[1],
      'registered': false,
      'recovering': true,
    });
    final previous = await identityStorage.read();
    await identityStorage.write(candidate);
    _identity = candidate;
    try {
      final fresh = await gateway.recover(candidate);
      await cache.apply(fresh);
      current = fresh;
      lastRefreshSucceeded = true;
      _identity = candidate.confirmed;
      await identityStorage.write(_identity!);
      await onChanged();
      await _deliver(fresh, _identity!);
    } on CommerceNetworkException catch (error) {
      if (error.status == 401 && previous != null) {
        await identityStorage.write(previous);
        _identity = previous;
      }
      rethrow;
    }
  }
}
