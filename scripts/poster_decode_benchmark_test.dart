// Actual Flutter host codec measurements; not an Android/iOS GPU benchmark.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('record real JPEG codec memory and CPU time', (tester) async {
    final results = <Map<String, Object?>>[];
    await tester.runAsync(() async {
      for (final id in [1, 2, 444]) {
        final bytes = (await rootBundle.load(
          'assets/posters/$id.jpg',
        )).buffer.asUint8List();
        for (final width in [64, 128, 256, 500]) {
          final timings = <int>[];
          var decodedBytes = 0, decodedHeight = 0;
          for (var i = 0; i < 7; i++) {
            final watch = Stopwatch()..start();
            final codec = await ui.instantiateImageCodec(
              bytes,
              targetWidth: width,
            );
            final frame = await codec.getNextFrame();
            watch.stop();
            timings.add(watch.elapsedMicroseconds);
            decodedHeight = frame.image.height;
            decodedBytes = (await frame.image.toByteData())!.lengthInBytes;
            frame.image.dispose();
            codec.dispose();
          }
          timings.sort();
          results.add({
            'movieId': id,
            'width': width,
            'height': decodedHeight,
            'rgba_bytes': decodedBytes,
            'median_decode_ms': timings[3] / 1000,
          });
          expect(decodedBytes, width * decodedHeight * 4);
        }
      }
      final out = File('docs/artwork/DECODE.json');
      await out.parent.create(recursive: true);
      await out.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert({'environment': 'Flutter test host codec on Windows; not mobile GPU or FPS', 'measurements': results})}\n',
      );
    });
  });
}
