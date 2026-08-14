import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/app_data_table.dart';
import 'package:asisteqr_baker/core/widgets/app_dialog_header.dart';
import 'package:asisteqr_baker/core/widgets/app_table_actions_menu.dart';
import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ScheduleSubjectsPanel extends StatelessWidget {
  const ScheduleSubjectsPanel({
    super.key,
    required this.subjects,
    required this.canManage,
    required this.busy,
    required this.onCreate,
    required this.onEdit,
    required this.onDeactivate,
  });

  final List<ScheduleSubject> subjects;
  final bool canManage;
  final bool busy;
  final VoidCallback onCreate;
  final ValueChanged<ScheduleSubject> onEdit;
  final ValueChanged<ScheduleSubject> onDeactivate;

  @override
  Widget build(BuildContext context) => _CatalogLayout(
    title: 'Materias',
    countLabel: '${subjects.length} activas',
    actionLabel: 'Nueva materia',
    actionIcon: LucideIcons.bookPlus,
    showAction: canManage,
    actionEnabled: canManage && !busy,
    onAction: onCreate,
    desktopBody: AppDataTable<ScheduleSubject>(
      items: subjects,
      searchHint: 'Buscar materia',
      searchText: (item) => item.name,
      emptyMessage: 'No hay materias activas.',
      columns: [
        AppDataColumn(
          label: 'Materia',
          compare: (left, right) => left.name.compareTo(right.name),
          cellBuilder: (context, item) => _CatalogIdentity(
            icon: LucideIcons.bookOpen,
            title: item.name,
            subtitle: 'Catálogo académico',
          ),
        ),
        if (canManage)
          AppDataColumn(
            label: 'Acciones',
            columnWidth: const FixedColumnWidth(92),
            cellBuilder: (context, item) => AppTableActionsMenu(
              tooltip: 'Acciones de la materia',
              actions: [
                AppTableAction(
                  label: 'Editar',
                  icon: LucideIcons.pencil,
                  onSelected: () => onEdit(item),
                ),
                AppTableAction.deactivate(onSelected: () => onDeactivate(item)),
              ],
            ),
          ),
      ],
    ),
    mobileBody: subjects.isEmpty
        ? const _EmptyCatalog(
            icon: LucideIcons.bookOpen,
            message: 'No hay materias activas.',
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            itemCount: subjects.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = subjects[index];
              return _CatalogTile(
                icon: LucideIcons.bookOpen,
                title: item.name,
                actions: canManage
                    ? AppTableActionsMenu(
                        tooltip: 'Acciones de la materia',
                        actions: [
                          AppTableAction(
                            label: 'Editar',
                            icon: LucideIcons.pencil,
                            onSelected: () => onEdit(item),
                          ),
                          AppTableAction.deactivate(
                            onSelected: () => onDeactivate(item),
                          ),
                        ],
                      )
                    : null,
              );
            },
          ),
  );
}

class ScheduleClassroomsPanel extends StatelessWidget {
  const ScheduleClassroomsPanel({
    super.key,
    required this.classrooms,
    required this.canManage,
    required this.busy,
    required this.onCreate,
    required this.onEdit,
    required this.onDeactivate,
  });

  final List<ScheduleClassroom> classrooms;
  final bool canManage;
  final bool busy;
  final VoidCallback onCreate;
  final ValueChanged<ScheduleClassroom> onEdit;
  final ValueChanged<ScheduleClassroom> onDeactivate;

  @override
  Widget build(BuildContext context) {
    final locations =
        classrooms
            .map((item) => item.location?.trim())
            .whereType<String>()
            .where((location) => location.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return _CatalogLayout(
      title: 'Aulas',
      countLabel: '${classrooms.length} activas',
      actionLabel: 'Nueva aula',
      actionIcon: LucideIcons.plus,
      showAction: canManage,
      actionEnabled: canManage && !busy,
      onAction: onCreate,
      desktopBody: AppDataTable<ScheduleClassroom>(
        items: classrooms,
        searchHint: 'Buscar aula o ubicación',
        searchText: (item) => [
          item.name,
          item.location,
          item.capacity,
        ].whereType<Object>().join(' '),
        emptyMessage: 'No hay aulas activas.',
        filters: [
          if (locations.isNotEmpty)
            AppDataFilter(
              label: 'Ubicación',
              options: [
                for (final location in locations)
                  AppDataFilterOption(
                    label: location,
                    matches: (item) => item.location?.trim() == location,
                  ),
              ],
            ),
        ],
        columns: [
          AppDataColumn(
            label: 'Aula',
            compare: (left, right) => left.name.compareTo(right.name),
            cellBuilder: (context, item) => _CatalogIdentity(
              icon: LucideIcons.doorOpen,
              title: item.name,
              subtitle: item.location?.isNotEmpty == true
                  ? item.location!
                  : 'Espacio académico',
            ),
          ),
          AppDataColumn(
            label: 'Capacidad',
            numeric: true,
            compare: (left, right) =>
                (left.capacity ?? 0).compareTo(right.capacity ?? 0),
            cellBuilder: (context, item) =>
                Text(item.capacity == null ? '—' : '${item.capacity}'),
          ),
          AppDataColumn(
            label: 'Ubicación',
            cellBuilder: (context, item) => Text(item.location ?? '—'),
          ),
          if (canManage)
            AppDataColumn(
              label: 'Acciones',
              columnWidth: const FixedColumnWidth(92),
              cellBuilder: (context, item) => AppTableActionsMenu(
                tooltip: 'Acciones del aula',
                actions: [
                  AppTableAction(
                    label: 'Editar',
                    icon: LucideIcons.pencil,
                    onSelected: () => onEdit(item),
                  ),
                  AppTableAction.deactivate(
                    onSelected: () => onDeactivate(item),
                  ),
                ],
              ),
            ),
        ],
      ),
      mobileBody: classrooms.isEmpty
          ? const _EmptyCatalog(
              icon: LucideIcons.doorOpen,
              message: 'No hay aulas activas.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              itemCount: classrooms.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = classrooms[index];
                final details = [
                  if (item.capacity != null) 'Capacidad ${item.capacity}',
                  if (item.location?.isNotEmpty == true) item.location!,
                ].join(' · ');
                return _CatalogTile(
                  icon: LucideIcons.doorOpen,
                  title: item.name,
                  subtitle: details.isEmpty ? null : details,
                  actions: canManage
                      ? AppTableActionsMenu(
                          tooltip: 'Acciones del aula',
                          actions: [
                            AppTableAction(
                              label: 'Editar',
                              icon: LucideIcons.pencil,
                              onSelected: () => onEdit(item),
                            ),
                            AppTableAction.deactivate(
                              onSelected: () => onDeactivate(item),
                            ),
                          ],
                        )
                      : null,
                );
              },
            ),
    );
  }
}

class ScheduleSubjectDialog extends StatefulWidget {
  const ScheduleSubjectDialog({super.key, this.current});

  final ScheduleSubject? current;

  @override
  State<ScheduleSubjectDialog> createState() => _ScheduleSubjectDialogState();
}

class _ScheduleSubjectDialogState extends State<ScheduleSubjectDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name = TextEditingController(
    text: widget.current?.name,
  );

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: AppDialogHeader(
      title: widget.current == null ? 'Nueva materia' : 'Editar materia',
      subtitle: 'Catálogo académico',
    ),
    content: SizedBox(
      width: 460,
      child: Form(
        key: formKey,
        child: TextFormField(
          controller: name,
          autofocus: true,
          maxLength: 120,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre de la materia',
            prefixIcon: Icon(LucideIcons.bookOpen, size: 18),
          ),
          validator: (value) => (value?.trim().length ?? 0) < 2
              ? 'Ingresa un nombre válido.'
              : null,
          onFieldSubmitted: (_) => _submit(),
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

  void _submit() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(context, ScheduleSubjectDraft(name: name.text.trim()));
  }
}

class ScheduleClassroomDialog extends StatefulWidget {
  const ScheduleClassroomDialog({super.key, this.current});

  final ScheduleClassroom? current;

  @override
  State<ScheduleClassroomDialog> createState() =>
      _ScheduleClassroomDialogState();
}

class _ScheduleClassroomDialogState extends State<ScheduleClassroomDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name = TextEditingController(
    text: widget.current?.name,
  );
  late final TextEditingController capacity = TextEditingController(
    text: widget.current?.capacity?.toString(),
  );
  late final TextEditingController location = TextEditingController(
    text: widget.current?.location,
  );

  @override
  void dispose() {
    name.dispose();
    capacity.dispose();
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: AppDialogHeader(
      title: widget.current == null ? 'Nueva aula' : 'Editar aula',
      subtitle: 'Espacio físico para clases',
    ),
    content: SizedBox(
      width: 620,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogFieldRow(
                children: [
                  TextFormField(
                    controller: name,
                    autofocus: true,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? 'Ingresa un nombre válido.'
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _DialogFieldRow(
                children: [
                  TextFormField(
                    controller: capacity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Capacidad',
                      hintText: 'Opcional',
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if ((value?.trim().isNotEmpty ?? false) &&
                          (parsed == null || parsed < 1 || parsed > 200)) {
                        return 'Usa un valor entre 1 y 200.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _DialogFieldRow(
                children: [
                  TextFormField(
                    controller: location,
                    maxLength: 160,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación',
                      hintText: 'Opcional',
                    ),
                  ),
                ],
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

  void _submit() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ScheduleClassroomDraft(
        name: name.text.trim(),
        capacity: int.tryParse(capacity.text.trim()),
        location: location.text.trim(),
      ),
    );
  }
}

class _CatalogLayout extends StatelessWidget {
  const _CatalogLayout({
    required this.title,
    required this.countLabel,
    required this.actionLabel,
    required this.actionIcon,
    required this.showAction,
    required this.actionEnabled,
    required this.onAction,
    required this.desktopBody,
    required this.mobileBody,
  });

  final String title;
  final String countLabel;
  final String actionLabel;
  final IconData actionIcon;
  final bool showAction;
  final bool actionEnabled;
  final VoidCallback onAction;
  final Widget desktopBody;
  final Widget mobileBody;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 700;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              desktop ? 28 : 14,
              desktop ? 22 : 14,
              desktop ? 28 : 14,
              14,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: desktop
                            ? Theme.of(context).textTheme.headlineSmall
                            : Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        countLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (showAction)
                  FilledButton.icon(
                    onPressed: actionEnabled ? onAction : null,
                    icon: Icon(actionIcon, size: 17),
                    label: Text(desktop ? actionLabel : 'Nuevo'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: desktop
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                    child: desktopBody,
                  )
                : mobileBody,
          ),
        ],
      );
    },
  );
}

class _CatalogIdentity extends StatelessWidget {
  const _CatalogIdentity({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: AppColors.navy),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ],
  );
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AppColors.inkMuted),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actions,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? actions;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.navy),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        ?actions,
      ],
    ),
  );
}

class _DialogFieldRow extends StatelessWidget {
  const _DialogFieldRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 520
        ? Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) const SizedBox(height: 10),
              ],
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                Expanded(child: children[index]),
                if (index < children.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
  );
}
