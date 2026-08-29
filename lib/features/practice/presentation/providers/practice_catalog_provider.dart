import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../data/practice_repository.dart';
import '../../domain/practice_catalog.dart';

part 'practice_catalog_provider.g.dart';

/// Subjects, topics, and tags for the Practice Builder.
@Riverpod(keepAlive: true)
class PracticeCatalogNotifier extends _$PracticeCatalogNotifier {
  @override
  Future<PracticeCatalog> build() async {
    final isSignedIn = ref.watch(authSessionProvider);
    if (!isSignedIn) {
      return const PracticeCatalog(subjects: [], topics: [], tags: []);
    }

    final result = await ref.read(practiceRepositoryProvider).fetchCatalog();
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
