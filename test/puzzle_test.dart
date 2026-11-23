import 'package:built_collection/built_collection.dart';
import 'package:crucigrama/model.dart';
import 'package:crucigrama/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CrosswordPuzzleGame', () {
    final crossword = Crossword.crossword(width: 5, height: 5)
        .addWord(
          location: Location.at(0, 0),
          word: 'cat',
          direction: Direction.across,
        )!
        .addWord(
          location: Location.at(0, 0),
          word: 'cow',
          direction: Direction.down,
        )!;
    final candidates = ['dog', 'pig', 'hen', 'fox', 'ant', 'bee', 'yak', 'emu']
        .toBuiltSet();

    test('offers the real word plus four same-length distractors', () {
      final game = CrosswordPuzzleGame.from(
        crossword: crossword,
        candidateWords: candidates,
      );
      final options = game.alternateWords[Location.at(0, 0)]![Direction.across]!;
      expect(options.length, 5);
      expect(options.contains('cat'), isTrue);
      expect(options.toList(), [...options]..sort());
      expect(options.every((w) => w.length == 3), isTrue);
    });

    test('selecting the solution words solves the puzzle', () {
      var game = CrosswordPuzzleGame.from(
        crossword: crossword,
        candidateWords: candidates,
      );
      expect(game.solved, isFalse);

      game = game.selectWord(
        location: Location.at(0, 0),
        word: 'cat',
        direction: Direction.across,
      )!;
      // "dog" can't cross the placed "cat" at (0, 0).
      expect(
        game.canSelectWord(
          location: Location.at(0, 0),
          word: 'dog',
          direction: Direction.down,
        ),
        isFalse,
      );
      expect(game.solved, isFalse);

      game = game.selectWord(
        location: Location.at(0, 0),
        word: 'cow',
        direction: Direction.down,
      )!;
      expect(game.solved, isTrue);
    });
  });

  test('puzzleProvider builds a puzzle once generation completes', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(sizeProvider.notifier).setSize(CrosswordSize.small);
    // The provider is auto-dispose: keep it alive like a watching widget would.
    container.listen(puzzleProvider, (_, _) {});

    final puzzle = await container
        .read(puzzleProvider.future)
        .timeout(const Duration(minutes: 2));

    expect(puzzle.crossword.words.length, greaterThan(5));
    expect(puzzle.crossword.valid, isTrue);
    expect(puzzle.solved, isFalse);

    // Solve it through the notifier, one word at a time.
    for (final word in puzzle.crossword.words) {
      await container
          .read(puzzleProvider.notifier)
          .selectWord(
            location: word.location,
            word: word.word,
            direction: word.direction,
          );
    }
    expect(container.read(puzzleProvider).value!.solved, isTrue);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
