import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

abstract class ResultShareService {
  Future<ShareResultStatus> share(String text, Rect origin, {Uint8List? png});
  Future<void> copy(String text);
}

class PlatformResultShareService implements ResultShareService {
  @override
  Future<ShareResultStatus> share(
    String text,
    Rect origin, {
    Uint8List? png,
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Cineus',
        sharePositionOrigin: origin,
        downloadFallbackEnabled: false,
        mailToFallbackEnabled: false,
        files: png == null
            ? null
            : [XFile.fromData(png, mimeType: 'image/png')],
        fileNameOverrides: png == null ? null : ['cineus-result.png'],
      ),
    );
    return result.status;
  }

  @override
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}

final resultShareServiceProvider = Provider<ResultShareService>(
  (ref) => PlatformResultShareService(),
);
