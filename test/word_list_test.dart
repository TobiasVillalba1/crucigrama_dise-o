import 'package:crucigrama/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wordList loads only lowercase a-z words longer than 2 chars', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final words = await container.read(wordListProvider.future);

    expect(words.length, greaterThan(200000));
    expect(words.every((w) => w.length > 2), isTrue);
    expect(words.every((w) => RegExp(r'^[a-z]+$').hasMatch(w)), isTrue);
    expect(words.contains('crossword'), isTrue);
  });
}
