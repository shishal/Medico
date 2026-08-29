// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_plan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Effective plan for UI gating (lock icons, upgrade prompts, builder limits).
///
/// Reads [UserProfile.effectivePlan] so expiry logic lives in one place.
/// RLS still enforces access on the server — this is display-only.
///
/// Usage from any screen:
/// ```dart
/// final plan = ref.watch(currentPlanProvider).value;
/// if (plan == PlanTier.free) { /* show lock */ }
/// ```

@ProviderFor(currentPlan)
final currentPlanProvider = CurrentPlanProvider._();

/// Effective plan for UI gating (lock icons, upgrade prompts, builder limits).
///
/// Reads [UserProfile.effectivePlan] so expiry logic lives in one place.
/// RLS still enforces access on the server — this is display-only.
///
/// Usage from any screen:
/// ```dart
/// final plan = ref.watch(currentPlanProvider).value;
/// if (plan == PlanTier.free) { /* show lock */ }
/// ```

final class CurrentPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlanTier?>,
          PlanTier?,
          FutureOr<PlanTier?>
        >
    with $FutureModifier<PlanTier?>, $FutureProvider<PlanTier?> {
  /// Effective plan for UI gating (lock icons, upgrade prompts, builder limits).
  ///
  /// Reads [UserProfile.effectivePlan] so expiry logic lives in one place.
  /// RLS still enforces access on the server — this is display-only.
  ///
  /// Usage from any screen:
  /// ```dart
  /// final plan = ref.watch(currentPlanProvider).value;
  /// if (plan == PlanTier.free) { /* show lock */ }
  /// ```
  CurrentPlanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentPlanProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentPlanHash();

  @$internal
  @override
  $FutureProviderElement<PlanTier?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PlanTier?> create(Ref ref) {
    return currentPlan(ref);
  }
}

String _$currentPlanHash() => r'53f4f336f994e4faba672303cd84cf94c2e8133c';
