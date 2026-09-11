import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app.dart';
import 'data/datasources/database_helper.dart';
import 'presentation/database_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Must be configured before any sqflite operation on Web.
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // Always mount Flutter before touching SQLite. DatabaseBootstrap owns the
  // startup attempt and gives the player retry/repair paths if local data cannot
  // be opened instead of leaving the app stuck on the native launch screen.
  runApp(
    ProviderScope(
      child: DatabaseBootstrap(
        initialize: () async {
          await DatabaseHelper.instance.database;
        },
        repair: () async {
          await DatabaseHelper.instance.repairDatabase();
        },
        child: const CineusApp(),
      ),
    ),
  );
}
