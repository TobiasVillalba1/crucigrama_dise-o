import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:characters/characters.dart';

part 'model.g.dart';

/// Returns a serializer collection for the crossword model types.
@SerializersFor([
  Location,
  Crossword,
  CrosswordWord,
  CrosswordCharacter,
  WorkQueue,
])
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

  /// Whether this crossword satisfies the English crossword constraints:
  ///
  /// * no duplicate words,
  /// * every character is inside the grid (and, by construction, part of at
  ///   least one word),
  /// * vertically adjacent characters share the same down word,
  /// * horizontally adjacent characters share the same across word.
  bool get valid {
    if (words.map((w) => w.word).toSet().length != words.length) {
      return false;
    }

    for (final MapEntry(key: location, value: character)
        in characters.entries) {
      if (location.x < 0 ||
          location.x >= width ||
          location.y < 0 ||
          location.y >= height) {
        return false;
      }
      if (character.acrossWord == null && character.downWord == null) {
        return false;
      }

      final below = characters[location.down];
      if (below != null &&
          (character.downWord == null || character.downWord != below.downWord)) {
        return false;
      }

      final right = characters[location.right];
      if (right != null &&
          (character.acrossWord == null ||
              character.acrossWord != right.acrossWord)) {
        return false;
      }
    }
    return true;
  }

  /// Adds [word] at [location] running in [direction].
  ///
  /// Returns `null` if the word is already in the crossword, conflicts with an
  /// existing character or same-direction word, does not overlap an existing
  /// word (when the crossword is not empty), or would make the crossword
  /// invalid.
  Crossword? addWord({
    required Location location,
    required String word,
    required Direction direction,
  }) {
    if (words.any((w) => w.word == word)) {
      return null;
    }

    var overlaps = false;
    for (final (idx, character) in word.characters.indexed) {
      final at = switch (direction) {
        Direction.across => location.rightOffset(idx),
        Direction.down => location.downOffset(idx),
      };
      final existing = characters[at];
      if (existing == null) {
        continue;
      }
      if (existing.character != character) {
        return null;
      }
      final sameDirectionWord = switch (direction) {
        Direction.across => existing.acrossWord,
        Direction.down => existing.downWord,
      };
      if (sameDirectionWord != null) {
        return null;
      }
      overlaps = true;
    }

    if (words.isNotEmpty && !overlaps) {
      return null;
    }

    final candidate = rebuild(
      (b) => b
        ..words.add(
          CrosswordWord.word(
            word: word,
            direction: direction,
            location: location,
          ),
        ),
    );

    return candidate.valid ? candidate : null;
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

/// The state of the backtracking search: the crossword built so far, the open
/// intersections still worth trying, the ones known to be dead ends and the
/// words not yet used.
abstract class WorkQueue implements Built<WorkQueue, WorkQueueBuilder> {
  static Serializer<WorkQueue> get serializer => _$workQueueSerializer;

  Crossword get crossword;
  BuiltMap<Location, Direction> get locationsToTry;
  BuiltSet<Location> get badLocations;
  BuiltSet<String> get candidateWords;

  bool get isCompleted => locationsToTry.isEmpty || candidateWords.isEmpty;

  /// Seeds a queue for [crossword]: [startLocation] (across) when the grid is
  /// empty, otherwise every character that belongs to exactly one word, with
  /// the perpendicular direction a crossing word would need.
  static WorkQueue from({
    required Crossword crossword,
    required Iterable<String> candidateWords,
    required Location startLocation,
  }) {
    return WorkQueue(
      (b) => b
        ..crossword.replace(crossword)
        ..candidateWords.replace(candidateWords)
        ..locationsToTry.replace(
          crossword.words.isEmpty
              ? {startLocation: Direction.across}
              : _openLocations(crossword, BuiltSet<Location>()),
        ),
    );
  }

  static BuiltMap<Location, Direction> _openLocations(
    Crossword crossword,
    BuiltSet<Location> badLocations,
  ) {
    final result = MapBuilder<Location, Direction>();
    for (final MapEntry(key: location, value: character)
        in crossword.characters.entries) {
      if (badLocations.contains(location)) {
        continue;
      }
      // Characters in two words, or next to a parallel word, can't take
      // another crossing word.
      if (character.acrossWord != null && character.downWord != null) {
        continue;
      }
      result[location] = switch ((character.acrossWord, character.downWord)) {
        (null, null) => throw StateError('Character is not part of a word'),
        (null, _) => Direction.across,
        (_, null) => Direction.down,
        (_, _) => throw StateError('Character is part of two words'),
      };
    }
    return result.build();
  }

  /// Marks [location] as a dead end and removes it from the queue.
  WorkQueue remove(Location location) {
    return rebuild(
      (b) => b
        ..locationsToTry.remove(location)
        ..badLocations.add(location),
    );
  }

  /// Adopts [crossword] (a valid extension of the current one): drops the
  /// words it used from the candidates and recomputes the open locations,
  /// keeping the known bad ones out.
  WorkQueue updateFrom(Crossword crossword) {
    return rebuild(
      (b) => b
        ..crossword.replace(crossword)
        ..candidateWords.removeAll(crossword.words.map((w) => w.word))
        ..locationsToTry.replace(_openLocations(crossword, badLocations)),
    );
  }

  WorkQueue._();
  factory WorkQueue([void Function(WorkQueueBuilder)? updates]) = _$WorkQueue;
}
