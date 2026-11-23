import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../model.dart';
import '../providers.dart';

class CrosswordWidget extends ConsumerStatefulWidget {
  const CrosswordWidget({super.key});

  @override
  ConsumerState<CrosswordWidget> createState() => _CrosswordWidgetState();
}

class _CrosswordWidgetState extends ConsumerState<CrosswordWidget> {
  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = ref.watch(sizeProvider);

    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        notificationPredicate: (notification) => notification.depth == 1,
        child: TableView.builder(
          verticalDetails: ScrollableDetails.vertical(
            controller: _verticalController,
          ),
          horizontalDetails: ScrollableDetails.horizontal(
            controller: _horizontalController,
          ),
          diagonalDragBehavior: DiagonalDragBehavior.free,
          cellBuilder: _buildCell,
          columnCount: size.width,
          columnBuilder: (index) =>
              TableSpan(extent: FixedTableSpanExtent(32)),
          rowCount: size.height,
          rowBuilder: (index) => TableSpan(extent: FixedTableSpanExtent(32)),
        ),
      ),
    );
  }

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    final location = Location.at(vicinity.column, vicinity.row);

    return TableViewCell(
      child: Consumer(
        builder: (context, ref, _) {
          // Only this cell rebuilds when its own character changes.
          final character = ref.watch(
            crosswordProvider.select(
              (crosswordAsync) => crosswordAsync.when(
                data: (crossword) => crossword.characters[location],
                error: (error, stackTrace) => null,
                loading: () => null,
              ),
            ),
          );
          final colors = Theme.of(context).colorScheme;

          return Container(
            margin: const EdgeInsets.all(1),
            color: character == null
                ? colors.surfaceContainerHighest
                : colors.primaryContainer,
            child: Center(
              child: Text(
                character?.character.toUpperCase() ?? '',
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
