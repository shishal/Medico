// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_providers.dart';

// ignore_for_file: type=lint, type=warning

@ProviderFor(universities)
final universitiesProvider = UniversitiesProvider._();

final class UniversitiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<University>>,
          List<University>,
          FutureOr<List<University>>
        >
    with $FutureModifier<List<University>>, $FutureProvider<List<University>> {
  UniversitiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'universitiesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$universitiesHash();

  @$internal
  @override
  $FutureProviderElement<List<University>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<University>> create(Ref ref) {
    return universities(ref);
  }
}

String _$universitiesHash() => r'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

@ProviderFor(mbbsPhases)
final mbbsPhasesProvider = MbbsPhasesProvider._();

final class MbbsPhasesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MbbsPhase>>,
          List<MbbsPhase>,
          FutureOr<List<MbbsPhase>>
        >
    with $FutureModifier<List<MbbsPhase>>, $FutureProvider<List<MbbsPhase>> {
  MbbsPhasesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mbbsPhasesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mbbsPhasesHash();

  @$internal
  @override
  $FutureProviderElement<List<MbbsPhase>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MbbsPhase>> create(Ref ref) {
    return mbbsPhases(ref);
  }
}

String _$mbbsPhasesHash() => r'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

@ProviderFor(colleges)
final collegesProvider = CollegesFamily._();

final class CollegesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<College>>,
          List<College>,
          FutureOr<List<College>>
        >
    with $FutureModifier<List<College>>, $FutureProvider<List<College>> {
  CollegesProvider._({
    required CollegesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'collegesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$collegesHash();

  @$internal
  @override
  $FutureProviderElement<List<College>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<College>> create(Ref ref) {
    final argument = this.argument as String;
    return colleges(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CollegesProvider && other.argument == argument;
  }

  @override
  int get hashCode => argument.hashCode;
}

String _$collegesHash() => r'cccccccccccccccccccccccccccccccccccccccc';

final class CollegesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<College>>, String> {
  CollegesFamily._()
    : super(
        retry: null,
        name: r'collegesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CollegesProvider call(String universityId) =>
      CollegesProvider._(argument: universityId, from: this);
}

@ProviderFor(phaseSubjects)
final phaseSubjectsProvider = PhaseSubjectsProvider._();

final class PhaseSubjectsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CatalogSubject>>,
          List<CatalogSubject>,
          FutureOr<List<CatalogSubject>>
        >
    with
        $FutureModifier<List<CatalogSubject>>,
        $FutureProvider<List<CatalogSubject>> {
  PhaseSubjectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phaseSubjectsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phaseSubjectsHash();

  @$internal
  @override
  $FutureProviderElement<List<CatalogSubject>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CatalogSubject>> create(Ref ref) {
    return phaseSubjects(ref);
  }
}

String _$phaseSubjectsHash() => r'dddddddddddddddddddddddddddddddddddddddd';

@ProviderFor(subjectTopics)
final subjectTopicsProvider = SubjectTopicsFamily._();

final class SubjectTopicsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CatalogTopic>>,
          List<CatalogTopic>,
          FutureOr<List<CatalogTopic>>
        >
    with
        $FutureModifier<List<CatalogTopic>>,
        $FutureProvider<List<CatalogTopic>> {
  SubjectTopicsProvider._({
    required SubjectTopicsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'subjectTopicsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$subjectTopicsHash();

  @$internal
  @override
  $FutureProviderElement<List<CatalogTopic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CatalogTopic>> create(Ref ref) {
    final argument = this.argument as String;
    return subjectTopics(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SubjectTopicsProvider && other.argument == argument;
  }

  @override
  int get hashCode => argument.hashCode;
}

String _$subjectTopicsHash() => r'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

final class SubjectTopicsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CatalogTopic>>, String> {
  SubjectTopicsFamily._()
    : super(
        retry: null,
        name: r'subjectTopicsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SubjectTopicsProvider call(String subjectId) =>
      SubjectTopicsProvider._(argument: subjectId, from: this);
}

@ProviderFor(topicLessons)
final topicLessonsProvider = TopicLessonsFamily._();

final class TopicLessonsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CatalogLesson>>,
          List<CatalogLesson>,
          FutureOr<List<CatalogLesson>>
        >
    with
        $FutureModifier<List<CatalogLesson>>,
        $FutureProvider<List<CatalogLesson>> {
  TopicLessonsProvider._({
    required TopicLessonsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'topicLessonsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$topicLessonsHash();

  @$internal
  @override
  $FutureProviderElement<List<CatalogLesson>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CatalogLesson>> create(Ref ref) {
    final argument = this.argument as String;
    return topicLessons(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TopicLessonsProvider && other.argument == argument;
  }

  @override
  int get hashCode => argument.hashCode;
}

String _$topicLessonsHash() => r'ffffffffffffffffffffffffffffffffffffffff';

final class TopicLessonsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CatalogLesson>>, String> {
  TopicLessonsFamily._()
    : super(
        retry: null,
        name: r'topicLessonsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TopicLessonsProvider call(String topicId) =>
      TopicLessonsProvider._(argument: topicId, from: this);
}

@ProviderFor(lessonDetail)
final lessonDetailProvider = LessonDetailFamily._();

final class LessonDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<CatalogLesson?>,
          CatalogLesson?,
          FutureOr<CatalogLesson?>
        >
    with $FutureModifier<CatalogLesson?>, $FutureProvider<CatalogLesson?> {
  LessonDetailProvider._({
    required LessonDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lessonDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lessonDetailHash();

  @$internal
  @override
  $FutureProviderElement<CatalogLesson?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CatalogLesson?> create(Ref ref) {
    final argument = this.argument as String;
    return lessonDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode => argument.hashCode;
}

String _$lessonDetailHash() => r'1212121212121212121212121212121212121212';

final class LessonDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CatalogLesson?>, String> {
  LessonDetailFamily._()
    : super(
        retry: null,
        name: r'lessonDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LessonDetailProvider call(String lessonId) =>
      LessonDetailProvider._(argument: lessonId, from: this);
}
