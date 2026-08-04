import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

import 'app.dart';
import 'data/datasources/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Must call this before ANY sqflite operation on web
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // Initialize database
  await DatabaseHelper.instance.database;

  runApp(const ProviderScope(child: CineusApp()));
}
