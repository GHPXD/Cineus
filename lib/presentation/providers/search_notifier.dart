import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/movie.dart';
import '../../domain/repositories/movie_repository.dart';
import 'providers.dart';

class SearchState {
  final String query;
  final List<Movie> results;
  final bool isSearching;
  final bool hasError;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.hasError = false,
  });

  bool get isQueryValid => query.trim().length >= 2;
  bool get isEmptyResult => isQueryValid && !isSearching && !hasError && results.isEmpty;
}

class SearchNotifier extends StateNotifier<SearchState> {
  final MovieRepository _movieRepo;
  Timer? _debounce;
  int _generation = 0;

  SearchNotifier(this._movieRepo) : super(const SearchState());

  void search(String query) {
    _debounce?.cancel();
    final generation = ++_generation;

    if (query.trim().length < 2) {
      state = SearchState(query: query);
      return;
    }

    state = SearchState(query: query, isSearching: true);

    _debounce = Timer(AppConstants.searchDebounce, () async {
      try {
        final results = await _movieRepo.searchMovies(query.trim(), limit: 8);
        if (mounted && generation == _generation) {
          state = SearchState(query: query, results: results);
        }
      } catch (_) {
        if (mounted && generation == _generation) {
          state = SearchState(query: query, hasError: true);
        }
      }
    });
  }

  void retry() {
    final query = state.query;
    if (query.trim().length >= 2) search(query);
  }

  void clear() {
    _debounce?.cancel();
    _generation++;
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _generation++;
    super.dispose();
  }
}

final searchNotifierProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.read(movieRepositoryProvider));
});