import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers.dart';

class PuzzleCompletedWidget extends ConsumerWidget {
  const PuzzleCompletedWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            size: 96,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Puzzle completed!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          FilledButton(
            // Generating a new crossword restarts the search and the puzzle.
            onPressed: () => ref.invalidate(workQueueProvider),
            child: const Text('Play again'),
          ),
        ],
      ),
    );
  }
}
