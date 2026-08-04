import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/core/utils/string_normalizer.dart';

void main() {
  group('StringNormalizer', () {
    group('normalize', () {
      test('lowercases text', () {
        expect(StringNormalizer.normalize('HELLO'), 'hello');
      });

      test('removes accents from Portuguese characters', () {
        expect(StringNormalizer.normalize('São Paulo'), 'sao paulo');
        expect(StringNormalizer.normalize('café'), 'cafe');
        expect(StringNormalizer.normalize('coração'), 'coracao');
        expect(StringNormalizer.normalize('ação'), 'acao');
      });

      test('removes special characters', () {
        expect(StringNormalizer.normalize('Spider-Man: No Way Home'),
            'spiderman no way home');
      });

      test('collapses whitespace', () {
        expect(
            StringNormalizer.normalize('  hello   world  '), 'hello world');
      });

      test('handles empty string', () {
        expect(StringNormalizer.normalize(''), '');
      });

      test('preserves numbers', () {
        expect(StringNormalizer.normalize('2001: Uma Odisseia'),
            '2001 uma odisseia');
      });
    });

    group('normalizeStrippingArticles', () {
      test('strips Portuguese articles', () {
        expect(StringNormalizer.normalizeStrippingArticles('O Poderoso Chefão'),
            'poderoso chefao');
        expect(StringNormalizer.normalizeStrippingArticles('A Origem'),
            'origem');
        expect(StringNormalizer.normalizeStrippingArticles('Os Vingadores'),
            'vingadores');
      });

      test('strips English articles', () {
        expect(StringNormalizer.normalizeStrippingArticles('The Godfather'),
            'godfather');
        expect(StringNormalizer.normalizeStrippingArticles('An Officer'),
            'officer');
      });

      test('does not strip non-articles', () {
        expect(
            StringNormalizer.normalizeStrippingArticles('Inception'), 'inception');
      });
    });

    group('isExactMatch', () {
      test('matches exact title case-insensitively', () {
        expect(
          StringNormalizer.isExactMatch(
              'inception', ['Inception', 'A Origem']),
          true,
        );
      });

      test('matches Portuguese title with accents', () {
        expect(
          StringNormalizer.isExactMatch(
              'A Origem', ['Inception', 'A Origem']),
          true,
        );
      });

      test('matches accent-insensitively', () {
        expect(
          StringNormalizer.isExactMatch(
              'a origem', ['Inception', 'A Origem']),
          true,
        );
      });

      test('does not match partial titles', () {
        expect(
          StringNormalizer.isExactMatch(
              'Incep', ['Inception', 'A Origem']),
          false,
        );
      });
    });

    group('isFranchiseMatch', () {
      test('matches franchise prefix', () {
        expect(
          StringNormalizer.isFranchiseMatch(
              'Harry Potter',
              ['Harry Potter e a Pedra Filosofal']),
          true,
        );
      });

      test('requires at least 4 chars', () {
        expect(
          StringNormalizer.isFranchiseMatch('Har', ['Harry Potter']),
          false,
        );
      });

      test('requires word boundary', () {
        expect(
          StringNormalizer.isFranchiseMatch(
              'Harry Potte', ['Harry Potter']),
          false,
        );
      });

      test('handles full title as franchise match', () {
        expect(
          StringNormalizer.isFranchiseMatch(
              'Harry Potter', ['Harry Potter']),
          true,
        );
      });
    });
  });
}
