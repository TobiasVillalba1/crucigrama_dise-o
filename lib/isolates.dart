import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';

import 'model.dart';
import 'utils.dart';

/// Gives up after this many consecutive rejected candidates (random placement
/// rarely reaches 80% coverage on its own).
const _maxConsecutiveFailures = 2000;

/// Top-level so the closure passed to [compute] captures nothing unsendable.
Crossword? _tryAddWord((Crossword, String, Direction, Location) args) {
  final (crossword, word, direction, location) = args;
  return crossword.addWord(word: word, direction: direction, location: location);
}

int _filledCells(Crossword crossword) => crossword.characters.length;

/// Tries random word placements, validating each candidate in a background
/// isolate, and yields every valid [Crossword] until 80% of the cells are
/// filled.
Stream<Crossword> exploreCrosswordSolutions({
  required Crossword crossword,
  required BuiltSet<String> wordList,
}) async* {
  final random = Random();
  final totalCells = crossword.width * crossword.height;
  var failures = 0;

  while (_filledCells(crossword) / totalCells < 0.8 &&
      failures < _maxConsecutiveFailures) {
    final word = wordList.randomElement();
    final direction = random.nextBool() ? Direction.across : Direction.down;
    final location = Location.at(
      random.nextInt(crossword.width),
      random.nextInt(crossword.height),
    );

    final candidate = await compute(_tryAddWord, (
      crossword,
      word,
      direction,
      location,
    ));

    if (candidate == null) {
      failures++;
      continue;
    }
    failures = 0;
    crossword = candidate;
    yield crossword;
  }
}
