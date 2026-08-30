// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pyq_providers.dart';

// ignore_for_file: type=lint, type=warning

@ProviderFor(lessonPyqs)
final lessonPyqsProvider = LessonPyqsFamily._();

final class LessonPyqsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PyqTeaser>>,
          List<PyqTeaser>,
          FutureOr<List<PyqTeaser>>
        >
    with $FutureModifier<List<PyqTeaser>>, $FutureProvider<List<PyqTeaser>> {
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

  @$internal
  @override
  $FutureProviderElement<List<PyqTeaser>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PyqTeaser>> create(Ref ref) {
    final argument = this.argument as String;
    return lessonPyqs(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonPyqsProvider && other.argument == argument;
  }

  @override
  int get hashCode => argument.hashCode;
}

String _$lessonPyqsHash() => r'1313131313131313131313131313131313131313';

final class LessonPyqsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PyqTeaser>>, String> {
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
}

@ProviderFor(pyqDetail)
final pyqDetailProvider = PyqDetailFamily._();

final class PyqDetailProvider
    extends
        $FunctionalProvider<AsyncValue<PyqDetail>, PyqDetail, FutureOr<PyqDetail>>
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
  int get hashCode => argument.hashCode;
}

String _$pyqDetailHash() => r'1414141414141414141414141414141414141414';

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
}
