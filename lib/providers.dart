import 'dart:async';
import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'isolates.dart';
import 'model.dart' as model;

part 'providers.g.dart';

/// Isolates used to search for the crossword in the background.
const backgroundWorkerCount = 4;

@riverpod
Future<BuiltSet<String>> wordList(Ref ref) async {
  final re = RegExp(r'^[a-z]+$');
  final words = await rootBundle.loadString('assets/words.txt');
  return const LineSplitter()
      .convert(words)
      .toBuiltSet()
      .rebuild(
        (b) => b
          ..map((word) => word.toLowerCase().trim())
          ..where((word) => word.length > 2)
          ..where((word) => re.hasMatch(word)),
      );
}

/// Selectable grid dimensions.
enum CrosswordSize {
  small(width: 20, height: 11),
  medium(width: 40, height: 22),
  large(width: 80, height: 44),
  xlarge(width: 160, height: 88),
  xxlarge(width: 500, height: 500);

  const CrosswordSize({required this.width, required this.height});

  final int width;
  final int height;

  String get label => '$width x $height';
}

@Riverpod(keepAlive: true)
class Size extends _$Size {
  @override
  CrosswordSize build() => CrosswordSize.medium;

  void setSize(CrosswordSize size) => state = size;
}

/// Streams the search state from [exploreCrosswordSolutions]. Watching
/// [sizeProvider] restarts the run whenever the user picks a new size.
@riverpod
Stream<model.WorkQueue> workQueue(Ref ref) async* {
  final size = ref.watch(sizeProvider);
  final wordList = await ref.watch(wordListProvider.future);

  yield* exploreCrosswordSolutions(
    crossword: model.Crossword.crossword(
      width: size.width,
      height: size.height,
    ),
    wordList: wordList,
    maxWorkerCount: backgroundWorkerCount,
  );
}

/// The puzzle game. It stays in the loading state until the background search
/// has finished, then builds the multiple-choice options in an isolate.
@riverpod
class Puzzle extends _$Puzzle {
  @override
  Future<model.CrosswordPuzzleGame> build() {
    // Only rebuilds when the search flips to completed, not on every step.
    final completed = ref.watch(
      workQueueProvider.select(
        (workQueueAsync) => switch (workQueueAsync.value) {
          final queue? when queue.isCompleted => queue,
          _ => null,
        },
      ),
    );

    if (completed == null) {
      // Pending until the search completes; a rebuild replaces this future.
      return Completer<model.CrosswordPuzzleGame>().future;
    }

    return compute(_puzzleFromCrosswordTrampoline, (
      completed.crossword,
      completed.candidateWords,
    ));
  }

  Future<void> selectWord({
    required model.Location location,
    required String word,
    required model.Direction direction,
  }) async {
    final puzzle = state.value;
    if (puzzle == null) {
      return;
    }

    final next = await compute(_puzzleSelectWordTrampoline, (
      puzzle,
      location,
      word,
      direction,
    ));

    if (next != null && ref.mounted) {
      state = AsyncData(next);
    }
  }
}

// Top-level so the closures given to compute never capture the notifier.
Future<model.CrosswordPuzzleGame> _puzzleFromCrosswordTrampoline(
  (model.Crossword, BuiltSet<String>) args,
) async =>
    model.CrosswordPuzzleGame.from(crossword: args.$1, candidateWords: args.$2);

model.CrosswordPuzzleGame? _puzzleSelectWordTrampoline(
  (model.CrosswordPuzzleGame, model.Location, String, model.Direction) args,
) => args.$1.selectWord(location: args.$2, word: args.$3, direction: args.$4);
