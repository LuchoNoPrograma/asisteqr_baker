import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/validation/school_form_validators.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/app_data_table.dart';
import 'package:asisteqr_baker/core/widgets/app_dialog_header.dart';
import 'package:asisteqr_baker/core/widgets/app_feedback.dart';
import 'package:asisteqr_baker/features/courses/domain/course_models.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CoursesPage extends ConsumerWidget {
  const CoursesPage({super.key});

  Future<void> _editCourse(
    BuildContext context,
    WidgetRef ref, [
    CourseEntry? course,
  ]) async {
    final model = ref.read(coursesViewModelProvider);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _CourseDialog(
        course: course,
        onSave: (draft) => model.saveCourse(draft, current: course),
        errorMessage: model.takeError,
      ),
    );
    if (saved == true && context.mounted) {
      showAppSuccess(
        context,
        course == null
            ? 'Curso registrado correctamente.'
            : 'Curso actualizado correctamente.',
      );
    }
  }

  Future<void> _deactivateCourse(
    BuildContext context,
    WidgetRef ref,
    CourseEntry course,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppDialogHeader(title: 'Inactivar curso'),
        content: Text(
          'Se ocultará ${course.name} y se inactivarán sus horarios. '
          'Los registros históricos se conservarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            icon: const Icon(LucideIcons.archive, size: 17),
            label: const Text('Inactivar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final saved = await ref
          .read(coursesViewModelProvider)
          .deactivateCourse(course);
      if (!context.mounted) return;
      if (saved) {
        showAppSuccess(context, 'Curso inactivado correctamente.');
      } else {
        await showAppErrorDialog(
          context,
          title: 'No se pudo inactivar el curso',
          message:
              ref.read(coursesViewModelProvider).takeError() ??
              'Intenta nuevamente.',
        );
      }
    }
  }

  Future<void> _editWeeklySchedule(
    BuildContext context,
    WidgetRef ref,
    CourseEntry course,
  ) async {
    final model = ref.read(coursesViewModelProvider);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _WeeklyScheduleDialog(
        course: course,
        onSave: (slots) => model.saveWeeklySchedule(course, slots),
        errorMessage: model.takeError,
      ),
    );
    if (saved == true && context.mounted) {
      showAppSuccess(context, 'Planilla horaria guardada correctamente.');
    }
  }

  Future<void> _manageEntrySchedules(
    BuildContext context,
    WidgetRef ref,
    CourseEntry course,
  ) async {
    final model = ref.read(coursesViewModelProvider);
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _EntrySchedulesDialog(
        course: course,
        onSave: (draft, current) async {
          final saved = await model.saveSchedule(
            course,
            draft,
            current: current,
          );
          return saved
              ? model.courses
                    .firstWhere((item) => item.id == course.id)
                    .schedules
              : null;
        },
        onDeactivate: (schedule) async {
          final saved = await model.deactivateSchedule(course, schedule);
          return saved
              ? model.courses
                    .firstWhere((item) => item.id == course.id)
                    .schedules
              : null;
        },
        errorMessage: model.takeError,
      ),
    );
    if (changed == true && context.mounted) {
      showAppSuccess(context, 'Horarios de ingreso actualizados.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(coursesViewModelProvider);
    final canManage = ref.watch(
      sessionViewModelProvider.select(
        (session) => session.user?.isAdministrator == true,
      ),
    );
    return AdaptiveShell(
      location: '/cursos',
      title: 'Cursos',
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cursos y horarios',
                                style: wide
                                    ? Theme.of(context).textTheme.headlineMedium
                                    : Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${model.courses.length} cursos activos',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (canManage)
                          ElevatedButton.icon(
                            onPressed: model.saving
                                ? null
                                : () => _editCourse(context, ref),
                            icon: const Icon(LucideIcons.plus, size: 18),
                            label: Text(wide ? 'Nuevo curso' : 'Nuevo'),
                          ),
                      ],
                    ),
                    if (!wide) ...[
                      const SizedBox(height: 14),
                      TextField(
                        onChanged: model.search,
                        decoration: const InputDecoration(
                          hintText: 'Buscar por curso, nivel o paralelo',
                          prefixIcon: Icon(LucideIcons.search, size: 18),
                        ),
                      ),
                    ],
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
                child: model.courses.isEmpty && !model.loading
                    ? const _EmptyCourses()
                    : wide
                    ? _CoursesTable(
                        courses: model.courses,
                        canManage: canManage,
                        onEdit: (course) => _editCourse(context, ref, course),
                        onDeactivate: (course) =>
                            _deactivateCourse(context, ref, course),
                        onManageEntrySchedules: (course) =>
                            _manageEntrySchedules(context, ref, course),
                        onEditWeeklySchedule: (course) =>
                            _editWeeklySchedule(context, ref, course),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(14, 0, 14, 24),
                        itemCount: model.courses.length,
                        itemBuilder: (context, index) {
                          final course = model.courses[index];
                          return _CoursePanel(
                            course: course,
                            canManage: canManage,
                            onEdit: () => _editCourse(context, ref, course),
                            onDeactivate: () =>
                                _deactivateCourse(context, ref, course),
                            onManageEntrySchedules: () =>
                                _manageEntrySchedules(context, ref, course),
                            onEditWeeklySchedule: () =>
                                _editWeeklySchedule(context, ref, course),
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

class _CoursesTable extends StatelessWidget {
  const _CoursesTable({
    required this.courses,
    required this.canManage,
    required this.onEdit,
    required this.onDeactivate,
    required this.onManageEntrySchedules,
    required this.onEditWeeklySchedule,
  });

  final List<CourseEntry> courses;
  final bool canManage;
  final ValueChanged<CourseEntry> onEdit;
  final ValueChanged<CourseEntry> onDeactivate;
  final ValueChanged<CourseEntry> onManageEntrySchedules;
  final ValueChanged<CourseEntry> onEditWeeklySchedule;

  @override
  Widget build(BuildContext context) {
    final levels = courses.map((course) => course.level).toSet().toList()
      ..sort();
    final years = courses.map((course) => course.year).toSet().toList()
      ..sort((first, second) => second.compareTo(first));
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      child: AppDataTable<CourseEntry>(
        items: courses,
        searchHint: 'Buscar curso, nivel o paralelo',
        searchText: (course) => [
          course.name,
          course.level,
          course.parallel,
          course.year,
          ...course.weeklySchedule.expand((slot) => [slot.weekday, slot.hour]),
        ].join(' '),
        filters: [
          AppDataFilter(
            label: 'Nivel',
            options: [
              for (final level in levels)
                AppDataFilterOption(
                  label: level,
                  matches: (course) => course.level == level,
                ),
            ],
          ),
          AppDataFilter(
            label: 'Gestión',
            options: [
              for (final year in years)
                AppDataFilterOption(
                  label: year.toString(),
                  matches: (course) => course.year == year,
                ),
            ],
          ),
        ],
        dataRowMaxHeight: 92,
        columns: [
          AppDataColumn(
            label: 'Curso',
            compare: (first, second) => first.name.compareTo(second.name),
            cellBuilder: (context, course) => Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    LucideIcons.school,
                    color: AppColors.navy,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 9),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      course.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Gestión ${course.year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppDataColumn(
            label: 'Estudiantes',
            numeric: true,
            compare: (first, second) =>
                first.studentCount.compareTo(second.studentCount),
            cellBuilder: (context, course) =>
                Text(course.studentCount.toString()),
          ),
          AppDataColumn(
            label: 'Docentes',
            numeric: true,
            compare: (first, second) =>
                first.teacherCount.compareTo(second.teacherCount),
            cellBuilder: (context, course) =>
                Text(course.teacherCount.toString()),
          ),
          AppDataColumn(
            label: 'Ingreso',
            cellBuilder: (context, course) =>
                _EntryScheduleSummary(schedules: course.schedules),
          ),
          AppDataColumn(
            label: 'Horario semanal',
            cellBuilder: (context, course) =>
                _WeeklyScheduleSummary(slots: course.weeklySchedule),
          ),
          if (canManage)
            AppDataColumn(
              label: 'Acciones',
              cellBuilder: (context, course) => PopupMenuButton<_CourseAction>(
                tooltip: 'Acciones del curso',
                onSelected: (action) {
                  switch (action.type) {
                    case _CourseActionType.edit:
                      onEdit(course);
                      break;
                    case _CourseActionType.deactivate:
                      onDeactivate(course);
                      break;
                    case _CourseActionType.manageEntrySchedules:
                      onManageEntrySchedules(course);
                      break;
                    case _CourseActionType.editWeeklySchedule:
                      onEditWeeklySchedule(course);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _CourseAction(_CourseActionType.edit),
                    child: _CourseMenuItem(
                      icon: LucideIcons.pencil,
                      label: 'Editar curso',
                    ),
                  ),
                  const PopupMenuItem(
                    value: _CourseAction(
                      _CourseActionType.manageEntrySchedules,
                    ),
                    child: _CourseMenuItem(
                      icon: LucideIcons.clock3,
                      label: 'Horarios de ingreso',
                    ),
                  ),
                  const PopupMenuItem(
                    value: _CourseAction(_CourseActionType.editWeeklySchedule),
                    child: _CourseMenuItem(
                      icon: LucideIcons.calendarClock,
                      label: 'Planilla semanal',
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _CourseAction(_CourseActionType.deactivate),
                    child: _CourseMenuItem(
                      icon: LucideIcons.archive,
                      label: 'Inactivar curso',
                      destructive: true,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

enum _CourseActionType {
  edit,
  manageEntrySchedules,
  editWeeklySchedule,
  deactivate,
}

class _CourseAction {
  const _CourseAction(this.type);

  final _CourseActionType type;
}

class _CourseMenuItem extends StatelessWidget {
  const _CourseMenuItem({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: destructive ? AppColors.red : null),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          maxLines: 2,
          style: TextStyle(color: destructive ? AppColors.red : null),
        ),
      ),
    ],
  );
}

class _CoursePanel extends StatelessWidget {
  const _CoursePanel({
    required this.course,
    required this.canManage,
    required this.onEdit,
    required this.onDeactivate,
    required this.onManageEntrySchedules,
    required this.onEditWeeklySchedule,
  });

  final CourseEntry course;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onManageEntrySchedules;
  final VoidCallback onEditWeeklySchedule;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(LucideIcons.school, color: AppColors.navy, size: 20),
      ),
      title: Text(
        course.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${course.studentCount} estudiantes · ${course.teacherCount} docentes · Gestión ${course.year}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: canManage
          ? PopupMenuButton<String>(
              tooltip: 'Acciones del curso',
              onSelected: (value) =>
                  value == 'edit' ? onEdit() : onDeactivate(),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(LucideIcons.pencil, size: 18),
                    title: Text('Editar curso'),
                  ),
                ),
                PopupMenuItem(
                  value: 'deactivate',
                  child: ListTile(
                    leading: Icon(
                      LucideIcons.archive,
                      size: 18,
                      color: AppColors.red,
                    ),
                    title: Text('Inactivar'),
                  ),
                ),
              ],
            )
          : null,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Control de ingreso',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (canManage)
                    IconButton(
                      tooltip: 'Gestionar horarios de ingreso',
                      onPressed: onManageEntrySchedules,
                      icon: const Icon(LucideIcons.settings2, size: 19),
                    ),
                ],
              ),
              _EntryScheduleSummary(schedules: course.schedules),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Horario semanal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (canManage)
                    OutlinedButton.icon(
                      onPressed: onEditWeeklySchedule,
                      icon: const Icon(LucideIcons.calendarClock, size: 18),
                      label: const Text('Editar'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _WeeklyScheduleSummary(slots: course.weeklySchedule),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EntryScheduleSummary extends StatelessWidget {
  const _EntryScheduleSummary({required this.schedules});

  final List<CourseSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Text(
        'Sin control de ingreso configurado',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
      );
    }
    final first = schedules.first;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${first.shiftLabel} · ${first.deadline}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Text(
          '${first.toleranceMinutes} min de tolerancia'
          '${schedules.length > 1 ? ' · +${schedules.length - 1}' : ''}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _EntrySchedulesDialog extends StatefulWidget {
  const _EntrySchedulesDialog({
    required this.course,
    required this.onSave,
    required this.onDeactivate,
    required this.errorMessage,
  });

  final CourseEntry course;
  final Future<List<CourseSchedule>?> Function(
    ScheduleDraft draft,
    CourseSchedule? current,
  )
  onSave;
  final Future<List<CourseSchedule>?> Function(CourseSchedule schedule)
  onDeactivate;
  final String? Function() errorMessage;

  @override
  State<_EntrySchedulesDialog> createState() => _EntrySchedulesDialogState();
}

class _EntrySchedulesDialogState extends State<_EntrySchedulesDialog> {
  late List<CourseSchedule> schedules;
  bool busy = false;
  bool changed = false;

  @override
  void initState() {
    super.initState();
    schedules = [...widget.course.schedules];
  }

  @override
  Widget build(BuildContext context) {
    final contentHeight = (MediaQuery.sizeOf(context).height - 250)
        .clamp(240.0, 500.0)
        .toDouble();
    return AlertDialog(
      title: AppDialogHeader(
        title: 'Horarios de ingreso',
        subtitle: widget.course.name,
      ),
      content: SizedBox(
        width: 640,
        height: contentHeight,
        child: schedules.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.clockAlert,
                      size: 34,
                      color: AppColors.inkMuted,
                    ),
                    SizedBox(height: 10),
                    Text('No hay horarios de ingreso configurados.'),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: schedules.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        LucideIcons.clock3,
                        size: 19,
                        color: AppColors.navy,
                      ),
                    ),
                    title: Text(
                      '${schedule.shiftLabel} · ${schedule.deadline}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${schedule.toleranceMinutes} min de tolerancia · ${schedule.timeZone}',
                      maxLines: 2,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Editar horario',
                          onPressed: busy ? null : () => _edit(schedule),
                          icon: const Icon(LucideIcons.pencil, size: 18),
                        ),
                        IconButton(
                          tooltip: 'Inactivar horario',
                          onPressed: busy ? null : () => _deactivate(schedule),
                          icon: const Icon(
                            LucideIcons.archive,
                            size: 18,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context, changed),
          child: const Text('Cerrar'),
        ),
        FilledButton.icon(
          onPressed: busy ? null : () => _edit(),
          icon: busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.plus, size: 18),
          label: const Text('Nuevo horario'),
        ),
      ],
    );
  }

  Future<void> _edit([CourseSchedule? current]) async {
    final draft = await showDialog<ScheduleDraft>(
      context: context,
      builder: (context) => _EntryScheduleFormDialog(schedule: current),
    );
    if (draft == null || !mounted) return;
    setState(() => busy = true);
    final updated = await widget.onSave(draft, current);
    if (!mounted) return;
    setState(() => busy = false);
    if (updated == null) {
      await _showOperationError('No se pudo guardar el horario');
      return;
    }
    setState(() {
      schedules = [...updated];
      changed = true;
    });
  }

  Future<void> _deactivate(CourseSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppDialogHeader(title: 'Inactivar horario'),
        content: Text(
          'Se retirará el ingreso de ${schedule.shiftLabel.toLowerCase()} a las ${schedule.deadline}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            icon: const Icon(LucideIcons.archive, size: 17),
            label: const Text('Inactivar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    final updated = await widget.onDeactivate(schedule);
    if (!mounted) return;
    setState(() => busy = false);
    if (updated == null) {
      await _showOperationError('No se pudo inactivar el horario');
      return;
    }
    setState(() {
      schedules = [...updated];
      changed = true;
    });
  }

  Future<void> _showOperationError(String title) => showAppErrorDialog(
    context,
    title: title,
    message: widget.errorMessage() ?? 'Revisa los datos e intenta nuevamente.',
  );
}

class _EntryScheduleFormDialog extends StatefulWidget {
  const _EntryScheduleFormDialog({this.schedule});

  final CourseSchedule? schedule;

  @override
  State<_EntryScheduleFormDialog> createState() =>
      _EntryScheduleFormDialogState();
}

class _EntryScheduleFormDialogState extends State<_EntryScheduleFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController tolerance;
  late final TextEditingController timeZone;
  late String shift;
  late String deadline;

  @override
  void initState() {
    super.initState();
    shift = widget.schedule?.shift ?? 'MANANA';
    deadline = widget.schedule?.deadline ?? '08:00';
    tolerance = TextEditingController(
      text: (widget.schedule?.toleranceMinutes ?? 5).toString(),
    );
    timeZone = TextEditingController(
      text: widget.schedule?.timeZone ?? 'America/La_Paz',
    );
  }

  @override
  void dispose() {
    tolerance.dispose();
    timeZone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: AppDialogHeader(
      title: widget.schedule == null ? 'Nuevo horario' : 'Editar horario',
      subtitle: 'Jornada, hora límite y tolerancia de ingreso',
    ),
    content: SizedBox(
      width: 520,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final shiftField = DropdownButtonFormField<String>(
                initialValue: shift,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Jornada'),
                items: const [
                  DropdownMenuItem(value: 'MANANA', child: Text('Mañana')),
                  DropdownMenuItem(value: 'TARDE', child: Text('Tarde')),
                  DropdownMenuItem(value: 'NOCHE', child: Text('Noche')),
                ],
                onChanged: (value) => shift = value ?? shift,
              );
              final toleranceField = TextFormField(
                controller: tolerance,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Tolerancia',
                  suffixText: 'min',
                ),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  return parsed == null || parsed < 0 || parsed > 120
                      ? 'Usa un valor entre 0 y 120.'
                      : null;
                },
              );
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (compact) ...[
                    shiftField,
                    const SizedBox(height: 12),
                    toleranceField,
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: shiftField),
                        const SizedBox(width: 12),
                        Expanded(child: toleranceField),
                      ],
                    ),
                  const SizedBox(height: 12),
                  FormField<String>(
                    initialValue: deadline,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Selecciona la hora límite.'
                        : null,
                    builder: (field) => InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => _pickTime(field),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Hora límite',
                          errorText: field.errorText,
                          suffixIcon: const Icon(LucideIcons.clock3, size: 18),
                        ),
                        child: Text(deadline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: timeZone,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Zona horaria',
                      prefixIcon: Icon(LucideIcons.globe2, size: 18),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresa la zona horaria.'
                        : null,
                  ),
                ],
              );
            },
          ),
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

  Future<void> _pickTime(FormFieldState<String> field) async {
    final parts = deadline.split(':');
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 8,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
      helpText: 'Hora límite de ingreso',
    );
    if (selected == null) return;
    final value =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    setState(() => deadline = value);
    field.didChange(value);
  }

  void _submit() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ScheduleDraft(
        shift: shift,
        deadline: deadline,
        toleranceMinutes: int.parse(tolerance.text),
        timeZone: timeZone.text.trim(),
      ),
    );
  }
}

class _WeeklyScheduleSummary extends StatelessWidget {
  const _WeeklyScheduleSummary({required this.slots});

  final List<WeeklyCourseSlot> slots;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Text(
        'Sin horario asignado',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
      );
    }
    final days = slots.map((slot) => slot.weekday).toSet().length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.calendarDays, size: 17, color: AppColors.navy),
        const SizedBox(width: 7),
        Text(
          '${slots.length} h semanales · $days días',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _CourseDialog extends StatefulWidget {
  const _CourseDialog({
    required this.onSave,
    required this.errorMessage,
    this.course,
  });

  final CourseEntry? course;
  final Future<bool> Function(CourseDraft) onSave;
  final String? Function() errorMessage;

  @override
  State<_CourseDialog> createState() => _CourseDialogState();
}

class _CourseDialogState extends State<_CourseDialog> {
  static const schoolLevels = [
    '1.º Secundaria',
    '2.º Secundaria',
    '3.º Secundaria',
    '4.º Secundaria',
    '5.º Secundaria',
    '6.º Secundaria',
  ];

  final formKey = GlobalKey<FormState>();
  late final TextEditingController parallel;
  late final TextEditingController year;
  late String level;
  bool saving = false;

  List<String> get levelOptions => schoolLevels;

  @override
  void initState() {
    super.initState();
    final currentLevel = widget.course?.level;
    level = schoolLevels.contains(currentLevel)
        ? currentLevel!
        : schoolLevels.first;
    parallel = TextEditingController(
      text: (widget.course?.parallel ?? 'A').trim().toUpperCase(),
    );
    year = TextEditingController(
      text: (widget.course?.year ?? DateTime.now().year).toString(),
    );
  }

  @override
  void dispose() {
    parallel.dispose();
    year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: AppDialogHeader(
      title: widget.course == null ? 'Registrar curso' : 'Editar curso',
      subtitle: 'Grado, paralelo y gestión escolar',
    ),
    content: SizedBox(
      width: 560,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: level,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Grado y nivel',
                prefixIcon: Icon(LucideIcons.layers3, size: 18),
              ),
              items: levelOptions
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => level = value ?? level,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: parallel,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      SchoolFormValidators.uppercaseFormatter,
                    ],
                    maxLength: 3,
                    decoration: const InputDecoration(
                      labelText: 'Paralelo',
                      hintText: 'Ej. A',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresa el paralelo.'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: year,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 4,
                    decoration: const InputDecoration(labelText: 'Gestión'),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      return parsed == null || parsed < 2000 || parsed > 2100
                          ? 'Gestión no válida.'
                          : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'El nombre institucional se genera con el grado y paralelo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: saving ? null : _save,
        icon: saving
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(LucideIcons.save, size: 17),
        label: Text(
          widget.course == null ? 'Registrar curso' : 'Guardar cambios',
        ),
      ),
    ],
  );

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final normalizedParallel = parallel.text.trim().toUpperCase();
    final saved = await widget.onSave(
      CourseDraft(
        name: '$level $normalizedParallel',
        level: level,
        parallel: normalizedParallel,
        year: int.parse(year.text),
      ),
    );
    if (mounted && saved) Navigator.pop(context, true);
    if (mounted && !saved) {
      setState(() => saving = false);
      await showAppErrorDialog(
        context,
        title: 'No se pudo guardar el curso',
        message:
            widget.errorMessage() ?? 'Revisa los datos e intenta nuevamente.',
      );
    }
  }
}

class _WeeklyScheduleDialog extends StatefulWidget {
  const _WeeklyScheduleDialog({
    required this.course,
    required this.onSave,
    required this.errorMessage,
  });

  final CourseEntry course;
  final Future<bool> Function(Iterable<WeeklyCourseSlot>) onSave;
  final String? Function() errorMessage;

  @override
  State<_WeeklyScheduleDialog> createState() => _WeeklyScheduleDialogState();
}

class _WeeklyScheduleDialogState extends State<_WeeklyScheduleDialog> {
  late Map<String, WeeklyCourseSlot> draft;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    draft = {for (final slot in widget.course.weeklySchedule) slot.key: slot};
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: AppDialogHeader(
      title: 'Horario semanal',
      subtitle: widget.course.name,
    ),
    content: SizedBox(
      width: 760,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: saving ? null : () => _applyPreset(8, 12),
                  icon: const Icon(LucideIcons.sunrise, size: 17),
                  label: const Text('Lun–Vie 08–12'),
                ),
                OutlinedButton.icon(
                  onPressed: saving ? null : () => _applyPreset(14, 20),
                  icon: const Icon(LucideIcons.sunset, size: 17),
                  label: const Text('Lun–Vie 14–20'),
                ),
                OutlinedButton.icon(
                  onPressed: saving || draft.isEmpty ? null : _clear,
                  icon: const Icon(LucideIcons.eraser, size: 17),
                  label: const Text('Limpiar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  LucideIcons.clock3,
                  size: 17,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '${draft.length} horas semanales · 08:00–20:00',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) => DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: _WeeklyScheduleMatrix(
                    selectedKeys: draft.keys.toSet(),
                    enabled: !saving,
                    width: constraints.maxWidth,
                    onPaint: _paintSlot,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: saving ? null : _save,
        icon: saving
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(LucideIcons.save, size: 17),
        label: const Text('Guardar horario'),
      ),
    ],
  );

  void _paintSlot(WeeklyCourseSlot slot, bool selected) {
    setState(() {
      if (selected) {
        draft[slot.key] = slot;
      } else {
        draft.remove(slot.key);
      }
    });
  }

  void _applyPreset(int firstHour, int endHour) {
    final slots = <WeeklyCourseSlot>[];
    for (
      var weekday = WeeklyCourseSlot.firstWeekday;
      weekday <= WeeklyCourseSlot.lastWeekday;
      weekday++
    ) {
      for (var hour = firstHour; hour < endHour; hour++) {
        slots.add(WeeklyCourseSlot(weekday: weekday, hour: hour));
      }
    }
    setState(() => draft = {for (final slot in slots) slot.key: slot});
  }

  void _clear() => setState(draft.clear);

  Future<void> _save() async {
    setState(() => saving = true);
    final saved = await widget.onSave(draft.values);
    if (mounted && saved) Navigator.pop(context, true);
    if (mounted && !saved) {
      setState(() => saving = false);
      await showAppErrorDialog(
        context,
        title: 'No se pudo guardar el horario',
        message: widget.errorMessage() ?? 'Intenta nuevamente.',
      );
    }
  }
}

class _WeeklyScheduleMatrix extends StatefulWidget {
  const _WeeklyScheduleMatrix({
    required this.selectedKeys,
    required this.enabled,
    required this.width,
    required this.onPaint,
  });

  final Set<String> selectedKeys;
  final bool enabled;
  final double width;
  final void Function(WeeklyCourseSlot slot, bool selected) onPaint;

  @override
  State<_WeeklyScheduleMatrix> createState() => _WeeklyScheduleMatrixState();
}

class _WeeklyScheduleMatrixState extends State<_WeeklyScheduleMatrix> {
  static const hourWidth = 66.0;
  static const headerHeight = 38.0;
  static const rowHeight = 32.0;
  static const dayCount = 5;
  static const hourCount = 12;
  static const matrixHeight = headerHeight + rowHeight * hourCount;
  static const dayLabels = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE'];
  static const touchPaintingDevices = {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };

  bool painting = false;
  bool paintValue = true;
  String? lastSlotKey;

  double get dayWidth => (widget.width - hourWidth) / dayCount;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    supportedDevices: touchPaintingDevices,
    onTapUp: widget.enabled ? _toggleTouchSlot : null,
    onLongPressStart: widget.enabled ? _startTouchPaint : null,
    onLongPressMoveUpdate: widget.enabled ? _continueTouchPaint : null,
    onLongPressEnd: widget.enabled ? (_) => _cancelPaint() : null,
    onLongPressCancel: widget.enabled ? _cancelPaint : null,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: widget.enabled ? _startMousePaint : null,
      onPointerMove: widget.enabled ? _continueMousePaint : null,
      onPointerUp: widget.enabled ? (_) => _cancelPaint() : null,
      onPointerCancel: widget.enabled ? (_) => _cancelPaint() : null,
      child: SizedBox(
        key: const ValueKey('course_weekly_schedule_matrix'),
        width: widget.width,
        height: matrixHeight,
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              top: 0,
              width: hourWidth,
              height: headerHeight,
              child: _ScheduleLabelCell(label: 'HORA'),
            ),
            for (var day = 0; day < dayCount; day++)
              Positioned(
                left: hourWidth + dayWidth * day,
                top: 0,
                width: dayWidth,
                height: headerHeight,
                child: _ScheduleLabelCell(label: dayLabels[day]),
              ),
            for (var row = 0; row < hourCount; row++) ...[
              Positioned(
                left: 0,
                top: headerHeight + rowHeight * row,
                width: hourWidth,
                height: rowHeight,
                child: _ScheduleLabelCell(
                  label:
                      '${(WeeklyCourseSlot.firstHour + row).toString().padLeft(2, '0')}–'
                      '${(WeeklyCourseSlot.firstHour + row + 1).toString().padLeft(2, '0')}',
                ),
              ),
              for (var day = 0; day < dayCount; day++)
                _positionedCell(day, row),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _positionedCell(int day, int row) {
    final slot = WeeklyCourseSlot(
      weekday: day + WeeklyCourseSlot.firstWeekday,
      hour: row + WeeklyCourseSlot.firstHour,
    );
    final selected = widget.selectedKeys.contains(slot.key);
    return Positioned(
      left: hourWidth + dayWidth * day,
      top: headerHeight + rowHeight * row,
      width: dayWidth,
      height: rowHeight,
      child: _ScheduleMatrixCell(
        key: ValueKey('course_slot_${slot.weekday}_${slot.hour}'),
        label: '${dayLabels[day]} ${slot.hour}:00',
        selected: selected,
        enabled: widget.enabled,
        onToggle: () => widget.onPaint(slot, !selected),
      ),
    );
  }

  void _startMousePaint(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.mouse) return;
    final slot = _slotAt(event.localPosition);
    if (slot == null) return;
    painting = true;
    paintValue = !widget.selectedKeys.contains(slot.key);
    lastSlotKey = slot.key;
    widget.onPaint(slot, paintValue);
  }

  void _continueMousePaint(PointerMoveEvent event) {
    if (event.kind != PointerDeviceKind.mouse || !painting) return;
    _paintOnce(_slotAt(event.localPosition));
  }

  void _toggleTouchSlot(TapUpDetails details) {
    final slot = _slotAt(details.localPosition);
    if (slot != null) {
      widget.onPaint(slot, !widget.selectedKeys.contains(slot.key));
    }
  }

  void _startTouchPaint(LongPressStartDetails details) {
    final slot = _slotAt(details.localPosition);
    if (slot == null) return;
    painting = true;
    paintValue = !widget.selectedKeys.contains(slot.key);
    lastSlotKey = slot.key;
    widget.onPaint(slot, paintValue);
  }

  void _continueTouchPaint(LongPressMoveUpdateDetails details) =>
      _paintOnce(_slotAt(details.localPosition));

  void _paintOnce(WeeklyCourseSlot? slot) {
    if (!painting || slot == null || slot.key == lastSlotKey) return;
    lastSlotKey = slot.key;
    widget.onPaint(slot, paintValue);
  }

  void _cancelPaint() {
    painting = false;
    lastSlotKey = null;
  }

  WeeklyCourseSlot? _slotAt(Offset position) {
    if (position.dx < hourWidth || position.dy < headerHeight) return null;
    final slot = WeeklyCourseSlot(
      weekday:
          ((position.dx - hourWidth) ~/ dayWidth) +
          WeeklyCourseSlot.firstWeekday,
      hour:
          ((position.dy - headerHeight) ~/ rowHeight) +
          WeeklyCourseSlot.firstHour,
    );
    return slot.isWithinMatrix ? slot : null;
  }
}

class _ScheduleLabelCell extends StatelessWidget {
  const _ScheduleLabelCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: AppColors.canvas,
      border: Border(
        right: BorderSide(color: AppColors.border),
        bottom: BorderSide(color: AppColors.border),
      ),
    ),
    child: Text(
      label,
      maxLines: 1,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _ScheduleMatrixCell extends StatelessWidget {
  const _ScheduleMatrixCell({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onToggle,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    enabled: enabled,
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
    },
    actions: {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          onToggle();
          return null;
        },
      ),
    },
    child: Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      onTap: enabled ? onToggle : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.greenSoft : AppColors.surface,
          border: const Border(
            right: BorderSide(color: AppColors.border),
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: selected
            ? const Icon(LucideIcons.check, size: 15, color: AppColors.green)
            : enabled
            ? const Icon(LucideIcons.plus, size: 11, color: AppColors.border)
            : null,
      ),
    ),
  );
}

class _EmptyCourses extends StatelessWidget {
  const _EmptyCourses();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.school, size: 38, color: AppColors.inkMuted),
        SizedBox(height: 10),
        Text('No hay cursos registrados'),
      ],
    ),
  );
}
