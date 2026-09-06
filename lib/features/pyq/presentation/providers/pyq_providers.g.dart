// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pyq_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lessonPyqs)
final lessonPyqsProvider = LessonPyqsFamily._();

final class LessonPyqsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PyqLessonFeed>,
          PyqLessonFeed,
          FutureOr<PyqLessonFeed>
        >
    with $FutureModifier<PyqLessonFeed>, $FutureProvider<PyqLessonFeed> {
  LessonPyqsProvider._({
    required LessonPyqsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lessonPyqsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lessonPyqsHash();

  @override
  String toString() {
    return r'lessonPyqsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PyqLessonFeed> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PyqLessonFeed> create(Ref ref) {
    final argument = this.argument as String;
    return lessonPyqs(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonPyqsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lessonPyqsHash() => r'ac051abcc090571a9a0fc6b05b77c3ef4d30ca33';

final class LessonPyqsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PyqLessonFeed>, String> {
  LessonPyqsFamily._()
    : super(
        retry: null,
        name: r'lessonPyqsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LessonPyqsProvider call(String lessonId) =>
      LessonPyqsProvider._(argument: lessonId, from: this);

  @override
  String toString() => r'lessonPyqsProvider';
}

/// Kept alive so leaving the subject and coming back does not re-show
/// the loading spinner while the feed is fetched again.

@ProviderFor(subjectPyqs)
final subjectPyqsProvider = SubjectPyqsFamily._();

/// Kept alive so leaving the subject and coming back does not re-show
/// the loading spinner while the feed is fetched again.

final class SubjectPyqsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PyqSubjectFeed>,
          PyqSubjectFeed,
          FutureOr<PyqSubjectFeed>
        >
    with $FutureModifier<PyqSubjectFeed>, $FutureProvider<PyqSubjectFeed> {
  /// Kept alive so leaving the subject and coming back does not re-show
  /// the loading spinner while the feed is fetched again.
  SubjectPyqsProvider._({
    required SubjectPyqsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'subjectPyqsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$subjectPyqsHash();

  @override
  String toString() {
    return r'subjectPyqsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PyqSubjectFeed> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PyqSubjectFeed> create(Ref ref) {
    final argument = this.argument as String;
    return subjectPyqs(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SubjectPyqsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$subjectPyqsHash() => r'51191e4a7c9e0ead37e6bd15fdc795a7a01fbb8a';

/// Kept alive so leaving the subject and coming back does not re-show
/// the loading spinner while the feed is fetched again.

final class SubjectPyqsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PyqSubjectFeed>, String> {
  SubjectPyqsFamily._()
    : super(
        retry: null,
        name: r'subjectPyqsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Kept alive so leaving the subject and coming back does not re-show
  /// the loading spinner while the feed is fetched again.

  SubjectPyqsProvider call(String subjectId) =>
      SubjectPyqsProvider._(argument: subjectId, from: this);

  @override
  String toString() => r'subjectPyqsProvider';
}

@ProviderFor(pyqDetail)
final pyqDetailProvider = PyqDetailFamily._();

final class PyqDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<PyqDetail>,
          PyqDetail,
          FutureOr<PyqDetail>
        >
    with $FutureModifier<PyqDetail>, $FutureProvider<PyqDetail> {
  PyqDetailProvider._({
    required PyqDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pyqDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pyqDetailHash();

  @override
  String toString() {
    return r'pyqDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PyqDetail> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PyqDetail> create(Ref ref) {
    final argument = this.argument as String;
    return pyqDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PyqDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pyqDetailHash() => r'8745bc3a0effe519046e16754fab8098ba9b116f';

final class PyqDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PyqDetail>, String> {
  PyqDetailFamily._()
    : super(
        retry: null,
        name: r'pyqDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PyqDetailProvider call(String questionId) =>
      PyqDetailProvider._(argument: questionId, from: this);

  @override
  String toString() => r'pyqDetailProvider';
}
