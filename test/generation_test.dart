import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:crucigrama/isolates.dart';
import 'package:crucigrama/model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parallel generation produces a valid crossword', () async {
    final words = File('assets/words.txt')
        .readAsLinesSync()
        .map((w) => w.toLowerCase().trim())
        .where((w) => w.length > 2 && w.length <= 8)
        .take(20000)
        .toBuiltSet();

    final last = await exploreCrosswordSolutions(
      crossword: Crossword.crossword(width: 20, height: 11),
      wordList: words,
      maxWorkerCount: 4,
    ).last;

    expect(last.crossword.words.length, greaterThan(5));
    expect(last.crossword.valid, isTrue);
    expect(last.isCompleted, isTrue);
    // ignore: avoid_print
    print(last.crossword.prettyPrintCrossword());
  }, timeout: const Timeout(Duration(minutes: 3)));
}
