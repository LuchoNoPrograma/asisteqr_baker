import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/app_data_table.dart';
import 'package:asisteqr_baker/core/widgets/app_dialog_header.dart';
import 'package:asisteqr_baker/core/widgets/app_feedback.dart';
import 'package:asisteqr_baker/features/courses/domain/course_models.dart';
import 'package:asisteqr_baker/features/people/domain/people_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TeachingSchedulesPage extends ConsumerWidget {
  const TeachingSchedulesPage({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    TeachingSchedule? schedule,
  ]) async {
    final model = ref.read(teachingSchedulesViewModelProvider);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _TeachingScheduleDialog(
        current: schedule,
        teachers: model.teachers,
        courses: model.courses,
        onSave: (draft) => model.save(draft, current: schedule),
        errorMessage: model.takeError,
      ),
    );
    if (saved == true && context.mounted) {
      showAppSuccess(
        context,
        schedule == null
            ? 'Horario registrado correctamente.'
            : 'Horario actualizado correctamente.',
      );
    }
  }

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    TeachingSchedule schedule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppDialogHeader(title: 'Retirar horario'),
        content: Text(
          'Se retirará ${schedule.subject} del ${schedule.weekdayLabel} '
          'para ${schedule.courseName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            icon: const Icon(LucideIcons.calendarX2, size: 17),
            label: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final model = ref.read(teachingSchedulesViewModelProvider);
    final removed = await model.deactivate(schedule);
    if (!context.mounted) return;
    if (removed) {
      showAppSuccess(context, 'Horario retirado correctamente.');
    } else {
      await showAppErrorDialog(
        context,
        title: 'No se pudo retirar el horario',
        message: model.takeError() ?? 'Intenta nuevamente.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(teachingSchedulesViewModelProvider);
    final canManage = ref.watch(
      sessionViewModelProvider.select(
        (session) => session.user?.isAdministrator == true,
      ),
    );
    return AdaptiveShell(
      location: '/horarios',
      title: 'Horarios',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 28 : 14,
                  wide ? 24 : 14,
                  wide ? 28 : 14,
                  14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Horarios docentes',
                            style: wide
                                ? Theme.of(context).textTheme.headlineMedium
                                : Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${model.schedules.length} clases programadas',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (canManage)
                      ElevatedButton.icon(
                        onPressed:
                            model.saving ||
                                model.teachers.isEmpty ||
                                model.courses.isEmpty
                            ? null
                            : () => _edit(context, ref),
                        icon: const Icon(LucideIcons.calendarPlus, size: 18),
                        label: Text(wide ? 'Nuevo horario' : 'Nuevo'),
                      ),
                  ],
                ),
              ),
              if (model.loading) const LinearProgressIndicator(minHeight: 2),
              if (model.error != null)
                MaterialBanner(
                  backgroundColor: AppColors.redSoft,
                  leading: const Icon(
                    LucideIcons.circleAlert,
                    color: AppColors.red,
                  ),
                  content: Text(model.error!),
                  actions: [
                    IconButton(
                      tooltip: 'Reintentar',
                      onPressed: model.load,
                      icon: const Icon(LucideIcons.refreshCw),
                    ),
                  ],
                ),
              Expanded(
                child: model.schedules.isEmpty && !model.loading
                    ? const _EmptySchedules()
                    : wide
                    ? _TeachingSchedulesTable(
                        schedules: model.schedules,
                        canManage: canManage,
                        onEdit: (schedule) => _edit(context, ref, schedule),
                        onDeactivate: (schedule) =>
                            _deactivate(context, ref, schedule),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                        itemCount: model.schedules.length,
                        itemBuilder: (context, index) {
                          final schedule = model.schedules[index];
                          return _TeachingScheduleTile(
                            schedule: schedule,
                            canManage: canManage,
                            onEdit: () => _edit(context, ref, schedule),
                            onDeactivate: () =>
                                _deactivate(context, ref, schedule),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TeachingSchedulesTable extends StatelessWidget {
  const _TeachingSchedulesTable({
    required this.schedules,
    required this.canManage,
    required this.onEdit,
    required this.onDeactivate,
  });

  final List<TeachingSchedule> schedules;
  final bool canManage;
  final ValueChanged<TeachingSchedule> onEdit;
  final ValueChanged<TeachingSchedule> onDeactivate;

  @override
  Widget build(BuildContext context) {
    final subjects = schedules.map((item) => item.subject).toSet().toList()
      ..sort();
    final courses = schedules.map((item) => item.courseName).toSet().toList()
      ..sort();
    final teachers = schedules.map((item) => item.teacherName).toSet().toList()
      ..sort();
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      child: AppDataTable<TeachingSchedule>(
        items: schedules,
        searchHint: 'Buscar materia, docente o curso',
        searchText: (schedule) => [
          schedule.subject,
          schedule.teacherCode,
          schedule.teacherName,
          schedule.teacherSpecialty,
          schedule.teacherPhone,
          schedule.courseName,
          schedule.weekdayLabel,
          schedule.startTime,
          schedule.endTime,
        ].whereType<Object>().join(' '),
        filters: [
          AppDataFilter(
            label: 'Día',
            options: [
              for (final entry in weekdayLabels.entries)
                AppDataFilterOption(
                  label: entry.value,
                  matches: (schedule) => schedule.weekday == entry.key,
                ),
            ],
          ),
          AppDataFilter(
            label: 'Materia',
            options: [
              for (final subject in subjects)
                AppDataFilterOption(
                  label: subject,
                  matches: (schedule) => schedule.subject == subject,
                ),
            ],
          ),
          AppDataFilter(
            label: 'Curso',
            options: [
              for (final course in courses)
                AppDataFilterOption(
                  label: course,
                  matches: (schedule) => schedule.courseName == course,
                ),
            ],
          ),
          AppDataFilter(
            label: 'Docente',
            options: [
              for (final teacher in teachers)
                AppDataFilterOption(
                  label: teacher,
                  matches: (schedule) => schedule.teacherName == teacher,
                ),
            ],
          ),
        ],
        dataRowMinHeight: 60,
        dataRowMaxHeight: 82,
        columnSpacing: 28,
        columns: [
          AppDataColumn(
            label: 'Día',
            compare: (first, second) => first.weekday.compareTo(second.weekday),
            cellBuilder: (context, schedule) => Text(schedule.weekdayLabel),
          ),
          AppDataColumn(
            label: 'Horario',
            compare: (first, second) =>
                first.startTime.compareTo(second.startTime),
            cellBuilder: (context, schedule) => Text(
              schedule.timeRange,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          AppDataColumn(
            label: 'Materia',
            compare: (first, second) => first.subject.compareTo(second.subject),
            cellBuilder: (context, schedule) => Text(schedule.subject),
          ),
          AppDataColumn(
            label: 'Docente',
            compare: (first, second) =>
                first.teacherName.compareTo(second.teacherName),
            cellBuilder: (context, schedule) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.teacherName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'COD ${schedule.teacherCode} · ${schedule.teacherSpecialty}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          AppDataColumn(
            label: 'Curso',
            compare: (first, second) =>
                first.courseName.compareTo(second.courseName),
            cellBuilder: (context, schedule) => Text(schedule.courseName),
          ),
          AppDataColumn(
            label: 'Contacto',
            cellBuilder: (context, schedule) =>
                Text(schedule.teacherPhone ?? '—'),
          ),
          if (canManage)
            AppDataColumn(
              label: 'Acciones',
              cellBuilder: (context, schedule) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Editar horario',
                    onPressed: () => onEdit(schedule),
                    icon: const Icon(LucideIcons.pencil, size: 17),
                  ),
                  IconButton(
                    tooltip: 'Retirar horario',
                    onPressed: () => onDeactivate(schedule),
                    icon: const Icon(LucideIcons.calendarX2, size: 17),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TeachingScheduleTile extends StatelessWidget {
  const _TeachingScheduleTile({
    required this.schedule,
    required this.canManage,
    required this.onEdit,
    required this.onDeactivate,
  });

  final TeachingSchedule schedule;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            LucideIcons.bookOpenCheck,
            size: 20,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schedule.subject,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '${schedule.weekdayLabel} · ${schedule.timeRange} · ${schedule.courseName}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                schedule.teacherName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (canManage)
          PopupMenuButton<String>(
            tooltip: 'Acciones del horario',
            onSelected: (value) => value == 'edit' ? onEdit() : onDeactivate(),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'remove', child: Text('Retirar')),
            ],
          ),
      ],
    ),
  );
}

class _TeachingScheduleDialog extends StatefulWidget {
  const _TeachingScheduleDialog({
    required this.teachers,
    required this.courses,
    required this.onSave,
    required this.errorMessage,
    this.current,
  });

  final List<TeacherEntry> teachers;
  final List<CourseEntry> courses;
  final TeachingSchedule? current;
  final Future<bool> Function(TeachingScheduleDraft) onSave;
  final String? Function() errorMessage;

  @override
  State<_TeachingScheduleDialog> createState() =>
      _TeachingScheduleDialogState();
}

class _TeachingScheduleDialogState extends State<_TeachingScheduleDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController subject;
  late String? teacherId;
  late String? courseId;
  late int weekday;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  bool saving = false;
  String? operationError;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    teacherId =
        current?.teacherId ??
        (widget.teachers.isEmpty ? null : widget.teachers.first.id);
    courseId =
        current?.courseId ??
        (widget.courses.isEmpty ? null : widget.courses.first.id);
    weekday = current?.weekday ?? DateTime.monday;
    startTime = _parseTime(current?.startTime ?? '08:00');
    endTime = _parseTime(current?.endTime ?? '09:00');
    subject = TextEditingController(text: current?.subject ?? '');
  }

  @override
  void dispose() {
    subject.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: AppDialogHeader(
      title: widget.current == null ? 'Nuevo horario' : 'Editar horario',
      subtitle: 'Asigna materia, docente, curso, día y rango de horas',
    ),
    content: SizedBox(
      width: 560,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: teacherId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Docente',
                  prefixIcon: Icon(LucideIcons.presentation, size: 18),
                ),
                items: [
                  for (final teacher in widget.teachers)
                    DropdownMenuItem(
                      value: teacher.id,
                      child: Text(
                        'COD ${teacher.teacherCode} · ${teacher.fullName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: saving
                    ? null
                    : (value) {
                        setState(() => teacherId = value);
                        if (subject.text.trim().isEmpty && value != null) {
                          subject.text = widget.teachers
                              .firstWhere((teacher) => teacher.id == value)
                              .specialty;
                        }
                      },
                validator: (value) =>
                    value == null ? 'Selecciona docente' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: subject,
                enabled: !saving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Materia',
                  prefixIcon: Icon(LucideIcons.bookOpen, size: 18),
                ),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Ingresa la materia'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: courseId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Curso',
                  prefixIcon: Icon(LucideIcons.school, size: 18),
                ),
                items: [
                  for (final course in widget.courses)
                    DropdownMenuItem(
                      value: course.id,
                      child: Text(
                        course.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: saving ? null : (value) => courseId = value,
                validator: (value) => value == null ? 'Selecciona curso' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: weekday,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Día',
                  prefixIcon: Icon(LucideIcons.calendarDays, size: 18),
                ),
                items: [
                  for (final entry in weekdayLabels.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: saving || weekdayLabels.isEmpty
                    ? null
                    : (value) => weekday = value ?? weekday,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final startButton = OutlinedButton.icon(
                    onPressed: saving ? null : () => _selectTime(start: true),
                    icon: const Icon(LucideIcons.clockArrowUp, size: 18),
                    label: Text('Desde ${startTime.format(context)}'),
                  );
                  final endButton = OutlinedButton.icon(
                    onPressed: saving ? null : () => _selectTime(start: false),
                    icon: const Icon(LucideIcons.clockArrowDown, size: 18),
                    label: Text('Hasta ${endTime.format(context)}'),
                  );
                  if (constraints.maxWidth < 420) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        startButton,
                        const SizedBox(height: 8),
                        endButton,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: startButton),
                      const SizedBox(width: 10),
                      Expanded(child: endButton),
                    ],
                  );
                },
              ),
              if (operationError != null) ...[
                const SizedBox(height: 12),
                Text(
                  operationError!,
                  style: const TextStyle(color: AppColors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context, false),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: saving ? null : _save,
        icon: saving
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(LucideIcons.save, size: 17),
        label: const Text('Guardar'),
      ),
    ],
  );

  Future<void> _selectTime({required bool start}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: start ? startTime : endTime,
      helpText: start ? 'Hora de inicio' : 'Hora de fin',
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (start) {
        startTime = selected;
      } else {
        endTime = selected;
      }
    });
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    if (_minutes(endTime) <= _minutes(startTime)) {
      setState(() {
        operationError = 'La hora final debe ser posterior a la inicial.';
      });
      return;
    }
    setState(() {
      saving = true;
      operationError = null;
    });
    final saved = await widget.onSave(
      TeachingScheduleDraft(
        teacherId: teacherId!,
        courseId: courseId!,
        subject: subject.text.trim(),
        weekday: weekday,
        startTime: _formatTime(startTime),
        endTime: _formatTime(endTime),
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      saving = false;
      operationError = widget.errorMessage() ?? 'No se pudo guardar.';
    });
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  int _minutes(TimeOfDay value) => value.hour * 60 + value.minute;
}

class _EmptySchedules extends StatelessWidget {
  const _EmptySchedules();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.calendarClock,
            size: 38,
            color: AppColors.inkMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay clases programadas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    ),
  );
}
