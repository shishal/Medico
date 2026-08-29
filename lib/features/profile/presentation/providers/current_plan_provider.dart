import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/plan_tier.dart';
import 'user_profile_provider.dart';

part 'current_plan_provider.g.dart';

/// Effective plan for UI gating (lock icons, upgrade prompts, builder limits).
///
/// Reads [UserProfile.effectivePlan] so expiry logic lives in one place.
/// RLS still enforces access on the server — this is display-only.
///
/// Usage from any screen:
/// ```dart
/// final plan = ref.watch(currentPlanProvider).valueOrNull;
/// if (plan == PlanTier.free) { /* show lock */ }
/// ```
@Riverpod(keepAlive: true)
Future<PlanTier?> currentPlan(Ref ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.effectivePlan;
}
