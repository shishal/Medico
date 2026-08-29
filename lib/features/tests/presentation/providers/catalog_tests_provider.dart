import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../data/tests_repository.dart';
import '../../domain/catalog_test.dart';

part 'catalog_tests_provider.g.dart';

/// Catalog teasers (including locked higher-plan tests) for the signed-in user.
///
/// Rebuilds on sign-in/out. Call [refresh] after you expect the set to change
/// (e.g. plan upgrade reflected in Supabase). Lock state is computed in the
/// list UI from [currentPlanProvider], not here.
@Riverpod(keepAlive: true)
class CatalogTestsNotifier extends _$CatalogTestsNotifier {
  @override
  Future<List<CatalogTest>> build() async {
    final isSignedIn = ref.watch(authSessionProvider);
    if (!isSignedIn) return const [];

    final result = await ref.read(testsRepositoryProvider).fetchCatalogTests();
    return switch (result) {
      Success(:final value) => value,
      Failure(:final message) => throw Exception(message),
    };
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
