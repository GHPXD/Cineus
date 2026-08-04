import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/core/utils/string_normalizer.dart';

/// Regression guard for the acceptance criterion of both game modes.
///
/// The poster mode used to accept `isExactMatch || isFranchiseMatch`, which
/// awarded full marks for the wrong film in 205 title combinations of the
/// bundled catalogue. Franchise proximity is a *hint* (`isSameFranchise`),
/// never an acceptance criterion.
///
/// Both notifiers must decide correctness with `isExactMatch` and nothing else,
/// so this file pins the behaviour of that predicate against the real title
/// pairs that used to leak.
void main() {
  // (palpite do jogador, título correto) — todos vindos da base real
  const leaks = <List<String>>[
    ['The Avengers', 'Avengers: Endgame'],
    ['The Avengers', 'Avengers: Infinity War'],
    ['Toy Story', 'Toy Story 3'],
    ['Batman', 'Batman Begins'],
    ['Star Wars', 'Star Wars: The Rise of Skywalker'],
    ['Spider-Man', 'Spider-Man: No Way Home'],
    ['Iron Man', 'Iron Man 2'],
    ['Matrix', 'Matrix Reloaded'],
    ['Deadpool', 'Deadpool 2'],
    ['O Poderoso Chefão', 'O Poderoso Chefão: Parte II'],
    ['De Volta para o Futuro', 'De Volta para o Futuro II'],
    ['Jogos Vorazes', 'Jogos Vorazes: Em Chamas'],
    ['Thor', 'Thor: Ragnarok'],
    ['Blade Runner', 'Blade Runner 2049'],
    ['Frozen', 'Frozen II'],
    ['Top Gun', 'Top Gun: Maverick'],
  ];

  group('isExactMatch é o único critério de acerto', () {
    for (final pair in leaks) {
      test('"${pair[0]}" NÃO acerta "${pair[1]}"', () {
        expect(StringNormalizer.isExactMatch(pair[0], [pair[1]]), isFalse);
      });
    }
  });

  group('isFranchiseMatch aceitaria todos eles — por isso saiu do critério', () {
    for (final pair in leaks) {
      test('"${pair[0]}" casaria com "${pair[1]}"', () {
        expect(StringNormalizer.isFranchiseMatch(pair[0], [pair[1]]), isTrue);
      });
    }
  });

  group('acertos legítimos continuam valendo', () {
    test('título exato', () {
      expect(
        StringNormalizer.isExactMatch('Avengers: Endgame', ['Avengers: Endgame']),
        isTrue,
      );
    });

    test('título original é aceito', () {
      expect(
        StringNormalizer.isExactMatch(
            'The Godfather', ['O Poderoso Chefão', 'The Godfather']),
        isTrue,
      );
    });

    test('sem acento e sem caixa correta', () {
      expect(
        StringNormalizer.isExactMatch(
            'o poderoso chefao', ['O Poderoso Chefão']),
        isTrue,
      );
    });

    test('pontuação é ignorada quando o palpite tem a mesma pontuação', () {
      expect(
        StringNormalizer.isExactMatch(
            'spider-man: no way home', ['Spider-Man: No Way Home']),
        isTrue,
      );
    });

    test('hífen é removido sem virar espaço — trocar por espaço NÃO casa', () {
      // `normalize` apaga o hífen ("Spider-Man" -> "spiderman") em vez de
      // substituí-lo por espaço, então a variante com espaço não bate.
      // Hoje é inofensivo: o palpite sempre vem do autocomplete, ou seja é
      // sempre o título exato do banco. Passaria a importar se algum dia o
      // jogador puder digitar o palpite livremente.
      expect(StringNormalizer.normalize('Spider-Man'), 'spiderman');
      expect(StringNormalizer.normalize('Spider Man'), 'spider man');
      expect(
        StringNormalizer.isExactMatch(
            'Spider Man No Way Home', ['Spider-Man: No Way Home']),
        isFalse,
      );
    });
  });

  group('títulos homônimos — decisão documentada (A13)', () {
    // Os 5 pares remake/original da base compartilham título. Nomear um aceita
    // o outro, de propósito: o jogador produziu o nome certo e as dicas não
    // fixam o ano de forma confiável. O autocomplete mostra o ano inline quando
    // dois resultados colidem.
    const pares = [
      'O Rei Leão',
      'A Bela e a Fera',
      'Aladdin',
      'Batman',
      'Os Suspeitos',
    ];

    for (final titulo in pares) {
      test('"$titulo" é aceito para o homônimo', () {
        expect(StringNormalizer.isExactMatch(titulo, [titulo]), isTrue);
      });
    }

    test('isso NÃO afrouxa o critério para filmes diferentes', () {
      expect(
        StringNormalizer.isExactMatch('O Rei Leão', ['O Rei Leão 2']),
        isFalse,
      );
      expect(
        StringNormalizer.isExactMatch('Batman', ['Batman Begins']),
        isFalse,
      );
    });
  });

  group('a dica de franquia (isSameFranchise) segue funcionando', () {
    test('sequência errada da mesma franquia é sinalizada', () {
      expect(
        StringNormalizer.isSameFranchise(
            'De Volta para o Futuro', ['De Volta para o Futuro II']),
        isTrue,
      );
      expect(
        StringNormalizer.isSameFranchise('Homem de Ferro', ['Homem de Ferro 3']),
        isTrue,
      );
    });

    test('filme sem relação não é sinalizado', () {
      expect(
        StringNormalizer.isSameFranchise('Titanic', ['Avengers: Endgame']),
        isFalse,
      );
    });

    test('sinalizar franquia não é acertar', () {
      const guess = 'Homem de Ferro';
      const answer = ['Homem de Ferro 3'];
      expect(StringNormalizer.isSameFranchise(guess, answer), isTrue);
      expect(StringNormalizer.isExactMatch(guess, answer), isFalse);
    });
  });
}
