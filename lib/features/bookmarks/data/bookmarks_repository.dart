import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../../core/supabase/tables.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/user_facing_error.dart';
import '../domain/bookmarked_lesson.dart';
import '../domain/bookmarked_question.dart';

part 'bookmarks_repository.g.dart';

/// Own-user bookmarks. Presentation never calls Supabase directly.
class BookmarksRepository {
  BookmarksRepository(this._client);

  final SupabaseClient _client;

  Future<Result<Set<String>>> fetchIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Failure('Not signed in.');
    }

    try {
      final rows = await _client
          .from(Tables.bookmarks)
          .select(BookmarkColumns.questionId)
          .eq(BookmarkColumns.userId, userId);

      return Success({
        for (final row in (rows as List<dynamic>).cast<Map<String, dynamic>>())
          if (row[BookmarkColumns.questionId] is String)
            row[BookmarkColumns.questionId] as String,
      });
    } catch (e) {
      return Failure(
        UserFacingError.from(
          e,
          fallback: 'Could not load bookmarks. Please try again.',
        ),
      );
    }
  }

  Future<Result<List<BookmarkedQuestion>>> fetchAll() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Failure('Not signed in.');
    }

    try {
      final rows = await _client
          .from(Tables.bookmarks)
          .select(
            '${BookmarkColumns.questionId},'
            '${BookmarkColumns.createdAt},'
            '${BookmarkColumns.questionEmbed}:${Tables.questions}('
            '${QuestionColumns.id},'
            '${QuestionColumns.questionText},'
            '${QuestionColumns.topicEmbed}:${Tables.topics}('
            '${TopicColumns.name},'
            '${TopicColumns.subjectEmbed}:${Tables.subjects}('
            '${SubjectColumns.name}'
            ')'
            ')'
            ')',
          )
          .eq(BookmarkColumns.userId, userId)
          .order(BookmarkColumns.createdAt, ascending: false);

      // `?item` includes the value only when fromJson succeeded (non-null).
      return Success([
        for (final row in (rows as List<dynamic>).cast<Map<String, dynamic>>())
          ?BookmarkedQuestion.fromJson(row),
      ]);
    } catch (e) {
      return Failure(
        UserFacingError.from(
          e,
          fallback: 'Could not load bookmarks. Please try again.',
        ),
      );
    }
  }

  Future<Result<void>> add(String questionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Failure('Not signed in.');
    }

    try {
      await _client.from(Tables.bookmarks).insert({
        BookmarkColumns.userId: userId,
        BookmarkColumns.questionId: questionId,
      });
      return const Success(null);
    } on PostgrestException catch (e) {
      // Unique violation — already bookmarked. Treat as success.
      if (e.code == '23505') return const Success(null);
      return Failure(
        UserFacingError.from(
          e,
          fallback: 'Could not save bookmark. Please try again.',
        ),
      );
    } catch (e) {
      return Failure(
        UserFacingError.from(
          e,
          fallback: 'Could not save bookmark. Please try again.',
        ),
      );
    }
  }

  Future<Result<void>> remove(String questionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Failure('Not signed in.');
    }

    try {
      await _client
          .from(Tables.bookmarks)
          .delete()
          .eq(BookmarkColumns.userId, userId)
          .eq(BookmarkColumns.questionId, questionId);
      return const Success(null);
    } catch (e) {
      return Failure(
        UserFacingError.from(
          e,
          fallback: 'Could not remove bookmark. Please try again.',
        ),
      );
    }
  }

  Future<Result<Set<String>>> fetchLessonIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Failure('Not signed in.');
    }

    try {
      final rows = await _client
          .from(Tables.lessonBookmarks)
          .select(LessonBookmarkColumns.lessonId)
          .eq(LessonBookmarkColumns.userId, userId);

      return Success({
        for (final row in (rows as List<dynamic>).cast<Map<String, dynamic>>())
          if (row[LessonBookmarkColumns.lessonId] is String)
            row[LessonBookmarkColumns.lessonId] as String,
      });
    } catch (e) {
      return Failure(
        UserFacingError.from(
          e,
          fallback: 'Could not load lesson bookmarks. Please try again.',
        ),
      );
    }
  }

  Future<Result<List<BookmarkedLesson>>> fetchLessons() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Failure('Not signed in.');
    }

    try {
      final rows = await _client
          .from(Tables.lessonBookmarks)
          .select(
            '${LessonBookmarkColumns.lessonId},'
            '${LessonBookmarkColumns.lessonEmbed}:${Tables.lessons}('
            '${LessonColumns.id},${LessonColumns.name})',
          )
          .eq(LessonBookmarkColumns.userId, userId)
          .order(LessonBookmarkColumns.createdAt, ascending: false);

      return Success([
        for (final row in (rows as List<dynamic>).cast<Map<String, dynamic>>())
          if (row[LessonBookmarkColumns.lessonId] is String)
            BookmarkedLesson(
              lessonId: row[LessonBookmarkColumns.lessonId] as String,
              name: _lessonName(row),
            ),
      ]);
    } catch (e) {
      return Failure(
        UserFacingError.from(
          e,
          fallback: 'Could not load lesson bookmarks. Please try again.',
        ),
      );
    }
  }

  Future<Result<void>> addLesson(String lessonId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Failure('Not signed in.');
    }

    try {
      await _client.from(Tables.lessonBookmarks).insert({
        LessonBookmarkColumns.userId: userId,
        LessonBookmarkColumns.lessonId: lessonId,
      });
      return const Success(null);
    } on PostgrestException catch (e) {
      if (e.code == '23505') return const Success(null);
      return Failure(
        UserFacingError.from(
          e,
          fallback: 'Could not save bookmark. Please try again.',
        ),
      );
    } catch (e) {
      return Failure(
        UserFacingError.from(
          e,
          fallback: 'Could not save bookmark. Please try again.',
        ),
      );
    }
  }

  Future<Result<void>> removeLesson(String lessonId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Failure('Not signed in.');
    }

    try {
      await _client
          .from(Tables.lessonBookmarks)
          .delete()
          .eq(LessonBookmarkColumns.userId, userId)
          .eq(LessonBookmarkColumns.lessonId, lessonId);
      return const Success(null);
    } catch (e) {
      return Failure(
        UserFacingError.from(
          e,
          fallback: 'Could not remove bookmark. Please try again.',
        ),
      );
    }
  }

  static String _lessonName(Map<String, dynamic> row) {
    final embed = row[LessonBookmarkColumns.lessonEmbed];
    if (embed is Map<String, dynamic>) {
      return embed[LessonColumns.name] as String? ?? 'Lesson';
    }
    if (embed is Map) {
      return embed[LessonColumns.name] as String? ?? 'Lesson';
    }
    return 'Lesson';
  }
}

@Riverpod(keepAlive: true)
BookmarksRepository bookmarksRepository(Ref ref) {
  return BookmarksRepository(ref.watch(supabaseClientProvider));
}
