import 'package:flutter_test/flutter_test.dart';

import 'package:medico/features/tests/domain/catalog_test.dart';
import 'package:medico/features/tests/domain/test_type.dart';
import 'package:medico/features/profile/domain/plan_tier.dart';

void main() {
  group('TestType', () {
    test('fromString maps known values', () {
      expect(TestType.fromString('mini'), TestType.mini);
      expect(TestType.fromString('SUBJECT'), TestType.subject);
      expect(TestType.fromString('mock'), TestType.mock);
      expect(TestType.fromString('grand'), TestType.grand);
    });

    test('label matches UI copy', () {
      expect(TestType.mini.label, 'Mini');
      expect(TestType.subject.label, 'Subject');
      expect(TestType.mock.label, 'Mock');
      expect(TestType.grand.label, 'Grand');
    });
  });

  group('CatalogTest', () {
    test('fromJson parses list fields', () {
      final test = CatalogTest.fromJson({
        'id': 't-1',
        'title': 'Mini Test 1',
        'description': null,
        'test_type': 'mini',
        'required_plan': 'free',
        'is_sectional': false,
        'total_duration_minutes': 30,
        'total_questions': 20,
      });

      expect(test.id, 't-1');
      expect(test.title, 'Mini Test 1');
      expect(test.testType, TestType.mini);
      expect(test.requiredPlan, PlanTier.free);
      expect(test.totalDurationMinutes, 30);
      expect(test.totalQuestions, 20);
      expect(test.durationLabel, '30 min');
    });

    test('durationLabel formats hours and minutes', () {
      final hourOnly = CatalogTest(
        id: 'a',
        title: 'A',
        testType: TestType.mock,
        requiredPlan: PlanTier.free,
        totalDurationMinutes: 120,
        totalQuestions: 100,
        isSectional: false,
      );
      final mixed = CatalogTest(
        id: 'b',
        title: 'B',
        testType: TestType.grand,
        requiredPlan: PlanTier.pro,
        totalDurationMinutes: 210,
        totalQuestions: 180,
        isSectional: true,
      );

      expect(hourOnly.durationLabel, '2h');
      expect(mixed.durationLabel, '3h 30m');
    });
  });
}
