import 'dart:math' as math;

import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/app_dialog_header.dart';
import 'package:asisteqr_baker/core/widgets/app_feedback.dart';
import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_models.dart';
import 'package:asisteqr_baker/features/schedules/presentation/schedule_planner_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum _PlannerPerspective { course, teacher, classroom }

extension on _PlannerPerspective {
  String get label => switch (this) {
    _PlannerPerspective.course => 'Cursos',
    _PlannerPerspective.teacher => 'Docentes',
    _PlannerPerspective.classroom => 'Aulas',
  };

  String get singularLabel => switch (this) {
    _PlannerPerspective.course => 'Curso',
    _PlannerPerspective.teacher => 'Docente',
    _PlannerPerspective.classroom => 'Aula',
  };

  IconData get icon => switch (this) {
    _PlannerPerspective.course => LucideIcons.school,
    _PlannerPerspective.teacher => LucideIcons.presentation,
    _PlannerPerspective.classroom => LucideIcons.doorOpen,
  };
}

enum _PlannerShift { morning, afternoon }

extension on _PlannerShift {
  int get startMinutes => switch (this) {
    _PlannerShift.morning => 7 * 60 + 30,
    _PlannerShift.afternoon => 14 * 60,
  };

  int get endMinutes => switch (this) {
    _PlannerShift.morning => 13 * 60 + 30,
    _PlannerShift.afternoon => 20 * 60,
  };

  String get label => switch (this) {
    _PlannerShift.morning => 'Mañana 07:30–13:30',
    _PlannerShift.afternoon => 'Tarde 14:00–20:00',
  };
}

class TeachingSchedulesPage extends ConsumerStatefulWidget {
  const TeachingSchedulesPage({
    super.key,
    this.initialPerspective,
    this.initialResourceId,
  });

  final String? initialPerspective;
  final String? initialResourceId;

  @override
  ConsumerState<TeachingSchedulesPage> createState() =>
      _TeachingSchedulesPageState();
}

class _TeachingSchedulesPageState extends ConsumerState<TeachingSchedulesPage> {
  late _PlannerPerspective perspective;
  String? selectedResourceId;
  _PlannerShift shift = _PlannerShift.morning;
  int mobileDay = DateTime.monday;

  SchedulePlannerViewModel get model =>
      ref.read(schedulePlannerViewModelProvider);

  @override
  void initState() {
    super.initState();
    perspective = switch (widget.initialPerspective) {
      'docente' => _PlannerPerspective.teacher,
      'aula' => _PlannerPerspective.classroom,
      _ => _PlannerPerspective.course,
    };
    selectedResourceId = widget.initialResourceId;
  }

  Future<void> _editAssignment(AcademicAssignment current) async {
    final data = model.data;
    if (data == null) return;
    if (data.subjects.isEmpty) {
      await showAppErrorDialog(
        context,
        title: 'No hay materias disponibles',
        message:
            'Registra una materia desde Catálogos > Materias antes de crear la carga académica.',
      );
      return;
    }
    if (data.courses.isEmpty || data.teachers.isEmpty) {
      await showAppErrorDialog(
        context,
        title: 'Faltan datos académicos',
        message: data.courses.isEmpty
            ? 'Registra al menos un curso antes de crear la carga académica.'
            : 'Registra al menos un docente antes de crear la carga académica.',
      );
      return;
    }
    final result = await showDialog<AcademicAssignment>(
      context: context,
      builder: (context) => _AssignmentDialog(data: data, current: current),
    );
    if (result == null || !mounted) return;
    final saved = await model.persistAssignment(result, current: current);
    if (!mounted) return;
    if (saved) {
      showAppSuccess(context, 'Asignación actualizada.');
    } else {
      await showAppErrorDialog(
        context,
        title: 'No se pudo actualizar la asignación',
        message: model.takeError() ?? 'Revise los datos indicados.',
      );
    }
  }

  Future<void> _removeAssignment(AcademicAssignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppDialogHeader(title: 'Retirar asignación'),
        content: const Text('También se retirarán sus bloques de clase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = await model.persistRemoveAssignment(assignment);
    if (!mounted) return;
    if (removed) {
      showAppSuccess(context, 'Asignación retirada.');
    } else {
      await showAppErrorDialog(
        context,
        title: 'No se pudo retirar la asignación',
        message: model.takeError() ?? 'Intente nuevamente.',
      );
    }
  }

  Future<void> _editBlock({
    PlannerScheduleBlock? current,
    AcademicAssignment? initialAssignment,
    required int weekday,
    required int startMinutes,
    int? endMinutes,
  }) async {
    final data = model.data;
    if (data == null) return;
    if (data.subjects.isEmpty) {
      await showAppErrorDialog(
        context,
        title: 'No hay materias disponibles',
        message:
            'Registra una materia desde Catálogos > Materias antes de programar una clase.',
      );
      return;
    }
    if (data.courses.isEmpty || data.teachers.isEmpty) {
      await showAppErrorDialog(
        context,
        title: 'Faltan datos académicos',
        message: data.courses.isEmpty
            ? 'Registra al menos un curso antes de programar una clase.'
            : 'Registra al menos un docente antes de programar una clase.',
      );
      return;
    }
    if (data.classrooms.isEmpty) {
      await showAppErrorDialog(
        context,
        title: 'No hay aulas disponibles',
        message:
            'Registra un aula desde Catálogos > Aulas antes de programar una clase.',
      );
      return;
    }
    final fixedCourseId = perspective == _PlannerPerspective.course
        ? selectedResourceId
        : null;
    final fixedTeacherId = perspective == _PlannerPerspective.teacher
        ? selectedResourceId
        : null;
    final fixedClassroomId = perspective == _PlannerPerspective.classroom
        ? selectedResourceId
        : null;
    var preferredAssignment = initialAssignment;
    if (preferredAssignment == null && current != null) {
      for (final item in model.assignments) {
        if (item.courseId == current.courseId &&
            item.subjectId == current.subjectId &&
            item.teacherId == current.teacherId) {
          preferredAssignment = item;
          break;
        }
      }
    }
    if (preferredAssignment == null) {
      for (final item in model.assignments) {
        if ((fixedCourseId == null || item.courseId == fixedCourseId) &&
            (fixedTeacherId == null || item.teacherId == fixedTeacherId)) {
          preferredAssignment = item;
          break;
        }
      }
    }
    if (preferredAssignment == null) {
      final seedCourseId = fixedCourseId ?? data.courses.first.id;
      final seedSubjectId = data.subjects.first.id;
      AcademicAssignment? storedSeed;
      for (final item in model.assignments) {
        if (item.courseId == seedCourseId && item.subjectId == seedSubjectId) {
          storedSeed = item;
          break;
        }
      }
      preferredAssignment =
          storedSeed?.copyWith(
            teacherId: fixedTeacherId ?? storedSeed.teacherId,
          ) ??
          AcademicAssignment(
            courseId: seedCourseId,
            subjectId: seedSubjectId,
            teacherId: fixedTeacherId ?? data.teachers.first.id,
            weeklyMinutes: 30,
          );
    }
    final initialDialogAssignment = preferredAssignment;
    final dialogAssignments = <AcademicAssignment>[
      ...model.assignments,
      if (!model.assignments.any(
        (item) => item.key == initialDialogAssignment.key,
      ))
        initialDialogAssignment,
    ];
    final draft = await showDialog<PlannerBlockDraft>(
      context: context,
      builder: (context) => _BlockDialog(
        data: data,
        assignments: dialogAssignments,
        initialAssignment: initialDialogAssignment,
        current: current,
        initialWeekday: weekday,
        initialStartMinutes: startMinutes,
        initialEndMinutes: endMinutes,
        fixedCourseId: fixedCourseId,
        fixedTeacherId: fixedTeacherId,
        fixedClassroomId: fixedClassroomId,
      ),
    );
    if (draft == null) return;
    AcademicAssignment? existingAssignment;
    for (final item in model.assignments) {
      if (item.courseId == draft.assignment.courseId &&
          item.subjectId == draft.assignment.subjectId) {
        existingAssignment = item;
        break;
      }
    }
    final assignmentChanged =
        existingAssignment == null ||
        existingAssignment.teacherId != draft.assignment.teacherId;
    final saved = assignmentChanged
        ? await model.persistClass(
            draft.assignment,
            draft,
            currentAssignment: existingAssignment,
            currentBlock: current,
          )
        : await model.persistBlock(draft, current: current);
    if (!mounted) return;
    if (saved) {
      showAppSuccess(
        context,
        current == null ? 'Clase programada.' : 'Clase actualizada.',
      );
    } else {
      await showAppErrorDialog(
        context,
        title: current == null
            ? 'No se pudo programar la clase'
            : 'No se pudo actualizar la clase',
        message: model.takeError() ?? 'Revise el rango seleccionado.',
      );
    }
  }

  Future<void> _removeBlock(PlannerScheduleBlock block) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppDialogHeader(title: 'Retirar clase'),
        content: Text(
          'Se retirará la clase del ${weekdayLabels[block.weekday]?.toLowerCase()} '
          'de ${block.startTime} a ${block.endTime}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(LucideIcons.trash2, size: 17),
            label: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = await model.persistRemoveBlock(block);
    if (!mounted) return;
    if (removed) {
      showAppSuccess(context, 'Clase retirada.');
    } else {
      await showAppErrorDialog(
        context,
        title: 'No se pudo retirar la clase',
        message: model.takeError() ?? 'Intente nuevamente.',
      );
    }
  }

  Future<void> _configureGeneral() async {
    final data = model.data;
    if (data == null) return;
    final draft = await showDialog<GeneralScheduleDraft>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _GeneralConfigDialog(data: data),
    );
    if (draft == null) return;
    final saved = await model.saveGeneralConfig(draft);
    if (!mounted) return;
    if (saved) {
      showAppSuccess(context, 'Configuración general actualizada.');
    } else {
      await showAppErrorDialog(
        context,
        title: 'No se pudo actualizar la configuración',
        message: model.takeError() ?? 'Revise la jornada y los recreos.',
      );
    }
  }

  List<AcademicAssignment> _assignmentsForSelection(
    List<AcademicAssignment> source,
  ) => switch (perspective) {
    _PlannerPerspective.course =>
      source.where((item) => item.courseId == selectedResourceId).toList(),
    _PlannerPerspective.teacher =>
      source.where((item) => item.teacherId == selectedResourceId).toList(),
    _PlannerPerspective.classroom => source.where((assignment) {
      return model.blocks.any(
        (block) =>
            block.classroomId == selectedResourceId &&
            block.courseId == assignment.courseId &&
            block.subjectId == assignment.subjectId &&
            block.teacherId == assignment.teacherId,
      );
    }).toList(),
  };

  List<PlannerScheduleBlock> _blocksForSelection(
    List<PlannerScheduleBlock> source,
  ) => source.where((item) {
    return switch (perspective) {
      _PlannerPerspective.course => item.courseId == selectedResourceId,
      _PlannerPerspective.teacher => item.teacherId == selectedResourceId,
      _PlannerPerspective.classroom => item.classroomId == selectedResourceId,
    };
  }).toList();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schedulePlannerViewModelProvider);
    final canManage = ref.watch(
      sessionViewModelProvider.select(
        (session) => session.user?.isAdministrator == true,
      ),
    );
    final data = state.data;
    if (data != null) {
      final ids = _resourceItems(data).map((item) => item.$1);
      if (!ids.contains(selectedResourceId)) {
        selectedResourceId = ids.firstOrNull;
      }
    }
    return AdaptiveShell(
      location: '/horarios',
      title: 'Planificador de horarios',
      child: state.loading && data == null
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? _LoadError(message: state.error, onRetry: state.load)
          : LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 840;
                final assignments = _assignmentsForSelection(state.assignments);
                final blocks = _blocksForSelection(state.blocks);
                final plannerCanManage = canManage && !state.saving;
                return Column(
                  children: [
                    if (state.loading || state.saving)
                      const LinearProgressIndicator(minHeight: 2),
                    if (state.error != null)
                      _InlineError(message: state.error!),
                    Expanded(
                      child: Column(
                        children: [
                          _PlannerHeader(
                            data: data,
                            perspective: perspective,
                            resourceItems: _resourceItems(data),
                            selectedResourceId: selectedResourceId,
                            shift: shift,
                            saving: state.saving,
                            canManage: canManage,
                            desktop: desktop,
                            onPerspectiveChanged: (value) => setState(() {
                              perspective = value;
                              selectedResourceId = null;
                            }),
                            onResourceChanged: (value) =>
                                setState(() => selectedResourceId = value),
                            onShiftChanged: (value) =>
                                setState(() => shift = value),
                            onNewClass: () => _editBlock(
                              weekday: mobileDay,
                              startMinutes: math.max(
                                data.config.startMinutes,
                                shift.startMinutes,
                              ),
                            ),
                            onConfigure: _configureGeneral,
                          ),
                          Expanded(
                            child: desktop
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: 276,
                                        child: _AssignmentRail(
                                          data: data,
                                          model: state,
                                          assignments: assignments,
                                          canManage: plannerCanManage,
                                          onEdit: _editAssignment,
                                          onSchedule: (assignment) =>
                                              _editBlock(
                                                initialAssignment: assignment,
                                                weekday: mobileDay,
                                                startMinutes: math.max(
                                                  data.config.startMinutes,
                                                  shift.startMinutes,
                                                ),
                                              ),
                                          onRemove: _removeAssignment,
                                        ),
                                      ),
                                      Expanded(
                                        child: _ScheduleMatrix(
                                          data: data,
                                          perspective: perspective,
                                          shift: shift,
                                          blocks: blocks,
                                          canManage: plannerCanManage,
                                          onEmptyRange: (day, start, end) =>
                                              _editBlock(
                                                weekday: day,
                                                startMinutes: start,
                                                endMinutes: end,
                                              ),
                                          onEditBlock: (block) => _editBlock(
                                            current: block,
                                            weekday: block.weekday,
                                            startMinutes: block.startMinutes,
                                            endMinutes: block.endMinutes,
                                          ),
                                          onRemoveBlock: _removeBlock,
                                        ),
                                      ),
                                    ],
                                  )
                                : _MobileSchedule(
                                    data: data,
                                    perspective: perspective,
                                    shift: shift,
                                    selectedDay: mobileDay,
                                    assignments: assignments,
                                    blocks: blocks,
                                    canManage: plannerCanManage,
                                    onDayChanged: (value) =>
                                        setState(() => mobileDay = value),
                                    onAdd: () => _editBlock(
                                      weekday: mobileDay,
                                      startMinutes: shift.startMinutes,
                                    ),
                                    onEdit: (block) => _editBlock(
                                      current: block,
                                      weekday: block.weekday,
                                      startMinutes: block.startMinutes,
                                      endMinutes: block.endMinutes,
                                    ),
                                    onRemove: _removeBlock,
                                    scheduledMinutes: state.scheduledMinutes,
                                    onScheduleAssignment: (assignment) =>
                                        _editBlock(
                                          initialAssignment: assignment,
                                          weekday: mobileDay,
                                          startMinutes: math.max(
                                            data.config.startMinutes,
                                            shift.startMinutes,
                                          ),
                                        ),
                                    onEditAssignment: _editAssignment,
                                    onRemoveAssignment: _removeAssignment,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  List<(String, String)> _resourceItems(SchedulePlannerData data) =>
      switch (perspective) {
        _PlannerPerspective.course =>
          data.courses.map((item) => (item.id, item.name)).toList(),
        _PlannerPerspective.teacher =>
          data.teachers.map((item) => (item.id, item.fullName)).toList(),
        _PlannerPerspective.classroom =>
          data.classrooms.map((item) => (item.id, item.name)).toList(),
      };
}

class _PlannerHeader extends StatelessWidget {
  const _PlannerHeader({
    required this.data,
    required this.perspective,
    required this.resourceItems,
    required this.selectedResourceId,
    required this.shift,
    required this.saving,
    required this.canManage,
    required this.desktop,
    required this.onPerspectiveChanged,
    required this.onResourceChanged,
    required this.onShiftChanged,
    required this.onNewClass,
    required this.onConfigure,
  });

  final SchedulePlannerData data;
  final _PlannerPerspective perspective;
  final List<(String, String)> resourceItems;
  final String? selectedResourceId;
  final _PlannerShift shift;
  final bool saving;
  final bool canManage;
  final bool desktop;
  final ValueChanged<_PlannerPerspective> onPerspectiveChanged;
  final ValueChanged<String?> onResourceChanged;
  final ValueChanged<_PlannerShift> onShiftChanged;
  final VoidCallback onNewClass;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) => desktop
      ? _DesktopPlannerHeader(
          data: data,
          perspective: perspective,
          resourceItems: resourceItems,
          selectedResourceId: selectedResourceId,
          shift: shift,
          saving: saving,
          canManage: canManage,
          onPerspectiveChanged: onPerspectiveChanged,
          onResourceChanged: onResourceChanged,
          onShiftChanged: onShiftChanged,
          onNewClass: onNewClass,
          onConfigure: onConfigure,
        )
      : Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Planificador',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${data.period.name} ${data.period.year}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canManage) ...[
                    IconButton(
                      tooltip: 'Configuración general',
                      onPressed: saving ? null : onConfigure,
                      icon: const Icon(LucideIcons.settings2, size: 19),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<_PlannerPerspective>(
                initialValue: perspective,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Vista'),
                items: _PlannerPerspective.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onPerspectiveChanged(value);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey('$perspective-$selectedResourceId'),
                initialValue: selectedResourceId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: perspective.singularLabel,
                ),
                items: resourceItems
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.$1,
                        child: Text(item.$2, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: onResourceChanged,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<_PlannerShift>(
                      initialValue: shift,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Turno'),
                      items: _PlannerShift.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                item == _PlannerShift.morning
                                    ? 'Mañana'
                                    : 'Tarde',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) onShiftChanged(value);
                      },
                    ),
                  ),
                  if (canManage) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: saving ? null : onNewClass,
                      icon: const Icon(LucideIcons.calendarClock, size: 17),
                      label: const Text('Clase'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
}

class _DesktopPlannerHeader extends StatelessWidget {
  const _DesktopPlannerHeader({
    required this.data,
    required this.perspective,
    required this.resourceItems,
    required this.selectedResourceId,
    required this.shift,
    required this.saving,
    required this.canManage,
    required this.onPerspectiveChanged,
    required this.onResourceChanged,
    required this.onShiftChanged,
    required this.onNewClass,
    required this.onConfigure,
  });

  final SchedulePlannerData data;
  final _PlannerPerspective perspective;
  final List<(String, String)> resourceItems;
  final String? selectedResourceId;
  final _PlannerShift shift;
  final bool saving;
  final bool canManage;
  final ValueChanged<_PlannerPerspective> onPerspectiveChanged;
  final ValueChanged<String?> onResourceChanged;
  final ValueChanged<_PlannerShift> onShiftChanged;
  final VoidCallback onNewClass;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    const compactSegmentStyle = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
    );

    final perspectiveSelector = SegmentedButton<_PlannerPerspective>(
      showSelectedIcon: false,
      style: compactSegmentStyle,
      segments: _PlannerPerspective.values
          .map(
            (item) => ButtonSegment(
              value: item,
              icon: Icon(item.icon, size: 16),
              label: Text(item.label),
            ),
          )
          .toList(),
      selected: {perspective},
      onSelectionChanged: (value) => onPerspectiveChanged(value.first),
    );
    final resourceSelector = DropdownButtonFormField<String>(
      key: ValueKey('$perspective-$selectedResourceId'),
      initialValue: selectedResourceId,
      isExpanded: true,
      decoration: InputDecoration(labelText: perspective.singularLabel),
      selectedItemBuilder: (context) => resourceItems
          .map(
            (item) => Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: item.$2,
                child: Text(
                  item.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          )
          .toList(),
      items: resourceItems
          .map(
            (item) => DropdownMenuItem(
              value: item.$1,
              child: Text(
                item.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onResourceChanged,
    );
    final shiftSelector = SegmentedButton<_PlannerShift>(
      showSelectedIcon: false,
      style: compactSegmentStyle,
      segments: _PlannerShift.values
          .map((item) => ButtonSegment(value: item, label: Text(item.label)))
          .toList(),
      selected: {shift},
      onSelectionChanged: (value) => onShiftChanged(value.first),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final compact = constraints.maxWidth < 920 * textScale;
          final assignmentAction = compact
              ? IconButton.outlined(
                  tooltip: 'Nueva clase',
                  onPressed: saving ? null : onNewClass,
                  icon: const Icon(LucideIcons.calendarClock, size: 18),
                )
              : OutlinedButton.icon(
                  onPressed: saving ? null : onNewClass,
                  icon: const Icon(LucideIcons.calendarClock, size: 17),
                  label: const Text('Nueva clase'),
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Planificador de horarios',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data.period.name} ${data.period.year} · '
                          '${data.config.startTime}–${data.config.endTime} · '
                          'intervalos de ${data.config.intervalMinutes} min',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canManage) ...[
                    IconButton.outlined(
                      tooltip: 'Configuración general',
                      onPressed: saving ? null : onConfigure,
                      icon: const Icon(LucideIcons.settings2, size: 18),
                    ),
                    const SizedBox(width: 8),
                    assignmentAction,
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (compact) ...[
                Row(
                  children: [
                    perspectiveSelector,
                    const SizedBox(width: 12),
                    Expanded(child: resourceSelector),
                  ],
                ),
                const SizedBox(height: 10),
                shiftSelector,
              ] else
                Row(
                  children: [
                    perspectiveSelector,
                    const SizedBox(width: 12),
                    Expanded(child: resourceSelector),
                    const SizedBox(width: 12),
                    shiftSelector,
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AssignmentRail extends StatelessWidget {
  const _AssignmentRail({
    required this.data,
    required this.model,
    required this.assignments,
    required this.canManage,
    required this.onEdit,
    required this.onSchedule,
    required this.onRemove,
  });

  final SchedulePlannerData data;
  final SchedulePlannerViewModel model;
  final List<AcademicAssignment> assignments;
  final bool canManage;
  final ValueChanged<AcademicAssignment> onEdit;
  final ValueChanged<AcademicAssignment> onSchedule;
  final ValueChanged<AcademicAssignment> onRemove;

  @override
  Widget build(BuildContext context) {
    final sorted = [...assignments]
      ..sort(
        (left, right) => model
            .scheduledMinutes(right)
            .compareTo(model.scheduledMinutes(left)),
      );
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Asignaciones académicas',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  assignments.length == 1
                      ? '1 asignación registrada'
                      : '${assignments.length} asignaciones registradas',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: sorted.isEmpty
                ? const _EmptyAssignments()
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = sorted[index];
                      return _AssignmentTile(
                        data: data,
                        assignment: item,
                        scheduled: model.scheduledMinutes(item),
                        canManage: canManage,
                        onEdit: () => onEdit(item),
                        onSchedule: () => onSchedule(item),
                        onRemove: () => onRemove(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({
    required this.data,
    required this.assignment,
    required this.scheduled,
    required this.canManage,
    required this.onEdit,
    required this.onSchedule,
    required this.onRemove,
  });

  final SchedulePlannerData data;
  final AcademicAssignment assignment;
  final int scheduled;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onSchedule;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final subject = data.subjects.firstWhere(
      (item) => item.id == assignment.subjectId,
    );
    final course = data.courses.firstWhere(
      (item) => item.id == assignment.courseId,
    );
    final teacher = data.teachers.firstWhere(
      (item) => item.id == assignment.teacherId,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (canManage)
                IconButton(
                  tooltip: 'Programar clase',
                  visualDensity: VisualDensity.compact,
                  onPressed: onSchedule,
                  icon: const Icon(LucideIcons.calendarClock, size: 17),
                ),
              if (canManage)
                PopupMenuButton<String>(
                  tooltip: 'Acciones de la asignación',
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onRemove(),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar asignación'),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Retirar asignación'),
                    ),
                  ],
                ),
            ],
          ),
          Text(
            course.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            teacher.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 11),
          ),
          const SizedBox(height: 9),
          Text(
            scheduled == 0
                ? 'Sin clases programadas'
                : '${_durationLabel(scheduled)} semanales',
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleMatrix extends StatefulWidget {
  const _ScheduleMatrix({
    required this.data,
    required this.perspective,
    required this.shift,
    required this.blocks,
    required this.canManage,
    required this.onEmptyRange,
    required this.onEditBlock,
    required this.onRemoveBlock,
  });

  static const rowHeight = 42.0;
  static const headerHeight = 36.0;
  static const timeWidth = 62.0;
  static const minWidth = 780.0;

  final SchedulePlannerData data;
  final _PlannerPerspective perspective;
  final _PlannerShift shift;
  final List<PlannerScheduleBlock> blocks;
  final bool canManage;
  final void Function(int day, int startMinutes, int endMinutes) onEmptyRange;
  final ValueChanged<PlannerScheduleBlock> onEditBlock;
  final ValueChanged<PlannerScheduleBlock> onRemoveBlock;

  @override
  State<_ScheduleMatrix> createState() => _ScheduleMatrixState();
}

class _ScheduleMatrixState extends State<_ScheduleMatrix> {
  int? _selectionDay;
  int? _selectionAnchorSlot;
  int? _selectionExtentSlot;

  int? _dayAt(double x, double dayWidth) {
    if (x < _ScheduleMatrix.timeWidth ||
        x >= _ScheduleMatrix.timeWidth + dayWidth * 5) {
      return null;
    }
    return ((x - _ScheduleMatrix.timeWidth) / dayWidth).floor() + 1;
  }

  int? _slotAt(double y, int slots, {required bool clamp}) {
    final bodyY = y - _ScheduleMatrix.headerHeight;
    if (!clamp && (bodyY < 0 || bodyY >= slots * _ScheduleMatrix.rowHeight)) {
      return null;
    }
    return (bodyY / _ScheduleMatrix.rowHeight).floor().clamp(0, slots - 1);
  }

  bool _slotIsAvailable(int day, int slot, int visibleStart) {
    final interval = widget.data.config.intervalMinutes;
    final start = visibleStart + slot * interval;
    final end = start + interval;
    return !widget.data.breaks.any((item) => item.includesRange(start, end)) &&
        !widget.blocks.any(
          (item) =>
              item.weekday == day &&
              start < item.endMinutes &&
              end > item.startMinutes,
        );
  }

  bool _rangeIsAvailable(
    int day,
    int anchorSlot,
    int extentSlot,
    int visibleStart,
  ) {
    final first = math.min(anchorSlot, extentSlot);
    final last = math.max(anchorSlot, extentSlot);
    for (var slot = first; slot <= last; slot += 1) {
      if (!_slotIsAvailable(day, slot, visibleStart)) return false;
    }
    return true;
  }

  void _clearSelection() {
    if (!mounted) return;
    setState(() {
      _selectionDay = null;
      _selectionAnchorSlot = null;
      _selectionExtentSlot = null;
    });
  }

  void _startSelection(
    Offset localPosition,
    double dayWidth,
    int slots,
    int visibleStart,
  ) {
    if (_selectionAnchorSlot != null) return;
    final day = _dayAt(localPosition.dx, dayWidth);
    final slot = _slotAt(localPosition.dy, slots, clamp: false);
    if (day == null ||
        slot == null ||
        !_slotIsAvailable(day, slot, visibleStart)) {
      return;
    }
    setState(() {
      _selectionDay = day;
      _selectionAnchorSlot = slot;
      _selectionExtentSlot = slot;
    });
  }

  void _extendSelection(
    Offset localPosition,
    double dayWidth,
    int slots,
    int visibleStart,
  ) {
    final day = _dayAt(localPosition.dx, dayWidth);
    final slot = _slotAt(localPosition.dy, slots, clamp: true);
    final anchor = _selectionAnchorSlot;
    if (day != _selectionDay || slot == null || anchor == null) return;
    if (_rangeIsAvailable(day!, anchor, slot, visibleStart) &&
        slot != _selectionExtentSlot) {
      setState(() => _selectionExtentSlot = slot);
    }
  }

  void _finishSelection(int visibleStart) {
    final day = _selectionDay;
    final anchor = _selectionAnchorSlot;
    final extent = _selectionExtentSlot;
    if (day == null || anchor == null || extent == null) {
      _clearSelection();
      return;
    }
    final interval = widget.data.config.intervalMinutes;
    final startMinutes = visibleStart + math.min(anchor, extent) * interval;
    final endMinutes = visibleStart + (math.max(anchor, extent) + 1) * interval;
    _clearSelection();
    widget.onEmptyRange(day, startMinutes, endMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final start = math.max(
      widget.data.config.startMinutes,
      widget.shift.startMinutes,
    );
    final end = math.min(
      widget.data.config.endMinutes,
      widget.shift.endMinutes,
    );
    final slots = (end - start) ~/ widget.data.config.intervalMinutes;
    return ColoredBox(
      color: AppColors.canvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.max(
            _ScheduleMatrix.minWidth,
            constraints.maxWidth,
          );
          final dayWidth = (width - _ScheduleMatrix.timeWidth) / 5;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                key: const ValueKey('schedule-matrix-grid'),
                behavior: HitTestBehavior.opaque,
                onTapUp: widget.canManage
                    ? (details) {
                        _startSelection(
                          details.localPosition,
                          dayWidth,
                          slots,
                          start,
                        );
                        _finishSelection(start);
                      }
                    : null,
                onVerticalDragDown: widget.canManage
                    ? (details) => _startSelection(
                        details.localPosition,
                        dayWidth,
                        slots,
                        start,
                      )
                    : null,
                onVerticalDragStart: widget.canManage
                    ? (details) {
                        if (_selectionAnchorSlot == null) {
                          _startSelection(
                            details.localPosition,
                            dayWidth,
                            slots,
                            start,
                          );
                        } else {
                          _extendSelection(
                            details.localPosition,
                            dayWidth,
                            slots,
                            start,
                          );
                        }
                      }
                    : null,
                onVerticalDragUpdate: widget.canManage
                    ? (details) => _extendSelection(
                        details.localPosition,
                        dayWidth,
                        slots,
                        start,
                      )
                    : null,
                onVerticalDragEnd: widget.canManage
                    ? (_) => _finishSelection(start)
                    : null,
                onVerticalDragCancel: widget.canManage ? _clearSelection : null,
                child: SizedBox(
                  width: width,
                  height:
                      _ScheduleMatrix.headerHeight +
                      slots * _ScheduleMatrix.rowHeight,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            height: _ScheduleMatrix.headerHeight,
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: _ScheduleMatrix.timeWidth,
                                ),
                                for (var day = 1; day <= 5; day += 1)
                                  Container(
                                    width: dayWidth,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: AppColors.navy,
                                      border: Border(
                                        right: BorderSide(
                                          color: AppColors.navyDark,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      weekdayLabels[day]!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          for (var slot = 0; slot < slots; slot += 1)
                            _MatrixRow(
                              data: widget.data,
                              dayWidth: dayWidth,
                              minutes:
                                  start +
                                  slot * widget.data.config.intervalMinutes,
                            ),
                        ],
                      ),
                      if (_selectionDay != null &&
                          _selectionAnchorSlot != null &&
                          _selectionExtentSlot != null)
                        Positioned(
                          left:
                              _ScheduleMatrix.timeWidth +
                              (_selectionDay! - 1) * dayWidth +
                              4,
                          top:
                              _ScheduleMatrix.headerHeight +
                              math.min(
                                    _selectionAnchorSlot!,
                                    _selectionExtentSlot!,
                                  ) *
                                  _ScheduleMatrix.rowHeight +
                              3,
                          width: dayWidth - 8,
                          height:
                              (math.max(
                                        _selectionAnchorSlot!,
                                        _selectionExtentSlot!,
                                      ) -
                                      math.min(
                                        _selectionAnchorSlot!,
                                        _selectionExtentSlot!,
                                      ) +
                                      1) *
                                  _ScheduleMatrix.rowHeight -
                              6,
                          child: IgnorePointer(
                            child: Container(
                              key: const ValueKey('schedule-range-preview'),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.blueSoft.withValues(alpha: .9),
                                border: Border.all(
                                  color: AppColors.navy,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '${scheduleMinutesToTime(start + math.min(_selectionAnchorSlot!, _selectionExtentSlot!) * widget.data.config.intervalMinutes)}–'
                                '${scheduleMinutesToTime(start + (math.max(_selectionAnchorSlot!, _selectionExtentSlot!) + 1) * widget.data.config.intervalMinutes)}',
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      for (final block in widget.blocks.where(
                        (item) =>
                            item.startMinutes < end && item.endMinutes > start,
                      ))
                        Positioned(
                          left:
                              _ScheduleMatrix.timeWidth +
                              (block.weekday - 1) * dayWidth +
                              4,
                          top:
                              _ScheduleMatrix.headerHeight +
                              ((math.max(block.startMinutes, start) - start) /
                                      widget.data.config.intervalMinutes) *
                                  _ScheduleMatrix.rowHeight +
                              3,
                          width: dayWidth - 8,
                          height: math.max(
                            35,
                            ((math.min(block.endMinutes, end) -
                                            math.max(
                                              block.startMinutes,
                                              start,
                                            )) /
                                        widget.data.config.intervalMinutes) *
                                    _ScheduleMatrix.rowHeight -
                                6,
                          ),
                          child: _BlockCard(
                            data: widget.data,
                            perspective: widget.perspective,
                            block: block,
                            onTap: widget.canManage
                                ? () => widget.onEditBlock(block)
                                : null,
                            onRemove: widget.canManage
                                ? () => widget.onRemoveBlock(block)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MatrixRow extends StatelessWidget {
  const _MatrixRow({
    required this.data,
    required this.dayWidth,
    required this.minutes,
  });

  final SchedulePlannerData data;
  final double dayWidth;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final end = minutes + data.config.intervalMinutes;
    final recess = data.breaks
        .where((item) => item.includesRange(minutes, end))
        .firstOrNull;
    return SizedBox(
      height: _ScheduleMatrix.rowHeight,
      child: Row(
        children: [
          Container(
            width: _ScheduleMatrix.timeWidth,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: AppColors.canvas,
              border: Border(
                right: BorderSide(color: AppColors.border),
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Text(
              scheduleMinutesToTime(minutes),
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 10),
            ),
          ),
          for (var day = 1; day <= 5; day += 1)
            SizedBox(
              width: dayWidth,
              child: MouseRegion(
                cursor: recess == null
                    ? SystemMouseCursors.precise
                    : SystemMouseCursors.forbidden,
                child: ColoredBox(
                  color: recess == null
                      ? AppColors.surface
                      : AppColors.amberSoft,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AppColors.border),
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: recess == null
                        ? null
                        : Text(
                            recess.name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({
    required this.data,
    required this.perspective,
    required this.block,
    required this.onTap,
    required this.onRemove,
  });

  final SchedulePlannerData data;
  final _PlannerPerspective perspective;
  final PlannerScheduleBlock block;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final subject = data.subjects.firstWhere(
      (item) => item.id == block.subjectId,
    );
    final course = data.courses.firstWhere((item) => item.id == block.courseId);
    final teacher = data.teachers.firstWhere(
      (item) => item.id == block.teacherId,
    );
    final classroom = data.classrooms.firstWhere(
      (item) => item.id == block.classroomId,
    );
    final detail = switch (perspective) {
      _PlannerPerspective.course => '${teacher.fullName} · ${classroom.name}',
      _PlannerPerspective.teacher => '${course.name} · ${classroom.name}',
      _PlannerPerspective.classroom => '${teacher.fullName} · ${course.name}',
    };
    return Material(
      color: AppColors.blueSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: const BorderSide(color: Color(0xFFB7C9E2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(width: 4, color: AppColors.navy),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 4, 2, 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (block.durationMinutes >= 60)
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9),
                      ),
                    if (block.durationMinutes >= 90)
                      Text(
                        '${block.startTime}–${block.endTime}',
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 8,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (onRemove != null)
              IconButton(
                tooltip: 'Retirar bloque',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 26,
                  height: 28,
                ),
                onPressed: onRemove,
                icon: const Icon(LucideIcons.x, size: 13),
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileSchedule extends StatelessWidget {
  const _MobileSchedule({
    required this.data,
    required this.perspective,
    required this.shift,
    required this.selectedDay,
    required this.assignments,
    required this.blocks,
    required this.canManage,
    required this.onDayChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.scheduledMinutes,
    required this.onScheduleAssignment,
    required this.onEditAssignment,
    required this.onRemoveAssignment,
  });

  final SchedulePlannerData data;
  final _PlannerPerspective perspective;
  final _PlannerShift shift;
  final int selectedDay;
  final List<AcademicAssignment> assignments;
  final List<PlannerScheduleBlock> blocks;
  final bool canManage;
  final ValueChanged<int> onDayChanged;
  final VoidCallback onAdd;
  final ValueChanged<PlannerScheduleBlock> onEdit;
  final ValueChanged<PlannerScheduleBlock> onRemove;
  final int Function(AcademicAssignment) scheduledMinutes;
  final ValueChanged<AcademicAssignment> onScheduleAssignment;
  final ValueChanged<AcademicAssignment> onEditAssignment;
  final ValueChanged<AcademicAssignment> onRemoveAssignment;

  @override
  Widget build(BuildContext context) {
    final dayBlocks =
        blocks
            .where(
              (item) =>
                  item.weekday == selectedDay &&
                  item.startMinutes < shift.endMinutes &&
                  item.endMinutes > shift.startMinutes,
            )
            .toList()
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return ColoredBox(
      color: AppColors.canvas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (var day = 1; day <= 5; day += 1)
                  ButtonSegment(
                    value: day,
                    label: Text(weekdayLabels[day]!.substring(0, 3)),
                  ),
              ],
              selected: {selectedDay},
              onSelectionChanged: (value) => onDayChanged(value.first),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Clases del día',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (canManage)
                FilledButton.tonalIcon(
                  onPressed: onAdd,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Clase'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (dayBlocks.isEmpty)
            const _MobileEmptyDay()
          else
            ...dayBlocks.map(
              (block) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MobileBlockTile(
                  data: data,
                  block: block,
                  onEdit: canManage ? () => onEdit(block) : null,
                  onRemove: canManage ? () => onRemove(block) : null,
                ),
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            'Asignaciones académicas',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (assignments.isEmpty)
            const _EmptyAssignments()
          else
            ...assignments.map(
              (assignment) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _MobileAssignmentSummary(
                  data: data,
                  assignment: assignment,
                  scheduled: scheduledMinutes(assignment),
                  canManage: canManage,
                  onSchedule: () => onScheduleAssignment(assignment),
                  onEdit: () => onEditAssignment(assignment),
                  onRemove: () => onRemoveAssignment(assignment),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileBlockTile extends StatelessWidget {
  const _MobileBlockTile({
    required this.data,
    required this.block,
    required this.onEdit,
    required this.onRemove,
  });
  final SchedulePlannerData data;
  final PlannerScheduleBlock block;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final subject = data.subjects.firstWhere(
      (item) => item.id == block.subjectId,
    );
    final course = data.courses.firstWhere((item) => item.id == block.courseId);
    final teacher = data.teachers.firstWhere(
      (item) => item.id == block.teacherId,
    );
    final classroom = data.classrooms.firstWhere(
      (item) => item.id == block.classroomId,
    );
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onEdit,
        leading: SizedBox(
          width: 48,
          child: Text(
            '${block.startTime}\n${block.endTime}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(subject.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${course.name} · ${teacher.fullName}\n${classroom.name}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: onRemove == null
            ? null
            : IconButton(
                tooltip: 'Retirar bloque',
                onPressed: onRemove,
                icon: const Icon(LucideIcons.x, size: 17),
              ),
      ),
    );
  }
}

class _MobileAssignmentSummary extends StatelessWidget {
  const _MobileAssignmentSummary({
    required this.data,
    required this.assignment,
    required this.scheduled,
    required this.canManage,
    required this.onSchedule,
    required this.onEdit,
    required this.onRemove,
  });
  final SchedulePlannerData data;
  final AcademicAssignment assignment;
  final int scheduled;
  final bool canManage;
  final VoidCallback onSchedule;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final subject = data.subjects.firstWhere(
      (item) => item.id == assignment.subjectId,
    );
    final course = data.courses.firstWhere(
      (item) => item.id == assignment.courseId,
    );
    final teacher = data.teachers.firstWhere(
      (item) => item.id == assignment.teacherId,
    );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.name, overflow: TextOverflow.ellipsis),
                Text(
                  '${course.name} · ${teacher.fullName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scheduled == 0
                      ? 'Sin clases programadas'
                      : '${_durationLabel(scheduled)} semanales',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (canManage)
            IconButton(
              tooltip: 'Programar clase',
              visualDensity: VisualDensity.compact,
              onPressed: onSchedule,
              icon: const Icon(LucideIcons.calendarClock, size: 17),
            ),
          if (canManage)
            PopupMenuButton<String>(
              tooltip: 'Acciones de la asignación',
              padding: EdgeInsets.zero,
              iconSize: 18,
              onSelected: (value) => value == 'edit' ? onEdit() : onRemove(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar asignación')),
                PopupMenuItem(
                  value: 'remove',
                  child: Text('Retirar asignación'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PlannerDialogShell extends StatefulWidget {
  const _PlannerDialogShell({
    required this.title,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.child,
    this.subtitle,
    this.maxWidth = 560,
  });

  final String title;
  final String? subtitle;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? onPrimary;
  final Widget child;
  final double maxWidth;

  @override
  State<_PlannerDialogShell> createState() => _PlannerDialogShellState();
}

class _PlannerDialogShellState extends State<_PlannerDialogShell> {
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 480;
    final horizontalInset = compact ? 12.0 : 24.0;
    final verticalInset = size.height < 640 ? 12.0 : 24.0;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: verticalInset,
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
          maxHeight: math.max(320, size.height - verticalInset * 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 22,
                compact ? 14 : 18,
                compact ? 12 : 16,
                compact ? 12 : 16,
              ),
              child: AppDialogHeader(
                title: widget.title,
                subtitle: widget.subtitle,
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                thickness: compact ? 3 : 5,
                radius: const Radius.circular(3),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(compact ? 16 : 22),
                  child: widget.child,
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 18,
                vertical: 12,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth < 400
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: widget.onPrimary,
                            icon: Icon(widget.primaryIcon, size: 16),
                            label: Text(widget.primaryLabel),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: widget.onPrimary,
                            icon: Icon(widget.primaryIcon, size: 16),
                            label: Text(widget.primaryLabel),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogSectionHeader extends StatelessWidget {
  const _DialogSectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.navy),
      const SizedBox(width: 8),
      Expanded(
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      ?trailing,
    ],
  );
}

class _ResponsiveFieldRow extends StatelessWidget {
  const _ResponsiveFieldRow({
    required this.children,
    this.compactBreakpoint = 500,
  });

  final List<Widget> children;
  final double compactBreakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < compactBreakpoint) {
        return Column(
          children: [
            for (final (index, child) in children.indexed) ...[
              child,
              if (index < children.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, child) in children.indexed) ...[
            Expanded(child: child),
            if (index < children.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    },
  );
}

class _AssignmentDialog extends StatefulWidget {
  const _AssignmentDialog({required this.data, required this.current});
  final SchedulePlannerData data;
  final AcademicAssignment current;

  @override
  State<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  late String courseId = widget.current.courseId;
  late String subjectId = widget.current.subjectId;
  late String teacherId = widget.current.teacherId;

  void _submit() => Navigator.pop(
    context,
    AcademicAssignment(
      id: widget.current.id,
      courseId: courseId,
      subjectId: subjectId,
      teacherId: teacherId,
      weeklyMinutes: widget.current.weeklyMinutes,
    ),
  );

  @override
  Widget build(BuildContext context) => _PlannerDialogShell(
    title: 'Editar asignación',
    subtitle: 'Los cambios se aplicarán a todas sus clases',
    primaryLabel: 'Guardar asignación',
    primaryIcon: LucideIcons.save,
    onPrimary: _submit,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DialogSectionHeader(
          icon: LucideIcons.bookOpen,
          title: 'Datos académicos',
        ),
        const SizedBox(height: 12),
        _SelectField(
          label: 'Curso',
          value: courseId,
          items: widget.data.courses
              .map((item) => (item.id, item.name))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => courseId = value);
          },
        ),
        const SizedBox(height: 12),
        _SelectField(
          label: 'Materia',
          value: subjectId,
          items: widget.data.subjects
              .map((item) => (item.id, item.name))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => subjectId = value);
          },
        ),
        const SizedBox(height: 12),
        _SelectField(
          label: 'Docente que imparte',
          value: teacherId,
          items: widget.data.teachers
              .map((item) => (item.id, item.fullName))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => teacherId = value);
          },
        ),
      ],
    ),
  );
}

class _BlockDialog extends StatefulWidget {
  const _BlockDialog({
    required this.data,
    required this.assignments,
    required this.initialWeekday,
    required this.initialStartMinutes,
    this.initialEndMinutes,
    this.initialAssignment,
    this.current,
    this.fixedCourseId,
    this.fixedTeacherId,
    this.fixedClassroomId,
  });
  final SchedulePlannerData data;
  final List<AcademicAssignment> assignments;
  final AcademicAssignment? initialAssignment;
  final PlannerScheduleBlock? current;
  final int initialWeekday;
  final int initialStartMinutes;
  final int? initialEndMinutes;
  final String? fixedCourseId;
  final String? fixedTeacherId;
  final String? fixedClassroomId;

  @override
  State<_BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends State<_BlockDialog> {
  late AcademicAssignment assignment = widget.current == null
      ? widget.assignments.firstWhere(
          (item) => item.key == widget.initialAssignment?.key,
          orElse: () => widget.assignments.first,
        )
      : widget.assignments.firstWhere(
          (item) =>
              item.courseId == widget.current!.courseId &&
              item.subjectId == widget.current!.subjectId &&
              item.teacherId == widget.current!.teacherId,
          orElse: () => widget.assignments.first,
        );
  late String classroomId =
      widget.fixedClassroomId ??
      widget.current?.classroomId ??
      widget.data.classrooms.first.id;
  late int weekday = widget.current?.weekday ?? widget.initialWeekday;
  late int startMinutes =
      widget.current?.startMinutes ?? widget.initialStartMinutes;
  late int endMinutes =
      widget.current?.endMinutes ??
      widget.initialEndMinutes ??
      math.min(
        widget.initialStartMinutes + widget.data.config.intervalMinutes,
        widget.data.config.endMinutes,
      );

  AcademicAssignment _assignmentFor({
    required String courseId,
    required String subjectId,
    required String teacherId,
  }) {
    AcademicAssignment? existing;
    for (final item in widget.assignments) {
      if (item.courseId == courseId && item.subjectId == subjectId) {
        existing = item;
        break;
      }
    }
    final selectedTeacherId = widget.fixedTeacherId ?? teacherId;
    return existing?.copyWith(
          teacherId: widget.fixedTeacherId == null
              ? existing.teacherId
              : selectedTeacherId,
        ) ??
        AcademicAssignment(
          courseId: courseId,
          subjectId: subjectId,
          teacherId: selectedTeacherId,
          weeklyMinutes: 30,
        );
  }

  void _selectCourse(String? courseId) {
    if (courseId == null) return;
    setState(
      () => assignment = _assignmentFor(
        courseId: courseId,
        subjectId: assignment.subjectId,
        teacherId: assignment.teacherId,
      ),
    );
  }

  void _selectSubject(String? subjectId) {
    if (subjectId == null) return;
    setState(
      () => assignment = _assignmentFor(
        courseId: assignment.courseId,
        subjectId: subjectId,
        teacherId: assignment.teacherId,
      ),
    );
  }

  void _selectTeacher(String? teacherId) {
    if (teacherId == null) return;
    setState(() => assignment = assignment.copyWith(teacherId: teacherId));
  }

  @override
  Widget build(BuildContext context) {
    final slots = <int>[
      for (
        var value = widget.data.config.startMinutes;
        value <= widget.data.config.endMinutes;
        value += widget.data.config.intervalMinutes
      )
        value,
    ];
    if (endMinutes <= startMinutes) {
      endMinutes = math.min(
        startMinutes + widget.data.config.intervalMinutes,
        widget.data.config.endMinutes,
      );
    }
    AcademicAssignment? storedAssignment;
    for (final item in widget.assignments) {
      if (item.courseId == assignment.courseId &&
          item.subjectId == assignment.subjectId) {
        storedAssignment = item;
        break;
      }
    }
    final reassigningTeacher =
        storedAssignment != null &&
        storedAssignment.teacherId != assignment.teacherId;
    return _PlannerDialogShell(
      title: widget.current == null ? 'Agregar una clase' : 'Editar la clase',
      maxWidth: 540,
      primaryLabel: widget.current == null
          ? 'Agregar clase'
          : 'Guardar cambios',
      primaryIcon: LucideIcons.check,
      onPrimary: () => Navigator.pop(
        context,
        PlannerBlockDraft(
          assignment: assignment,
          classroomId: classroomId,
          weekday: weekday,
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DialogSectionHeader(
            icon: LucideIcons.bookOpen,
            title: '1. Asignación académica',
          ),
          const SizedBox(height: 12),
          _SelectField(
            key: ValueKey('course-${assignment.courseId}'),
            label: 'Curso',
            value: assignment.courseId,
            items: widget.data.courses
                .where(
                  (item) =>
                      widget.fixedCourseId == null ||
                      item.id == widget.fixedCourseId,
                )
                .map((item) => (item.id, item.name))
                .toList(),
            enabled: widget.fixedCourseId == null,
            onChanged: _selectCourse,
          ),
          const SizedBox(height: 12),
          _SelectField(
            key: ValueKey(
              'subject-${assignment.courseId}-${assignment.subjectId}',
            ),
            label: 'Materia',
            value: assignment.subjectId,
            items: widget.data.subjects
                .map((item) => (item.id, item.name))
                .toList(),
            onChanged: _selectSubject,
          ),
          const SizedBox(height: 12),
          _SelectField(
            key: ValueKey(
              'teacher-${assignment.courseId}-${assignment.subjectId}-${assignment.teacherId}',
            ),
            label: 'Docente',
            value: assignment.teacherId,
            items: widget.data.teachers
                .where(
                  (item) =>
                      widget.fixedTeacherId == null ||
                      item.id == widget.fixedTeacherId,
                )
                .map((item) => (item.id, item.fullName))
                .toList(),
            enabled: widget.fixedTeacherId == null,
            onChanged: _selectTeacher,
          ),
          if (reassigningTeacher) ...[
            const SizedBox(height: 10),
            _TeacherReassignmentNotice(
              subjectName: widget.data.subjects
                  .firstWhere((item) => item.id == assignment.subjectId)
                  .name,
              courseName: widget.data.courses
                  .firstWhere((item) => item.id == assignment.courseId)
                  .name,
              teacherName: widget.data.teachers
                  .firstWhere((item) => item.id == assignment.teacherId)
                  .fullName,
            ),
          ],
          const SizedBox(height: 24),
          const _DialogSectionHeader(
            icon: LucideIcons.calendarClock,
            title: '2. Día y horario',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: weekday,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Día de la semana'),
            items: [
              for (var day = 1; day <= 5; day += 1)
                DropdownMenuItem(value: day, child: Text(weekdayLabels[day]!)),
            ],
            onChanged: (value) => setState(() => weekday = value ?? weekday),
          ),
          const SizedBox(height: 12),
          _TimeField(
            label: 'Hora de inicio',
            value: startMinutes,
            options: slots
                .where((item) => item < widget.data.config.endMinutes)
                .toList(),
            onChanged: (value) => setState(() {
              startMinutes = value;
              if (endMinutes <= startMinutes) {
                endMinutes = math.min(
                  startMinutes + widget.data.config.intervalMinutes,
                  widget.data.config.endMinutes,
                );
              }
            }),
          ),
          const SizedBox(height: 12),
          _TimeField(
            key: ValueKey('$startMinutes-$endMinutes'),
            label: 'Hora de fin',
            value: endMinutes,
            options: slots.where((item) => item > startMinutes).toList(),
            onChanged: (value) => setState(() => endMinutes = value),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                LucideIcons.timer,
                size: 16,
                color: AppColors.inkMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Duración total: ${_durationLabel(endMinutes - startMinutes)}',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _DialogSectionHeader(
            icon: LucideIcons.doorOpen,
            title: '3. Aula',
          ),
          const SizedBox(height: 12),
          _SelectField(
            label: 'Aula donde será la clase',
            value: classroomId,
            enabled: widget.fixedClassroomId == null,
            items: widget.data.classrooms
                .map((item) => (item.id, item.name))
                .toList(),
            onChanged: (value) =>
                setState(() => classroomId = value ?? classroomId),
          ),
        ],
      ),
    );
  }
}

class _TeacherReassignmentNotice extends StatelessWidget {
  const _TeacherReassignmentNotice({
    required this.subjectName,
    required this.courseName,
    required this.teacherName,
  });

  final String subjectName;
  final String courseName;
  final String teacherName;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.amberSoft,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(LucideIcons.triangleAlert, size: 17, color: AppColors.amber),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Al guardar, todas las clases de $subjectName en $courseName '
            'pasarán a $teacherName.',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _GeneralConfigDialog extends StatefulWidget {
  const _GeneralConfigDialog({required this.data});
  final SchedulePlannerData data;

  @override
  State<_GeneralConfigDialog> createState() => _GeneralConfigDialogState();
}

class _GeneralConfigDialogState extends State<_GeneralConfigDialog> {
  late int startMinutes = widget.data.config.startMinutes;
  late int endMinutes = widget.data.config.endMinutes;
  late int tolerance = widget.data.config.toleranceMinutes;
  late List<_BreakInput> breaks = widget.data.breaks
      .map(
        (item) => _BreakInput(
          id: item.id,
          name: item.name,
          startMinutes: scheduleTimeToMinutes(item.startTime),
          endMinutes: scheduleTimeToMinutes(item.endTime),
        ),
      )
      .toList();
  String? validation;

  @override
  Widget build(BuildContext context) {
    final options = [
      for (var value = 6 * 60; value <= 21 * 60; value += 30) value,
    ];
    return _PlannerDialogShell(
      title: 'Configuración del horario',
      subtitle: '${widget.data.period.name} ${widget.data.period.year}',
      maxWidth: 680,
      primaryLabel: 'Guardar configuración',
      primaryIcon: LucideIcons.save,
      onPrimary: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DialogSectionHeader(
            icon: LucideIcons.calendarClock,
            title: 'Jornada general',
          ),
          const SizedBox(height: 12),
          _ResponsiveFieldRow(
            children: [
              _TimeField(
                label: 'Inicio de jornada',
                value: startMinutes,
                options: options.where((item) => item < endMinutes).toList(),
                onChanged: (value) => setState(() => startMinutes = value),
              ),
              _TimeField(
                label: 'Fin de jornada',
                value: endMinutes,
                options: options.where((item) => item > startMinutes).toList(),
                onChanged: (value) => setState(() => endMinutes = value),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tolerancia de atraso',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$tolerance min',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: tolerance.toDouble(),
            min: 0,
            max: 30,
            divisions: 6,
            label: '$tolerance min',
            onChanged: (value) => setState(() => tolerance = value.round()),
          ),
          const Divider(height: 34),
          _DialogSectionHeader(
            icon: LucideIcons.coffee,
            title: 'Recreos generales',
            trailing: OutlinedButton.icon(
              onPressed: () => setState(
                () => breaks.add(
                  _BreakInput(
                    name: 'RECREO',
                    startMinutes: 10 * 60,
                    endMinutes: 10 * 60 + 30,
                  ),
                ),
              ),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Agregar'),
            ),
          ),
          const SizedBox(height: 12),
          if (breaks.isEmpty)
            const _EmptyBreaks()
          else
            ...breaks.indexed.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BreakEditor(
                  index: entry.$1 + 1,
                  value: entry.$2,
                  options: options,
                  onChanged: (value) =>
                      setState(() => breaks[entry.$1] = value),
                  onRemove: () => setState(() => breaks.removeAt(entry.$1)),
                ),
              ),
            ),
          if (validation != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.redSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                validation!,
                style: const TextStyle(color: AppColors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  void _submit() {
    if (breaks.any(
      (item) =>
          item.name.trim().length < 2 ||
          item.endMinutes <= item.startMinutes ||
          item.startMinutes < startMinutes ||
          item.endMinutes > endMinutes,
    )) {
      setState(
        () => validation =
            'Cada recreo debe tener nombre y estar dentro de la jornada.',
      );
      return;
    }
    for (var left = 0; left < breaks.length; left += 1) {
      for (var right = left + 1; right < breaks.length; right += 1) {
        if (breaks[left].startMinutes < breaks[right].endMinutes &&
            breaks[left].endMinutes > breaks[right].startMinutes) {
          setState(() => validation = 'Los recreos no pueden superponerse.');
          return;
        }
      }
    }
    Navigator.pop(
      context,
      GeneralScheduleDraft(
        periodId: widget.data.period.id,
        version: widget.data.config.version,
        startTime: scheduleMinutesToTime(startMinutes),
        endTime: scheduleMinutesToTime(endMinutes),
        toleranceMinutes: tolerance,
        breaks: breaks
            .map(
              (item) => ScheduleBreak(
                id: item.id,
                name: item.name.trim(),
                startTime: scheduleMinutesToTime(item.startMinutes),
                endTime: scheduleMinutesToTime(item.endMinutes),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BreakInput {
  const _BreakInput({
    this.id,
    required this.name,
    required this.startMinutes,
    required this.endMinutes,
  });
  final String? id;
  final String name;
  final int startMinutes;
  final int endMinutes;

  _BreakInput copyWith({String? name, int? startMinutes, int? endMinutes}) =>
      _BreakInput(
        id: id,
        name: name ?? this.name,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
      );
}

class _BreakEditor extends StatelessWidget {
  const _BreakEditor({
    required this.index,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.onRemove,
  });
  final int index;
  final _BreakInput value;
  final List<int> options;
  final ValueChanged<_BreakInput> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recreo $index',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Retirar recreo',
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(LucideIcons.trash2, size: 17),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value.name,
          decoration: const InputDecoration(labelText: 'Nombre'),
          onChanged: (text) => onChanged(value.copyWith(name: text)),
        ),
        const SizedBox(height: 10),
        _ResponsiveFieldRow(
          compactBreakpoint: 390,
          children: [
            _TimeField(
              label: 'Desde',
              value: value.startMinutes,
              options: options
                  .where((item) => item < value.endMinutes)
                  .toList(),
              onChanged: (item) =>
                  onChanged(value.copyWith(startMinutes: item)),
            ),
            _TimeField(
              label: 'Hasta',
              value: value.endMinutes,
              options: options
                  .where((item) => item > value.startMinutes)
                  .toList(),
              onChanged: (item) => onChanged(value.copyWith(endMinutes: item)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });
  final String label;
  final String? value;
  final List<(String, String)> items;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: items
        .map(
          (item) => DropdownMenuItem(
            value: item.$1,
            child: Text(item.$2, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: enabled ? onChanged : null,
  );
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: options
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(scheduleMinutesToTime(item)),
          ),
        )
        .toList(),
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
}

class _EmptyBreaks extends StatelessWidget {
  const _EmptyBreaks();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text(
      'No hay recreos configurados.',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.inkMuted),
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: AppColors.redSoft,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    child: Text(
      message,
      style: const TextStyle(color: AppColors.red, fontSize: 12),
    ),
  );
}

class _EmptyAssignments extends StatelessWidget {
  const _EmptyAssignments();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'No hay asignaciones para esta vista.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.inkMuted),
      ),
    ),
  );
}

class _MobileEmptyDay extends StatelessWidget {
  const _MobileEmptyDay();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text(
      'No hay clases en este turno.',
      style: TextStyle(color: AppColors.inkMuted),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String? message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.triangleAlert, size: 34, color: AppColors.red),
          const SizedBox(height: 10),
          Text(
            message ?? 'No se pudo cargar el planificador.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

String _durationLabel(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '$rest min';
  if (rest == 0) return '$hours h';
  return '$hours h $rest min';
}
