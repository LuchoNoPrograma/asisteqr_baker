import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/validation/school_form_validators.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/app_data_table.dart';
import 'package:asisteqr_baker/core/widgets/app_dialog_header.dart';
import 'package:asisteqr_baker/core/widgets/app_feedback.dart';
import 'package:asisteqr_baker/features/courses/domain/course_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
                                'Cursos',
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
                        onPlanClasses: (course) => context.go(
                          '/horarios?perspectiva=curso&recursoId=${course.id}',
                        ),
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
                            onPlanClasses: () => context.go(
                              '/horarios?perspectiva=curso&recursoId=${course.id}',
                            ),
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
    required this.onPlanClasses,
  });

  final List<CourseEntry> courses;
  final bool canManage;
  final ValueChanged<CourseEntry> onEdit;
  final ValueChanged<CourseEntry> onDeactivate;
  final ValueChanged<CourseEntry> onManageEntrySchedules;
  final ValueChanged<CourseEntry> onPlanClasses;

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
        searchText: (course) =>
            [course.name, course.level, course.parallel, course.year].join(' '),
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
                    case _CourseActionType.planClasses:
                      onPlanClasses(course);
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
                    value: _CourseAction(_CourseActionType.planClasses),
                    child: _CourseMenuItem(
                      icon: LucideIcons.settings2,
                      label: 'Configurar clases',
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

enum _CourseActionType { edit, planClasses, manageEntrySchedules, deactivate }

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
    required this.onPlanClasses,
  });

  final CourseEntry course;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onManageEntrySchedules;
  final VoidCallback onPlanClasses;

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
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'classes') onPlanClasses();
                if (value == 'deactivate') onDeactivate();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(LucideIcons.pencil, size: 18),
                    title: Text('Editar curso'),
                  ),
                ),
                PopupMenuItem(
                  value: 'classes',
                  child: ListTile(
                    leading: Icon(LucideIcons.settings2, size: 18),
                    title: Text('Configurar clases'),
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
          'Hora límite de ingreso'
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
                    subtitle: Text('Hora límite de ingreso', maxLines: 2),
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
  late String shift;
  late String deadline;

  @override
  void initState() {
    super.initState();
    shift = widget.schedule?.shift ?? 'MANANA';
    deadline = widget.schedule?.deadline ?? '08:00';
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: AppDialogHeader(
      title: widget.schedule == null ? 'Nuevo horario' : 'Editar horario',
      subtitle: 'Hora límite de ingreso por jornada',
    ),
    content: SizedBox(
      width: 520,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: shift,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Jornada'),
                items: const [
                  DropdownMenuItem(value: 'MANANA', child: Text('Mañana')),
                  DropdownMenuItem(value: 'TARDE', child: Text('Tarde')),
                  DropdownMenuItem(value: 'NOCHE', child: Text('Noche')),
                ],
                onChanged: (value) => shift = value ?? shift,
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
            ],
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
      ScheduleDraft(shift: shift, deadline: deadline, toleranceMinutes: 0),
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
