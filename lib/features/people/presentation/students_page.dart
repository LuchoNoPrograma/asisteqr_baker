import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/active_status_badge.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/app_data_table.dart';
import 'package:asisteqr_baker/core/widgets/app_dialog_header.dart';
import 'package:asisteqr_baker/core/widgets/app_feedback.dart';
import 'package:asisteqr_baker/core/widgets/app_table_actions_menu.dart';
import 'package:asisteqr_baker/core/validation/school_form_validators.dart';
import 'package:asisteqr_baker/features/people/application/person_image_picker.dart';
import 'package:asisteqr_baker/features/people/domain/people_models.dart';
import 'package:asisteqr_baker/features/people/presentation/person_image_crop_dialog.dart';
import 'package:asisteqr_baker/features/people/presentation/person_photo_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StudentsPage extends ConsumerWidget {
  const StudentsPage({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    StudentEntry? student,
  ]) async {
    final model = ref.read(studentsViewModelProvider);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _StudentDialog(
        student: student,
        courses: model.courses,
        onSave: (draft) => model.save(draft, current: student),
        errorMessage: model.takeError,
      ),
    );
    if (saved == true && context.mounted) {
      showAppSuccess(
        context,
        student == null
            ? 'Estudiante registrado correctamente.'
            : 'Estudiante actualizado correctamente.',
      );
    }
  }

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    StudentEntry student,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppDialogHeader(title: 'Desactivar estudiante'),
        content: Text(
          'Se desactivará a ${student.fullName} y su credencial QR.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            icon: const Icon(LucideIcons.circleOff, size: 17),
            label: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final model = ref.read(studentsViewModelProvider);
      final saved = await model.retire(student);
      if (!context.mounted) return;
      if (saved) {
        showAppSuccess(context, 'Estudiante desactivado correctamente.');
      } else {
        await showAppErrorDialog(
          context,
          title: 'No se pudo desactivar al estudiante',
          message: model.takeError() ?? 'Intenta nuevamente.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(studentsViewModelProvider);
    final canManage = ref.watch(
      sessionViewModelProvider.select(
        (session) => session.user?.isAdministrator == true,
      ),
    );
    return AdaptiveShell(
      location: '/estudiantes',
      title: 'Estudiantes',
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
                                'Estudiantes',
                                style: wide
                                    ? Theme.of(context).textTheme.headlineMedium
                                    : Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${model.students.length} registros',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (canManage)
                          ElevatedButton.icon(
                            onPressed: model.courses.isEmpty
                                ? null
                                : () => _edit(context, ref),
                            icon: const Icon(LucideIcons.userPlus, size: 18),
                            label: Text(wide ? 'Nuevo estudiante' : 'Nuevo'),
                          ),
                      ],
                    ),
                    if (!wide) ...[
                      const SizedBox(height: 14),
                      TextField(
                        onChanged: model.search,
                        decoration: const InputDecoration(
                          hintText: 'Buscar por nombre, documento o código',
                          prefixIcon: Icon(LucideIcons.search, size: 18),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        key: ValueKey(model.courseId),
                        initialValue: model.courseId ?? '',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Curso',
                          prefixIcon: Icon(LucideIcons.school, size: 18),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Todos los cursos'),
                          ),
                          for (final course in model.courses)
                            DropdownMenuItem(
                              value: course.id,
                              child: Text(
                                course.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => model.filterCourse(
                          value == null || value.isEmpty ? null : value,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (model.loading) const LinearProgressIndicator(minHeight: 2),
              if (model.error != null)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    model.error!,
                    style: const TextStyle(color: AppColors.red),
                  ),
                ),
              Expanded(
                child: model.students.isEmpty && !model.loading
                    ? const _EmptyPeople(
                        icon: LucideIcons.graduationCap,
                        label: 'No hay estudiantes registrados',
                      )
                    : wide
                    ? _StudentsTable(
                        students: model.students,
                        canManage: canManage,
                        onHistory: (item) =>
                            context.push('/historial', extra: item.id),
                        onEdit: (item) => _edit(context, ref, item),
                        onDeactivate: (item) => _deactivate(context, ref, item),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                        itemCount: model.students.length,
                        itemBuilder: (context, index) {
                          final student = model.students[index];
                          return _StudentTile(
                            student: student,
                            canManage: canManage,
                            onHistory: () =>
                                context.push('/historial', extra: student.id),
                            onEdit: () => _edit(context, ref, student),
                            onDeactivate: () =>
                                _deactivate(context, ref, student),
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

class _StudentsTable extends StatelessWidget {
  const _StudentsTable({
    required this.students,
    required this.canManage,
    required this.onHistory,
    required this.onEdit,
    required this.onDeactivate,
  });
  final List<StudentEntry> students;
  final bool canManage;
  final ValueChanged<StudentEntry> onHistory;
  final ValueChanged<StudentEntry> onEdit;
  final ValueChanged<StudentEntry> onDeactivate;

  @override
  Widget build(BuildContext context) {
    final courses =
        students
            .map((student) => student.course?.name)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      child: AppDataTable<StudentEntry>(
        items: students,
        searchHint: 'Buscar estudiante, código, tutor o curso',
        searchText: (student) => [
          student.studentCode,
          student.fullName,
          student.documentNumber,
          student.guardianName,
          student.guardianPhone,
          student.course?.name,
          student.status,
        ].whereType<Object>().join(' '),
        filters: [
          AppDataFilter(
            label: 'Estado',
            options: [
              AppDataFilterOption(
                label: 'ACTIVOS',
                matches: (student) => student.status == 'ACTIVO',
              ),
              AppDataFilterOption(
                label: 'INACTIVOS',
                matches: (student) => student.status != 'ACTIVO',
              ),
            ],
          ),
          AppDataFilter(
            label: 'Curso',
            options: [
              for (final course in courses)
                AppDataFilterOption(
                  label: course,
                  matches: (student) => student.course?.name == course,
                ),
            ],
          ),
        ],
        dataRowMinHeight: 48,
        dataRowMaxHeight: 60,
        columnSpacing: 28,
        columns: [
          AppDataColumn(
            label: 'Código',
            columnWidth: const FixedColumnWidth(112),
            compare: (first, second) =>
                first.studentCode.compareTo(second.studentCode),
            cellBuilder: (context, student) => Text(
              student.studentCode.toString(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          AppDataColumn(
            label: 'Estudiante',
            columnWidth: const IntrinsicColumnWidth(flex: 1),
            compare: (first, second) =>
                first.fullName.compareTo(second.fullName),
            cellBuilder: (context, student) => Row(
              children: [
                PersonAvatar(
                  photoUrl: student.photoUrl,
                  fallback: student.firstNames.characters.first,
                  size: 34,
                ),
                const SizedBox(width: 9),
                Text(
                  student.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          AppDataColumn(
            label: 'Curso',
            compare: (first, second) =>
                (first.course?.name ?? '').compareTo(second.course?.name ?? ''),
            cellBuilder: (context, student) =>
                Text(student.course?.name ?? 'Sin curso'),
          ),
          AppDataColumn(
            label: 'Tutor',
            compare: (first, second) =>
                (first.guardianName ?? '').compareTo(second.guardianName ?? ''),
            cellBuilder: (context, student) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.guardianName ?? 'Sin tutor'),
                if (student.guardianPhone?.isNotEmpty == true)
                  Text(
                    student.guardianPhone!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          AppDataColumn(
            label: 'Estado',
            compare: (first, second) => first.status.compareTo(second.status),
            cellBuilder: (context, student) =>
                ActiveStatusBadge(active: student.status == 'ACTIVO'),
          ),
          AppDataColumn(
            label: 'Acciones',
            cellBuilder: (context, student) => AppTableActionsMenu(
              tooltip: 'Acciones del estudiante',
              actions: [
                AppTableAction(
                  label: 'Ver historial',
                  icon: LucideIcons.history,
                  onSelected: () => onHistory(student),
                ),
                if (canManage)
                  AppTableAction(
                    label: 'Editar',
                    icon: LucideIcons.pencil,
                    onSelected: () => onEdit(student),
                  ),
                if (canManage && student.status == 'ACTIVO')
                  AppTableAction.deactivate(
                    onSelected: () => onDeactivate(student),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({
    required this.student,
    required this.canManage,
    required this.onHistory,
    required this.onEdit,
    required this.onDeactivate,
  });
  final StudentEntry student;
  final bool canManage;
  final VoidCallback onHistory;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        PersonAvatar(
          photoUrl: student.photoUrl,
          fallback: student.firstNames.characters.first,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.fullName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                student.course?.name ?? 'Sin curso',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                [
                  if (student.guardianName?.isNotEmpty == true)
                    'Tutor: ${student.guardianName}',
                  if (student.guardianPhone?.isNotEmpty == true)
                    student.guardianPhone!,
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        ActiveStatusBadge(active: student.status == 'ACTIVO'),
        AppTableActionsMenu(
          tooltip: 'Acciones del estudiante',
          actions: [
            AppTableAction(
              label: 'Ver historial',
              icon: LucideIcons.history,
              onSelected: onHistory,
            ),
            if (canManage)
              AppTableAction(
                label: 'Editar',
                icon: LucideIcons.pencil,
                onSelected: onEdit,
              ),
            if (canManage && student.status == 'ACTIVO')
              AppTableAction.deactivate(onSelected: onDeactivate),
          ],
        ),
      ],
    ),
  );
}

class _StudentDialog extends StatefulWidget {
  const _StudentDialog({
    required this.courses,
    required this.onSave,
    required this.errorMessage,
    this.student,
  });

  final StudentEntry? student;
  final List<CourseOption> courses;
  final Future<bool> Function(StudentDraft) onSave;
  final String? Function() errorMessage;

  @override
  State<_StudentDialog> createState() => _StudentDialogState();
}

class _StudentDialogState extends State<_StudentDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController firstNames;
  late final TextEditingController lastNames;
  late final TextEditingController document;
  late final TextEditingController guardianName;
  late final TextEditingController phone;
  late DateTime? birthDate;
  late String courseId;
  String? photoUrl;
  bool saving = false;
  bool pickingPhoto = false;

  @override
  void initState() {
    super.initState();
    firstNames = TextEditingController(text: widget.student?.firstNames);
    lastNames = TextEditingController(text: widget.student?.lastNames);
    document = TextEditingController(text: widget.student?.documentNumber);
    guardianName = TextEditingController(text: widget.student?.guardianName);
    phone = TextEditingController(text: widget.student?.guardianPhone);
    birthDate = widget.student?.birthDate;
    photoUrl = widget.student?.photoUrl;
    courseId = widget.student?.course?.id ?? widget.courses.first.id;
  }

  @override
  void dispose() {
    firstNames.dispose();
    lastNames.dispose();
    document.dispose();
    guardianName.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: AppDialogHeader(
      title: widget.student == null
          ? 'Registrar estudiante'
          : 'Editar estudiante',
      subtitle: 'Identificación, responsable y asignación académica',
    ),
    content: SizedBox(
      width: 720,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              PersonPhotoField(
                photoUrl: photoUrl,
                busy: pickingPhoto,
                onPick: _pickPhoto,
                onRemove: photoUrl == null
                    ? null
                    : () => setState(() => photoUrl = null),
              ),
              const SizedBox(height: 18),
              const _DialogSectionTitle(
                title: 'Datos del estudiante',
                icon: LucideIcons.userRound,
              ),
              const SizedBox(height: 10),
              _DialogFieldPair(
                first: TextFormField(
                  key: const ValueKey('student_first_names'),
                  controller: firstNames,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    SchoolFormValidators.personNameFormatter,
                    SchoolFormValidators.uppercaseFormatter,
                  ],
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Nombres'),
                  validator: (value) => SchoolFormValidators.personName(
                    value,
                    label: 'los nombres',
                  ),
                ),
                second: TextFormField(
                  key: const ValueKey('student_last_names'),
                  controller: lastNames,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    SchoolFormValidators.personNameFormatter,
                    SchoolFormValidators.uppercaseFormatter,
                  ],
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                  validator: (value) => SchoolFormValidators.personName(
                    value,
                    label: 'los apellidos',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _DialogFieldPair(
                first: TextFormField(
                  controller: document,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [SchoolFormValidators.uppercaseFormatter],
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'Documento de identidad',
                    hintText: 'Opcional',
                  ),
                  validator: SchoolFormValidators.document,
                ),
                second: FormField<DateTime>(
                  initialValue: birthDate,
                  validator: (value) => value == null
                      ? 'Selecciona la fecha de nacimiento.'
                      : null,
                  builder: (field) => InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _selectBirthDate(field),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha de nacimiento',
                        errorText: field.errorText,
                        suffixIcon: const Icon(
                          LucideIcons.calendarDays,
                          size: 18,
                        ),
                      ),
                      child: Text(
                        birthDate == null
                            ? 'Seleccionar fecha'
                            : DateFormat('dd/MM/yyyy').format(birthDate!),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _DialogSectionTitle(
                title: 'Responsable y matrícula',
                icon: LucideIcons.usersRound,
              ),
              const SizedBox(height: 10),
              _DialogFieldPair(
                first: TextFormField(
                  controller: guardianName,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    SchoolFormValidators.personNameFormatter,
                    SchoolFormValidators.uppercaseFormatter,
                  ],
                  maxLength: 180,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del tutor',
                  ),
                  validator: (value) => SchoolFormValidators.personName(
                    value,
                    label: 'el nombre del tutor',
                  ),
                ),
                second: TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono del tutor',
                    hintText: 'Ej. 71234567',
                  ),
                  validator: (value) =>
                      SchoolFormValidators.phone(value, label: 'teléfono'),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: courseId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Curso actual',
                  prefixIcon: Icon(LucideIcons.school, size: 18),
                ),
                items: widget.courses
                    .map(
                      (course) => DropdownMenuItem(
                        value: course.id,
                        child: Text(course.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => courseId = value ?? courseId,
              ),
              if (widget.student != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Código institucional: ${widget.student!.studentCode}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
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
          widget.student == null ? 'Registrar estudiante' : 'Guardar cambios',
        ),
      ),
    ],
  );

  Future<void> _selectBirthDate(FormFieldState<DateTime> field) async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(today.year - 10),
      firstDate: DateTime(today.year - 25),
      lastDate: DateTime(today.year - 3),
      helpText: 'Fecha de nacimiento',
    );
    if (selected == null) return;
    setState(() => birthDate = selected);
    field.didChange(selected);
  }

  Future<void> _pickPhoto() async {
    if (pickingPhoto) return;
    setState(() => pickingPhoto = true);
    try {
      final source = await PersonImagePicker.pick();
      if (source == null || !mounted) return;
      final selected = await showPersonImageCropDialog(context, source: source);
      if (selected != null && mounted) setState(() => photoUrl = selected);
    } on PersonImageException catch (error) {
      if (mounted) {
        await showAppErrorDialog(
          context,
          title: 'No se pudo cargar la fotografía',
          message: error.message,
        );
      }
    } finally {
      if (mounted) setState(() => pickingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate() || birthDate == null) return;
    setState(() => saving = true);
    final result = await widget.onSave(
      StudentDraft(
        firstNames: SchoolFormValidators.normalizeUpper(firstNames.text),
        lastNames: SchoolFormValidators.normalizeUpper(lastNames.text),
        documentNumber: SchoolFormValidators.normalizeUpper(document.text),
        birthDate: birthDate!,
        guardianName: SchoolFormValidators.normalizeUpper(guardianName.text),
        guardianPhone: SchoolFormValidators.normalizeText(phone.text),
        photoUrl: photoUrl,
        courseId: courseId,
      ),
    );
    if (mounted && result) Navigator.pop(context, true);
    if (mounted && !result) {
      setState(() => saving = false);
      await showAppErrorDialog(
        context,
        title: 'No se pudo guardar al estudiante',
        message:
            widget.errorMessage() ?? 'Revisa los datos e intenta nuevamente.',
      );
    }
  }
}

class _DialogFieldPair extends StatelessWidget {
  const _DialogFieldPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 560
        ? Column(children: [first, const SizedBox(height: 10), second])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 12),
              Expanded(child: second),
            ],
          ),
  );
}

class _DialogSectionTitle extends StatelessWidget {
  const _DialogSectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.navy),
      const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(width: 10),
      const Expanded(child: Divider()),
    ],
  );
}

class _EmptyPeople extends StatelessWidget {
  const _EmptyPeople({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 36, color: AppColors.inkMuted),
        const SizedBox(height: 10),
        Text(label),
      ],
    ),
  );
}
