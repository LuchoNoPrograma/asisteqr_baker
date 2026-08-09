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

  Future<void> _save() async {
    final saved = await model.save();
    if (!mounted) return;
    if (saved) {
      showAppSuccess(context, 'Planificación guardada.');
    } else {
      await showAppErrorDialog(
        context,
        title: 'No se pudo guardar',
        message: model.takeError() ?? 'No hay cambios pendientes.',
      );
    }
  }

  Future<void> _editAssignment([AcademicAssignment? current]) async {
    final data = model.data;
    if (data == null) return;
    final result = await showDialog<AcademicAssignment>(
      context: context,
      builder: (context) => _AssignmentDialog(
        data: data,
        current: current,
        initialCourseId: perspective == _PlannerPerspective.course
            ? selectedResourceId
            : null,
        initialTeacherId: perspective == _PlannerPerspective.teacher
            ? selectedResourceId
            : null,
      ),
    );
    if (result == null) return;
    final saved = model.saveAssignment(result, current: current);
    if (!saved && mounted) {
      await showAppErrorDialog(
        context,
        title: 'No se pudo guardar la asignación',
        message: model.takeError() ?? 'Revise los datos indicados.',
      );
    }
  }

  Future<void> _removeAssignment(AcademicAssignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppDialogHeader(title: 'Retirar asignación'),
        content: const Text(
          'También se retirarán sus bloques de clase al guardar.',
        ),
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
    if (confirmed == true) model.removeAssignment(assignment);
  }

  Future<void> _editBlock({
    PlannerScheduleBlock? current,
    required int weekday,
    required int startMinutes,
  }) async {
    final data = model.data;
    if (data == null) return;
    var available = _assignmentsForSelection(model.assignments);
    if (available.isEmpty) {
      final assignment = await showDialog<AcademicAssignment>(
        context: context,
        builder: (context) => _AssignmentDialog(
          data: data,
          initialCourseId: perspective == _PlannerPerspective.course
              ? selectedResourceId
              : null,
          initialTeacherId: perspective == _PlannerPerspective.teacher
              ? selectedResourceId
              : null,
        ),
      );
      if (assignment == null) return;
      if (!model.saveAssignment(assignment)) {
        if (mounted) {
          await showAppErrorDialog(
            context,
            title: 'No se pudo crear la asignación',
            message: model.takeError() ?? 'Revise los datos indicados.',
          );
        }
        return;
      }
      available = _assignmentsForSelection(model.assignments);
    }
    final fixedClassroomId = perspective == _PlannerPerspective.classroom
        ? selectedResourceId
        : null;
    final draft = await showDialog<PlannerBlockDraft>(
      context: context,
      builder: (context) => _BlockDialog(
        data: data,
        assignments: available,
        current: current,
        initialWeekday: weekday,
        initialStartMinutes: startMinutes,
        fixedClassroomId: fixedClassroomId,
      ),
    );
    if (draft == null) return;
    final saved = model.saveBlock(draft, current: current);
    if (!saved && mounted) {
      await showAppErrorDialog(
        context,
        title: 'No se puede ubicar la clase',
        message: model.takeError() ?? 'Revise el rango seleccionado.',
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
    _PlannerPerspective.classroom => source,
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
                return Column(
                  children: [
                    _PlannerHeader(
                      data: data,
                      perspective: perspective,
                      resourceItems: _resourceItems(data),
                      selectedResourceId: selectedResourceId,
                      shift: shift,
                      dirty: state.dirty,
                      saving: state.saving,
                      desktop: desktop,
                      onPerspectiveChanged: (value) => setState(() {
                        perspective = value;
                        selectedResourceId = null;
                      }),
                      onResourceChanged: (value) =>
                          setState(() => selectedResourceId = value),
                      onShiftChanged: (value) => setState(() => shift = value),
                      onNewAssignment: _editAssignment,
                      onConfigure: _configureGeneral,
                      onSave: _save,
                    ),
                    if (state.loading || state.saving)
                      const LinearProgressIndicator(minHeight: 2),
                    if (state.error != null)
                      _InlineError(message: state.error!),
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
                                    onEdit: _editAssignment,
                                    onRemove: _removeAssignment,
                                  ),
                                ),
                                Expanded(
                                  child: _ScheduleMatrix(
                                    data: data,
                                    perspective: perspective,
                                    shift: shift,
                                    blocks: blocks,
                                    onEmptyCell: (day, minutes) => _editBlock(
                                      weekday: day,
                                      startMinutes: minutes,
                                    ),
                                    onEditBlock: (block) => _editBlock(
                                      current: block,
                                      weekday: block.weekday,
                                      startMinutes: block.startMinutes,
                                    ),
                                    onRemoveBlock: state.removeBlock,
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
                              ),
                              onRemove: state.removeBlock,
                              scheduledMinutes: state.scheduledMinutes,
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
          data.classrooms
              .map((item) => (item.id, '${item.code} · ${item.name}'))
              .toList(),
      };
}

class _PlannerHeader extends StatelessWidget {
  const _PlannerHeader({
    required this.data,
    required this.perspective,
    required this.resourceItems,
    required this.selectedResourceId,
    required this.shift,
    required this.dirty,
    required this.saving,
    required this.desktop,
    required this.onPerspectiveChanged,
    required this.onResourceChanged,
    required this.onShiftChanged,
    required this.onNewAssignment,
    required this.onConfigure,
    required this.onSave,
  });

  final SchedulePlannerData data;
  final _PlannerPerspective perspective;
  final List<(String, String)> resourceItems;
  final String? selectedResourceId;
  final _PlannerShift shift;
  final bool dirty;
  final bool saving;
  final bool desktop;
  final ValueChanged<_PlannerPerspective> onPerspectiveChanged;
  final ValueChanged<String?> onResourceChanged;
  final ValueChanged<_PlannerShift> onShiftChanged;
  final VoidCallback onNewAssignment;
  final VoidCallback onConfigure;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: EdgeInsets.fromLTRB(desktop ? 22 : 14, 14, desktop ? 22 : 14, 12),
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
                    'Planificador de horarios',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
            IconButton(
              tooltip: 'Configuración general',
              onPressed: saving ? null : onConfigure,
              icon: const Icon(LucideIcons.settings2, size: 19),
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed: dirty && !saving ? onSave : null,
              icon: const Icon(LucideIcons.save, size: 17),
              label: Text(desktop ? 'Guardar cambios' : 'Guardar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<_PlannerPerspective>(
              showSelectedIcon: false,
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
            ),
            SizedBox(
              width: desktop
                  ? 270
                  : math.min(330, MediaQuery.sizeOf(context).width - 28),
              child: DropdownButtonFormField<String>(
                key: ValueKey('$perspective-$selectedResourceId'),
                initialValue: selectedResourceId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: perspective.label.substring(
                    0,
                    perspective.label.length - 1,
                  ),
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
            ),
            SegmentedButton<_PlannerShift>(
              showSelectedIcon: false,
              segments: _PlannerShift.values
                  .map(
                    (item) => ButtonSegment(
                      value: item,
                      label: Text(
                        desktop
                            ? item.label
                            : item.name == 'morning'
                            ? 'Mañana'
                            : 'Tarde',
                      ),
                    ),
                  )
                  .toList(),
              selected: {shift},
              onSelectionChanged: (value) => onShiftChanged(value.first),
            ),
            OutlinedButton.icon(
              onPressed: saving ? null : onNewAssignment,
              icon: const Icon(LucideIcons.plus, size: 17),
              label: const Text('Asignación'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AssignmentRail extends StatelessWidget {
  const _AssignmentRail({
    required this.data,
    required this.model,
    required this.assignments,
    required this.onEdit,
    required this.onRemove,
  });

  final SchedulePlannerData data;
  final SchedulePlannerViewModel model;
  final List<AcademicAssignment> assignments;
  final ValueChanged<AcademicAssignment> onEdit;
  final ValueChanged<AcademicAssignment> onRemove;

  @override
  Widget build(BuildContext context) {
    final sorted = [...assignments]
      ..sort(
        (left, right) => model
            .remainingMinutes(right)
            .compareTo(model.remainingMinutes(left)),
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
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Carga semanal',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${assignments.where((item) => model.remainingMinutes(item) > 0).length} pendientes',
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
                        onEdit: () => onEdit(item),
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
    required this.onEdit,
    required this.onRemove,
  });

  final SchedulePlannerData data;
  final AcademicAssignment assignment;
  final int scheduled;
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
    final progress = scheduled / assignment.weeklyMinutes;
    final remaining = math.max(0, assignment.weeklyMinutes - scheduled);
    return InkWell(
      onTap: onEdit,
      child: Padding(
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
                PopupMenuButton<String>(
                  tooltip: 'Acciones de la asignación',
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onRemove(),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'remove', child: Text('Retirar')),
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
            LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 4,
              color: remaining == 0 ? AppColors.green : AppColors.navy,
              backgroundColor: AppColors.border,
            ),
            const SizedBox(height: 5),
            Text(
              remaining == 0
                  ? '${_durationLabel(scheduled)} completos'
                  : '${_durationLabel(scheduled)} de ${_durationLabel(assignment.weeklyMinutes)} · faltan ${_durationLabel(remaining)}',
              style: TextStyle(
                color: remaining == 0 ? AppColors.green : AppColors.inkMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleMatrix extends StatelessWidget {
  const _ScheduleMatrix({
    required this.data,
    required this.perspective,
    required this.shift,
    required this.blocks,
    required this.onEmptyCell,
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
  final void Function(int day, int minutes) onEmptyCell;
  final ValueChanged<PlannerScheduleBlock> onEditBlock;
  final ValueChanged<PlannerScheduleBlock> onRemoveBlock;

  @override
  Widget build(BuildContext context) {
    final start = math.max(data.config.startMinutes, shift.startMinutes);
    final end = math.min(data.config.endMinutes, shift.endMinutes);
    final slots = (end - start) ~/ data.config.intervalMinutes;
    return ColoredBox(
      color: AppColors.canvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.max(minWidth, constraints.maxWidth);
          final dayWidth = (width - timeWidth) / 5;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: width,
                height: headerHeight + slots * rowHeight,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: headerHeight,
                          child: Row(
                            children: [
                              const SizedBox(width: timeWidth),
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
                            data: data,
                            dayWidth: dayWidth,
                            minutes: start + slot * data.config.intervalMinutes,
                            onTap: onEmptyCell,
                          ),
                      ],
                    ),
                    for (final block in blocks.where(
                      (item) =>
                          item.startMinutes < end && item.endMinutes > start,
                    ))
                      Positioned(
                        left: timeWidth + (block.weekday - 1) * dayWidth + 4,
                        top:
                            headerHeight +
                            ((math.max(block.startMinutes, start) - start) /
                                    data.config.intervalMinutes) *
                                rowHeight +
                            3,
                        width: dayWidth - 8,
                        height: math.max(
                          35,
                          ((math.min(block.endMinutes, end) -
                                          math.max(block.startMinutes, start)) /
                                      data.config.intervalMinutes) *
                                  rowHeight -
                              6,
                        ),
                        child: _BlockCard(
                          data: data,
                          perspective: perspective,
                          block: block,
                          onTap: () => onEditBlock(block),
                          onRemove: () => onRemoveBlock(block),
                        ),
                      ),
                  ],
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
    required this.onTap,
  });

  final SchedulePlannerData data;
  final double dayWidth;
  final int minutes;
  final void Function(int day, int minutes) onTap;

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
              child: Material(
                color: recess == null ? AppColors.surface : AppColors.amberSoft,
                child: InkWell(
                  mouseCursor: recess == null
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.forbidden,
                  onTap: recess == null ? () => onTap(day, minutes) : null,
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
  final VoidCallback onTap;
  final VoidCallback onRemove;

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
      _PlannerPerspective.course => '${teacher.fullName} · ${classroom.code}',
      _PlannerPerspective.teacher => '${course.name} · ${classroom.code}',
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
            if (perspective == _PlannerPerspective.classroom)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  child: Text(
                    _initials(teacher.fullName),
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
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
            IconButton(
              tooltip: 'Retirar bloque',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 26, height: 28),
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
    required this.onDayChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.scheduledMinutes,
  });

  final SchedulePlannerData data;
  final _PlannerPerspective perspective;
  final _PlannerShift shift;
  final int selectedDay;
  final List<AcademicAssignment> assignments;
  final List<PlannerScheduleBlock> blocks;
  final ValueChanged<int> onDayChanged;
  final VoidCallback onAdd;
  final ValueChanged<PlannerScheduleBlock> onEdit;
  final ValueChanged<PlannerScheduleBlock> onRemove;
  final int Function(AcademicAssignment) scheduledMinutes;

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
              FilledButton.tonalIcon(
                onPressed: assignments.isEmpty ? null : onAdd,
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
                  onEdit: () => onEdit(block),
                  onRemove: () => onRemove(block),
                ),
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            'Carga semanal',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...assignments.map(
            (assignment) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _MobileAssignmentSummary(
                data: data,
                assignment: assignment,
                scheduled: scheduledMinutes(assignment),
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
  final VoidCallback onEdit;
  final VoidCallback onRemove;

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
          '${course.name} · ${teacher.fullName}\n${classroom.code} · ${classroom.name}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
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
  });
  final SchedulePlannerData data;
  final AcademicAssignment assignment;
  final int scheduled;

  @override
  Widget build(BuildContext context) {
    final subject = data.subjects.firstWhere(
      (item) => item.id == assignment.subjectId,
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
          Expanded(child: Text(subject.name, overflow: TextOverflow.ellipsis)),
          Text(
            '${_durationLabel(scheduled)} / ${_durationLabel(assignment.weeklyMinutes)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AssignmentDialog extends StatefulWidget {
  const _AssignmentDialog({
    required this.data,
    this.current,
    this.initialCourseId,
    this.initialTeacherId,
  });
  final SchedulePlannerData data;
  final AcademicAssignment? current;
  final String? initialCourseId;
  final String? initialTeacherId;

  @override
  State<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  late String? courseId =
      widget.current?.courseId ??
      widget.initialCourseId ??
      widget.data.courses.firstOrNull?.id;
  late String? subjectId =
      widget.current?.subjectId ?? widget.data.subjects.firstOrNull?.id;
  late String? teacherId =
      widget.current?.teacherId ??
      widget.initialTeacherId ??
      widget.data.teachers.firstOrNull?.id;
  late int weeklyMinutes = widget.current?.weeklyMinutes ?? 120;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: AppDialogHeader(
      title: widget.current == null ? 'Nueva asignación' : 'Editar asignación',
    ),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SelectField(
              label: 'Curso',
              value: courseId,
              items: widget.data.courses
                  .map((item) => (item.id, item.name))
                  .toList(),
              onChanged: (value) => setState(() => courseId = value),
            ),
            const SizedBox(height: 12),
            _SelectField(
              label: 'Materia',
              value: subjectId,
              items: widget.data.subjects
                  .map((item) => (item.id, '${item.code} · ${item.name}'))
                  .toList(),
              onChanged: (value) => setState(() => subjectId = value),
            ),
            const SizedBox(height: 12),
            _SelectField(
              label: 'Docente',
              value: teacherId,
              items: widget.data.teachers
                  .map((item) => (item.id, item.fullName))
                  .toList(),
              onChanged: (value) => setState(() => teacherId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: weeklyMinutes,
              decoration: const InputDecoration(labelText: 'Carga semanal'),
              items: [
                for (var minutes = 30; minutes <= 600; minutes += 30)
                  DropdownMenuItem(
                    value: minutes,
                    child: Text(_durationLabel(minutes)),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => weeklyMinutes = value ?? weeklyMinutes),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: courseId == null || subjectId == null || teacherId == null
            ? null
            : () => Navigator.pop(
                context,
                AcademicAssignment(
                  id: widget.current?.id,
                  courseId: courseId!,
                  subjectId: subjectId!,
                  teacherId: teacherId!,
                  weeklyMinutes: weeklyMinutes,
                ),
              ),
        icon: const Icon(LucideIcons.check, size: 16),
        label: const Text('Aceptar'),
      ),
    ],
  );
}

class _BlockDialog extends StatefulWidget {
  const _BlockDialog({
    required this.data,
    required this.assignments,
    required this.initialWeekday,
    required this.initialStartMinutes,
    this.current,
    this.fixedClassroomId,
  });
  final SchedulePlannerData data;
  final List<AcademicAssignment> assignments;
  final PlannerScheduleBlock? current;
  final int initialWeekday;
  final int initialStartMinutes;
  final String? fixedClassroomId;

  @override
  State<_BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends State<_BlockDialog> {
  late AcademicAssignment assignment = widget.current == null
      ? widget.assignments.first
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
      math.min(widget.initialStartMinutes + 30, widget.data.config.endMinutes);

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
    return AlertDialog(
      title: AppDialogHeader(
        title: widget.current == null ? 'Ubicar clase' : 'Editar bloque',
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<AcademicAssignment>(
                initialValue: assignment,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Asignación académica',
                ),
                items: widget.assignments
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          _assignmentLabel(widget.data, item),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => assignment = value ?? assignment),
              ),
              const SizedBox(height: 12),
              _SelectField(
                label: 'Aula',
                value: classroomId,
                enabled: widget.fixedClassroomId == null,
                items: widget.data.classrooms
                    .map((item) => (item.id, '${item.code} · ${item.name}'))
                    .toList(),
                onChanged: (value) =>
                    setState(() => classroomId = value ?? classroomId),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: weekday,
                decoration: const InputDecoration(labelText: 'Día'),
                items: [
                  for (var day = 1; day <= 5; day += 1)
                    DropdownMenuItem(
                      value: day,
                      child: Text(weekdayLabels[day]!),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => weekday = value ?? weekday),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: startMinutes,
                      decoration: const InputDecoration(labelText: 'Desde'),
                      items: slots
                          .where((item) => item < widget.data.config.endMinutes)
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(scheduleMinutesToTime(item)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        startMinutes = value ?? startMinutes;
                        if (endMinutes <= startMinutes) {
                          endMinutes = math.min(
                            startMinutes + widget.data.config.intervalMinutes,
                            widget.data.config.endMinutes,
                          );
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('$startMinutes-$endMinutes'),
                      initialValue: endMinutes,
                      decoration: const InputDecoration(labelText: 'Hasta'),
                      items: slots
                          .where((item) => item > startMinutes)
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(scheduleMinutesToTime(item)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => endMinutes = value ?? endMinutes),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(
            context,
            PlannerBlockDraft(
              assignment: assignment,
              classroomId: classroomId,
              weekday: weekday,
              startMinutes: startMinutes,
              endMinutes: endMinutes,
            ),
          ),
          icon: const Icon(LucideIcons.check, size: 16),
          label: const Text('Aceptar'),
        ),
      ],
    );
  }
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
    return AlertDialog(
      title: const AppDialogHeader(title: 'Configuración general'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jornada',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Desde',
                      value: startMinutes,
                      options: options
                          .where((item) => item < endMinutes)
                          .toList(),
                      onChanged: (value) =>
                          setState(() => startMinutes = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeField(
                      label: 'Hasta',
                      value: endMinutes,
                      options: options
                          .where((item) => item > startMinutes)
                          .toList(),
                      onChanged: (value) => setState(() => endMinutes = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tolerancia de atraso',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '$tolerance min',
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
              const Divider(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recreos generales',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Agregar recreo',
                    onPressed: () => setState(
                      () => breaks.add(
                        _BreakInput(
                          name: 'RECREO',
                          startMinutes: 10 * 60,
                          endMinutes: 10 * 60 + 30,
                        ),
                      ),
                    ),
                    icon: const Icon(LucideIcons.plus, size: 18),
                  ),
                ],
              ),
              ...breaks.indexed.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BreakEditor(
                    value: entry.$2,
                    options: options,
                    onChanged: (value) =>
                        setState(() => breaks[entry.$1] = value),
                    onRemove: () => setState(() => breaks.removeAt(entry.$1)),
                  ),
                ),
              ),
              if (validation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    validation!,
                    style: const TextStyle(color: AppColors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(LucideIcons.save, size: 16),
          label: const Text('Guardar'),
        ),
      ],
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
    required this.value,
    required this.options,
    required this.onChanged,
    required this.onRemove,
  });
  final _BreakInput value;
  final List<int> options;
  final ValueChanged<_BreakInput> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 500;
      final name = TextFormField(
        initialValue: value.name,
        decoration: const InputDecoration(labelText: 'Nombre'),
        onChanged: (text) => onChanged(value.copyWith(name: text)),
      );
      final times = Row(
        children: [
          Expanded(
            child: _TimeField(
              label: 'Desde',
              value: value.startMinutes,
              options: options
                  .where((item) => item < value.endMinutes)
                  .toList(),
              onChanged: (item) =>
                  onChanged(value.copyWith(startMinutes: item)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TimeField(
              label: 'Hasta',
              value: value.endMinutes,
              options: options
                  .where((item) => item > value.startMinutes)
                  .toList(),
              onChanged: (item) => onChanged(value.copyWith(endMinutes: item)),
            ),
          ),
          IconButton(
            tooltip: 'Retirar recreo',
            onPressed: onRemove,
            icon: const Icon(LucideIcons.trash2, size: 17),
          ),
        ],
      );
      return compact
          ? Column(children: [name, const SizedBox(height: 8), times])
          : Row(
              children: [
                Expanded(flex: 3, child: name),
                const SizedBox(width: 8),
                Expanded(flex: 5, child: times),
              ],
            );
    },
  );
}

class _SelectField extends StatelessWidget {
  const _SelectField({
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

String _assignmentLabel(
  SchedulePlannerData data,
  AcademicAssignment assignment,
) {
  final course = data.courses.firstWhere(
    (item) => item.id == assignment.courseId,
  );
  final subject = data.subjects.firstWhere(
    (item) => item.id == assignment.subjectId,
  );
  final teacher = data.teachers.firstWhere(
    (item) => item.id == assignment.teacherId,
  );
  return '${course.name} · ${subject.name} · ${teacher.fullName}';
}

String _durationLabel(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '$rest min';
  if (rest == 0) return '$hours h';
  return '$hours h $rest min';
}

String _initials(String value) {
  final words = value.trim().split(RegExp(r'\s+'));
  if (words.isEmpty) return '';
  return words.take(2).map((item) => item[0].toUpperCase()).join();
}
