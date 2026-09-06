// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ug_home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(studyProgress)
final studyProgressProvider = StudyProgressProvider._();

final class StudyProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<StudyProgress>,
          StudyProgress,
          FutureOr<StudyProgress>
        >
    with $FutureModifier<StudyProgress>, $FutureProvider<StudyProgress> {
  StudyProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'studyProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$studyProgressHash();

  @$internal
  @override
  $FutureProviderElement<StudyProgress> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StudyProgress> create(Ref ref) {
    return studyProgress(ref);
  }
}

String _$studyProgressHash() => r'd1a3e995995bdeff8e5147d6ad546cd1b711a871';

@ProviderFor(trackerList)
final trackerListProvider = TrackerListProvider._();

final class TrackerListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TrackerSummary>>,
          List<TrackerSummary>,
          FutureOr<List<TrackerSummary>>
        >
    with
        $FutureModifier<List<TrackerSummary>>,
        $FutureProvider<List<TrackerSummary>> {
  TrackerListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackerListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackerListHash();

  @$internal
  @override
  $FutureProviderElement<List<TrackerSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TrackerSummary>> create(Ref ref) {
    return trackerList(ref);
  }
}

String _$trackerListHash() => r'427b1fa16269cf9ca20e562f21ff6eec04ee75c5';
