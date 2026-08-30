import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../catalog/domain/catalog_models.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  String? _universityId;
  String? _universityName;
  String? _collegeId;
  String? _phaseId;
  int _batchYear = DateTime.now().year;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applyUniversity(List<University> items) {
    if (items.isEmpty || _universityId != null) return;
    final kuhs = items.where((u) => u.code == 'KUHS');
    final chosen = kuhs.isNotEmpty ? kuhs.first : items.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _universityId != null) return;
      setState(() {
        _universityId = chosen.id;
        _universityName = chosen.name;
      });
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty ||
        _universityId == null ||
        _collegeId == null ||
        _phaseId == null) {
      setState(() => _error = 'Fill in every field to continue.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await ref.read(profileRepositoryProvider).saveOnboarding(
          fullName: name,
          universityId: _universityId!,
          collegeId: _collegeId!,
          batchYear: _batchYear,
          mbbsPhaseId: _phaseId!,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Success():
        await ref.read(userProfileProvider.notifier).refresh();
        if (!mounted) return;
        context.go(AppRoutes.home);
      case Failure(:final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final universities = ref.watch(universitiesProvider);
    final phases = ref.watch(mbbsPhasesProvider);
    final colleges = _universityId == null
        ? const AsyncValue<List<College>>.data([])
        : ref.watch(collegesProvider(_universityId!));

    return Scaffold(
      appBar: AppBar(title: const Text('Your course')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Text(
            'Tell us where you study',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'We use this to show KUHS subjects for your MBBS year.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: Spacing.lg),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Spacing.md),
          universities.when(
            data: (items) {
              _applyUniversity(items);
              return InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'University',
                  border: OutlineInputBorder(),
                ),
                child: Text(_universityName ?? 'Loading…'),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: Spacing.md),
          colleges.when(
            data: (items) => DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _collegeId,
              decoration: const InputDecoration(
                labelText: 'College',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in items)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (id) => setState(() => _collegeId = id),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: Spacing.md),
          phases.when(
            data: (items) => DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _phaseId,
              decoration: const InputDecoration(
                labelText: 'Current MBBS year',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final p in items)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (id) => setState(() => _phaseId = id),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: Spacing.md),
          DropdownButtonFormField<int>(
            // ignore: deprecated_member_use
            value: _batchYear,
            decoration: const InputDecoration(
              labelText: 'Batch year',
              border: OutlineInputBorder(),
            ),
            items: [
              for (var y = DateTime.now().year; y >= DateTime.now().year - 6; y--)
                DropdownMenuItem(value: y, child: Text('$y')),
            ],
            onChanged: (y) => setState(() => _batchYear = y ?? _batchYear),
          ),
          if (_error != null) ...[
            const SizedBox(height: Spacing.md),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: Spacing.lg),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
