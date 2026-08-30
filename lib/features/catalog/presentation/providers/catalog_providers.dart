import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../data/catalog_repository.dart';
import '../../domain/catalog_models.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';

part 'catalog_providers.g.dart';

/// Year the student is browsing on Home. Null = follow the profile year.
/// Tapping a year sticker writes here so subjects can change immediately.
@Riverpod(keepAlive: true)
class CatalogBrowsePhase extends _$CatalogBrowsePhase {
  @override
  String? build() => null;

  void select(String phaseId) => state = phaseId;

  /// After the profile year is saved, Home should follow it again.
  void followProfile() => state = null;
}

/// Effective catalog year: explicit browse selection, else onboarding year.
@riverpod
String? activePhaseId(Ref ref) {
  final browse = ref.watch(catalogBrowsePhaseProvider);
  if (browse != null) return browse;
  return ref.watch(userProfileProvider).value?.mbbsPhaseId;
}

@riverpod
Future<List<University>> universities(Ref ref) async {
  final result = await ref.watch(catalogRepositoryProvider).fetchUniversities();
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

@riverpod
Future<List<MbbsPhase>> mbbsPhases(Ref ref) async {
  final result = await ref.watch(catalogRepositoryProvider).fetchPhases();
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

@riverpod
Future<List<College>> colleges(Ref ref, String universityId) async {
  final result = await ref
      .watch(catalogRepositoryProvider)
      .fetchColleges(universityId);
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

@riverpod
Future<List<CatalogSubject>> phaseSubjects(Ref ref) async {
  final browse = ref.watch(catalogBrowsePhaseProvider);
  final phaseId =
      browse ?? (await ref.watch(userProfileProvider.future))?.mbbsPhaseId;
  final result = await ref
      .watch(catalogRepositoryProvider)
      .fetchSubjects(phaseId: phaseId);
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

@riverpod
Future<List<CatalogTopic>> subjectTopics(Ref ref, String subjectId) async {
  final result = await ref
      .watch(catalogRepositoryProvider)
      .fetchTopics(subjectId);
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

@riverpod
Future<List<CatalogLesson>> topicLessons(Ref ref, String topicId) async {
  final result = await ref
      .watch(catalogRepositoryProvider)
      .fetchLessons(topicId);
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

@riverpod
Future<CatalogLesson?> lessonDetail(Ref ref, String lessonId) async {
  final result = await ref
      .watch(catalogRepositoryProvider)
      .fetchLesson(lessonId);
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}
