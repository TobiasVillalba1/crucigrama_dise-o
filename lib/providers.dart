import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'isolates.dart';
import 'model.dart' as model;

part 'providers.g.dart';

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

/// Selectable sizes for the pool of background worker isolates.
enum BackgroundWorkers {
  one(1),
  two(2),
  four(4),
  eight(8),
  sixteen(16),
  thirtyTwo(32),
  sixtyFour(64),
  oneTwentyEight(128);

  const BackgroundWorkers(this.count);

  final int count;

  String get label => '$count';
}

@Riverpod(keepAlive: true)
class WorkerCount extends _$WorkerCount {
  @override
  BackgroundWorkers build() => BackgroundWorkers.four;

  void setCount(BackgroundWorkers workers) => state = workers;
}

/// When the current generation run started. Kept alive so the value survives
/// the stats overlay being hidden.
@Riverpod(keepAlive: true)
class StartTime extends _$StartTime {
  @override
  DateTime? build() => null;

  void start() => state = DateTime.now();
}

/// When the current generation run finished (null while running).
@Riverpod(keepAlive: true)
class EndTime extends _$EndTime {
  @override
  DateTime? build() => null;

  void clear() => state = null;
  void end() => state = DateTime.now();
}

@Riverpod(keepAlive: true)
class ShowDisplayInfo extends _$ShowDisplayInfo {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

/// Streams the search state from [exploreCrosswordSolutions]. Watching
/// [sizeProvider] restarts the run whenever the user picks a new size.
@riverpod
Stream<model.WorkQueue> workQueue(Ref ref) async* {
  final size = ref.watch(sizeProvider);
  final workers = ref.watch(workerCountProvider);
  final wordList = await ref.watch(wordListProvider.future);

  ref.read(endTimeProvider.notifier).clear();
  ref.read(startTimeProvider.notifier).start();

  yield* exploreCrosswordSolutions(
    crossword: model.Crossword.crossword(
      width: size.width,
      height: size.height,
    ),
    wordList: wordList,
    maxWorkerCount: workers.count,
  );

  ref.read(endTimeProvider.notifier).end();
}

/// Greedy search tops out well below a full grid; this is the coverage a
/// finished run typically reaches and is used to extrapolate the remaining
/// time.
const _estimatedTotalCoverage = 0.54;

@riverpod
Duration expectedRemainingTime(Ref ref) {
  final start = ref.watch(startTimeProvider);
  final end = ref.watch(endTimeProvider);
  final workQueue = ref.watch(workQueueProvider).value;

  if (start == null || end != null || workQueue == null) {
    return Duration.zero;
  }

  final crossword = workQueue.crossword;
  final coverage =
      crossword.characters.length / (crossword.width * crossword.height);
  final progress = (coverage / _estimatedTotalCoverage).clamp(0.0, 1.0);
  if (progress <= 0) {
    return Duration.zero;
  }

  final elapsed = DateTime.now().difference(start);
  return elapsed * ((1 - progress) / progress);
}

@riverpod
class DisplayInfo extends _$DisplayInfo {
  @override
  model.DisplayInfo build() {
    return ref.watch(
      workQueueProvider.select(
        (workQueueAsync) => workQueueAsync.when(
          data: (workQueue) => model.DisplayInfo.from(workQueue: workQueue),
          error: (error, stackTrace) => model.DisplayInfo.empty,
          loading: () => model.DisplayInfo.empty,
        ),
      ),
    );
  }
}
