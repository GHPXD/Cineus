import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/utils/challenge_code.dart';
import 'routes/app_router.dart';

/// Routes incoming `cineus://` links (D10).
///
/// Wrapped around the app so it lives as long as the router does. Handles both
/// the cold-start link and links that arrive while the app is already running.
///
/// A custom scheme rather than an https universal link: the latter needs a domain
/// we control and a hosted association file. `cineus.app` is only a string in the
/// share text for now — so a friend without the app installed sees a code they can
/// paste, which is exactly what the settings screen accepts.
class DeepLinkHandler extends StatefulWidget {
  final Widget child;

  const DeepLinkHandler({super.key, required this.child});

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    // app_links has no web implementation worth wiring here; on the web the
    // challenge code is pasted instead.
    if (!kIsWeb) _listen();
  }

  Future<void> _listen() async {
    final links = AppLinks();

    // Cold start: the link that launched the app.
    final initial = await links.getInitialLink();
    if (initial != null) _navigate(initial);

    _subscription = links.uriLinkStream.listen(
      _navigate,
      // A malformed link is not worth crashing over.
      onError: (_) {},
    );
  }

  void _navigate(Uri uri) {
    final movieId = ChallengeCode.movieIdFromLink(uri);
    if (movieId == null) return;
    AppRouter.router.go('/challenge/$movieId');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
