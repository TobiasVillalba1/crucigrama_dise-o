import 'package:crucigrama/model.dart';
import 'package:crucigrama/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty crossword seeds the start location across', () {
    final queue = WorkQueue.from(
      crossword: Crossword.crossword(width: 5, height: 5),
      candidateWords: ['cat', 'dog'],
      startLocation: Location.at(0, 0),
    );
    expect(queue.locationsToTry.toMap(), {Location.at(0, 0): Direction.across});
    expect(queue.isCompleted, isFalse);
  });

  test('updateFrom opens single-word cells and remove marks dead ends', () {
    final empty = Crossword.crossword(width: 5, height: 5);
    var queue = WorkQueue.from(
      crossword: empty,
      candidateWords: ['cat', 'cow', 'dog'],
      startLocation: Location.at(0, 0),
    );
    final cat = empty.addWord(
      location: Location.at(0, 0),
      word: 'cat',
      direction: Direction.across,
    )!;
    queue = queue.updateFrom(cat);
    expect(queue.candidateWords.contains('cat'), isFalse);
    expect(queue.locationsToTry.length, 3);
    expect(queue.locationsToTry.values.every((d) => d == Direction.down), isTrue);

    queue = queue.remove(Location.at(1, 0));
    expect(queue.locationsToTry.length, 2);
    expect(queue.badLocations.contains(Location.at(1, 0)), isTrue);

    // A dead end stays excluded after the next update.
    final withCow = cat.addWord(
      location: Location.at(0, 0),
      word: 'cow',
      direction: Direction.down,
    )!;
    queue = queue.updateFrom(withCow);
    expect(queue.locationsToTry.containsKey(Location.at(1, 0)), isFalse);
    expect(queue.locationsToTry.containsKey(Location.at(0, 0)), isFalse);
  });

  test('Duration.formatted', () {
    expect(const Duration(seconds: 42).formatted, '42s');
    expect(const Duration(minutes: 3, seconds: 5).formatted, '3:05');
    expect(const Duration(hours: 1, minutes: 2, seconds: 3).formatted, '1:02:03');
  });
}
