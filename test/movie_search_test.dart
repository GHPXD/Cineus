import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/core/utils/movie_search.dart';

SearchCandidate c(int id, String title, [String? original]) =>
    SearchCandidate.fromTitles(id, title, original);

void main() {
  group('levenshtein', () {
    test('distância zero para strings iguais', () {
      expect(MovieSearch.levenshtein('matrix', 'matrix'), 0);
    });

    test('conta substituição, inserção e remoção', () {
      expect(MovieSearch.levenshtein('matrix', 'matrox'), 1);
      expect(MovieSearch.levenshtein('matrix', 'matrixx'), 1);
      expect(MovieSearch.levenshtein('matrix', 'matri'), 1);
      expect(MovieSearch.levenshtein('kitten', 'sitting'), 3);
    });

    test('string vazia custa o tamanho da outra', () {
      expect(MovieSearch.levenshtein('', 'abc'), 3);
      expect(MovieSearch.levenshtein('abc', ''), 3);
    });

    test('aborta cedo devolvendo maxDistance + 1', () {
      expect(MovieSearch.levenshtein('kitten', 'sitting', 2), 3);
      expect(MovieSearch.levenshtein('abc', 'xyzxyzxyz', 2), 3);
      // dentro do limite continua exato
      expect(MovieSearch.levenshtein('matrix', 'matrox', 2), 1);
    });

    test('diferença de tamanho maior que o limite sai imediatamente', () {
      expect(MovieSearch.levenshtein('a', 'abcdefghij', 2), 3);
    });
  });

  group('score — camadas de relevância', () {
    test('título idêntico vence tudo', () {
      expect(MovieSearch.score('matrix', 'matrix'), 1000);
    });

    test('prefixo do título vem antes de prefixo de palavra', () {
      final prefixoTitulo = MovieSearch.score('matrix', 'matrix reloaded');
      final prefixoPalavra = MovieSearch.score('reloaded', 'matrix reloaded');
      expect(prefixoTitulo, greaterThan(prefixoPalavra));
    });

    test('prefixo de palavra vem antes de substring no meio', () {
      final prefixoPalavra = MovieSearch.score('gelo', 'a era do gelo');
      final substring = MovieSearch.score('ra do', 'a era do gelo');
      expect(prefixoPalavra, greaterThan(substring));
    });

    test('sem correspondência devolve 0', () {
      expect(MovieSearch.score('titanic', 'matrix reloaded'), 0);
    });

    test('insensível a pontuação: "spider man" alcança "spiderman"', () {
      // normalize("Spider-Man") == "spiderman" (o hífen é removido, não virou
      // espaço), então a camada compacta é o que salva essa busca.
      expect(
        MovieSearch.score('spider man', 'spiderman no way home'),
        greaterThan(0),
      );
    });

    test('tolera erro de digitação a partir de 4 caracteres', () {
      expect(MovieSearch.score('matrox', 'matrix'), greaterThan(0));
      expect(MovieSearch.score('vingadores', 'vingadores'), 1000);
      // curto demais: não aplica fuzzy
      expect(MovieSearch.score('mat', 'xyz'), 0);
    });

    test('erro de digitação em uma palavra do título', () {
      expect(
        MovieSearch.score('galaxa', 'guardioes da galaxia'),
        greaterThan(0),
      );
    });

    test('fuzzy nunca supera uma correspondência literal', () {
      final literal = MovieSearch.score('matrix', 'matrix reloaded');
      final fuzzy = MovieSearch.score('matrox', 'matrix');
      expect(literal, greaterThan(fuzzy));
    });
  });

  group('rank — ordenação e limite', () {
    final catalogo = [
      c(1, 'A Culpa é das Estrelas', 'The Fault in Our Stars'),
      c(2, 'Guerra nas Estrelas', 'Star Wars'),
      c(3, 'Nasce uma Estrela', 'A Star Is Born'),
      c(4, 'Star Trek'),
      c(5, 'Matrix', 'The Matrix'),
      c(6, 'Matrix Reloaded'),
      c(7, 'Titanic'),
    ];

    test('query vazia devolve lista vazia', () {
      expect(MovieSearch.rank('', catalogo), isEmpty);
      expect(MovieSearch.rank('   ', catalogo), isEmpty);
    });

    test('"star" prioriza quem começa com star, não a ordem alfabética', () {
      final ids = MovieSearch.rank('star', catalogo);
      // Star Trek (#4) e Star Wars (#2, via título original) vêm primeiro;
      // antes a ordenação alfabética punha "A Culpa é das Estrelas" na frente.
      expect(ids.take(2), containsAll([2, 4]));
      expect(ids.indexOf(1), greaterThan(ids.indexOf(4)));
    });

    test('título exato vence o prefixo mais longo', () {
      final ids = MovieSearch.rank('matrix', catalogo);
      expect(ids.first, 5);
      expect(ids, contains(6));
    });

    test('respeita o limite', () {
      expect(MovieSearch.rank('star', catalogo, limit: 2).length, 2);
      expect(
        MovieSearch.rank('star', catalogo, limit: 100).length,
        lessThanOrEqualTo(catalogo.length),
      );
    });

    test('acentos são irrelevantes nos dois sentidos', () {
      final semAcento = MovieSearch.rank('estrelas', catalogo);
      final comAcento = MovieSearch.rank('Estrêlas', catalogo);
      expect(semAcento, isNotEmpty);
      expect(comAcento, isNotEmpty);
    });

    test('caixa alta com acento funciona', () {
      final items = [c(1, 'Coração Valente')];
      expect(MovieSearch.rank('CORAÇÃO', items), [1]);
      expect(MovieSearch.rank('coracao', items), [1]);
      expect(MovieSearch.rank('CORACAO', items), [1]);
    });

    test('ordem é estável entre execuções', () {
      final a = MovieSearch.rank('star', catalogo);
      final b = MovieSearch.rank('star', catalogo);
      expect(a, b);
    });

    test('empate desempata pelo título mais curto', () {
      final items = [c(1, 'Alien Covenant Extended Edition'), c(2, 'Alien')];
      // ambos começam com "alien" -> mesma camada; o mais curto ganha
      expect(MovieSearch.rank('alien', items).first, 2);
    });
  });
}
