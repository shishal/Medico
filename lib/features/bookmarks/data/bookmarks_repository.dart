import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../../core/supabase/tables.dart';
import '../../../core/utils/result.dart';
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
    } on PostgrestException catch (_) {
      return const Failure('Could not load bookmarks. Please try again.');
    } catch (_) {
      return const Failure('Could not load bookmarks. Please try again.');
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
    } on PostgrestException catch (_) {
      return const Failure('Could not load bookmarks. Please try again.');
    } catch (_) {
      return const Failure('Could not load bookmarks. Please try again.');
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
      return const Failure('Could not save bookmark. Please try again.');
    } catch (_) {
      return const Failure('Could not save bookmark. Please try again.');
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
    } on PostgrestException catch (_) {
      return const Failure('Could not remove bookmark. Please try again.');
    } catch (_) {
      return const Failure('Could not remove bookmark. Please try again.');
    }
  }
}

@Riverpod(keepAlive: true)
BookmarksRepository bookmarksRepository(Ref ref) {
  return BookmarksRepository(ref.watch(supabaseClientProvider));
}
