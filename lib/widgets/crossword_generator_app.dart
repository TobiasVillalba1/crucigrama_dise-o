import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers.dart';
import 'crossword_info_widget.dart';
import 'crossword_widget.dart';

class CrosswordGeneratorApp extends StatelessWidget {
  const CrosswordGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _EagerInitialization(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Crossword Generator'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: const [_CrosswordGeneratorMenu()],
        ),
        body: SafeArea(
          child: Consumer(
            builder: (context, ref, child) {
              final showInfo = ref.watch(showDisplayInfoProvider);
              return Stack(
                children: [
                  const Positioned.fill(child: CrosswordWidget()),
                  if (showInfo)
                    const Positioned(
                      right: 16,
                      bottom: 16,
                      child: CrosswordInfoWidget(),
                    ),
                ],
              );
            },
          ),
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

class _CrosswordGeneratorMenu extends ConsumerWidget {
  const _CrosswordGeneratorMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSize = ref.watch(sizeProvider);
    final showInfo = ref.watch(showDisplayInfoProvider);

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
        const Divider(),
        MenuItemButton(
          leadingIcon: Icon(showInfo ? Icons.check : null, size: 20),
          onPressed: () => ref.read(showDisplayInfoProvider.notifier).toggle(),
          child: const Text('Display Info'),
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
