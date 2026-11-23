import 'package:crucigrama/model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Location', () {
    test('directional getters and offsets', () {
      final l = Location.at(3, 4);
      expect(l.left, Location.at(2, 4));
      expect(l.right, Location.at(4, 4));
      expect(l.up, Location.at(3, 3));
      expect(l.down, Location.at(3, 5));
      expect(l.rightOffset(5), Location.at(8, 4));
      expect(l.downOffset(2), Location.at(3, 6));
      expect(l.prettyPrint(), '(3, 4)');
    });
  });

  group('Crossword', () {
    test('addWord fills the characters map across and down', () {
      final crossword = Crossword.crossword(width: 5, height: 5)
          .addWord(
            location: Location.at(0, 0),
            word: 'cat',
            direction: Direction.across,
          )
          .addWord(
            location: Location.at(0, 0),
            word: 'cow',
            direction: Direction.down,
          );

      expect(crossword.words.length, 2);
      expect(crossword.characters[Location.at(1, 0)]!.character, 'a');
      expect(crossword.characters[Location.at(0, 2)]!.character, 'w');
      final corner = crossword.characters[Location.at(0, 0)]!;
      expect(corner.acrossWord!.word, 'cat');
      expect(corner.downWord!.word, 'cow');
    });

    test('prettyPrintCrossword renders one row per line', () {
      final crossword = Crossword.crossword(width: 3, height: 2).addWord(
        location: Location.at(0, 0),
        word: 'cat',
        direction: Direction.across,
      );
      expect(crossword.prettyPrintCrossword(), 'cat\n   \n');
    });
  });
}
