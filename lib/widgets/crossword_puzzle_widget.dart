import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../model.dart';
import '../providers.dart';

/// The playable grid. Tapping an occupied cell opens a menu with the options
/// for the across and down words that pass through it.
class CrosswordPuzzleWidget extends ConsumerWidget {
  const CrosswordPuzzleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ref.watch(sizeProvider);

    return TableView.builder(
      diagonalDragBehavior: DiagonalDragBehavior.free,
      cellBuilder: _buildCell,
      columnCount: size.width,
      columnBuilder: (index) => TableSpan(extent: FixedTableSpanExtent(32)),
      rowCount: size.height,
      rowBuilder: (index) => TableSpan(extent: FixedTableSpanExtent(32)),
    );
  }

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    final location = Location.at(vicinity.column, vicinity.row);

    return TableViewCell(
      child: Consumer(
        builder: (context, ref, _) {
          final colors = Theme.of(context).colorScheme;

          // The solution's cell: null means this cell is not part of any word.
          final solutionCell = ref.watch(
            puzzleProvider.select(
              (puzzleAsync) => puzzleAsync.value?.crossword.characters[location],
            ),
          );
          // Cells outside any word: light blue, like the empty background.
          if (solutionCell == null) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                border: Border.all(color: colors.onSurface),
              ),
            );
          }

          // The letter the player has placed here, if any.
          final placed = ref.watch(
            puzzleProvider.select(
              (puzzleAsync) => puzzleAsync
                  .value
                  ?.crosswordFromSelectedWords
                  .characters[location]
                  ?.character,
            ),
          );

          // Options never change for a given puzzle, so read them once.
          final alternateWords = ref.read(puzzleProvider).value!.alternateWords;

          return MenuAnchor(
            menuChildren: [
              for (final word in [solutionCell.acrossWord, solutionCell.downWord])
                if (word != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      word.direction == Direction.across ? 'Across' : 'Down',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  for (final alternate
                      in alternateWords[word.location]![word.direction]!)
                    _WordSelectMenuItem(
                      location: word.location,
                      word: alternate,
                      direction: word.direction,
                    ),
                ],
            ],
            builder: (context, controller, child) {
              return GestureDetector(
                onTap: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  // Word cells are white; the letter appears once chosen.
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: colors.onSurface),
                    ),
                    child: Center(
                      child: Text(
                        placed?.toUpperCase() ?? '',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WordSelectMenuItem extends ConsumerWidget {
  const _WordSelectMenuItem({
    required this.location,
    required this.word,
    required this.direction,
  });

  final Location location;
  final String word;
  final Direction direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(puzzleProvider.notifier);

    final canSelect = ref.watch(
      puzzleProvider.select(
        (puzzleAsync) =>
            puzzleAsync.value?.canSelectWord(
              location: location,
              word: word,
              direction: direction,
            ) ??
            false,
      ),
    );
    final selected = ref.watch(
      puzzleProvider.select(
        (puzzleAsync) =>
            puzzleAsync.value?.selectedWords.any(
              (w) =>
                  w.location == location &&
                  w.direction == direction &&
                  w.word == word,
            ) ??
            false,
      ),
    );

    return MenuItemButton(
      onPressed: canSelect
          ? () => notifier.selectWord(
              location: location,
              word: word,
              direction: direction,
            )
          : null,
      leadingIcon: Icon(selected ? Icons.check : null, size: 20),
      child: Text(word.toUpperCase()),
    );
  }
}
