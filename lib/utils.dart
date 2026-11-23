import 'dart:math';

import 'package:built_collection/built_collection.dart';

final _random = Random();

extension RandomElements<E> on BuiltSet<E> {
  /// Returns a uniformly random element of this (non-empty) set.
  E randomElement() => elementAt(_random.nextInt(length));
}
