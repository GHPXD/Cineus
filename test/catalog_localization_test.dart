import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/data/repositories/movie_repository_impl.dart';

import 'support/test_database.dart';

void main() {
  test('translated movie and clues overlay Portuguese base content', () async {
    final db = await openTestDatabase(withMovies: true);
    addTearDown(db.close);

    await db.insert('movies', {
      'id': 1,
      'title': 'A Viagem de Chihiro',
      'original_title': 'Sen to Chihiro no Kamikakushi',
      'genres': 'Animação,Fantasia',
    });
    await db.insert('clues', {
      'id': 11,
      'movie_id': 1,
      'clue_number': 1,
      'category': 'Atmosfera',
      'text': 'Uma casa de banhos esconde outro mundo.',
    });
    await db.insert('movie_localizations', {
      'movie_id': 1,
      'locale': 'en',
      'title': 'Spirited Away',
      'genres': 'Animation,Fantasy',
      'overview': 'A translated overview',
    });
    await db.insert('clue_localizations', {
      'clue_id': 11,
      'locale': 'en',
      'category': 'Atmosphere',
      'text': 'A bathhouse hides another world.',
    });

    final repo = MovieRepositoryImpl(
      TestDatabaseProvider(db),
      localeLoader: () async => 'en',
    );
    final movie = await repo.getMovieById(1);

    expect(movie!.title, 'Spirited Away');
    expect(movie.genres, ['Animation', 'Fantasy']);
    expect(movie.overview, 'A translated overview');
    expect(movie.clues.single.category, 'Atmosphere');
    expect(movie.clues.single.text, 'A bathhouse hides another world.');
  });

  test('missing translations safely fall back to Portuguese', () async {
    final db = await openTestDatabase(withMovies: true);
    addTearDown(db.close);

    await db.insert('movies', {'id': 2, 'title': 'Central do Brasil'});
    await db.insert('clues', {
      'id': 21,
      'movie_id': 2,
      'clue_number': 1,
      'category': 'Narrativa',
      'text': 'Uma viagem pelo Brasil.',
    });

    final repo = MovieRepositoryImpl(
      TestDatabaseProvider(db),
      localeLoader: () async => 'es',
    );
    final movie = await repo.getMovieById(2);

    expect(movie!.title, 'Central do Brasil');
    expect(movie.clues.single.text, 'Uma viagem pelo Brasil.');
  });

  test('search index follows locale changes and localized titles', () async {
    final db = await openTestDatabase(withMovies: true);
    addTearDown(db.close);

    await db.insert('movies', {
      'id': 3,
      'title': 'O Labirinto do Fauno',
      'original_title': 'El laberinto del fauno',
    });
    await db.insert('movie_localizations', {
      'movie_id': 3,
      'locale': 'en',
      'title': "Pan's Labyrinth",
    });
    await db.insert('movie_localizations', {
      'movie_id': 3,
      'locale': 'es',
      'title': 'El laberinto del fauno',
    });

    var locale = 'en';
    final repo = MovieRepositoryImpl(
      TestDatabaseProvider(db),
      localeLoader: () async => locale,
    );

    expect((await repo.searchMovies('pans labyrinth')).single.id, 3);
    locale = 'es';
    expect((await repo.searchMovies('laberinto del fauno')).single.id, 3);
  });

  test('getMoviesByIds overlays localized list titles', () async {
    final db = await openTestDatabase(withMovies: true);
    addTearDown(db.close);

    await db.insert('movies', {'id': 4, 'title': 'Cidade de Deus'});
    await db.insert('movie_localizations', {
      'movie_id': 4,
      'locale': 'en',
      'title': 'City of God',
    });

    final repo = MovieRepositoryImpl(
      TestDatabaseProvider(db),
      localeLoader: () async => 'en',
    );
    final movies = await repo.getMoviesByIds([4]);
    expect(movies.single.title, 'City of God');
  });
}
