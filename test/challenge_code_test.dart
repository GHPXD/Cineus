import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/core/utils/challenge_code.dart';

void main() {
  group('ida e volta', () {
    test('todo id do catálogo sobrevive ao round-trip', () {
      for (var id = 1; id <= 500; id++) {
        final code = ChallengeCode.encode(id);
        expect(ChallengeCode.decode(code), id, reason: 'id $id via $code');
      }
    });

    test('funciona bem além do catálogo atual', () {
      for (final id in [501, 1000, 5000, 32767]) {
        expect(ChallengeCode.decode(ChallengeCode.encode(id)), id);
      }
    });

    test('o formato é sempre CIN-XXXX', () {
      for (var id = 1; id <= 500; id += 37) {
        expect(ChallengeCode.encode(id), matches(r'^CIN-[0-9A-Z]{4}$'));
      }
    });

    test('rejeita ids fora da faixa', () {
      expect(() => ChallengeCode.encode(0), throwsArgumentError);
      expect(() => ChallengeCode.encode(-1), throwsArgumentError);
      expect(() => ChallengeCode.encode(32768), throwsArgumentError);
    });
  });

  group('tolerante na forma, estrito no conteúdo', () {
    final code = ChallengeCode.encode(42);

    test('aceita variações de apresentação', () {
      for (final variant in [
        code,
        code.toLowerCase(),
        '  $code  ',
        code.replaceAll('-', ''),
        code.replaceAll('-', ' '),
        code.replaceAll('-', '_'),
      ]) {
        expect(ChallengeCode.decode(variant), 42, reason: variant);
      }
    });

    test('rejeita lixo', () {
      for (final bad in [
        '',
        'CIN',
        'CIN-',
        'CIN-ABC',
        'CIN-ABCDE',
        'XXX-ABCD',
        'lixo qualquer',
        'CIN-AB!D',
      ]) {
        expect(ChallengeCode.decode(bad), isNull, reason: 'aceitou "$bad"');
      }
    });

    test('rejeita as letras ambíguas que o alfabeto não usa', () {
      // I, L, O e U ficam fora justamente para não confundir com 1 e 0.
      for (final letter in ['I', 'L', 'O', 'U']) {
        expect(ChallengeCode.decode('CIN-${letter}AAA'), isNull);
      }
    });
  });

  group('o checksum pega erro de digitação', () {
    test('trocar um caractere quase sempre invalida', () {
      const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
      var wrongFilm = 0;
      var caught = 0;
      var total = 0;

      for (var id = 1; id <= 200; id++) {
        final code = ChallengeCode.encode(id);
        final body = code.substring(4);

        for (var pos = 0; pos < body.length; pos++) {
          for (final replacement in alphabet.split('')) {
            if (body[pos] == replacement) continue;
            total++;
            final typo = 'CIN-'
                '${body.substring(0, pos)}$replacement${body.substring(pos + 1)}';
            final decoded = ChallengeCode.decode(typo);
            if (decoded == null) {
              caught++;
            } else if (decoded != id) {
              wrongFilm++;
            }
          }
        }
      }

      // Com 5 bits de checksum, ~31/32 dos erros de um caractere são pegos.
      expect(caught / total, greaterThan(0.9),
          reason: 'só $caught de $total erros pegos');
      // O resto colide, mas o ponto é que erro silencioso é raro.
      expect(wrongFilm / total, lessThan(0.05));
    });

    test('transpor dois caracteres é detectado na maioria dos casos', () {
      var caught = 0;
      var total = 0;
      for (var id = 1; id <= 300; id++) {
        final body = ChallengeCode.encode(id).substring(4);
        for (var i = 0; i < body.length - 1; i++) {
          if (body[i] == body[i + 1]) continue;
          total++;
          final swapped = body.substring(0, i) +
              body[i + 1] +
              body[i] +
              body.substring(i + 2);
          if (ChallengeCode.decode('CIN-$swapped') != id) caught++;
        }
      }
      expect(caught / total, greaterThan(0.9));
    });
  });

  group('códigos não parecem sequenciais', () {
    test('ids vizinhos geram códigos sem prefixo comum', () {
      var sharedFirstChar = 0;
      for (var id = 1; id < 200; id++) {
        final a = ChallengeCode.encode(id).substring(4);
        final b = ChallengeCode.encode(id + 1).substring(4);
        if (a[0] == b[0]) sharedFirstChar++;
      }
      // Se fosse sequencial, o primeiro caractere quase nunca mudaria.
      expect(sharedFirstChar / 199, lessThan(0.3));
    });

    test('todos os 500 códigos são distintos', () {
      final codes = {for (var id = 1; id <= 500; id++) ChallengeCode.encode(id)};
      expect(codes.length, 500);
    });
  });

  group('deep link', () {
    test('gera cineus://challenge/CODE', () {
      final uri = ChallengeCode.linkFor(77);
      expect(uri.scheme, 'cineus');
      expect(uri.host, 'challenge');
      expect(ChallengeCode.movieIdFromLink(uri), 77);
    });

    test('aceita o código na query também', () {
      final code = ChallengeCode.encode(123);
      expect(
        ChallengeCode.movieIdFromLink(Uri.parse('cineus://challenge?code=$code')),
        123,
      );
    });

    test('ignora links de outro scheme ou sem código válido', () {
      for (final link in [
        'https://cineus.app/challenge/CIN-AAAA',
        'cineus://challenge/lixo',
        'cineus://outracoisa',
        'cineus://challenge',
      ]) {
        expect(ChallengeCode.movieIdFromLink(Uri.parse(link)), isNull,
            reason: link);
      }
    });
  });

  test('isValid é coerente com decode', () {
    final good = ChallengeCode.encode(7);
    expect(ChallengeCode.isValid(good), isTrue);
    expect(ChallengeCode.isValid('CIN-ZZZZ'),
        ChallengeCode.decode('CIN-ZZZZ') != null);
    expect(ChallengeCode.isValid('nada'), isFalse);
  });
}
