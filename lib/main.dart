import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'widgets/crossword_puzzle_app.dart';

void main() {
  runApp(ProviderScope(child: CrosswordPuzzleApp()));
}
