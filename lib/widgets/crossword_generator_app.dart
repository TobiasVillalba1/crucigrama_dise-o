import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers.dart';

class CrosswordGeneratorApp extends StatelessWidget {
  const CrosswordGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _EagerInitialization(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Crossword Generator'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Consumer(
          builder: (context, ref, child) {
            final wordListAsync = ref.watch(wordListProvider);
            return wordListAsync.when(
              data: (wordList) => ListView.builder(
                itemCount: wordList.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(wordList.elementAt(index)));
                },
              ),
              error: (error, stackTrace) => Center(child: Text('$error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }
}

/// Watches [wordListProvider] near the root of the tree so the dictionary
/// starts loading immediately at startup instead of on first read.
class _EagerInitialization extends ConsumerWidget {
  const _EagerInitialization({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(wordListProvider);
    return child;
  }
}
