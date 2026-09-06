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
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    this.correctOption,
    this.explanationText,
  });

  final PyqTeaser teaser;
  final List<ExamAppearance> appearances;
  final List<TextbookCitation> textbookRefs;
  final List<ResourceLink> lessonResources;
  final List<ResourceLink> questionResources;
  final String? sampleAnswer;
  final bool canReadSample;
  final bool questionLearnt;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final String? correctOption;
  final String? explanationText;

  bool get isMcq => teaser.kind == 'mcq';
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

  Future<Result<PyqLessonFeed>> fetchTeasersForLesson({
    required String lessonId,
    String? universityId,
  }) async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }
    try {
      final rows = await _client
          .from(Tables.pyqTeasers)
          .select()
          .eq(PyqTeaserColumns.lessonId, lessonId)
          .order(PyqTeaserColumns.appearanceCount, ascending: false);
      final all = (rows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(PyqTeaser.fromJson)
          .toList();
      if (all.isEmpty) {
        return const Success(PyqLessonFeed(teasers: [], usingFallback: false));
      }

      final ids = all.map((t) => t.id).toList();
      final appRows = await _client
          .from(Tables.questionAppearances)
          .select(
            '${AppearanceColumns.questionId},'
            '${AppearanceColumns.examPaperEmbed}:${Tables.examPapers}('
            '${ExamPaperColumns.universityId},'
            '${ExamPaperColumns.examYear})',
          )
          .inFilter(AppearanceColumns.questionId, ids);

      final uniRows = await _client
          .from(Tables.universities)
          .select(
            '${UniversityColumns.id},${UniversityColumns.code},'
            '${UniversityColumns.isFallback}',
          );
      final unis = (uniRows as List<dynamic>).cast<Map<String, dynamic>>();
      String? fallbackId;
      for (final u in unis) {
        if (u[UniversityColumns.isFallback] == true ||
            u[UniversityColumns.code] == 'KUHS') {
          fallbackId = u[UniversityColumns.id] as String;
          if (u[UniversityColumns.isFallback] == true) break;
        }
      }

      final yearsByQuestionUni = <String, Map<String, List<int>>>{};
      final unisByQuestion = <String, Set<String>>{};
      for (final raw in (appRows as List<dynamic>).cast<Map<String, dynamic>>()) {
        final qid = raw[AppearanceColumns.questionId] as String;
        final paper = raw[AppearanceColumns.examPaperEmbed];
        final map = paper is Map<String, dynamic> ? paper : <String, dynamic>{};
        final uid = map[ExamPaperColumns.universityId] as String?;
        if (uid != null) {
          unisByQuestion.putIfAbsent(qid, () => {}).add(uid);
        }
        final year = map[ExamPaperColumns.examYear];
        if (uid != null && year is num) {
          yearsByQuestionUni
              .putIfAbsent(qid, () => {})
              .putIfAbsent(uid, () => [])
              .add(year.toInt());
        }
      }

      // Fallback is university-wide: if the selected university has any
      // papers, empty lessons stay empty. Only swap to KUHS when that
      // university has zero papers in the catalog.
      var contentUni = universityId;
      var usingFallback = false;
      if (contentUni != null && contentUni.isNotEmpty) {
        final paperRows = await _client
            .from(Tables.examPapers)
            .select(ExamPaperColumns.id)
            .eq(ExamPaperColumns.universityId, contentUni)
            .limit(1);
        final hasPapers = (paperRows as List<dynamic>).isNotEmpty;
        if (!hasPapers && fallbackId != null) {
          usingFallback = contentUni != fallbackId;
          contentUni = fallbackId;
        }
      } else if (fallbackId != null) {
        contentUni = fallbackId;
      }

      final refRows = await _client
          .from(Tables.questionTextbookRefs)
          .select(
            '${TextbookRefColumns.questionId},${TextbookRefColumns.page},'
            '${TextbookRefColumns.sectionHeading},'
            '${TextbookRefColumns.textbookEmbed}:${Tables.textbooks}('
            '${TextbookColumns.title},${TextbookColumns.edition},'
            '${TextbookColumns.sheetKey})',
          )
          .inFilter(TextbookRefColumns.questionId, ids);
      final firstRef = <String, String>{};
      for (final raw in (refRows as List<dynamic>).cast<Map<String, dynamic>>()) {
        final qid = raw[TextbookRefColumns.questionId] as String;
        if (firstRef.containsKey(qid)) continue;
        firstRef[qid] = TextbookCitation.fromJson(raw).label;
      }

      final teasers = <PyqTeaser>[];
      for (final t in all) {
        final owned = unisByQuestion[t.id];
        final isMcqBank = t.kind == 'mcq' && (owned == null || owned.isEmpty);
        final matchesUni = contentUni == null ||
            isMcqBank ||
            (owned != null && owned.contains(contentUni));
        if (!matchesUni) continue;
        final years = {
          ...?yearsByQuestionUni[t.id]?[contentUni],
        }.toList()
          ..sort();
        teasers.add(
          t.copyWith(
            textbookLine: firstRef[t.id],
            appearanceYears: years,
            appearanceCount: years.length,
          ),
        );
      }

      return Success(
        PyqLessonFeed(teasers: teasers, usingFallback: usingFallback),
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
            '${TextbookColumns.title},${TextbookColumns.authors},'
            '${TextbookColumns.edition},${TextbookColumns.sheetKey})',
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

      String? optionA;
      String? optionB;
      String? optionC;
      String? optionD;
      String? correctOption;
      String? explanationText;
      if (teaser.kind == 'mcq') {
        final qRows = await _client
            .from(Tables.questions)
            .select(
              '${QuestionColumns.optionA},${QuestionColumns.optionB},'
              '${QuestionColumns.optionC},${QuestionColumns.optionD},'
              '${QuestionColumns.correctOption},${QuestionColumns.explanationText}',
            )
            .eq(QuestionColumns.id, questionId)
            .limit(1);
        final qList = (qRows as List<dynamic>).cast<Map<String, dynamic>>();
        if (qList.isNotEmpty) {
          final q = qList.first;
          optionA = q[QuestionColumns.optionA] as String?;
          optionB = q[QuestionColumns.optionB] as String?;
          optionC = q[QuestionColumns.optionC] as String?;
          optionD = q[QuestionColumns.optionD] as String?;
          correctOption = q[QuestionColumns.correctOption] as String?;
          explanationText = q[QuestionColumns.explanationText] as String?;
        }
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
          optionA: optionA,
          optionB: optionB,
          optionC: optionC,
          optionD: optionD,
          correctOption: correctOption,
          explanationText: explanationText,
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
