import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/soft_keyboard.dart';
import '../../../../core/widgets/comic_select_sheet.dart';
import '../../../catalog/domain/catalog_models.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../catalog/presentation/widgets/year_picker.dart';
import '../../data/profile_repository.dart';
import '../../domain/user_profile.dart';
import '../providers/user_profile_provider.dart';

/// Lets a student change name, university, year, college, and batch.
class AcademicEditor extends ConsumerStatefulWidget {
  const AcademicEditor({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<AcademicEditor> createState() => _AcademicEditorState();
}

class _AcademicEditorState extends ConsumerState<AcademicEditor> {
  late final _nameController = TextEditingController(
    text: widget.profile.fullName ?? '',
  );
  late String? _phaseId = widget.profile.mbbsPhaseId;
  late String? _universityId = widget.profile.universityId;
  late String? _collegeId = widget.profile.collegeId;
  late int _batchYear = widget.profile.batchYear ?? DateTime.now().year;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final universityId = _universityId;
    final phaseId = _phaseId;
    if (universityId == null || phaseId == null) return;
    setState(() => _saving = true);
    final result = await ref.read(profileRepositoryProvider).updateAcademic(
          fullName: _nameController.text.trim(),
          universityId: universityId,
          collegeId: _collegeId,
          batchYear: _batchYear,
          mbbsPhaseId: phaseId,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success():
        await ref.read(userProfileProvider.notifier).refresh();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Course updated')));
      case Failure(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final phases = ref.watch(mbbsPhasesProvider);
    final universities = ref.watch(universitiesProvider);
    final colleges = _universityId == null
        ? const AsyncValue<List<College>>.data([])
        : ref.watch(collegesProvider(_universityId!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your course',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          'University, college, year, and batch. Home follows these.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Spacing.md),
        TextField(
          controller: _nameController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          onTap: requestSoftKeyboard,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: Spacing.md),
        universities.when(
          data: (items) {
            final selected = items.where((u) => u.id == _universityId);
            return ComicSelectField<University>(
              label: 'University',
              items: items,
              value: selected.isEmpty ? null : selected.first,
              labelOf: (u) => '${u.code} · ${u.name}',
              onSelected: (u) => setState(() {
                _universityId = u.id;
                _collegeId = null;
              }),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
        ),
        const SizedBox(height: Spacing.md),
        phases.when(
          data: (items) => YearPickerRow(
            phases: items,
            selectedId: _phaseId,
            onSelect: (id) => setState(() => _phaseId = id),
            padding: EdgeInsets.zero,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
        ),
        const SizedBox(height: Spacing.md),
        colleges.when(
          data: (items) {
            final selected = items.where((c) => c.id == _collegeId);
            return ComicSelectField<College>(
              label: 'College',
              items: items,
              value: selected.isEmpty ? null : selected.first,
              labelOf: (c) => c.name,
              onSelected: (c) => setState(() => _collegeId = c.id),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
        ),
        const SizedBox(height: Spacing.md),
        ComicSelectField<int>(
          label: 'Batch year',
          items: [
            for (var y = DateTime.now().year; y >= DateTime.now().year - 6; y--)
              y,
          ],
          value: _batchYear,
          labelOf: (y) => '$y',
          onSelected: (y) => setState(() => _batchYear = y),
        ),
        const SizedBox(height: Spacing.md),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save course'),
        ),
      ],
    );
  }
}
