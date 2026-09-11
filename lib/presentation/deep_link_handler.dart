import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/utils/challenge_code.dart';
import 'routes/app_router.dart';

/// Small seam around app_links so lifecycle/error behaviour can be tested
/// without a platform channel.
abstract class DeepLinkSource {
  Future<Uri?> getInitialLink();
  Stream<Uri> get uriLinkStream;
}

class AppLinksDeepLinkSource implements DeepLinkSource {
  final AppLinks _links;

  AppLinksDeepLinkSource({AppLinks? links}) : _links = links ?? AppLinks();

  @override
  Future<Uri?> getInitialLink() => _links.getInitialLink();

  @override
  Stream<Uri> get uriLinkStream => _links.uriLinkStream;
}

/// Routes incoming `cineus://` links (D10).
///
/// Handles both the cold-start link and links received while the app is alive.
/// Platform/plugin failures are deliberately contained: a bad deep-link bridge
/// must never prevent Cineus from opening normally.
class DeepLinkHandler extends StatefulWidget {
  final Widget child;
  final DeepLinkSource? source;
  final void Function(int movieId)? onChallenge;

  const DeepLinkHandler({
    super.key,
    required this.child,
    this.source,
    this.onChallenge,
  });

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  StreamSubscription<Uri>? _subscription;
  late final DeepLinkSource _source;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _source = widget.source ?? AppLinksDeepLinkSource();
    if (!kIsWeb) unawaited(_listen());
  }

  Future<void> _listen() async {
    // Subscribe first so a warm link cannot be missed while the platform is
    // resolving the cold-start URI.
    try {
      _subscription = _source.uriLinkStream.listen(
        _navigate,
        onError: (_) {
          // A malformed/platform link event is non-fatal by design.
        },
      );
    } catch (_) {
      // Some platform implementations can fail while creating the stream.
      // Cold-start handling below can still succeed independently.
    }

    try {
      final initial = await _source.getInitialLink();
      if (!_disposed && initial != null) _navigate(initial);
    } catch (_) {
      // Do not let app_links/plugin failures break application startup.
    }
  }

  void _navigate(Uri uri) {
    if (_disposed) return;
    final movieId = ChallengeCode.movieIdFromLink(uri);
    if (movieId == null) return;

    final callback = widget.onChallenge;
    if (callback != null) {
      callback(movieId);
      return;
    }
    AppRouter.router.go('/challenge/$movieId');
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
