import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app.dart';
import 'core/utils/orientation_policy.dart';
import 'data/datasources/database_helper.dart';
import 'presentation/database_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    if (OrientationPolicy.lockPortrait(logicalSize)) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

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
