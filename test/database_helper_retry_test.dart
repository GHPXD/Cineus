import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cineus/data/datasources/database_helper.dart';

void main() {
  test(
    'database initialization preserves the original error and retries',
    () async {
      sqfliteFfiInit();
      var attempts = 0;
      final helper = DatabaseHelper.forTesting(() async {
        attempts++;
        if (attempts == 1) throw StateError('original database failure');
        return databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      });

      await expectLater(
        helper.database,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'original database failure',
          ),
        ),
      );

      final db = await helper.database;
      expect(attempts, 2);
      await db.close();
    },
  );
}
