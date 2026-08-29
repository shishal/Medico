import 'package:flutter_test/flutter_test.dart';

import 'package:medico/features/profile/domain/plan_tier.dart';
import 'package:medico/features/profile/domain/user_profile.dart';

void main() {
  UserProfile profile({
    required PlanTier plan,
    DateTime? planExpiresAt,
  }) {
    return UserProfile(
      id: 'user-1',
      plan: plan,
      planExpiresAt: planExpiresAt,
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }

  test('effectivePlan stays paid when expiry is in the future', () {
    final p = profile(
      plan: PlanTier.pro,
      planExpiresAt: DateTime.now().add(const Duration(days: 1)),
    );
    expect(p.effectivePlan, PlanTier.pro);
  });

  test('effectivePlan falls back to free when expiry is in the past', () {
    final p = profile(
      plan: PlanTier.elite,
      planExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    expect(p.effectivePlan, PlanTier.free);
  });

  test('effectivePlan uses stored plan when expiry is null', () {
    final p = profile(plan: PlanTier.pro);
    expect(p.effectivePlan, PlanTier.pro);
  });
}
