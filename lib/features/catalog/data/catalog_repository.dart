import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../../core/supabase/tables.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/user_facing_error.dart';
import '../domain/catalog_models.dart';
import '../domain/university_coverage.dart';

part 'catalog_repository.g.dart';

class CatalogRepository {
  CatalogRepository(this._client);

  final SupabaseClient _client;

  Future<Result<List<University>>> fetchUniversities() => _list(
        Tables.universities,
        University.fromJson,
        order: UniversityColumns.name,
      );

  Future<Result<List<MbbsPhase>>> fetchPhases() => _list(
        Tables.mbbsPhases,
        MbbsPhase.fromJson,
        order: MbbsPhaseColumns.displayOrder,
      );

  Future<Result<List<College>>> fetchColleges(String universityId) async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }
    try {
      final rows = await _client
          .from(Tables.colleges)
          .select()
          .eq(CollegeColumns.universityId, universityId)
          .order(CollegeColumns.name);
      return Success(_map(rows, College.fromJson));
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not load colleges.'),
      );
    }
  }

  Future<Result<List<CatalogSubject>>> fetchSubjects({String? phaseId}) async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }
    try {
      final filter = _client.from(Tables.subjects).select();
      final rows = phaseId == null
          ? await filter.order(SubjectColumns.displayOrder)
          : await filter
              .eq(SubjectColumns.mbbsPhaseId, phaseId)
              .order(SubjectColumns.displayOrder);
      return Success(_map(rows, CatalogSubject.fromJson));
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not load subjects.'),
      );
    }
  }

  Future<Result<List<CatalogTopic>>> fetchTopics(String subjectId) async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }
    try {
      final rows = await _client
          .from(Tables.topics)
          .select()
          .eq(TopicColumns.subjectId, subjectId)
          .order(TopicColumns.displayOrder);
      return Success(_map(rows, CatalogTopic.fromJson));
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not load topics.'),
      );
    }
  }

  Future<Result<List<CatalogLesson>>> fetchLessons(String topicId) async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }
    try {
      final rows = await _client
          .from(Tables.lessons)
          .select()
          .eq(LessonColumns.topicId, topicId)
          .eq(LessonColumns.isActive, true)
          .order(LessonColumns.displayOrder);
      return Success(_map(rows, CatalogLesson.fromJson));
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not load lessons.'),
      );
    }
  }

  Future<Result<void>> markLessonLearnt(String lessonId) async {
    try {
      await _client.rpc(
        RpcFunctions.markLessonLearnt,
        params: {MarkLearntParams.lessonId: lessonId},
      );
      return const Success(null);
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not mark as learnt.'),
      );
    }
  }

  Future<Result<List<LessonPickerItem>>> fetchLessonsForPhase(
    String? phaseId,
  ) async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }
    try {
      final rows = await _client
          .from(Tables.lessons)
          .select(
            '${LessonColumns.id},'
            '${LessonColumns.name},'
            '${LessonColumns.topicEmbed}:${Tables.topics}!inner('
            '${TopicColumns.name},'
            '${TopicColumns.subjectEmbed}:${Tables.subjects}!inner('
            '${SubjectColumns.name},'
            '${SubjectColumns.mbbsPhaseId}'
            ')'
            ')',
          )
          .eq(LessonColumns.isActive, true)
          .order(LessonColumns.displayOrder);
      final items = _map(rows, LessonPickerItem.fromJson)
          .where((item) => phaseId == null || item.mbbsPhaseId == phaseId)
          .toList();
      return Success(items);
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not load lessons.'),
      );
    }
  }

  Future<Result<void>> recordOpenedLesson(String lessonId) async {
    try {
      await _client.rpc(
        RpcFunctions.recordStudyEvent,
        params: {
          StudyEventParams.kind: 'opened_lesson',
          StudyEventParams.lessonId: lessonId,
        },
      );
      return const Success(null);
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not record that view.'),
      );
    }
  }

  Future<Result<CatalogLesson?>> fetchLesson(String lessonId) async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }
    try {
      final rows = await _client
          .from(Tables.lessons)
          .select()
          .eq(LessonColumns.id, lessonId)
          .limit(1);
      final list = _map(rows, CatalogLesson.fromJson);
      return Success(list.isEmpty ? null : list.first);
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not load that lesson.'),
      );
    }
  }

  /// Papers + PYQ counts for [selectedUniversityId], falling back to KUHS.
  Future<Result<UniversityCoverage>> fetchCoverage(String? selectedUniversityId) async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }
    try {
      final uniRows = await _client.from(Tables.universities).select();
      final unis = _map(uniRows, University.fromJson);
      University? selected;
      University? fallback;
      for (final u in unis) {
        if (u.id == selectedUniversityId) selected = u;
        if (u.isFallback) fallback = u;
      }
      fallback ??= unis.where((u) => u.code == 'KUHS').firstOrNull ?? unis.firstOrNull;
      if (fallback == null) {
        return const Success(
          UniversityCoverage(
            paperCount: 0,
            pyqCount: 0,
            usingFallback: false,
            contentUniversityId: '',
          ),
        );
      }

      Future<int> paperCount(String universityId) async {
        final rows = await _client
            .from(Tables.examPapers)
            .select(ExamPaperColumns.id)
            .eq(ExamPaperColumns.universityId, universityId);
        return (rows as List<dynamic>).length;
      }

      final selectedCount = selected == null ? 0 : await paperCount(selected.id);
      final University content;
      final bool showingFallback;
      if (selected != null && selectedCount > 0) {
        content = selected;
        showingFallback = false;
      } else {
        content = fallback;
        showingFallback = selected != null && selected.id != fallback.id;
      }
      final papers = showingFallback || selected == null
          ? await paperCount(content.id)
          : selectedCount;

      final paperIds = await _client
          .from(Tables.examPapers)
          .select(ExamPaperColumns.id)
          .eq(ExamPaperColumns.universityId, content.id);
      final ids = (paperIds as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((r) => r[ExamPaperColumns.id] as String)
          .toList();
      var pyqCount = 0;
      if (ids.isNotEmpty) {
        final apps = await _client
            .from(Tables.questionAppearances)
            .select(AppearanceColumns.questionId)
            .inFilter(AppearanceColumns.examPaperId, ids);
        pyqCount = {
          for (final row in (apps as List<dynamic>).cast<Map<String, dynamic>>())
            row[AppearanceColumns.questionId] as String,
        }.length;
      }

      return Success(
        UniversityCoverage(
          paperCount: papers,
          pyqCount: pyqCount,
          usingFallback: showingFallback,
          contentUniversityId: content.id,
          contentUniversityName: content.name,
          selectedUniversityName: selected?.name,
        ),
      );
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not load coverage.'),
      );
    }
  }

  Future<Result<List<T>>> _list<T>(
    String table,
    T Function(Map<String, dynamic>) fromJson, {
    required String order,
  }) async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }
    try {
      final rows = await _client.from(table).select().order(order);
      return Success(_map(rows, fromJson));
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not load catalog.'),
      );
    }
  }

  static List<T> _map<T>(
    dynamic rows,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }
}

@Riverpod(keepAlive: true)
CatalogRepository catalogRepository(Ref ref) {
  return CatalogRepository(ref.watch(supabaseClientProvider));
}
