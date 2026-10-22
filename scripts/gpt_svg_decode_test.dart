// Diagnostic: compile traced assets with the real Flutter SVG codec.
// Optional --dart-define=CINEUS_GPT_IDS=id,id for a stable partial batch.
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('traced GPT assets decode into real Flutter vector pictures', () async {
    const selection = String.fromEnvironment('CINEUS_GPT_IDS');
    final ids = selection.split(',').where((id) => id.isNotEmpty).toSet();
    final records =
        (jsonDecode(
                  File(
                    'docs/artwork/interface/MANIFEST.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>();
    final selected = records.where((r) => ids.isEmpty || ids.contains(r['id']));
    expect(selected, isNotEmpty);
    if (ids.isNotEmpty) {
      expect(selected.map((r) => r['id']).toSet(), ids);
    }
    for (final record in selected) {
      for (final file in [
        record['svg'],
        record['ink_svg'],
      ].whereType<String>()) {
        final picture = await vg.loadPicture(SvgAssetLoader(file), null);
        expect(picture.size.width, greaterThan(0), reason: file);
        expect(picture.size.height, greaterThan(0), reason: file);
        picture.picture.dispose();
      }
    }
  });
}
