// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Plan-gated test row for the instructions screen.
///
/// Throws with the repository message on failure (including "not on your plan")
/// so the screen can show a dedicated upgrade path vs a generic retry.

@ProviderFor(testDetail)
final testDetailProvider = TestDetailFamily._();

/// Plan-gated test row for the instructions screen.
///
/// Throws with the repository message on failure (including "not on your plan")
/// so the screen can show a dedicated upgrade path vs a generic retry.

final class TestDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<TestDetail>,
          TestDetail,
          FutureOr<TestDetail>
        >
    with $FutureModifier<TestDetail>, $FutureProvider<TestDetail> {
  /// Plan-gated test row for the instructions screen.
  ///
  /// Throws with the repository message on failure (including "not on your plan")
  /// so the screen can show a dedicated upgrade path vs a generic retry.
  TestDetailProvider._({
    required TestDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'testDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$testDetailHash();

  @override
  String toString() {
    return r'testDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TestDetail> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TestDetail> create(Ref ref) {
    final argument = this.argument as String;
    return testDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TestDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$testDetailHash() => r'ad8e42693ccb13cb701c44e3802ea994efa24bcc';

/// Plan-gated test row for the instructions screen.
///
/// Throws with the repository message on failure (including "not on your plan")
/// so the screen can show a dedicated upgrade path vs a generic retry.

final class TestDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TestDetail>, String> {
  TestDetailFamily._()
    : super(
        retry: null,
        name: r'testDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Plan-gated test row for the instructions screen.
  ///
  /// Throws with the repository message on failure (including "not on your plan")
  /// so the screen can show a dedicated upgrade path vs a generic retry.

  TestDetailProvider call(String testId) =>
      TestDetailProvider._(argument: testId, from: this);

  @override
  String toString() => r'testDetailProvider';
}
