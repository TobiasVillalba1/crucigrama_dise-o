// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wordList)
final wordListProvider = WordListProvider._();

final class WordListProvider
    extends
        $FunctionalProvider<
          AsyncValue<BuiltSet<String>>,
          BuiltSet<String>,
          FutureOr<BuiltSet<String>>
        >
    with $FutureModifier<BuiltSet<String>>, $FutureProvider<BuiltSet<String>> {
  WordListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wordListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wordListHash();

  @$internal
  @override
  $FutureProviderElement<BuiltSet<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BuiltSet<String>> create(Ref ref) {
    return wordList(ref);
  }
}

String _$wordListHash() => r'07003444d7241448561b638500001e31610b4717';

@ProviderFor(Size)
final sizeProvider = SizeProvider._();

final class SizeProvider extends $NotifierProvider<Size, CrosswordSize> {
  SizeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sizeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sizeHash();

  @$internal
  @override
  Size create() => Size();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrosswordSize value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrosswordSize>(value),
    );
  }
}

String _$sizeHash() => r'eb133b42965790fb371fcf8cd0f69b29b5199947';

abstract class _$Size extends $Notifier<CrosswordSize> {
  CrosswordSize build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CrosswordSize, CrosswordSize>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CrosswordSize, CrosswordSize>,
              CrosswordSize,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Streams the search state from [exploreCrosswordSolutions]. Watching
/// [sizeProvider] restarts the run whenever the user picks a new size.

@ProviderFor(workQueue)
final workQueueProvider = WorkQueueProvider._();

/// Streams the search state from [exploreCrosswordSolutions]. Watching
/// [sizeProvider] restarts the run whenever the user picks a new size.

final class WorkQueueProvider
    extends
        $FunctionalProvider<
          AsyncValue<model.WorkQueue>,
          model.WorkQueue,
          Stream<model.WorkQueue>
        >
    with $FutureModifier<model.WorkQueue>, $StreamProvider<model.WorkQueue> {
  /// Streams the search state from [exploreCrosswordSolutions]. Watching
  /// [sizeProvider] restarts the run whenever the user picks a new size.
  WorkQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workQueueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workQueueHash();

  @$internal
  @override
  $StreamProviderElement<model.WorkQueue> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<model.WorkQueue> create(Ref ref) {
    return workQueue(ref);
  }
}

String _$workQueueHash() => r'd2c177deb5964f3ec7e9c339c7d6ee7b9a31f1a1';

/// The puzzle game. It stays in the loading state until the background search
/// has finished, then builds the multiple-choice options in an isolate.

@ProviderFor(Puzzle)
final puzzleProvider = PuzzleProvider._();

/// The puzzle game. It stays in the loading state until the background search
/// has finished, then builds the multiple-choice options in an isolate.
final class PuzzleProvider
    extends $AsyncNotifierProvider<Puzzle, model.CrosswordPuzzleGame> {
  /// The puzzle game. It stays in the loading state until the background search
  /// has finished, then builds the multiple-choice options in an isolate.
  PuzzleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'puzzleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$puzzleHash();

  @$internal
  @override
  Puzzle create() => Puzzle();
}

String _$puzzleHash() => r'8d821a79497975ad918fd4e780dd98208f17a674';

/// The puzzle game. It stays in the loading state until the background search
/// has finished, then builds the multiple-choice options in an isolate.

abstract class _$Puzzle extends $AsyncNotifier<model.CrosswordPuzzleGame> {
  FutureOr<model.CrosswordPuzzleGame> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<model.CrosswordPuzzleGame>,
              model.CrosswordPuzzleGame
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<model.CrosswordPuzzleGame>,
                model.CrosswordPuzzleGame
              >,
              AsyncValue<model.CrosswordPuzzleGame>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
