import 'plan_tier.dart';

/// One row in the upgrade-screen comparison (included or not on that plan).
class PlanFeatureLine {
  const PlanFeatureLine(this.label, {required this.included});

  final String label;
  final bool included;
}

/// Marketing copy for Free / Pro / Elite — display only.
///
/// Access is still enforced by RLS and `plan_limits`; this list is what we
/// show on the paywall so students can compare before leaving the app.
class PlanOffering {
  const PlanOffering({
    required this.tier,
    required this.tagline,
    required this.features,
  });

  final PlanTier tier;
  final String tagline;
  final List<PlanFeatureLine> features;

  static const List<PlanOffering> comparison = [free, pro, elite];

  static const free = PlanOffering(
    tier: PlanTier.free,
    tagline: 'Try the QBank',
    features: [
      PlanFeatureLine('Free catalog tests', included: true),
      PlanFeatureLine('Pro catalog tests', included: false),
      PlanFeatureLine('Elite catalog tests', included: false),
      PlanFeatureLine('Practice sessions up to 10 questions', included: true),
      PlanFeatureLine('20 practice questions per day', included: true),
      PlanFeatureLine('Full explanations', included: false),
      PlanFeatureLine('Tag filters', included: false),
      PlanFeatureLine('Timer on/off control', included: false),
      PlanFeatureLine('Negative-marking toggle', included: false),
    ],
  );

  static const pro = PlanOffering(
    tier: PlanTier.pro,
    tagline: 'Serious daily practice',
    features: [
      PlanFeatureLine('Free catalog tests', included: true),
      PlanFeatureLine('Pro catalog tests', included: true),
      PlanFeatureLine('Elite catalog tests', included: false),
      PlanFeatureLine('Practice sessions up to 50 questions', included: true),
      PlanFeatureLine('Unlimited daily practice', included: true),
      PlanFeatureLine('Full explanations', included: true),
      PlanFeatureLine('Tag filters', included: true),
      PlanFeatureLine('Timer on/off control', included: true),
      PlanFeatureLine('Negative-marking toggle', included: true),
    ],
  );

  static const elite = PlanOffering(
    tier: PlanTier.elite,
    tagline: 'Everything unlocked',
    features: [
      PlanFeatureLine('Free catalog tests', included: true),
      PlanFeatureLine('Pro catalog tests', included: true),
      PlanFeatureLine('Elite catalog tests', included: true),
      PlanFeatureLine('Practice sessions up to 100 questions', included: true),
      PlanFeatureLine('Unlimited daily practice', included: true),
      PlanFeatureLine('Full explanations', included: true),
      PlanFeatureLine('Tag filters', included: true),
      PlanFeatureLine('Timer on/off control', included: true),
      PlanFeatureLine('Negative-marking toggle', included: true),
    ],
  );
}
