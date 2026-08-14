import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/app_dialog_header.dart';
import 'package:asisteqr_baker/core/widgets/app_feedback.dart';
import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:asisteqr_baker/features/schedules/presentation/schedule_catalogs_panel.dart';
import 'package:asisteqr_baker/features/schedules/presentation/schedule_planner_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ScheduleCatalogType { subjects, classrooms }

extension on ScheduleCatalogType {
  String get route => switch (this) {
    ScheduleCatalogType.subjects => '/materias',
    ScheduleCatalogType.classrooms => '/aulas',
  };

  String get title => switch (this) {
    ScheduleCatalogType.subjects => 'Materias',
    ScheduleCatalogType.classrooms => 'Aulas',
  };
}

class ScheduleCatalogPage extends ConsumerStatefulWidget {
  const ScheduleCatalogPage({super.key, required this.catalog});

  final ScheduleCatalogType catalog;

  @override
  ConsumerState<ScheduleCatalogPage> createState() =>
      _ScheduleCatalogPageState();
}

class _ScheduleCatalogPageState extends ConsumerState<ScheduleCatalogPage> {
  SchedulePlannerViewModel get model =>
      ref.read(schedulePlannerViewModelProvider);

  Future<void> _editSubject([ScheduleSubject? current]) async {
    final draft = await showDialog<ScheduleSubjectDraft>(
      context: context,
      builder: (context) => ScheduleSubjectDialog(current: current),
    );
    if (draft == null) return;
    final saved = await model.saveSubject(draft, current: current);
    if (!mounted) return;
    if (saved) {
      await showAppSuccess(
        context,
        current == null ? 'Materia creada.' : 'Materia actualizada.',
      );
      return;
    }
    await showAppErrorDialog(
      context,
      title: 'No se pudo guardar la materia',
      message: model.takeError() ?? 'Revisa los datos e intenta nuevamente.',
    );
  }

  Future<void> _deactivateSubject(ScheduleSubject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppDialogHeader(title: 'Desactivar materia'),
        content: Text('Se desactivará ${subject.name}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(LucideIcons.circleOff, size: 17),
            label: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final saved = await model.deactivateSubject(subject);
    if (!mounted) return;
    if (saved) {
      await showAppSuccess(context, 'Materia desactivada.');
      return;
    }
    await showAppErrorDialog(
      context,
      title: 'No se pudo desactivar la materia',
      message: model.takeError() ?? 'Intenta nuevamente.',
    );
  }

  Future<void> _editClassroom([ScheduleClassroom? current]) async {
    final draft = await showDialog<ScheduleClassroomDraft>(
      context: context,
      builder: (context) => ScheduleClassroomDialog(current: current),
    );
    if (draft == null) return;
    final saved = await model.saveClassroom(draft, current: current);
    if (!mounted) return;
    if (saved) {
      await showAppSuccess(
        context,
        current == null ? 'Aula creada.' : 'Aula actualizada.',
      );
      return;
    }
    await showAppErrorDialog(
      context,
      title: 'No se pudo guardar el aula',
      message: model.takeError() ?? 'Revisa los datos e intenta nuevamente.',
    );
  }

  Future<void> _deactivateClassroom(ScheduleClassroom classroom) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppDialogHeader(title: 'Desactivar aula'),
        content: Text('Se desactivará ${classroom.name}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(LucideIcons.circleOff, size: 17),
            label: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final saved = await model.deactivateClassroom(classroom);
    if (!mounted) return;
    if (saved) {
      await showAppSuccess(context, 'Aula desactivada.');
      return;
    }
    await showAppErrorDialog(
      context,
      title: 'No se pudo desactivar el aula',
      message: model.takeError() ?? 'Intenta nuevamente.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schedulePlannerViewModelProvider);
    final canManage = ref.watch(
      sessionViewModelProvider.select(
        (session) => session.user?.isAdministrator == true,
      ),
    );
    final data = state.data;
    return AdaptiveShell(
      location: widget.catalog.route,
      title: widget.catalog.title,
      child: data == null
          ? _CatalogLoadState(
              loading: state.loading,
              message: state.error,
              onRetry: state.load,
            )
          : Column(
              children: [
                if (state.loading || state.catalogSaving)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: switch (widget.catalog) {
                    ScheduleCatalogType.subjects => ScheduleSubjectsPanel(
                      subjects: data.subjects,
                      canManage: canManage,
                      busy: state.catalogSaving,
                      onCreate: _editSubject,
                      onEdit: _editSubject,
                      onDeactivate: _deactivateSubject,
                    ),
                    ScheduleCatalogType.classrooms => ScheduleClassroomsPanel(
                      classrooms: data.classrooms,
                      canManage: canManage,
                      busy: state.catalogSaving,
                      onCreate: _editClassroom,
                      onEdit: _editClassroom,
                      onDeactivate: _deactivateClassroom,
                    ),
                  },
                ),
              ],
            ),
    );
  }
}

class _CatalogLoadState extends StatelessWidget {
  const _CatalogLoadState({
    required this.loading,
    required this.message,
    required this.onRetry,
  });

  final bool loading;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.wifiOff, size: 34, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              message ?? 'No se pudo cargar el catálogo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
