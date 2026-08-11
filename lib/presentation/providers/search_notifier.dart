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

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
  });
}

class SearchNotifier extends StateNotifier<SearchState> {
  final MovieRepository _movieRepo;
  Timer? _debounce;

  SearchNotifier(this._movieRepo) : super(const SearchState());

  void search(String query) {
    _debounce?.cancel();

    if (query.trim().length < 2) {
      state = SearchState(query: query);
      return;
    }

    state = SearchState(query: query, isSearching: true);

    _debounce = Timer(AppConstants.searchDebounce, () async {
      final results = await _movieRepo.searchMovies(query.trim(), limit: 8);
      // Only update if query hasn't changed during search
      if (mounted && state.query == query) {
        state = SearchState(query: query, results: results);
      }
    });
  }

  void clear() {
    _debounce?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
      return SearchNotifier(ref.read(movieRepositoryProvider));
    });
