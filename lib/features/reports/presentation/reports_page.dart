import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/app_feedback.dart';
import 'package:asisteqr_baker/features/reports/domain/report_repository.dart';
import 'package:asisteqr_baker/features/reports/presentation/report_export_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  String period = 'Semanal';
  String? courseId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() => ref
      .read(reportExportViewModelProvider)
      .load(period, selectedCourseId: courseId);

  Future<void> _exportPdf() async {
    final model = ref.read(reportExportViewModelProvider);
    final exported = await model.export(period);
    if (!mounted) return;
    if (exported) {
      await showAppSuccess(
        context,
        model.message ?? 'El reporte quedó listo.',
        title: 'Reporte exportado',
      );
    } else {
      await showAppErrorDialog(
        context,
        title: 'No se pudo exportar el reporte',
        message: model.message ?? 'Intenta nuevamente.',
      );
    }
  }

  void _setPeriod(String value) {
    setState(() => period = value);
    _load();
  }

  void _setCourse(String? value) {
    setState(() => courseId = value);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(reportExportViewModelProvider);
    final courses = ref.watch(coursesViewModelProvider).courses;
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final exporting = report.status == ReportExportStatus.exporting;
    return AdaptiveShell(
      location: '/reportes',
      title: 'Reportes',
      child: ListView(
        padding: EdgeInsets.all(wide ? 28 : 14),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reportes de asistencia',
                      style: wide
                          ? Theme.of(context).textTheme.headlineMedium
                          : Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Resumen calculado con los registros del periodo activo.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: exporting || report.summary == null
                    ? null
                    : _exportPdf,
                icon: exporting
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.fileDown, size: 17),
                label: Text(wide ? 'Exportar PDF' : 'PDF'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'Diario',
                label: Text('Diario'),
                icon: Icon(LucideIcons.calendarDays, size: 16),
              ),
              ButtonSegment(
                value: 'Semanal',
                label: Text('Semanal'),
                icon: Icon(LucideIcons.calendarRange, size: 16),
              ),
              ButtonSegment(
                value: 'Mensual',
                label: Text('Mensual'),
                icon: Icon(LucideIcons.calendarClock, size: 16),
              ),
            ],
            selected: {period},
            onSelectionChanged: (values) => _setPeriod(values.first),
          ),
          const SizedBox(height: 14),
          _ReportFilters(
            courses: courses
                .map((course) => (id: course.id, name: course.name))
                .toList(),
            courseId: courseId,
            from: report.from,
            to: report.to,
            onCourseChanged: _setCourse,
            onClear: courseId == null ? null : () => _setCourse(null),
          ),
          if (report.loading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (report.loadError != null) ...[
            const SizedBox(height: 12),
            MaterialBanner(
              backgroundColor: AppColors.redSoft,
              leading: const Icon(
                LucideIcons.circleAlert,
                color: AppColors.red,
              ),
              content: Text(report.loadError!),
              actions: [
                IconButton(
                  tooltip: 'Reintentar',
                  onPressed: _load,
                  icon: const Icon(LucideIcons.refreshCw),
                ),
              ],
            ),
          ],
          if (report.summary case final summary?) ...[
            const SizedBox(height: 14),
            _SummaryMetrics(summary: summary),
            const SizedBox(height: 14),
            _AttendanceDistribution(summary: summary),
          ],
        ],
      ),
    );
  }
}

class _ReportFilters extends StatelessWidget {
  const _ReportFilters({
    required this.courses,
    required this.courseId,
    required this.from,
    required this.to,
    required this.onCourseChanged,
    required this.onClear,
  });

  final List<({String id, String name})> courses;
  final String? courseId;
  final DateTime? from;
  final DateTime? to;
  final ValueChanged<String?> onCourseChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy');
    final range = from == null || to == null
        ? 'Cargando periodo'
        : '${format.format(from!)} – ${format.format(to!)}';
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 720;
        final fields = [
          SizedBox(
            width: horizontal ? 270 : constraints.maxWidth,
            child: DropdownButtonFormField<String?>(
              initialValue: courseId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Curso'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                for (final course in courses)
                  DropdownMenuItem(
                    value: course.id,
                    child: Text(
                      course.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onCourseChanged,
            ),
          ),
          SizedBox(
            width: horizontal ? 240 : constraints.maxWidth,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Rango'),
              child: Text(range, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(LucideIcons.filterX, size: 17),
            label: const Text('Limpiar filtros'),
          ),
        ];
        return horizontal
            ? Row(
                children: [
                  fields[0],
                  const SizedBox(width: 10),
                  fields[1],
                  const SizedBox(width: 10),
                  fields[2],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  fields[0],
                  const SizedBox(height: 10),
                  fields[1],
                  const SizedBox(height: 10),
                  fields[2],
                ],
              );
      },
    );
  }
}

class _SummaryMetrics extends StatelessWidget {
  const _SummaryMetrics({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      _ReportMetric(
        label: 'Asistencia',
        value: '${summary.attendancePercentage.toStringAsFixed(1)}%',
        detail: '${summary.totalRecords} de ${summary.expectedAttendances}',
        icon: LucideIcons.calendarCheck,
        color: AppColors.green,
      ),
      _ReportMetric(
        label: 'Puntualidad',
        value: '${summary.punctualityPercentage.toStringAsFixed(1)}%',
        detail: '${summary.punctualAttendances} registros puntuales',
        icon: LucideIcons.clock3,
        color: AppColors.navy,
      ),
      _ReportMetric(
        label: 'Atrasos',
        value: summary.lateAttendances.toString(),
        detail: '${summary.totalRecords} registros totales',
        icon: LucideIcons.clockAlert,
        color: AppColors.amber,
      ),
      _ReportMetric(
        label: 'Inasistencias',
        value: summary.absences.toString(),
        detail:
            '${summary.enrolledStudents} estudiantes · ${summary.schoolDays} días',
        icon: LucideIcons.userRoundX,
        color: AppColors.red,
      ),
    ],
  );
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 250,
    constraints: const BoxConstraints(minHeight: 112),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            Icon(icon, size: 18, color: color),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _AttendanceDistribution extends StatelessWidget {
  const _AttendanceDistribution({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Distribución de registros',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _DistributionRow(
          label: 'Puntuales',
          value: summary.punctualAttendances,
          total: summary.totalRecords,
          color: AppColors.green,
        ),
        const SizedBox(height: 14),
        _DistributionRow(
          label: 'Atrasos',
          value: summary.lateAttendances,
          total: summary.totalRecords,
          color: AppColors.amber,
        ),
      ],
    ),
  );
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value.toString(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          color: color,
          backgroundColor: AppColors.canvas,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
