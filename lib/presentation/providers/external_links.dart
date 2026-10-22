import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

abstract interface class ExternalLinks {
  Future<bool> openSupport();
  Future<void> copySupport();
}

class PlatformExternalLinks implements ExternalLinks {
  static Uri subscriptionSettings({required bool apple}) => Uri.parse(
    apple
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions',
  );
  static const supportUrl = 'https://github.com/GHPXD/Cineus/issues';
  @override
  Future<bool> openSupport() =>
      launchUrl(Uri.parse(supportUrl), mode: LaunchMode.externalApplication);
  @override
  Future<void> copySupport() =>
      Clipboard.setData(const ClipboardData(text: supportUrl));
}

final externalLinksProvider = Provider<ExternalLinks>(
  (_) => PlatformExternalLinks(),
);
