import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../../core/supabase/tables.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../profile/domain/plan_tier.dart';
import '../domain/pyq_models.dart';

part 'pyq_repository.g.dart';

class PyqDetail {
  const PyqDetail({
    required this.teaser,
    required this.appearances,
    required this.textbookRefs,
    required this.lessonResources,
    required this.questionResources,
    this.sampleAnswer,
    required this.canReadSample,
    required this.questionLearnt,
  });

  final PyqTeaser teaser;
  final List<ExamAppearance> appearances;
  final List<TextbookCitation> textbookRefs;
  final List<ResourceLink> lessonResources;
  final List<ResourceLink> questionResources;
  final String? sampleAnswer;
  final bool canReadSample;
  final bool questionLearnt;
}

class PyqRepository {
  PyqRepository(this._client);

  final SupabaseClient _client;

  Future<Result<List<ResourceLink>>> fetchLessonResources(String lessonId) async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }
    try {
      final rows = await _client
          .from(Tables.lessonResources)
          .select()
          .eq(ResourceColumns.lessonId, lessonId)
          .order(ResourceColumns.displayOrder);
      return Success(
        (rows as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(ResourceLink.fromJson)
            .toList(),
      );
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not load topic links.'),
      );
    }
  }

  Future<Result<List<PyqTeaser>>> fetchTeasersForLesson(String lessonId) async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }
    try {
      final rows = await _client
          .from(Tables.pyqTeasers)
          .select()
          .eq(PyqTeaserColumns.lessonId, lessonId)
          .order(PyqTeaserColumns.appearanceCount, ascending: false);
      return Success(
        (rows as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(PyqTeaser.fromJson)
            .toList(),
      );
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not load PYQs.'),
      );
    }
  }

  Future<Result<PyqDetail>> fetchDetail({
    required String questionId,
    required PlanTier plan,
  }) async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }
    try {
      final teaserRows = await _client
          .from(Tables.pyqTeasers)
          .select()
          .eq(PyqTeaserColumns.id, questionId)
          .limit(1);
      final teasers = (teaserRows as List<dynamic>).cast<Map<String, dynamic>>();
      if (teasers.isEmpty) {
        return const Failure('This question is not available.');
      }
      final teaser = PyqTeaser.fromJson(teasers.first);
      final lessonId = teaser.lessonId;

      final appearancesRows = await _client
          .from(Tables.questionAppearances)
          .select(
            '${AppearanceColumns.examPaperEmbed}:${Tables.examPapers}('
            '${ExamPaperColumns.examYear},${ExamPaperColumns.paperName})',
          )
          .eq(AppearanceColumns.questionId, questionId);

      final refRows = await _client
          .from(Tables.questionTextbookRefs)
          .select(
            '${TextbookRefColumns.page},${TextbookRefColumns.sectionHeading},'
            '${TextbookRefColumns.textbookEmbed}:${Tables.textbooks}('
            '${TextbookColumns.title},${TextbookColumns.authors},${TextbookColumns.edition})',
          )
          .eq(TextbookRefColumns.questionId, questionId);

      final qRes = await _client
          .from(Tables.questionResources)
          .select()
          .eq(ResourceColumns.questionId, questionId)
          .order(ResourceColumns.displayOrder);

      var lessonRes = <dynamic>[];
      if (lessonId != null) {
        lessonRes = await _client
            .from(Tables.lessonResources)
            .select()
            .eq(ResourceColumns.lessonId, lessonId)
            .order(ResourceColumns.displayOrder) as List<dynamic>;
      }

      String? sample;
      final canReadSample = plan.rank >= PlanTier.pro.rank;
      if (canReadSample) {
        final sampleRows = await _client
            .from(Tables.questionSampleAnswers)
            .select(SampleAnswerColumns.body)
            .eq(SampleAnswerColumns.questionId, questionId)
            .limit(1);
        final list = (sampleRows as List<dynamic>).cast<Map<String, dynamic>>();
        if (list.isNotEmpty) {
          sample = list.first[SampleAnswerColumns.body] as String?;
        }
      }

      final userId = _client.auth.currentUser!.id;
      final progressRows = await _client
          .from(Tables.questionProgress)
          .select('learnt_at')
          .eq('user_id', userId)
          .eq('question_id', questionId)
          .limit(1);
      final progress = (progressRows as List<dynamic>).cast<Map<String, dynamic>>();
      final learnt = progress.isNotEmpty && progress.first['learnt_at'] != null;

      await _client.rpc(
        RpcFunctions.recordStudyEvent,
        params: {
          StudyEventParams.kind: 'opened_pyq',
          StudyEventParams.questionId: questionId,
          StudyEventParams.lessonId: lessonId,
        },
      );

      return Success(
        PyqDetail(
          teaser: teaser,
          appearances: (appearancesRows as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(ExamAppearance.fromJson)
              .toList(),
          textbookRefs: (refRows as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(TextbookCitation.fromJson)
              .toList(),
          lessonResources: lessonRes
              .cast<Map<String, dynamic>>()
              .map(ResourceLink.fromJson)
              .toList(),
          questionResources: (qRes as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(ResourceLink.fromJson)
              .toList(),
          sampleAnswer: sample,
          canReadSample: canReadSample,
          questionLearnt: learnt,
        ),
      );
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not load this question.'),
      );
    }
  }

  Future<Result<void>> markLearnt(String questionId) async {
    try {
      await _client.rpc(
        RpcFunctions.markQuestionLearnt,
        params: {MarkLearntParams.questionId: questionId},
      );
      return const Success(null);
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not mark as learnt.'),
      );
    }
  }
}

@Riverpod(keepAlive: true)
PyqRepository pyqRepository(Ref ref) {
  return PyqRepository(ref.watch(supabaseClientProvider));
}
