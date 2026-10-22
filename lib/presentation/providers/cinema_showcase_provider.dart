import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cinema_showcase.dart';
import '../../data/repositories/cinema_showcase_repository.dart';
import 'providers.dart';

final cinemaShowcasesProvider = FutureProvider<List<CinemaShowcase>>(
  (ref) async => CinemaShowcase.parse(
    jsonDecode(await rootBundle.loadString('assets/daily/themes_v1.json')),
  ),
);
final cinemaShowcaseRepositoryProvider = Provider(
  (ref) => CinemaShowcaseRepository(
    ref.read(databaseProvider),
    ref.read(gameRepositoryProvider),
  ),
);
