// Ranking exercised against the real bundled catalogue (500 films).
//
// Reads assets/cineus_v1.db straight from disk and feeds the exact same
// `MovieSearch.rank` the repository calls, so these are the searches a player
// actually performs — not synthetic fixtures.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cineus/core/utils/movie_search.dart';

void main() {
  sqfliteFfiInit();

  Database? db;
  late List<SearchCandidate> catalogue;
  late Map<int, String> titleById;

  setUpAll(() async {
    // Absolute: a relative path would resolve against sqflite_common_ffi's own
    // databases directory, not the project root.
    final assetDb = File('assets/cineus_v1.db').absolute.path;
    expect(File(assetDb).existsSync(), isTrue, reason: 'não achei $assetDb');

    final database = await databaseFactoryFfi.openDatabase(
      assetDb,
      options: OpenDatabaseOptions(readOnly: true),
    );
    db = database;
    final rows = await database
        .query('movies', columns: ['id', 'title', 'original_title']);
    catalogue = rows
        .map((r) => SearchCandidate.fromTitles(
              r['id'] as int,
              r['title'] as String,
              r['original_title'] as String?,
            ))
        .toList();
    titleById = {
      for (final r in rows) r['id'] as int: r['title'] as String,
    };
  });

  tearDownAll(() async => db?.close());

  List<String> search(String query, {int limit = 8}) =>
      MovieSearch.rank(query, catalogue, limit: limit)
          .map((id) => titleById[id]!)
          .toList();

  test('o catálogo carregou', () {
    expect(catalogue.length, 500);
  });

  group('acentos — o bug A8', () {
    // 172 dos 500 títulos têm acento. Com `LIKE` era impossível achá-los sem
    // digitar o diacrítico, e em caixa alta era impossível de qualquer forma.
    final casos = {
      'guardioes': 'Guardiões da Galáxia',
      'coracao': 'Coração',
      'aneis': 'Anéis',
      'ingloriosos': 'Inglórios',
      'historias': 'Histórias',
    };

    casos.forEach((semAcento, esperadoContem) {
      test('"$semAcento" (sem acento) encontra título acentuado', () {
        final r = search(semAcento);
        expect(r, isNotEmpty, reason: 'nada encontrado para "$semAcento"');
        expect(
          r.any((t) => t.contains(esperadoContem)),
          isTrue,
          reason: 'esperava algo com "$esperadoContem", veio: $r',
        );
      });
    });

    test('caixa alta com acento funciona (antes retornava zero)', () {
      expect(search('GUARDIÕES'), isNotEmpty);
      expect(search('Guardiões'), isNotEmpty);
      expect(search('guardioes'), isNotEmpty);
    });
  });

  group('relevância — o bug A30', () {
    test('"star" não começa mais por "A Culpa é das Estrelas"', () {
      final r = search('star');
      expect(r, isNotEmpty);
      expect(r.first, isNot('A Culpa é das Estrelas'));
    });

    test('"matrix" traz o filme original primeiro', () {
      expect(search('matrix').first, 'Matrix');
    });

    test('"vingadores" prioriza o título mais curto da franquia', () {
      final r = search('vingadores');
      expect(r, isNotEmpty);
      expect(r.first.startsWith('Vingadores'), isTrue, reason: 'veio: $r');
    });

    test('título exato sempre aparece em primeiro', () {
      for (final titulo in [
        'Titanic',
        'Interestelar',
        'Coringa',
        'Parasita',
      ]) {
        final r = search(titulo);
        expect(r.first, titulo, reason: 'busca por "$titulo" deu: $r');
      }
    });
  });

  group('tolerância a erro de digitação — B2', () {
    final typos = {
      'matrox': 'Matrix',
      'vingadors': 'Vingadores',
      'interestellar': 'Interestelar',
      'titanik': 'Titanic',
    };

    typos.forEach((typo, esperado) {
      test('"$typo" ainda encontra "$esperado"', () {
        final r = search(typo);
        expect(
          r.any((t) => t.contains(esperado)),
          isTrue,
          reason: 'esperava "$esperado", veio: $r',
        );
      });
    });

    test('lixo não retorna nada', () {
      expect(search('zzqxwvk'), isEmpty);
      expect(search('qqqqqqqqqqqq'), isEmpty);
    });
  });

  group('título original em inglês', () {
    test('buscar pelo título original encontra o filme', () {
      expect(search('The Godfather').any((t) => t.contains('Chefão')), isTrue);
      expect(search('Star Wars').isNotEmpty, isTrue);
      expect(search('Spider-Man').isNotEmpty, isTrue);
    });

    test('"spider man" com espaço alcança "Spider-Man"', () {
      // normalize remove o hífen sem inserir espaço; a camada compacta cobre.
      expect(search('spider man'), isNotEmpty);
    });
  });

  group('títulos duplicados — A13 / B3', () {
    test('os 5 pares homônimos aparecem ambos nos resultados', () {
      for (final titulo in [
        'O Rei Leão',
        'A Bela e a Fera',
        'Aladdin',
        'Batman',
        'Os Suspeitos',
      ]) {
        final r = search(titulo, limit: 20);
        final iguais = r.where((t) => t == titulo).length;
        expect(iguais, 2,
            reason: '"$titulo" deveria aparecer 2x (remake + original), '
                'veio $iguais em: $r');
      }
    });
  });

  group('robustez', () {
    test('query de 1 caractere não explode', () {
      for (final q in ['a', 'e', 'z', '1', ' ']) {
        expect(() => search(q), returnsNormally);
      }
    });

    test('query muito longa não explode', () {
      expect(() => search('a' * 500), returnsNormally);
    });

    test('só pontuação devolve vazio', () {
      expect(search('!!!'), isEmpty);
      expect(search('---'), isEmpty);
    });

    test('respeita o limite em query muito abrangente', () {
      expect(search('a', limit: 8).length, lessThanOrEqualTo(8));
    });
  });
}
