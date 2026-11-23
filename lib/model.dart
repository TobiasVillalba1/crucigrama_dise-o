import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:characters/characters.dart';

part 'model.g.dart';

/// Returns a serializer collection for the crossword model types.
@SerializersFor([Location, Crossword, CrosswordWord, CrosswordCharacter])
final Serializers serializers = _$serializers;

/// A 0-based (x, y) coordinate on the crossword grid.
abstract class Location implements Built<Location, LocationBuilder> {
  static Serializer<Location> get serializer => _$locationSerializer;

  int get x;
  int get y;

  Location get left => rebuild((b) => b..x = x - 1);
  Location get right => rebuild((b) => b..x = x + 1);
  Location get up => rebuild((b) => b..y = y - 1);
  Location get down => rebuild((b) => b..y = y + 1);

  Location leftOffset(int offset) => rebuild((b) => b..x = x - offset);
  Location rightOffset(int offset) => rebuild((b) => b..x = x + offset);
  Location upOffset(int offset) => rebuild((b) => b..y = y - offset);
  Location downOffset(int offset) => rebuild((b) => b..y = y + offset);

  String prettyPrint() => '($x, $y)';

  factory Location.at(int x, int y) =>
      Location((b) => b
        ..x = x
        ..y = y);

  Location._();
  factory Location([void Function(LocationBuilder)? updates]) = _$Location;
}

enum Direction {
  across,
  down;

  @override
  String toString() => name;
}

/// A word placed on the grid, starting at [location] and running in
/// [direction].
abstract class CrosswordWord
    implements Built<CrosswordWord, CrosswordWordBuilder> {
  static Serializer<CrosswordWord> get serializer => _$crosswordWordSerializer;

  String get word;
  Location get location;
  Direction get direction;

  /// Orders words by row first, then by column.
  static int locationComparator(CrosswordWord a, CrosswordWord b) {
    final compareRows = a.location.y.compareTo(b.location.y);
    if (compareRows != 0) {
      return compareRows;
    }
    return a.location.x.compareTo(b.location.x);
  }

  factory CrosswordWord.word({
    required String word,
    required Location location,
    required Direction direction,
  }) => CrosswordWord(
    (b) => b
      ..word = word
      ..direction = direction
      ..location.replace(location),
  );

  CrosswordWord._();
  factory CrosswordWord([void Function(CrosswordWordBuilder)? updates]) =
      _$CrosswordWord;
}

/// A single cell of the grid and the words that pass through it.
abstract class CrosswordCharacter
    implements Built<CrosswordCharacter, CrosswordCharacterBuilder> {
  static Serializer<CrosswordCharacter> get serializer =>
      _$crosswordCharacterSerializer;

  String get character;
  CrosswordWord? get acrossWord;
  CrosswordWord? get downWord;

  factory CrosswordCharacter.character({
    required String character,
    CrosswordWord? acrossWord,
    CrosswordWord? downWord,
  }) => CrosswordCharacter((b) {
    b.character = character;
    if (acrossWord != null) {
      b.acrossWord.replace(acrossWord);
    }
    if (downWord != null) {
      b.downWord.replace(downWord);
    }
  });

  CrosswordCharacter._();
  factory CrosswordCharacter([
    void Function(CrosswordCharacterBuilder)? updates,
  ]) = _$CrosswordCharacter;
}

/// An immutable crossword: a list of words and a derived location -> character
/// map used for fast lookups from the UI.
abstract class Crossword implements Built<Crossword, CrosswordBuilder> {
  static Serializer<Crossword> get serializer => _$crosswordSerializer;

  int get width;
  int get height;
  BuiltList<CrosswordWord> get words;
  BuiltMap<Location, CrosswordCharacter> get characters;

  /// Adds [word] at [location] running in [direction].
  ///
  /// At this stage no validation is performed, so words can overwrite each
  /// other. Constraints are enforced in a later step.
  Crossword addWord({
    required Location location,
    required String word,
    required Direction direction,
  }) {
    return rebuild(
      (b) => b
        ..words.add(
          CrosswordWord.word(
            word: word,
            direction: direction,
            location: location,
          ),
        ),
    );
  }

  /// Recomputes [characters] from [words] every time a builder is finalized.
  @BuiltValueHook(finalizeBuilder: true)
  static void _fillCharacters(CrosswordBuilder b) {
    b.characters.clear();

    for (final word in b.words.build()) {
      for (final (idx, character) in word.word.characters.indexed) {
        switch (word.direction) {
          case Direction.across:
            b.characters.updateValue(
              word.location.rightOffset(idx),
              (b) => b.rebuild((bInner) => bInner.acrossWord.replace(word)),
              ifAbsent: () => CrosswordCharacter.character(
                acrossWord: word,
                character: character,
              ),
            );
          case Direction.down:
            b.characters.updateValue(
              word.location.downOffset(idx),
              (b) => b.rebuild((bInner) => bInner.downWord.replace(word)),
              ifAbsent: () => CrosswordCharacter.character(
                downWord: word,
                character: character,
              ),
            );
        }
      }
    }
  }

  /// Renders the grid as text, one row per line.
  String prettyPrintCrossword() {
    final buffer = StringBuffer();
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final character = characters[Location.at(x, y)];
        buffer.write(character?.character ?? ' ');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  factory Crossword.crossword({required int width, required int height}) =>
      Crossword(
        (b) => b
          ..width = width
          ..height = height,
      );

  Crossword._();
  factory Crossword([void Function(CrosswordBuilder)? updates]) = _$Crossword;
}
