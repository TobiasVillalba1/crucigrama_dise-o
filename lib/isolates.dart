import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';

import 'model.dart';
import 'utils.dart';

/// Words tried per background call before a location is declared a dead end.
const _maxWordsPerAttempt = 1000;

/// Top-level so the closure passed to [compute] captures nothing unsendable.
///
/// Tries to cross [location] with one of [words] (running in [direction]) and
/// returns the first valid [Crossword], or `null` if none fits.
Crossword? _findFit(
  (Crossword, List<String>, Location, Direction, String?) args,
) {
  final (crossword, words, location, direction, character) = args;

  for (final word in words) {
    // With no character yet (empty grid) the word simply starts at location.
    final offsets = character == null
        ? const [0]
        : [
            for (var i = 0; i < word.length; i++)
              if (word[i] == character) i,
          ];

    for (final offset in offsets) {
      final start = switch (direction) {
        Direction.across => location.leftOffset(offset),
        Direction.down => location.upOffset(offset),
      };
      final candidate = crossword.addWord(
        word: word,
        direction: direction,
        location: start,
      );
      if (candidate != null) {
        return candidate;
      }
    }
  }
  return null;
}

/// Backtracking search: repeatedly picks an open intersection from the
/// [WorkQueue], filters the dictionary to words containing the letter already
/// there, and tries to cross it in a background isolate. Dead ends are
/// removed from the queue. Yields the [WorkQueue] after every iteration so the
/// UI can show both the grid and the search statistics.
Stream<WorkQueue> exploreCrosswordSolutions({
  required Crossword crossword,
  required BuiltSet<String> wordList,
}) async* {
  final random = Random();
  final stopwatch = Stopwatch()..start();

  var workQueue = WorkQueue.from(
    crossword: crossword,
    candidateWords: wordList,
    startLocation: Location.at(0, 0),
  );

  while (!workQueue.isCompleted) {
    final locations = workQueue.locationsToTry.keys;
    final location = locations.elementAt(random.nextInt(locations.length));
    final direction = workQueue.locationsToTry[location]!;
    final character = workQueue.crossword.characters[location]?.character;

    final words =
        workQueue.candidateWords
            .where(
              (word) => character == null
                  ? word.length <= workQueue.crossword.width
                  : word.contains(character),
            )
            .toList()
          ..shuffle(random);

    final candidate = await compute(_findFit, (
      workQueue.crossword,
      words.take(_maxWordsPerAttempt).toList(),
      location,
      direction,
      character,
    ));

    if (candidate == null) {
      workQueue = workQueue.remove(location);
    } else {
      workQueue = workQueue.updateFrom(candidate);
    }
    yield workQueue;
  }

  debugPrint(
    'Generated ${workQueue.crossword.words.length} words in '
    '${stopwatch.elapsed.formatted}',
  );
}
