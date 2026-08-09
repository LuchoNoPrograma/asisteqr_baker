import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/app_feedback.dart';
import 'package:asisteqr_baker/core/widgets/app_person_image.dart';
import 'package:asisteqr_baker/features/credentials/data/credential_pdf_service.dart';
import 'package:asisteqr_baker/features/credentials/domain/credential_models.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CredentialsPage extends ConsumerStatefulWidget {
  const CredentialsPage({super.key});

  @override
  ConsumerState<CredentialsPage> createState() => _CredentialsPageState();
}

class _CredentialsPageState extends ConsumerState<CredentialsPage> {
  final _searchController = TextEditingController();
  final _pdfService = CredentialPdfService();
  List<CredentialStudent>? _students;
  final Set<String> _selectedIds = {};
  String? _course;
  String _query = '';
  CredentialPrintMode _printMode = CredentialPrintMode.doubleSided;
  String? _previewStudentId;
  bool _showBack = false;
  bool _exporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final students = await ref
          .read(credentialRepositoryProvider)
          .getStudents();
      if (!mounted) return;
      setState(() {
        _students = students;
        _error = null;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _error = 'No pudimos cargar los estudiantes.');
    }
  }

  List<CredentialStudent> get _filtered {
    final query = _query.trim().toLowerCase();
    return (_students ?? []).where((student) {
      final matchesCourse = _course == null || student.course == _course;
      final matchesQuery =
          query.isEmpty ||
          student.fullName.toLowerCase().contains(query) ||
          student.code.toLowerCase().contains(query);
      return matchesCourse && matchesQuery;
    }).toList();
  }

  List<CredentialStudent> get _selected => (_students ?? [])
      .where((student) => _selectedIds.contains(student.id))
      .toList();

  List<String> get _courses {
    final values = (_students ?? [])
        .map((student) => student.course)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  CredentialStudent? get _previewStudent {
    for (final student in _students ?? <CredentialStudent>[]) {
      if (student.id == _previewStudentId) return student;
    }
    final selected = _selected;
    if (selected.isNotEmpty) return selected.first;
    final filtered = _filtered;
    return filtered.isEmpty ? null : filtered.first;
  }

  void _toggleVisible(bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedIds.addAll(_filtered.map((student) => student.id));
        if (_filtered.isNotEmpty) {
          _previewStudentId ??= _filtered.first.id;
        }
      } else {
        _selectedIds.removeAll(_filtered.map((student) => student.id));
      }
    });
  }

  void _toggleStudent(CredentialStudent student) {
    setState(() {
      _previewStudentId = student.id;
      if (_selectedIds.contains(student.id)) {
        _selectedIds.remove(student.id);
      } else {
        _selectedIds.add(student.id);
      }
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

  Future<void> _export({required bool print}) async {
    final selected = _selected;
    if (selected.isEmpty) {
      await showAppWarning(
        context,
        title: 'Falta seleccionar estudiantes',
        message: 'Selecciona al menos un estudiante para preparar el PDF.',
      );
      return;
    }
    setState(() => _exporting = true);
    try {
      final bytes = await _pdfService.build(
        students: selected,
        mode: _printMode,
      );
      if (print) {
        await Printing.layoutPdf(
          name: 'Credenciales AsisteQR Baker',
          onLayout: (_) async => bytes,
        );
        if (mounted) {
          await showAppSuccess(
            context,
            'Se prepararon ${selected.length} credenciales para imprimir.',
            title: 'Documento preparado',
          );
        }
      } else {
        await FileSaver.instance.saveFile(
          name: 'credenciales_asisteqr_${selected.length}',
          bytes: bytes,
          fileExtension: 'pdf',
          mimeType: MimeType.pdf,
        );
        if (mounted) {
          await showAppSuccess(
            context,
            'El PDF contiene ${selected.length} credenciales.',
            title: 'PDF descargado',
          );
        }
      }
    } on Object {
      if (mounted) {
        await showAppErrorDialog(
          context,
          title: 'No se pudo generar el PDF',
          message: 'Revisa la conexión e intenta nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveShell(
      location: '/credenciales',
      title: 'Credenciales',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          return Padding(
            padding: EdgeInsets.all(wide ? 20 : 14),
            child: wide ? _desktopWorkspace() : _mobileWorkspace(),
          );
        },
      ),
    );
  }

  Widget _desktopWorkspace() => LayoutBuilder(
    builder: (context, constraints) {
      final previewWidth = constraints.maxWidth >= 1080 ? 410.0 : 350.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pageHeader(compact: false),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _filters(),
                      const SizedBox(height: 12),
                      Expanded(child: _studentPanel()),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                SizedBox(width: previewWidth, child: _previewPanel()),
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget _mobileWorkspace() => ListView(
    children: [
      _pageHeader(compact: true),
      const SizedBox(height: 16),
      _filters(),
      const SizedBox(height: 12),
      SizedBox(
        height: (MediaQuery.sizeOf(context).height * .46).clamp(260.0, 420.0),
        child: _studentPanel(showClearSelection: false),
      ),
      const SizedBox(height: 12),
      _selectionSummary(),
      const SizedBox(height: 12),
      _previewPanel(),
      const SizedBox(height: 20),
    ],
  );

  Widget _pageHeader({required bool compact}) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Credenciales estudiantiles',
              style: compact
                  ? Theme.of(context).textTheme.titleLarge
                  : Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 3),
            Text(
              'Selecciona estudiantes y prepara hojas A4 listas para imprimir.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      if (!compact)
        Text(
          _selectedIds.length == 1
              ? '1 seleccionado'
              : '${_selectedIds.length} seleccionados',
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
    ],
  );

  Widget _selectionSummary() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: const BoxDecoration(
      color: AppColors.blueSoft,
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    child: Row(
      children: [
        const Icon(LucideIcons.listChecks, size: 19, color: AppColors.navy),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _selectedIds.length == 1
                ? '1 estudiante seleccionado'
                : '${_selectedIds.length} estudiantes seleccionados',
            maxLines: 2,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (_selectedIds.isNotEmpty)
          TextButton(onPressed: _clearSelection, child: const Text('Limpiar')),
      ],
    ),
  );

  Widget _filters() => Container(
    padding: const EdgeInsets.all(12),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 500;
        final search = TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Buscar por nombre o código',
            prefixIcon: Icon(LucideIcons.search, size: 18),
            isDense: true,
          ),
        );
        final course = DropdownButtonFormField<String?>(
          initialValue: _course,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Curso',
            prefixIcon: Icon(LucideIcons.school, size: 18),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Todos los cursos'),
            ),
            for (final value in _courses)
              DropdownMenuItem(value: value, child: Text(value)),
          ],
          onChanged: (value) => setState(() => _course = value),
        );
        if (!wide) {
          return Column(children: [search, const SizedBox(height: 10), course]);
        }
        return Row(
          children: [
            Expanded(flex: 3, child: search),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: course),
          ],
        );
      },
    ),
  );

  Widget _studentPanel({bool showClearSelection = true}) {
    if (_error != null) {
      return _PanelMessage(
        icon: LucideIcons.cloudAlert,
        message: _error!,
        action: TextButton(onPressed: _load, child: const Text('Reintentar')),
      );
    }
    if (_students == null) {
      return const _PanelMessage(
        icon: LucideIcons.loaderCircle,
        message: 'Cargando estudiantes…',
      );
    }
    final visible = _filtered;
    final visibleSelectionCount = visible
        .where((student) => _selectedIds.contains(student.id))
        .length;
    final bool? selectionValue = visibleSelectionCount == 0
        ? false
        : visibleSelectionCount == visible.length
        ? true
        : null;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFFF1F4F7),
            child: Row(
              children: [
                Checkbox(
                  value: selectionValue,
                  tristate: true,
                  onChanged: visible.isEmpty ? null : _toggleVisible,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${visible.length} estudiantes',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        visibleSelectionCount == 1
                            ? '1 seleccionado en esta lista'
                            : '$visibleSelectionCount seleccionados en esta lista',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (showClearSelection && _selectedIds.isNotEmpty)
                  IconButton(
                    onPressed: _clearSelection,
                    tooltip: 'Limpiar selección',
                    icon: const Icon(LucideIcons.x, size: 18),
                  ),
              ],
            ),
          ),
          if (visible.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No hay estudiantes con estos filtros.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) => _studentRow(visible[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _studentRow(CredentialStudent student) {
    final selected = _selectedIds.contains(student.id);
    return Material(
      color: selected ? const Color(0xFFF4F8ED) : Colors.white,
      child: InkWell(
        onTap: () => _toggleStudent(student),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            return Container(
              constraints: const BoxConstraints(minHeight: 68),
              padding: EdgeInsets.fromLTRB(10, 8, compact ? 10 : 14, 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (_) => _toggleStudent(student),
                  ),
                  if (!compact) ...[
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.blueSoft,
                      foregroundColor: AppColors.navy,
                      child: Text(
                        student.initials,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          student.code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (compact)
                          Text(
                            student.course,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 10),
                    Flexible(
                      flex: 2,
                      child: Text(
                        student.course,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      LucideIcons.badgeCheck,
                      size: 18,
                      color: AppColors.green,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _previewPanel() {
    final student = _previewStudent;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 300;
                final title = const Text(
                  'Vista previa',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                );
                final sides = SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Anverso')),
                    ButtonSegment(value: true, label: Text('Reverso')),
                  ],
                  selected: {_showBack},
                  onSelectionChanged: (value) =>
                      setState(() => _showBack = value.first),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11)),
                  ),
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [title, const SizedBox(height: 10), sides],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: title),
                    sides,
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            if (student == null)
              const AspectRatio(
                aspectRatio: 85.6 / 54,
                child: ColoredBox(
                  color: Color(0xFFF1F4F7),
                  child: Center(child: Text('Selecciona un estudiante')),
                ),
              )
            else
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _showBack
                    ? _CredentialBackPreview(
                        key: const ValueKey('back'),
                        student: student,
                      )
                    : _CredentialFrontPreview(
                        key: const ValueKey('front'),
                        student: student,
                      ),
              ),
            const SizedBox(height: 18),
            const Text(
              'Plantilla de impresión',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<CredentialPrintMode>(
              initialValue: _printMode,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.layoutTemplate, size: 18),
                isDense: true,
              ),
              items: [
                for (final mode in CredentialPrintMode.values)
                  DropdownMenuItem(
                    value: mode,
                    child: Text(
                      mode.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _printMode = value);
              },
            ),
            const SizedBox(height: 10),
            const _PrintFact(
              icon: LucideIcons.files,
              text: '8 credenciales por hoja A4',
            ),
            const _PrintFact(
              icon: LucideIcons.ruler,
              text: 'Tamaño estándar 85,6 × 54 mm',
            ),
            const _PrintFact(
              icon: LucideIcons.rotateCcw,
              text: 'Reversos alineados para doble cara',
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _exporting || _selectedIds.isEmpty
                  ? null
                  : () => _export(print: false),
              icon: _exporting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.fileDown, size: 18),
              label: Text(
                _exporting
                    ? 'Generando PDF'
                    : 'Descargar ${_selectedIds.length} en PDF',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _exporting || _selectedIds.isEmpty
                  ? null
                  : () => _export(print: true),
              icon: const Icon(LucideIcons.printer, size: 18),
              label: const Text('Imprimir ahora'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CredentialFrontPreview extends StatelessWidget {
  const _CredentialFrontPreview({super.key, required this.student});
  final CredentialStudent student;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 85.6 / 54,
    child: MediaQuery.withNoTextScaling(
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: 428,
          height: 270,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F002045),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 52,
                  color: AppColors.navyDark,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Row(
                    children: [
                      _SchoolMark(),
                      SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UNIDAD EDUCATIVA ADVENTISTA BAKER',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'CREDENCIAL ESTUDIANTIL',
                              style: TextStyle(
                                color: Color(0xFF9AD75A),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: AspectRatio(
                            aspectRatio: .78,
                            child: AppPersonImage(
                              source: student.photoSource,
                              fallback: ColoredBox(
                                color: AppColors.blueSoft,
                                child: Center(
                                  child: Text(
                                    student.initials,
                                    style: const TextStyle(
                                      color: AppColors.navy,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _PreviewBrand(),
                              const Spacer(),
                              _PreviewField(
                                label: 'NOMBRE',
                                value: student.fullName,
                              ),
                              const SizedBox(height: 4),
                              _PreviewField(
                                label: 'CURSO',
                                value: student.course,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: _PreviewField(
                                      label: 'CÓDIGO',
                                      value: student.code,
                                    ),
                                  ),
                                  QrImageView(
                                    data: student.qrPayload,
                                    size: 45,
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 25,
                  color: AppColors.navyDark,
                  alignment: Alignment.center,
                  child: const Text(
                    'USO PERSONAL E INTRANSFERIBLE  ·  GESTIÓN 2026',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _CredentialBackPreview extends StatelessWidget {
  const _CredentialBackPreview({super.key, required this.student});
  final CredentialStudent student;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 85.6 / 54,
    child: MediaQuery.withNoTextScaling(
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: 428,
          height: 270,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F002045),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 46,
                  color: AppColors.navyDark,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'CONTROL DE ASISTENCIA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      _SchoolMark(compact: true),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.green),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: QrImageView(
                            data: student.qrPayload,
                            size: 112,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _PreviewField(
                                label: 'ESTUDIANTE',
                                value: student.fullName,
                              ),
                              const SizedBox(height: 8),
                              _PreviewField(
                                label: 'CURSO',
                                value: student.course,
                              ),
                              const SizedBox(height: 8),
                              _PreviewField(
                                label: 'CÓDIGO',
                                value: student.code,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(7),
                                color: AppColors.blueSoft,
                                child: const Text(
                                  'Presenta esta credencial al ingresar para registrar tu asistencia.',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 25,
                  color: AppColors.navyDark,
                  alignment: Alignment.center,
                  child: const Text(
                    'AsisteQR Baker  ·  Gestión 2026',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _PreviewField extends StatelessWidget {
  const _PreviewField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.inkMuted,
          fontSize: 7,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
    ],
  );
}

class _PreviewBrand extends StatelessWidget {
  const _PreviewBrand();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Icon(LucideIcons.qrCode, color: AppColors.navy, size: 18),
      SizedBox(width: 5),
      Text(
        'Asiste',
        style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
      ),
      Text(
        'QR',
        style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w800),
      ),
      Text(
        ' Baker',
        style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _SchoolMark extends StatelessWidget {
  const _SchoolMark({this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    width: compact ? 28 : 34,
    height: compact ? 28 : 34,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF9AD75A)),
      borderRadius: BorderRadius.circular(5),
    ),
    alignment: Alignment.center,
    child: Text(
      compact ? 'QR' : 'UE',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _PrintFact extends StatelessWidget {
  const _PrintFact({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage({required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    alignment: Alignment.center,
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.inkMuted),
        const SizedBox(height: 10),
        Text(message),
        ?action,
      ],
    ),
  );
}
