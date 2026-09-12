import 'package:flutter_test/flutter_test.dart';
import 'package:medico/core/supabase/tables.dart';
import 'package:medico/features/catalog/domain/catalog_models.dart';

void main() {
  test('University equality is by id so the picker checkmark works', () {
    const a = University(
      id: 'u1',
      code: 'KUHS',
      name: 'Kerala University of Health Sciences',
      state: 'Kerala',
      slug: 'kuhs',
    );
    const b = University(
      id: 'u1',
      code: 'KUHS',
      name: 'Kerala University of Health Sciences',
      state: 'Kerala',
      slug: 'kuhs',
    );
    expect(a, equals(b));
  });
}
