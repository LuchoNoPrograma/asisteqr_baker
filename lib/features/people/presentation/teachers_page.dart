import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/app_data_table.dart';
import 'package:asisteqr_baker/core/widgets/app_dialog_header.dart';
import 'package:asisteqr_baker/core/widgets/app_feedback.dart';
import 'package:asisteqr_baker/core/validation/school_form_validators.dart';
import 'package:asisteqr_baker/features/people/application/person_image_picker.dart';
import 'package:asisteqr_baker/features/people/domain/people_models.dart';
import 'package:asisteqr_baker/features/people/presentation/person_image_crop_dialog.dart';
import 'package:asisteqr_baker/features/people/presentation/person_photo_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TeachersPage extends ConsumerWidget {
  const TeachersPage({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    TeacherEntry? teacher,
  ]) async {
    final model = ref.read(teachersViewModelProvider);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _TeacherDialog(
        teacher: teacher,
        courses: model.courses,
        onSave: (draft) => model.save(draft, current: teacher),
        errorMessage: model.takeError,
      ),
    );
    if (saved == true && context.mounted) {
      showAppSuccess(
        context,
        teacher == null
            ? 'Docente registrado correctamente.'
            : 'Docente actualizado correctamente.',
      );
    }
  }

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    TeacherEntry teacher,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppDialogHeader(title: 'Inactivar docente'),
        content: Text('Se inactivará a ${teacher.fullName}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            icon: const Icon(LucideIcons.userRoundX, size: 17),
            label: const Text('Inactivar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final model = ref.read(teachersViewModelProvider);
      final saved = await model.deactivate(teacher);
      if (!context.mounted) return;
      if (saved) {
        showAppSuccess(context, 'Docente inactivado correctamente.');
      } else {
        await showAppErrorDialog(
          context,
          title: 'No se pudo inactivar al docente',
          message: model.takeError() ?? 'Intenta nuevamente.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(teachersViewModelProvider);
    final canManage = ref.watch(
      sessionViewModelProvider.select(
        (session) => session.user?.isAdministrator == true,
      ),
    );
    return AdaptiveShell(
      location: '/docentes',
      title: 'Docentes',
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
                                'Docentes',
                                style: wide
                                    ? Theme.of(context).textTheme.headlineMedium
                                    : Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${model.teachers.length} registros',
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
                            icon: const Icon(
                              LucideIcons.userRoundPlus,
                              size: 18,
                            ),
                            label: Text(wide ? 'Nuevo docente' : 'Nuevo'),
                          ),
                      ],
                    ),
                    if (!wide) ...[
                      const SizedBox(height: 14),
                      TextField(
                        onChanged: model.search,
                        decoration: const InputDecoration(
                          hintText: 'Buscar por nombre, documento o correo',
                          prefixIcon: Icon(LucideIcons.search, size: 18),
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
                child: model.teachers.isEmpty && !model.loading
                    ? const _EmptyTeachers()
                    : wide
                    ? _TeachersTable(
                        teachers: model.teachers,
                        canManage: canManage,
                        onEdit: (item) => _edit(context, ref, item),
                        onDeactivate: (item) => _deactivate(context, ref, item),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                        itemCount: model.teachers.length,
                        itemBuilder: (context, index) {
                          final teacher = model.teachers[index];
                          return _TeacherTile(
                            teacher: teacher,
                            canManage: canManage,
                            onEdit: () => _edit(context, ref, teacher),
                            onDeactivate: () =>
                                _deactivate(context, ref, teacher),
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

class _TeachersTable extends StatelessWidget {
  const _TeachersTable({
    required this.teachers,
    required this.canManage,
    required this.onEdit,
    required this.onDeactivate,
  });
  final List<TeacherEntry> teachers;
  final bool canManage;
  final ValueChanged<TeacherEntry> onEdit;
  final ValueChanged<TeacherEntry> onDeactivate;

  @override
  Widget build(BuildContext context) {
    final specialties =
        teachers
            .map((teacher) => teacher.specialty)
            .where((specialty) => specialty.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final courses =
        teachers
            .expand((teacher) => teacher.courses)
            .map((course) => course.name)
            .toSet()
            .toList()
          ..sort();
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      child: AppDataTable<TeacherEntry>(
        items: teachers,
        searchHint: 'Buscar docente, especialidad o contacto',
        searchText: (teacher) => [
          teacher.teacherCode,
          teacher.fullName,
          teacher.specialty,
          teacher.email,
          teacher.phone,
          teacher.status,
          ...teacher.courses.map((course) => course.name),
        ].whereType<Object>().join(' '),
        filters: [
          AppDataFilter(
            label: 'Estado',
            options: [
              AppDataFilterOption(
                label: 'Activos',
                matches: (teacher) => teacher.status == 'ACTIVO',
              ),
              AppDataFilterOption(
                label: 'Inactivos',
                matches: (teacher) => teacher.status != 'ACTIVO',
              ),
            ],
          ),
          AppDataFilter(
            label: 'Curso',
            options: [
              for (final course in courses)
                AppDataFilterOption(
                  label: course,
                  matches: (teacher) =>
                      teacher.courses.any((item) => item.name == course),
                ),
            ],
          ),
          AppDataFilter(
            label: 'Especialidad',
            options: [
              for (final specialty in specialties)
                AppDataFilterOption(
                  label: specialty,
                  matches: (teacher) => teacher.specialty == specialty,
                ),
            ],
          ),
        ],
        columnSpacing: 28,
        columns: [
          AppDataColumn(
            label: 'COD',
            compare: (first, second) =>
                first.teacherCode.compareTo(second.teacherCode),
            cellBuilder: (context, teacher) => Text(
              teacher.teacherCode.toString(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          AppDataColumn(
            label: 'Docente',
            compare: (first, second) =>
                first.fullName.compareTo(second.fullName),
            cellBuilder: (context, teacher) => Row(
              children: [
                PersonAvatar(
                  photoUrl: teacher.photoUrl,
                  fallback: teacher.firstNames.characters.first,
                  size: 34,
                ),
                const SizedBox(width: 9),
                Text(
                  teacher.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          AppDataColumn(
            label: 'Especialidad',
            compare: (first, second) =>
                first.specialty.compareTo(second.specialty),
            cellBuilder: (context, teacher) => Text(teacher.specialty),
          ),
          AppDataColumn(
            label: 'Teléfono',
            cellBuilder: (context, teacher) => Text(teacher.phone ?? '—'),
          ),
          AppDataColumn(
            label: 'Cursos',
            cellBuilder: (context, teacher) => Text(
              teacher.courses.isEmpty
                  ? 'Sin asignación'
                  : teacher.courses.map((item) => item.name).join(', '),
            ),
          ),
          AppDataColumn(
            label: 'Estado',
            compare: (first, second) => first.status.compareTo(second.status),
            cellBuilder: (context, teacher) =>
                _TeacherStatus(active: teacher.status == 'ACTIVO'),
          ),
          if (canManage)
            AppDataColumn(
              label: 'Acciones',
              cellBuilder: (context, teacher) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: () => onEdit(teacher),
                    icon: const Icon(LucideIcons.pencil, size: 17),
                  ),
                  IconButton(
                    tooltip: 'Inactivar',
                    onPressed: teacher.status == 'ACTIVO'
                        ? () => onDeactivate(teacher)
                        : null,
                    icon: const Icon(LucideIcons.userRoundX, size: 17),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TeacherTile extends StatelessWidget {
  const _TeacherTile({
    required this.teacher,
    required this.canManage,
    required this.onEdit,
    required this.onDeactivate,
  });
  final TeacherEntry teacher;
  final bool canManage;
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
          photoUrl: teacher.photoUrl,
          fallback: teacher.firstNames.characters.first,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teacher.fullName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                teacher.specialty,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (teacher.phone?.isNotEmpty == true)
                Text(
                  teacher.phone!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        _TeacherStatus(active: teacher.status == 'ACTIVO'),
        if (canManage)
          PopupMenuButton<String>(
            onSelected: (value) => value == 'edit' ? onEdit() : onDeactivate(),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              if (teacher.status == 'ACTIVO')
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Text('Inactivar'),
                ),
            ],
          ),
      ],
    ),
  );
}

class _TeacherDialog extends StatefulWidget {
  const _TeacherDialog({
    required this.courses,
    required this.onSave,
    required this.errorMessage,
    this.teacher,
  });

  final TeacherEntry? teacher;
  final List<CourseOption> courses;
  final Future<bool> Function(TeacherDraft) onSave;
  final String? Function() errorMessage;

  @override
  State<_TeacherDialog> createState() => _TeacherDialogState();
}

class _TeacherDialogState extends State<_TeacherDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController firstNames;
  late final TextEditingController lastNames;
  late final TextEditingController document;
  late final TextEditingController specialty;
  late final TextEditingController email;
  late final TextEditingController phone;
  late final Set<String> courseIds;
  String? photoUrl;
  bool saving = false;
  bool pickingPhoto = false;

  @override
  void initState() {
    super.initState();
    firstNames = TextEditingController(text: widget.teacher?.firstNames);
    lastNames = TextEditingController(text: widget.teacher?.lastNames);
    document = TextEditingController(text: widget.teacher?.documentNumber);
    specialty = TextEditingController(text: widget.teacher?.specialty);
    email = TextEditingController(text: widget.teacher?.email);
    phone = TextEditingController(text: widget.teacher?.phone);
    photoUrl = widget.teacher?.photoUrl;
    courseIds =
        widget.teacher?.courses.map((item) => item.id).toSet() ?? <String>{};
  }

  @override
  void dispose() {
    firstNames.dispose();
    lastNames.dispose();
    document.dispose();
    specialty.dispose();
    email.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: AppDialogHeader(
      title: widget.teacher == null ? 'Registrar docente' : 'Editar docente',
      subtitle: 'Identidad profesional y responsabilidad académica',
    ),
    content: SizedBox(
      width: 760,
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
              const _TeacherSectionTitle(
                title: 'Datos personales',
                icon: LucideIcons.userRound,
              ),
              const SizedBox(height: 10),
              _TeacherFieldPair(
                first: TextFormField(
                  key: const ValueKey('teacher_first_names'),
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
                  key: const ValueKey('teacher_last_names'),
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
              _TeacherFieldPair(
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
                second: TextFormField(
                  key: const ValueKey('teacher_specialty'),
                  controller: specialty,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [SchoolFormValidators.uppercaseFormatter],
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Especialidad o área',
                    hintText: 'Ej. Matemática y Física',
                  ),
                  validator: (value) => SchoolFormValidators.requiredText(
                    value,
                    label: 'la especialidad',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _TeacherSectionTitle(
                title: 'Contacto institucional',
                icon: LucideIcons.contactRound,
              ),
              const SizedBox(height: 10),
              _TeacherFieldPair(
                first: TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  maxLength: 180,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    hintText: 'Opcional',
                  ),
                  validator: SchoolFormValidators.email,
                ),
                second: TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    hintText: 'Ej. 70112233',
                  ),
                  validator: (value) =>
                      SchoolFormValidators.phone(value, label: 'teléfono'),
                ),
              ),
              const SizedBox(height: 18),
              const _TeacherSectionTitle(
                title: 'Cursos bajo responsabilidad',
                icon: LucideIcons.school,
              ),
              const SizedBox(height: 6),
              Text(
                'Selecciona los cursos en los que el docente registra asistencia.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.courses
                      .map(
                        (course) => FilterChip(
                          label: Text(course.name),
                          selected: courseIds.contains(course.id),
                          onSelected: (selected) => setState(
                            () => selected
                                ? courseIds.add(course.id)
                                : courseIds.remove(course.id),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              if (widget.teacher != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Código docente: ${widget.teacher!.teacherCode}',
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
          widget.teacher == null ? 'Registrar docente' : 'Guardar cambios',
        ),
      ),
    ],
  );

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
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final result = await widget.onSave(
      TeacherDraft(
        firstNames: SchoolFormValidators.normalizeUpper(firstNames.text),
        lastNames: SchoolFormValidators.normalizeUpper(lastNames.text),
        documentNumber: SchoolFormValidators.normalizeUpper(document.text),
        specialty: SchoolFormValidators.normalizeUpper(specialty.text),
        email: SchoolFormValidators.normalizeLower(email.text),
        phone: SchoolFormValidators.normalizeText(phone.text),
        photoUrl: photoUrl,
        courseIds: courseIds.toList(),
      ),
    );
    if (mounted && result) Navigator.pop(context, true);
    if (mounted && !result) {
      setState(() => saving = false);
      await showAppErrorDialog(
        context,
        title: 'No se pudo guardar al docente',
        message:
            widget.errorMessage() ?? 'Revisa los datos e intenta nuevamente.',
      );
    }
  }
}

class _TeacherFieldPair extends StatelessWidget {
  const _TeacherFieldPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 580
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

class _TeacherSectionTitle extends StatelessWidget {
  const _TeacherSectionTitle({required this.title, required this.icon});

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

class _TeacherStatus extends StatelessWidget {
  const _TeacherStatus({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: active ? AppColors.greenSoft : AppColors.redSoft,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      active ? 'Activo' : 'Inactivo',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: active ? AppColors.green : AppColors.red,
      ),
    ),
  );
}

class _EmptyTeachers extends StatelessWidget {
  const _EmptyTeachers();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.presentation, size: 36, color: AppColors.inkMuted),
        SizedBox(height: 10),
        Text('No hay docentes registrados'),
      ],
    ),
  );
}
