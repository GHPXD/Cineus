import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Size;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all 160 traced character layers decode with matching frames', () async {
    final records =
        jsonDecode(
              File(
                'docs/artwork/characters/base/MANIFEST.json',
              ).readAsStringSync(),
            )
            as List;
    records.addAll(
      jsonDecode(
            File(
              'docs/artwork/characters/expanded/MANIFEST.json',
            ).readAsStringSync(),
          )
          as List,
    );
    expect(records.length, 50);
    for (final record in records) {
      Size? size;
      for (final entry in record['files']) {
        final pic = await vg.loadPicture(
          SvgAssetLoader(entry['file'] as String),
          null,
        );
        size ??= pic.size;
        expect(pic.size, size);
        expect(pic.size.width, greaterThan(0));
        pic.picture.dispose();
      }
    }
    final continuity =
        jsonDecode(
              File(
                'docs/artwork/characters/continuity/MANIFEST.json',
              ).readAsStringSync(),
            )
            as List;
    for (final row in continuity) {
      final pic = await vg.loadPicture(
        SvgAssetLoader(row['file'] as String),
        null,
      );
      final base = await vg.loadPicture(
        SvgAssetLoader('assets/colors/art/${row['character_id']}_base.svg'),
        null,
      );
      expect(pic.size, base.size);
      base.picture.dispose();
      expect(pic.size.width, greaterThan(0));
      pic.picture.dispose();
    }
  });
}
