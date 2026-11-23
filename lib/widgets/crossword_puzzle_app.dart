import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers.dart';
import 'crossword_generator_widget.dart';
import 'crossword_puzzle_widget.dart';
import 'puzzle_completed_widget.dart';

class CrosswordPuzzleApp extends StatelessWidget {
  const CrosswordPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crossword Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        brightness: Brightness.light,
      ),
      home: const _EagerInitialization(child: _PuzzleScaffold()),
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

class _PuzzleScaffold extends StatelessWidget {
  const _PuzzleScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossword Puzzle'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: const [_CrosswordPuzzleMenu()],
      ),
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, child) {
            final puzzleAsync = ref.watch(puzzleProvider);
            return puzzleAsync.when(
              data: (puzzle) => puzzle.solved
                  ? const PuzzleCompletedWidget()
                  : const CrosswordPuzzleWidget(),
              error: (error, stackTrace) => Center(child: Text('$error')),
              loading: () => const CrosswordGeneratorWidget(),
            );
          },
        ),
      ),
    );
  }
}

class _CrosswordPuzzleMenu extends ConsumerWidget {
  const _CrosswordPuzzleMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSize = ref.watch(sizeProvider);

    return MenuAnchor(
      menuChildren: [
        for (final size in CrosswordSize.values)
          MenuItemButton(
            leadingIcon: Icon(
              size == currentSize ? Icons.check : null,
              size: 20,
            ),
            onPressed: () => ref.read(sizeProvider.notifier).setSize(size),
            child: Text(size.label),
          ),
      ],
      builder: (context, controller, child) {
        return IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        );
      },
    );
  }
}
