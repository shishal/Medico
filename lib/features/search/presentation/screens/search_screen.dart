import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../progress/data/progress_repository.dart';
import '../../../progress/domain/progress_models.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  bool _loading = false;
  String? _error;
  SearchHits? _hits;
  bool _searched = false;

  Future<void> _run(String q) async {
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    final result = await ref.read(progressRepositoryProvider).search(q);
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        setState(() {
          _hits = value;
          _loading = false;
        });
      case Failure(:final message):
        setState(() {
          _error = message;
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hits = _hits;
    final empty = hits != null &&
        hits.subjects.isEmpty &&
        hits.lessons.isEmpty &&
        hits.questions.isEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Subjects, lessons, PYQs',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (q) {
                if (q.trim().length >= 2) _run(q.trim());
              },
            ),
            const SizedBox(height: Spacing.md),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) Text(_error!),
            if (_searched && empty && !_loading)
              const Text('No matches. Try another word.'),
            if (hits != null && !empty)
              Expanded(
                child: ListView(
                  children: [
                    for (final s in hits.subjects)
                      ListTile(
                        leading: const Icon(Icons.book_outlined),
                        title: Text(s.title),
                        onTap: () =>
                            context.push(AppRoutes.subjectPath(s.id, s.title)),
                      ),
                    for (final l in hits.lessons)
                      ListTile(
                        leading: const Icon(Icons.article_outlined),
                        title: Text(l.title),
                        onTap: () =>
                            context.push(AppRoutes.lessonPath(l.id, l.title)),
                      ),
                    for (final q in hits.questions)
                      ListTile(
                        leading: const Icon(Icons.quiz_outlined),
                        title: Text(
                          q.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => context.push(AppRoutes.pyqPath(q.id)),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
