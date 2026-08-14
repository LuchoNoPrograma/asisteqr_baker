import 'dart:io';
import 'dart:typed_data';

import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/app_feedback.dart';
import 'package:asisteqr_baker/core/widgets/app_person_image.dart';
import 'package:asisteqr_baker/core/widgets/institution_mark.dart';
import 'package:asisteqr_baker/features/credentials/domain/credential_models.dart';
import 'package:asisteqr_baker/features/credentials/presentation/credentials_view_model.dart';
import 'package:file_saver/file_saver.dart';
import 'package:file_selector/file_selector.dart';
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
  bool _showBack = false;

  CredentialsViewModel get _model => ref.read(credentialsViewModelProvider);
  List<CredentialStudent> get _filtered => _model.filtered;
  List<CredentialStudent> get _selected => _model.selected;
  List<String> get _courses => _model.courses;
  CredentialStudent? get _previewStudent => _model.previewStudent;
  Set<String> get _selectedIds => _model.selectedIds;
  String? get _course => _model.course;
  CredentialPrintMode get _printMode => _model.printMode;
  bool get _exporting => _model.exporting;
  String? get _error => _model.error;
  CredentialsLoadStatus get _loadStatus => _model.loadStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() => _model.load();

  void _toggleVisible(bool? selected) => _model.toggleVisible(selected == true);

  void _toggleStudent(CredentialStudent student) =>
      _model.toggleStudent(student);

  void _clearSelection() => _model.clearSelection();

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
    try {
      final bytes = await _model.buildSelectedPdf();
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
        final fileName = 'credenciales_asisteqr_${selected.length}.pdf';
        final savedPath = await _savePdf(bytes, fileName);
        if (savedPath == null || !mounted) return;
        final action = await showSavedFileDialog(
          context,
          fileName: fileName,
          location: _savedLocationLabel(savedPath),
          canReveal: _canRevealSavedFile(savedPath),
        );
        if (!mounted) return;
        switch (action) {
          case SavedFileAction.preview:
            await _previewSavedPdf(bytes, fileName);
          case SavedFileAction.reveal:
            await _revealSavedFile(savedPath);
          case SavedFileAction.close:
            break;
        }
      }
    } on Object {
      if (mounted) {
        await showAppErrorDialog(
          context,
          title: 'No se pudo guardar el PDF',
          message:
              'Revisa la conexión, los permisos de la ubicación e intenta nuevamente.',
        );
      }
    }
  }

  Future<String?> _savePdf(Uint8List bytes, String fileName) async {
    if (Platform.isLinux || Platform.isWindows) {
      const pdfType = XTypeGroup(label: 'Documento PDF', extensions: ['pdf']);
      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: const [pdfType],
        confirmButtonText: 'Guardar',
      );
      if (location == null) return null;
      final file = XFile.fromData(
        bytes,
        mimeType: 'application/pdf',
        name: fileName,
      );
      await file.saveTo(location.path);
      return location.path;
    }

    return FileSaver.instance.saveAs(
      name: fileName.substring(0, fileName.length - 4),
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  String _savedLocationLabel(String path) {
    if (path.startsWith('/') || RegExp(r'^[A-Za-z]:\\').hasMatch(path)) {
      return path;
    }
    return 'Ubicación elegida en el dispositivo';
  }

  bool _canRevealSavedFile(String path) =>
      (Platform.isLinux || Platform.isWindows) && File(path).isAbsolute;

  Future<void> _previewSavedPdf(Uint8List bytes, String fileName) async {
    try {
      await Printing.layoutPdf(name: fileName, onLayout: (_) async => bytes);
    } on Object {
      if (!mounted) return;
      await showAppErrorDialog(
        context,
        title: 'El PDF ya está guardado',
        message: 'No se pudo abrir la vista previa en este dispositivo.',
      );
    }
  }

  Future<void> _revealSavedFile(String path) async {
    try {
      if (Platform.isLinux) {
        await Process.start('xdg-open', [
          File(path).parent.path,
        ], mode: ProcessStartMode.detached);
        return;
      }
      if (Platform.isWindows) {
        await Process.start('explorer.exe', [
          '/select,$path',
        ], mode: ProcessStartMode.detached);
      }
    } on Object {
      if (!mounted) return;
      await showAppErrorDialog(
        context,
        title: 'El PDF ya está guardado',
        message: 'No se pudo abrir la carpeta. Ubicación: $path',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(credentialsViewModelProvider);
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
          onChanged: _model.setQuery,
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
          onChanged: _model.setCourse,
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
    if (_loadStatus == CredentialsLoadStatus.failure) {
      return _PanelMessage(
        icon: LucideIcons.cloudAlert,
        message: _error ?? 'No pudimos cargar los estudiantes.',
        action: TextButton(onPressed: _load, child: const Text('Reintentar')),
      );
    }
    if (_loadStatus == CredentialsLoadStatus.loading) {
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
                if (value != null) _model.setPrintMode(value);
              },
            ),
            const SizedBox(height: 10),
            _PrintFact(
              icon: LucideIcons.files,
              text: _printMode == CredentialPrintMode.frontAndBack
                  ? 'Hasta 4 credenciales completas por hoja A4'
                  : 'Hasta 8 anversos por hoja A4',
            ),
            const _PrintFact(
              icon: LucideIcons.ruler,
              text: 'Tamaño estándar 85,6 × 54 mm',
            ),
            _PrintFact(
              icon: LucideIcons.rotateCcw,
              text: _printMode == CredentialPrintMode.frontAndBack
                  ? 'Anverso y reverso juntos, sin páginas separadas'
                  : 'Todos los seleccionados en un único PDF',
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
                    : 'Guardar ${_selectedIds.length} en PDF',
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
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/branding/credential-front-template.png',
                    fit: BoxFit.fill,
                  ),
                ),
                const _CredentialTemplateHeader(
                  subtitle: 'CREDENCIAL ESTUDIANTIL',
                ),
                Positioned(
                  left: 55,
                  top: 70,
                  width: 134,
                  height: 134,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF13A8DB),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1727C9),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
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
                  ),
                ),
                Positioned(
                  left: 202,
                  top: 62,
                  right: 16,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'IDENTIDAD ESTUDIANTIL',
                            style: TextStyle(
                              color: Color(0xFF087AA7),
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            color: AppColors.navyDark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              'CÓD. ${student.code}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      _PreviewField(
                        label: 'ESTUDIANTE',
                        value: student.fullName,
                      ),
                      const SizedBox(height: 6),
                      _PreviewField(label: 'CURSO', value: student.course),
                      const Spacer(),
                      const Divider(color: Color(0xFF13A8DB), height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _PreviewField(
                              label: 'TUTOR/A',
                              value: _credentialValue(student.guardianName),
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _PreviewField(
                              label: 'CONTACTO',
                              value: _credentialValue(student.guardianPhone),
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'USO PERSONAL E INTRANSFERIBLE',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/branding/credential-back-template.png',
                    fit: BoxFit.fill,
                  ),
                ),
                const _CredentialTemplateHeader(
                  subtitle: 'CONTROL DE ASISTENCIA',
                  subtitleTop: 20,
                ),
                Positioned(
                  left: 34,
                  top: 64,
                  width: 144,
                  height: 174,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.navyDark, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        const SizedBox(height: 3),
                        Container(
                          width: 42,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.navyDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: QrImageView(
                              data: student.qrPayload,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Container(
                          height: 26,
                          color: AppColors.navyDark,
                          alignment: Alignment.center,
                          child: const Text(
                            'ESCANEAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 196,
                  top: 66,
                  right: 18,
                  bottom: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: student.active
                                  ? AppColors.green
                                  : AppColors.inkMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CREDENCIAL ${student.active ? 'ACTIVA' : 'INACTIVA'}',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      const Text(
                        'VALIDACIÓN DE INGRESO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _PreviewInstruction(
                        number: '01',
                        text: 'Presenta la credencial al ingresar.',
                      ),
                      const SizedBox(height: 6),
                      const _PreviewInstruction(
                        number: '02',
                        text: 'Escanea el QR solo con AsisteQR Baker.',
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: _PreviewField(
                              label: 'VIGENCIA',
                              value: 'Gestión ${student.managementYear}',
                              compact: true,
                            ),
                          ),
                          Container(
                            color: const Color(0xFFE5F6FC),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            child: const Text(
                              'QR PERSONAL',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'En caso de extravío, entrégala en Administración.',
                        maxLines: 2,
                        style: TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 8,
                          height: 1.15,
                        ),
                      ),
                    ],
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
  const _PreviewField({
    required this.label,
    required this.value,
    this.compact = false,
  });
  final String label;
  final String value;
  final bool compact;

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
        style: TextStyle(
          fontSize: compact ? 8 : 10,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
    ],
  );
}

class _PreviewInstruction extends StatelessWidget {
  const _PreviewInstruction({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 19,
        height: 19,
        color: AppColors.blueSoft,
        alignment: Alignment.center,
        child: Text(
          number,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 7,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          maxLines: 2,
          style: const TextStyle(fontSize: 7.5, height: 1.15),
        ),
      ),
    ],
  );
}

String _credentialValue(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty
      ? 'No registrado'
      : normalized;
}

class _CredentialTemplateHeader extends StatelessWidget {
  const _CredentialTemplateHeader({
    required this.subtitle,
    this.subtitleTop = 14,
  });

  final String subtitle;
  final double subtitleTop;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 14,
    top: 8,
    right: 12,
    height: 38,
    child: Stack(
      children: [
        const Positioned(left: 0, top: 1, child: InstitutionMark(size: 31)),
        const Positioned(
          left: 38,
          top: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UNIDAD EDUCATIVA',
                style: TextStyle(
                  color: Color(0xFF087AA7),
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'ADVENTISTA BAKER',
                style: TextStyle(
                  color: AppColors.navyDark,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 112,
          right: 0,
          top: subtitleTop,
          child: Text(
            subtitle,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
