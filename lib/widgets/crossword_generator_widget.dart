import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../model.dart';
import '../providers.dart';

/// Shown while the crossword is being generated: occupied cells show a '•'
/// (the letters stay hidden) and cells on the search frontier are highlighted.
class CrosswordGeneratorWidget extends ConsumerWidget {
  const CrosswordGeneratorWidget({super.key});

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
          // Only this cell rebuilds when its own state changes.
          final occupied = ref.watch(
            workQueueProvider.select(
              (workQueueAsync) => workQueueAsync.when(
                data: (workQueue) =>
                    workQueue.crossword.characters.containsKey(location),
                error: (error, stackTrace) => false,
                loading: () => false,
              ),
            ),
          );
          final explorationCell = ref.watch(
            workQueueProvider.select(
              (workQueueAsync) => workQueueAsync.when(
                data: (workQueue) =>
                    workQueue.locationsToTry.containsKey(location),
                error: (error, stackTrace) => false,
                loading: () => false,
              ),
            ),
          );
          final colors = Theme.of(context).colorScheme;

          return AnimatedContainer(
            duration: Durations.extralong1,
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: explorationCell
                  ? colors.primary
                  : occupied
                  ? Colors.white
                  : colors.primaryContainer,
              border: Border.all(color: colors.onSurface),
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: Durations.extralong1,
                curve: Curves.easeInOut,
                style: TextStyle(
                  color: explorationCell
                      ? colors.onPrimary
                      : colors.onPrimaryContainer,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                child: Text(occupied ? '•' : ''),
              ),
            ),
          );
        },
      ),
    );
  }
}
