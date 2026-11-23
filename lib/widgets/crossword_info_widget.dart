import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers.dart';
import '../utils.dart';
import 'ticker_builder.dart';

/// Floating HUD with live generation statistics.
class CrosswordInfoWidget extends ConsumerWidget {
  const CrosswordInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(displayInfoProvider);
    final startTime = ref.watch(startTimeProvider);
    final endTime = ref.watch(endTimeProvider);
    final remaining = ref.watch(expectedRemainingTimeProvider);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            switch ((startTime, endTime)) {
              (null, _) => const _CrosswordInfoRichText(
                label: 'Time elapsed',
                value: 'Not started yet',
              ),
              (DateTime start, null) => TickerBuilder(
                builder: (context) => _CrosswordInfoRichText(
                  label: 'Time elapsed',
                  value: DateTime.now().difference(start).formatted,
                ),
              ),
              (DateTime start, DateTime end) => _CrosswordInfoRichText(
                label: 'Completed in',
                value: end.difference(start).formatted,
              ),
            },
            if (startTime != null && endTime == null)
              _CrosswordInfoRichText(
                label: 'Expected remaining',
                value: remaining.formatted,
              ),
            _CrosswordInfoRichText(
              label: 'Words in grid',
              value: info.wordsInGridCount,
            ),
            _CrosswordInfoRichText(
              label: 'Candidate words',
              value: info.candidateWordsCount,
            ),
            _CrosswordInfoRichText(
              label: 'Locations to explore',
              value: info.locationsToExploreCount,
            ),
            _CrosswordInfoRichText(
              label: 'Known bad locations',
              value: info.knownBadLocationsCount,
            ),
            _CrosswordInfoRichText(
              label: 'Grid filled',
              value: info.gridFilledPercentage,
            ),
          ],
        ),
      ),
    );
  }
}

class _CrosswordInfoRichText extends StatelessWidget {
  const _CrosswordInfoRichText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
