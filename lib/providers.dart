import 'dart:convert';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'model.dart' as model;
import 'utils.dart';

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

/// Places random words at random locations and directions every 100 ms until
/// 80% of the grid cells are filled. Watching [sizeProvider] restarts the
/// stream whenever the user picks a different grid size.
@riverpod
Stream<model.Crossword> crossword(Ref ref) async* {
  final size = ref.watch(sizeProvider);
  final wordList = await ref.watch(wordListProvider.future);
  final random = Random();

  var crossword = model.Crossword.crossword(
    width: size.width,
    height: size.height,
  );
  yield crossword;

  final totalCells = size.width * size.height;
  while (_filledCells(crossword) / totalCells < 0.8) {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final word = wordList.randomElement();
    final location = model.Location.at(
      random.nextInt(size.width),
      random.nextInt(size.height),
    );
    final direction = random.nextBool()
        ? model.Direction.across
        : model.Direction.down;

    crossword = crossword.addWord(
      location: location,
      word: word,
      direction: direction,
    );
    yield crossword;
  }
}

int _filledCells(model.Crossword crossword) => crossword.characters.keys
    .where(
      (l) => l.x >= 0 && l.x < crossword.width && l.y >= 0 && l.y < crossword.height,
    )
    .length;
