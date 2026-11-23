import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';

import 'model.dart';
import 'utils.dart';

/// Words tried per worker before a location is declared a dead end.
const _maxWordsPerWorker = 1000;

/// Wall-clock limit for a single worker.
const _maxWorkerDuration = Duration(seconds: 10);

/// Candidate offsets at which [word] could cross a cell holding [character].
/// With no character yet (empty grid) the word simply starts at the location.
List<int> _crossingOffsets(String word, String? character) => character == null
    ? const [0]
    : [
        for (var i = 0; i < word.length; i++)
          if (word[i] == character) i,
      ];

Location _wordStart(Location location, Direction direction, int offset) =>
    switch (direction) {
      Direction.across => location.leftOffset(offset),
      Direction.down => location.upOffset(offset),
    };

/// Backtracking search, parallelised over background isolates. Each round
/// ships the current [WorkQueue] to a coordinator isolate that fans out up to
/// [maxWorkerCount] workers (one per open intersection), then merges their
/// results. Yields the [WorkQueue] after every round so the UI can show both
/// the grid and the search statistics.
Stream<WorkQueue> exploreCrosswordSolutions({
  required Crossword crossword,
  required BuiltSet<String> wordList,
  required int maxWorkerCount,
}) async* {
  final stopwatch = Stopwatch()..start();

  var workQueue = WorkQueue.from(
    crossword: crossword,
    candidateWords: wordList,
    startLocation: Location.at(0, 0),
  );

  while (!workQueue.isCompleted) {
    workQueue = await compute(_generate, (workQueue, maxWorkerCount));
    yield workQueue;
  }

  debugPrint(
    'Generated ${workQueue.crossword.words.length} words in '
    '${stopwatch.elapsed.formatted} using $maxWorkerCount workers',
  );
}

/// Top-level so the closures passed to [compute] capture nothing unsendable.
///
/// Dispatches up to `maxWorkerCount` parallel [_generateCandidate] calls over
/// shuffled open locations, waits for all of them, applies the words that
/// still fit and removes the locations where nothing fit.
Future<WorkQueue> _generate((WorkQueue, int) args) async {
  final (initial, maxWorkerCount) = args;
  final random = Random();
  var workQueue = initial;

  final locations = workQueue.locationsToTry.keys.toList()..shuffle(random);

  final candidateGeneratorFutures = <Future<(Location, Direction, String?)>>[];
  for (final location in locations.take(maxWorkerCount)) {
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

    candidateGeneratorFutures.add(
      compute(_generateCandidate, (
        workQueue.crossword,
        words.take(_maxWordsPerWorker).toList(),
        location,
        direction,
        character,
      )),
    );
  }

  final results = await candidateGeneratorFutures.wait;

  var crossword = workQueue.crossword;
  var changed = false;
  for (final (location, direction, word) in results) {
    if (word == null) {
      // Nothing fit here: a known dead end.
      workQueue = workQueue.remove(location);
      continue;
    }

    // Workers ran in parallel against the same crossword, so an earlier
    // result may have taken the space. Re-validate against the latest grid and
    // simply retry the location next round if it no longer fits.
    final character = crossword.characters[location]?.character;
    for (final offset in _crossingOffsets(word, character)) {
      final next = crossword.addWord(
        word: word,
        direction: direction,
        location: _wordStart(location, direction, offset),
      );
      if (next != null) {
        crossword = next;
        changed = true;
        break;
      }
    }
  }

  return changed ? workQueue.updateFrom(crossword) : workQueue;
}

/// Looks for a word from [words] that crosses [location] validly. Stops after
/// [_maxWordsPerWorker] words or [_maxWorkerDuration]. Returns the location
/// and direction it was asked about plus the word found, or `null` if none.
(Location, Direction, String?) _generateCandidate(
  (Crossword, List<String>, Location, Direction, String?) args,
) {
  final (crossword, words, location, direction, character) = args;
  final stopwatch = Stopwatch()..start();

  for (final word in words.take(_maxWordsPerWorker)) {
    if (stopwatch.elapsed > _maxWorkerDuration) {
      break;
    }
    for (final offset in _crossingOffsets(word, character)) {
      final candidate = crossword.addWord(
        word: word,
        direction: direction,
        location: _wordStart(location, direction, offset),
      );
      if (candidate != null) {
        return (location, direction, word);
      }
    }
  }
  return (location, direction, null);
}
