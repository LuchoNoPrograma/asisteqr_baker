import 'dart:math' as math;

import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/app_dialog_header.dart';
import 'package:asisteqr_baker/core/widgets/app_feedback.dart';
import 'package:asisteqr_baker/features/people/presentation/person_photo_field.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_models.dart';
import 'package:asisteqr_baker/features/schedules/presentation/teacher_schedule_editor_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TeacherScheduleEditorPage extends ConsumerStatefulWidget {
  const TeacherScheduleEditorPage({super.key, required this.teacherId});

  final String teacherId;

  @override
  ConsumerState<TeacherScheduleEditorPage> createState() =>
      _TeacherScheduleEditorPageState();
}

class _TeacherScheduleEditorPageState
    extends ConsumerState<TeacherScheduleEditorPage> {
  int mobileDay = DateTime.monday;

  TeacherScheduleEditorViewModel get model =>
      ref.read(teacherScheduleEditorViewModelProvider(widget.teacherId));

  Future<void> _save() async {
    final saved = await model.save();
    if (!mounted) return;
    if (saved) {
      showAppSuccess(context, 'Horario del docente guardado.');
    } else {
      await showAppErrorDialog(
        context,
        title: 'No se pudo guardar el horario',
        message:
            model.takeError() ?? 'Revise los bloques e intente nuevamente.',
      );
    }
  }

  Future<void> _configure() async {
    final current = model.data;
    if (current == null) return;
    final draft = await showDialog<GeneralScheduleDraft>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _GeneralConfigDialog(data: current),
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
        message: model.takeError() ?? 'Intenta nuevamente.',
      );
    }
  }

  Future<void> _addMobileBlock() async {
    final current = model.data;
    if (current == null) return;
    final draft = await showDialog<_ClassBlockDraft>(
      context: context,
      builder: (context) => _ClassBlockDialog(
        data: current,
        weekday: mobileDay,
        startMinutes: current.config.startMinutes,
        endMinutes: current.config.startMinutes + 30,
        initialCourseId: model.selectedCourseId,
        initialSubjectId: model.selectedSubjectId,
        initialClassroomId: model.selectedClassroomId,
      ),
    );
    if (draft == null) return;
    model
      ..selectCourse(draft.courseId)
      ..selectSubject(draft.subjectId)
      ..selectClassroom(draft.classroomId);
    final added = model.addRange(
      weekday: mobileDay,
      startMinutes: draft.startMinutes,
      endMinutes: draft.endMinutes,
    );
    if (!added && mounted) {
      await showAppErrorDialog(
        context,
        title: 'No se puede agregar la clase',
        message: model.takeError() ?? 'Seleccione curso, materia y aula.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      teacherScheduleEditorViewModelProvider(widget.teacherId),
    );
    return AdaptiveShell(
      location: '/docentes',
      title: 'Horario docente',
      child: state.loading && state.data == null
          ? const Center(child: CircularProgressIndicator())
          : state.data == null
          ? _LoadError(message: state.error, onRetry: state.load)
          : LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 840;
                return Column(
                  children: [
                    _TeacherHeader(
                      data: state.data!,
                      desktop: desktop,
                      onBack: () => context.go('/docentes'),
                      onConfigure: _configure,
                    ),
                    if (state.loading || state.saving)
                      const LinearProgressIndicator(minHeight: 2),
                    _EditorToolbar(model: state, desktop: desktop),
                    if (state.error != null)
                      Container(
                        width: double.infinity,
                        color: AppColors.redSoft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: AppColors.red),
                        ),
                      ),
                    Expanded(
                      child: desktop
                          ? _ScheduleMatrix(model: state)
                          : _MobileDaySchedule(
                              model: state,
                              selectedDay: mobileDay,
                              onDayChanged: (value) =>
                                  setState(() => mobileDay = value),
                              onAdd: _addMobileBlock,
                            ),
                    ),
                    _SaveBar(model: state, onSave: _save),
                  ],
                );
              },
            ),
    );
  }
}

class _TeacherHeader extends StatelessWidget {
  const _TeacherHeader({
    required this.data,
    required this.desktop,
    required this.onBack,
    required this.onConfigure,
  });

  final TeacherScheduleEditorData data;
  final bool desktop;
  final VoidCallback onBack;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final teacher = data.teacher;
    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          desktop ? 24 : 12,
          desktop ? 18 : 10,
          desktop ? 24 : 12,
          12,
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Volver a docentes',
              onPressed: onBack,
              icon: const Icon(LucideIcons.arrowLeft, size: 20),
            ),
            PersonAvatar(
              photoUrl: teacher.photoUrl,
              fallback: teacher.fullName.characters.first,
              size: desktop ? 48 : 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${teacher.specialty} · DOC-${teacher.code.toString().padLeft(3, '0')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${data.period.name} ${data.period.year} · ${data.config.startTime}–${data.config.endTime}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Configurar jornada, recreos y tolerancia',
              onPressed: onConfigure,
              icon: const Icon(LucideIcons.settings2, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({required this.model, required this.desktop});

  final TeacherScheduleEditorViewModel model;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final data = model.data!;
    final controls = <Widget>[
      IconButton.outlined(
        tooltip: 'Deshacer',
        onPressed: model.canUndo ? model.undo : null,
        icon: const Icon(LucideIcons.undo2, size: 18),
      ),
      IconButton.outlined(
        tooltip: 'Rehacer',
        onPressed: model.canRedo ? model.redo : null,
        icon: const Icon(LucideIcons.redo2, size: 18),
      ),
      _InfoPill(
        icon: LucideIcons.coffee,
        text: data.breaks.isEmpty
            ? 'Sin recreo'
            : data.breaks
                  .map((item) => '${item.startTime}–${item.endTime}')
                  .join(', '),
      ),
      _InfoPill(
        icon: LucideIcons.timer,
        text: '${data.config.toleranceMinutes} min de tolerancia',
      ),
    ];
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.border),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: desktop ? 24 : 7, vertical: 8),
      child: desktop
          ? Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: controls,
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final control in controls)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: control,
                    ),
                ],
              ),
            ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppColors.inkMuted),
      const SizedBox(width: 5),
      Text(text, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _ScheduleMatrix extends StatefulWidget {
  const _ScheduleMatrix({required this.model});

  final TeacherScheduleEditorViewModel model;

  @override
  State<_ScheduleMatrix> createState() => _ScheduleMatrixState();
}

class _ScheduleMatrixState extends State<_ScheduleMatrix> {
  static const rowHeight = 32.0;
  int? dragDay;
  int? dragStart;
  int? dragEnd;

  Future<void> _openClassDialog({
    required int weekday,
    required int startMinutes,
    required int endMinutes,
  }) async {
    final data = widget.model.data;
    if (data == null) return;
    final draft = await showDialog<_ClassBlockDraft>(
      context: context,
      builder: (context) => _ClassBlockDialog(
        data: data,
        weekday: weekday,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        initialCourseId: widget.model.selectedCourseId,
        initialSubjectId: widget.model.selectedSubjectId,
        initialClassroomId: widget.model.selectedClassroomId,
      ),
    );
    if (draft == null || !mounted) return;
    widget.model
      ..selectCourse(draft.courseId)
      ..selectSubject(draft.subjectId)
      ..selectClassroom(draft.classroomId);
    final added = widget.model.addRange(
      weekday: weekday,
      startMinutes: draft.startMinutes,
      endMinutes: draft.endMinutes,
    );
    if (!added && mounted) {
      await showAppErrorDialog(
        context,
        title: 'No se puede agregar la clase',
        message: widget.model.takeError() ?? 'Revise el horario seleccionado.',
      );
    }
  }

  void _clearSelection() {
    if (!mounted) return;
    setState(() {
      dragDay = null;
      dragStart = null;
      dragEnd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.model.data!;
    final config = data.config;
    final rows = (config.endMinutes - config.startMinutes) ~/ 30;
    const gutterWidth = 76.0;
    const dayWidth = 184.0;
    const matrixWidth = gutterWidth + dayWidth * 5;
    final bodyHeight = rows * rowHeight;
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: SizedBox(
          width: matrixWidth,
          child: Column(
            children: [
              SizedBox(
                height: 42,
                child: Row(
                  children: [
                    const SizedBox(width: gutterWidth),
                    for (var day = 1; day <= 5; day += 1)
                      Container(
                        width: dayWidth,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          border: Border.all(color: AppColors.navyDark),
                        ),
                        child: Text(
                          weekdayLabels[day]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: bodyHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: gutterWidth,
                          child: Column(
                            children: [
                              for (var row = 0; row < rows; row += 1)
                                Container(
                                  height: rowHeight,
                                  alignment: Alignment.topCenter,
                                  padding: const EdgeInsets.only(top: 5),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: AppColors.border,
                                      ),
                                      bottom: BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    scheduleMinutesToTime(
                                      config.startMinutes + row * 30,
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        for (var day = 1; day <= 5; day += 1)
                          _DayColumn(
                            width: dayWidth,
                            height: bodyHeight,
                            rowHeight: rowHeight,
                            day: day,
                            rows: rows,
                            data: data,
                            blocks: widget.model.blocks
                                .where((item) => item.weekday == day)
                                .toList(),
                            selectedStart: dragDay == day ? dragStart : null,
                            selectedEnd: dragDay == day ? dragEnd : null,
                            onTapCell: (row) {
                              final startMinutes =
                                  config.startMinutes + row * 30;
                              final endMinutes = startMinutes + 30;
                              final occupied =
                                  data.breaks.any(
                                    (item) => item.includesRange(
                                      startMinutes,
                                      endMinutes,
                                    ),
                                  ) ||
                                  widget.model.blocks.any(
                                    (item) =>
                                        item.weekday == day &&
                                        startMinutes < item.endMinutes &&
                                        endMinutes > item.startMinutes,
                                  );
                              if (!occupied) {
                                _openClassDialog(
                                  weekday: day,
                                  startMinutes: startMinutes,
                                  endMinutes: endMinutes,
                                );
                              }
                            },
                            onDragStart: (row) => setState(() {
                              dragDay = day;
                              dragStart = row;
                              dragEnd = row;
                            }),
                            onDragUpdate: (row) =>
                                setState(() => dragEnd = row),
                            onDragEnd: () {
                              if (dragStart == null || dragEnd == null) return;
                              final startRow = math.min(dragStart!, dragEnd!);
                              final endRow = math.max(dragStart!, dragEnd!) + 1;
                              final startMinutes =
                                  config.startMinutes + startRow * 30;
                              final endMinutes =
                                  config.startMinutes + endRow * 30;
                              _clearSelection();
                              _openClassDialog(
                                weekday: day,
                                startMinutes: startMinutes,
                                endMinutes: endMinutes,
                              );
                            },
                            onDragCancel: _clearSelection,
                            onRemove: widget.model.removeBlock,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.width,
    required this.height,
    required this.rowHeight,
    required this.day,
    required this.rows,
    required this.data,
    required this.blocks,
    required this.onTapCell,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    required this.onRemove,
    this.selectedStart,
    this.selectedEnd,
  });

  final double width;
  final double height;
  final double rowHeight;
  final int day;
  final int rows;
  final TeacherScheduleEditorData data;
  final List<TeacherScheduleBlock> blocks;
  final int? selectedStart;
  final int? selectedEnd;
  final ValueChanged<int> onTapCell;
  final ValueChanged<int> onDragStart;
  final ValueChanged<int> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onDragCancel;
  final ValueChanged<String> onRemove;

  int _row(double y) => (y / rowHeight).floor().clamp(0, rows - 1);

  @override
  Widget build(BuildContext context) {
    final config = data.config;
    final startSelection = selectedStart == null || selectedEnd == null
        ? null
        : math.min(selectedStart!, selectedEnd!);
    final endSelection = selectedStart == null || selectedEnd == null
        ? null
        : math.max(selectedStart!, selectedEnd!);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => onTapCell(_row(details.localPosition.dy)),
      onPanStart: (details) => onDragStart(_row(details.localPosition.dy)),
      onPanUpdate: (details) => onDragUpdate(_row(details.localPosition.dy)),
      onPanEnd: (_) => onDragEnd(),
      onPanCancel: onDragCancel,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Column(
              children: [
                for (var row = 0; row < rows; row += 1)
                  Container(
                    height: rowHeight,
                    decoration: BoxDecoration(
                      color: row.isEven ? Colors.white : AppColors.canvas,
                      border: const Border(
                        right: BorderSide(color: AppColors.border),
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
              ],
            ),
            for (final recess in data.breaks)
              Positioned(
                top:
                    (scheduleTimeToMinutes(recess.startTime) -
                        config.startMinutes) /
                    30 *
                    rowHeight,
                left: 0,
                right: 0,
                height:
                    (scheduleTimeToMinutes(recess.endTime) -
                        scheduleTimeToMinutes(recess.startTime)) /
                    30 *
                    rowHeight,
                child: Container(
                  alignment: Alignment.center,
                  color: AppColors.amberSoft.withValues(alpha: .82),
                  child: Text(
                    recess.name,
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (startSelection != null)
              Positioned(
                top: startSelection * rowHeight,
                left: 3,
                right: 3,
                height: (endSelection! - startSelection + 1) * rowHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft.withValues(alpha: .8),
                    border: Border.all(color: AppColors.green, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            for (final block in blocks)
              Positioned(
                top:
                    (block.startMinutes - config.startMinutes) /
                        30 *
                        rowHeight +
                    2,
                left: 4,
                right: 4,
                height:
                    (block.endMinutes - block.startMinutes) / 30 * rowHeight -
                    4,
                child: _BlockTile(block: block, onRemove: onRemove),
              ),
          ],
        ),
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({required this.block, required this.onRemove});
  final TeacherScheduleBlock block;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxHeight < 44;
      final detailed = constraints.maxHeight >= 76;
      return Material(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          onLongPress: () => onRemove(block.id),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 2, 4),
            decoration: BoxDecoration(
              border: const Border(
                left: BorderSide(color: AppColors.navy, width: 4),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 2),
                        Text(
                          detailed
                              ? block.courseName
                              : '${block.startTime}–${block.endTime} · ${block.classroomName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.1,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                      if (detailed) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${block.classroomName} · ${block.startTime}–${block.endTime}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.1,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar bloque',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 22,
                    height: 22,
                  ),
                  onPressed: () => onRemove(block.id),
                  icon: const Icon(LucideIcons.x, size: 14),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _MobileDaySchedule extends StatelessWidget {
  const _MobileDaySchedule({
    required this.model,
    required this.selectedDay,
    required this.onDayChanged,
    required this.onAdd,
  });
  final TeacherScheduleEditorViewModel model;
  final int selectedDay;
  final ValueChanged<int> onDayChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final blocks = model.blocks
        .where((item) => item.weekday == selectedDay)
        .toList();
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: SegmentedButton<int>(
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
        Expanded(
          child: blocks.isEmpty
              ? Center(
                  child: Text(
                    'Sin clases el ${weekdayLabels[selectedDay]!.toLowerCase()}.',
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 90),
                  itemCount: blocks.length,
                  itemBuilder: (context, index) {
                    final block = blocks[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 88,
                            child: Text(
                              '${block.startTime}\n${block.endTime}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  block.subjectName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${block.courseName} · ${block.classroomName}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Quitar bloque',
                            onPressed: () => model.removeBlock(block.id),
                            icon: const Icon(LucideIcons.trash2, size: 18),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: model.canCreateBlock ? onAdd : null,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Agregar clase'),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.model, required this.onSave});
  final TeacherScheduleEditorViewModel model;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(
            child: Text(
              model.dirty
                  ? '${model.blocks.length} bloques · Cambios sin guardar'
                  : '${model.blocks.length} bloques · Todo guardado',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (constraints.maxWidth < 350)
            IconButton.filled(
              tooltip: 'Guardar horario',
              onPressed: model.dirty && !model.saving ? onSave : null,
              icon: const Icon(LucideIcons.save, size: 18),
            )
          else
            FilledButton.icon(
              onPressed: model.dirty && !model.saving ? onSave : null,
              icon: const Icon(LucideIcons.save, size: 18),
              label: const Text('Guardar'),
            ),
        ],
      ),
    ),
  );
}

class _GeneralConfigDialog extends StatefulWidget {
  const _GeneralConfigDialog({required this.data});
  final TeacherScheduleEditorData data;

  @override
  State<_GeneralConfigDialog> createState() => _GeneralConfigDialogState();
}

class _GeneralConfigDialogState extends State<_GeneralConfigDialog> {
  late String start;
  late String end;
  late double tolerance;
  late List<_BreakDraft> breaks;

  List<String> get times => [
    for (var value = 6 * 60; value <= 20 * 60; value += 30)
      scheduleMinutesToTime(value),
  ];

  @override
  void initState() {
    super.initState();
    start = widget.data.config.startTime;
    end = widget.data.config.endTime;
    tolerance = widget.data.config.toleranceMinutes.toDouble();
    breaks = widget.data.breaks
        .map(
          (item) => _BreakDraft(
            id: item.id,
            name: item.name,
            start: item.startTime,
            end: item.endTime,
          ),
        )
        .toList();
  }

  void _submit() {
    final startMinutes = scheduleTimeToMinutes(start);
    final endMinutes = scheduleTimeToMinutes(end);
    final valid =
        endMinutes > startMinutes &&
        breaks.every((item) {
          final breakStart = scheduleTimeToMinutes(item.start);
          final breakEnd = scheduleTimeToMinutes(item.end);
          return item.name.trim().length >= 2 &&
              breakStart >= startMinutes &&
              breakEnd <= endMinutes &&
              breakEnd > breakStart;
        });
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revise el rango de jornada y recreos.')),
      );
      return;
    }
    Navigator.pop(
      context,
      GeneralScheduleDraft(
        periodId: widget.data.period.id,
        version: widget.data.config.version,
        startTime: start,
        endTime: end,
        toleranceMinutes: tolerance.round(),
        breaks: breaks
            .map(
              (item) => ScheduleBreak(
                id: item.id,
                name: item.name.trim(),
                startTime: item.start,
                endTime: item.end,
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    title: const AppDialogHeader(title: 'Configuración general'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
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
                  child: _TimeSelect(
                    label: 'Desde',
                    value: start,
                    times: times,
                    onChanged: (value) => setState(() => start = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeSelect(
                    label: 'Hasta',
                    value: end,
                    times: times,
                    onChanged: (value) => setState(() => end = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tolerancia de atraso',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text('${tolerance.round()} min'),
              ],
            ),
            Slider(
              value: tolerance,
              min: 0,
              max: 30,
              divisions: 6,
              label: '${tolerance.round()} min',
              onChanged: (value) => setState(() => tolerance = value),
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
                  onPressed: breaks.length >= 8
                      ? null
                      : () => setState(
                          () => breaks.add(
                            _BreakDraft(
                              name: 'RECREO',
                              start: '10:00',
                              end: '10:30',
                            ),
                          ),
                        ),
                  icon: const Icon(LucideIcons.plus, size: 18),
                ),
              ],
            ),
            for (var index = 0; index < breaks.length; index += 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 170,
                      child: TextFormField(
                        initialValue: breaks[index].name,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          isDense: true,
                        ),
                        onChanged: (value) => breaks[index].name = value,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: _TimeSelect(
                        label: 'Desde',
                        value: breaks[index].start,
                        times: times,
                        onChanged: (value) =>
                            setState(() => breaks[index].start = value),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: _TimeSelect(
                        label: 'Hasta',
                        value: breaks[index].end,
                        times: times,
                        onChanged: (value) =>
                            setState(() => breaks[index].end = value),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Quitar recreo',
                      onPressed: () => setState(() => breaks.removeAt(index)),
                      icon: const Icon(LucideIcons.trash2, size: 17),
                    ),
                  ],
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
        icon: const Icon(LucideIcons.save, size: 17),
        label: const Text('Guardar'),
      ),
    ],
  );
}

class _BreakDraft {
  _BreakDraft({
    this.id,
    required this.name,
    required this.start,
    required this.end,
  });
  final String? id;
  String name;
  String start;
  String end;
}

class _TimeSelect extends StatelessWidget {
  const _TimeSelect({
    required this.label,
    required this.value,
    required this.times,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> times;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label, isDense: true),
    items: times
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(),
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
}

class _ClassBlockDraft {
  const _ClassBlockDraft({
    required this.startMinutes,
    required this.endMinutes,
    required this.courseId,
    required this.subjectId,
    required this.classroomId,
  });

  final int startMinutes;
  final int endMinutes;
  final String courseId;
  final String subjectId;
  final String classroomId;
}

class _ClassBlockDialog extends StatefulWidget {
  const _ClassBlockDialog({
    required this.data,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    this.initialCourseId,
    this.initialSubjectId,
    this.initialClassroomId,
  });

  final TeacherScheduleEditorData data;
  final int weekday;
  final int startMinutes;
  final int endMinutes;
  final String? initialCourseId;
  final String? initialSubjectId;
  final String? initialClassroomId;

  @override
  State<_ClassBlockDialog> createState() => _ClassBlockDialogState();
}

class _ClassBlockDialogState extends State<_ClassBlockDialog> {
  late String start;
  late String end;
  late String? courseId;
  late String? subjectId;
  late String? classroomId;

  @override
  void initState() {
    super.initState();
    final config = widget.data.config;
    start = scheduleMinutesToTime(widget.startMinutes);
    end = scheduleMinutesToTime(math.min(widget.endMinutes, config.endMinutes));
    courseId = _validId(
      widget.initialCourseId,
      widget.data.courses.map((item) => item.id),
    );
    subjectId = _validId(
      widget.initialSubjectId,
      widget.data.subjects.map((item) => item.id),
    );
    classroomId = _validId(
      widget.initialClassroomId,
      widget.data.classrooms.map((item) => item.id),
    );
    courseId ??= widget.data.courses.firstOrNull?.id;
    subjectId ??= widget.data.subjects.firstOrNull?.id;
    classroomId ??= widget.data.classrooms.firstOrNull?.id;
  }

  String? _validId(String? value, Iterable<String> ids) =>
      value != null && ids.contains(value) ? value : null;

  List<String> get times => [
    for (
      var value = widget.data.config.startMinutes;
      value <= widget.data.config.endMinutes;
      value += 30
    )
      scheduleMinutesToTime(value),
  ];

  bool get canSubmit =>
      courseId != null &&
      subjectId != null &&
      classroomId != null &&
      scheduleTimeToMinutes(end) > scheduleTimeToMinutes(start);

  void _submit() {
    if (!canSubmit) return;
    Navigator.pop(
      context,
      _ClassBlockDraft(
        startMinutes: scheduleTimeToMinutes(start),
        endMinutes: scheduleTimeToMinutes(end),
        courseId: courseId!,
        subjectId: subjectId!,
        classroomId: classroomId!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    title: const AppDialogHeader(title: 'Nueva clase'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.calendarDays,
                  size: 17,
                  color: AppColors.navy,
                ),
                const SizedBox(width: 7),
                Text(
                  weekdayLabels[widget.weekday]!,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimeSelect(
                    label: 'Desde',
                    value: start,
                    times: times,
                    onChanged: (value) => setState(() => start = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeSelect(
                    label: 'Hasta',
                    value: end,
                    times: times,
                    onChanged: (value) => setState(() => end = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _CatalogSelect(
              label: 'Curso',
              value: courseId,
              items: widget.data.courses
                  .map((item) => (item.id, item.name))
                  .toList(),
              onChanged: (value) => setState(() => courseId = value),
            ),
            const SizedBox(height: 14),
            _CatalogSelect(
              label: 'Materia',
              value: subjectId,
              items: widget.data.subjects
                  .map((item) => (item.id, item.name))
                  .toList(),
              onChanged: (value) => setState(() => subjectId = value),
            ),
            const SizedBox(height: 14),
            _CatalogSelect(
              label: 'Aula',
              value: classroomId,
              items: widget.data.classrooms
                  .map((item) => (item.id, '${item.code} · ${item.name}'))
                  .toList(),
              onChanged: (value) => setState(() => classroomId = value),
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
        onPressed: canSubmit ? _submit : null,
        icon: const Icon(LucideIcons.plus, size: 17),
        label: const Text('Agregar'),
      ),
    ],
  );
}

class _CatalogSelect extends StatelessWidget {
  const _CatalogSelect({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<(String, String)> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: items.any((item) => item.$1 == value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: label, isDense: true),
    items: items
        .map(
          (item) => DropdownMenuItem(
            value: item.$1,
            child: Text(item.$2, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: items.isEmpty ? null : onChanged,
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
          const Icon(LucideIcons.calendarX2, size: 42, color: AppColors.red),
          const SizedBox(height: 12),
          Text(
            message ?? 'No se pudo cargar el horario.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 17),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
