import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/core/utils/challenge_code.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/l10n/app_l10n_pt.dart';
import 'package:cineus/presentation/widgets/result_share_card.dart';
import 'package:cineus/presentation/widgets/share_grid_widget.dart';

void main() {
  test(
    'all catalogue IDs round-trip in both modes; legacy prefix P remains clues',
    () {
      for (final mode in GameMode.values) {
        for (var id = 1; id <= 500; id++) {
          final code = ChallengeCode.encode(id, mode: mode);
          final target = ChallengeCode.decodeTarget(code)!;
          expect(target.movieId, id);
          expect(target.mode, mode);
          expect(
            ChallengeCode.parseInput(
              ChallengeCode.linkFor(id, mode: mode).toString(),
            )!.mode,
            mode,
          );
        }
      }
      expect(ChallengeCode.decodeTarget('CIN-PWQH')!.movieId, 117);
      expect(ChallengeCode.decodeTarget('CIN-PWQH')!.mode, GameMode.clue);
    },
  );
  test('verified HTTPS respects exact origin, base path and mode', () {
    final base = Uri.parse('https://play.example/app');
    final link = ChallengeCode.linkFor(
      77,
      mode: GameMode.poster,
      publicBase: base,
    );
    final target = ChallengeCode.parseInput(link.toString(), publicBase: base)!;
    expect(target.movieId, 77);
    expect(target.mode, GameMode.poster);
    expect(
      ChallengeCode.parseInput(
        'https://play.example/challenge/${ChallengeCode.encode(77)}',
        publicBase: base,
      ),
      isNull,
    );
  });
  test(
    'rejects injection, hostile links, conflicting query and overlong inputs',
    () {
      final base = Uri.parse('https://play.example/app');
      final code = ChallengeCode.encode(77, mode: GameMode.poster);
      for (final bad in [
        "' OR 1=1--",
        '<script>alert(1)</script>',
        'javascript:alert(1)',
        'https://play.example.evil/app/challenge/$code',
        'https://play.example@evil.example/app/challenge/$code',
        'http://play.example/app/challenge/$code',
        'https://play.example:8443/app/challenge/$code',
        'https://play.example/app/other?code=$code',
        'https://play.example/app/challenge/$code/extra',
        'https://play.example/app/challenge/$code?code=$code',
        'https://play.example/app/challenge?code=$code&code=$code',
        'cineus://challenge/extra/$code',
        'cineus://challenge:80/$code',
        'cineus://challenge/$code#extra',
        'x' * 2049,
      ]) {
        expect(
          ChallengeCode.parseInput(bad, publicBase: base),
          isNull,
          reason: bad.substring(0, bad.length.clamp(0, 80)),
        );
      }
    },
  );
  test('invalid public origin falls back to supported custom scheme', () {
    expect(
      ChallengeCode.linkFor(
        1,
        publicBase: Uri.parse('https://user:pass@evil.example'),
      ).scheme,
      'cineus',
    );
  });
  test('Poster uses five grid cells; clues retains ten', () {
    expect(
      ShareGrid(revealedClues: 2, won: true, totalSteps: 5).toEmojiGrid(),
      '🟨🟩⬛⬛⬛',
    );
    expect(ShareGrid(revealedClues: 10, won: false).toEmojiGrid(), '🟥' * 10);
  });
  test(
    'share caption contains only brand, points and score band; no guesses or stage metadata',
    () {
      final l = AppL10nPt();
      for (final mode in GameMode.values) {
        final data = ResultShareData.fromSession(
          GameSession.daily(
            mode: mode,
            date: '2026-10-12',
            movieId: 157336,
          ).copyWith(
            status: GameStatus.won,
            score: 2,
            revealedClues: 4,
            guesses: ['Interestelar'],
          ),
          650,
        );
        final text = data.text(l);
        expect(text, isNot(contains('#650')));
        expect(data.movieId, 157336);
        expect(text, contains('2/${mode == GameMode.poster ? 5 : 10} pontos'));
        expect(
          text,
          isNot(contains(mode == GameMode.clue ? 'Dicas' : 'Poster')),
        );
        expect(text, isNot(contains(mode == GameMode.clue ? '4/10' : '4/5')));
        for (final answer in [
          'Interestelar',
          '157336',
          'cineus://challenge',
          'CIN-',
          'cineus.app',
        ]) {
          expect(text, isNot(contains(answer)));
        }
      }
      expect(l.resultScore(0), '0 pontos');
      expect(l.resultScore(1), '1 ponto');
      expect(l.resultScore(2), '2 pontos');
    },
  );
  test('score bar uses green at 7–10, yellow at 4–6 and red below 4', () {
    for (final score in [0, 1, 3, 4, 6, 7, 10]) {
      final bar = ShareGrid(revealedClues: 4, won: true, score: score);
      expect(
        bar.toEmojiGrid(),
        (score >= 7
                    ? '🟩'
                    : score >= 4
                    ? '🟨'
                    : '🟥') *
                4 +
            '⬛' * 6,
      );
    }
    expect(
      const ShareGrid(revealedClues: 10, won: false, score: 0).toEmojiGrid(),
      '🟥' * 10,
    );
  });
}
