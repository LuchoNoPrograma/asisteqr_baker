import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/entrance.dart';
import 'package:asisteqr_baker/core/widgets/app_person_image.dart';
import 'package:asisteqr_baker/core/widgets/status_badge.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:asisteqr_baker/features/dashboard/presentation/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final dashboardViewModelProvider = ChangeNotifierProvider.autoDispose(
  (ref) => DashboardViewModel(ref.watch(attendanceRepositoryProvider)),
);

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(dashboardViewModelProvider);
    return AdaptiveShell(
      location: '/inicio',
      child: RefreshIndicator(
        onRefresh: model.load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (model.loading && model.summary == null) {
              return const _DashboardSkeleton();
            }
            if (model.error != null && model.summary == null) {
              return _DashboardError(message: model.error!, retry: model.load);
            }
            final summary = model.summary!;
            return constraints.maxWidth >= 840
                ? _DesktopDashboard(summary: summary)
                : _MobileDashboard(summary: summary);
          },
        ),
      ),
    );
  }
}

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Entrance(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/escaner'),
            icon: const Icon(LucideIcons.scanLine),
            label: const Text('Escanear QR'),
          ),
        ),
        const SizedBox(height: 20),
        Entrance(
          index: 1,
          child: Text(
            'Resumen del día',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 10),
        Entrance(
          index: 2,
          child: _MetricTile(
            label: 'Total esperados',
            value: '${summary.expected}',
            color: AppColors.navy,
            icon: LucideIcons.usersRound,
          ),
        ),
        const SizedBox(height: 8),
        Entrance(
          index: 3,
          child: Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Presentes',
                  value: '${summary.present}',
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'Puntuales',
                  value: '${summary.punctual}',
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Entrance(
          index: 4,
          child: Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Atrasados',
                  value: '${summary.late}',
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'Ausentes',
                  value: '${summary.absent}',
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Entrance(
          index: 5,
          child: _SectionHeader(
            title: 'Últimos registros',
            action: 'Ver todos',
            onTap: () => context.go('/asistencia'),
          ),
        ),
        const SizedBox(height: 8),
        ...summary.recent.asMap().entries.map(
          (entry) => Entrance(
            index: 6 + entry.key,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RecordTile(record: entry.value),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopDashboard extends StatelessWidget {
  const _DesktopDashboard({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vista general',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Asistencia y actividad institucional en tiempo real.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/reportes'),
              icon: const Icon(LucideIcons.download, size: 17),
              label: const Text('Exportar reporte'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _DesktopMetric(
                label: 'Asistencia hoy',
                value: '${(summary.attendanceRate * 100).toStringAsFixed(1)}%',
                detail: '${summary.present} registros',
                color: AppColors.green,
                icon: LucideIcons.trendingUp,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DesktopMetric(
                label: 'Ausencias reportadas',
                value: '${summary.absent}',
                detail: 'de ${summary.expected} estudiantes',
                color: AppColors.red,
                icon: LucideIcons.triangleAlert,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DesktopMetric(
                label: 'Atrasos registrados',
                value: '${summary.late}',
                detail: 'jornada actual',
                color: AppColors.amber,
                icon: LucideIcons.clock3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _AttendanceComposition(summary: summary)),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _RecentPanel(records: summary.recent)),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 68),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 52,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(3),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (icon != null)
                      Icon(icon, size: 19, color: AppColors.border),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      TextButton(onPressed: onTap, child: Text(action)),
    ],
  );
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final AttendanceRecord record;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      children: [
        AppPersonAvatar(
          source: record.student.photoSource,
          fallback: record.student.fullName.characters.first,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.student.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${DateFormat('HH:mm').format(record.timestamp)} · ${record.student.course}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        StatusBadge(status: record.status),
      ],
    ),
  );
}

class _DesktopMetric extends StatelessWidget {
  const _DesktopMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
    required this.icon,
  });
  final String label, value, detail;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    height: 150,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Icon(icon, color: color, size: 18),
          ],
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _AttendanceComposition extends StatelessWidget {
  const _AttendanceComposition({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) => Container(
    height: 270,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Composición de la jornada',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(
              LucideIcons.chartNoAxesColumnIncreasing,
              size: 18,
              color: AppColors.navy,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _CompositionRow(
          label: 'Puntuales',
          value: summary.punctual,
          total: summary.expected,
          color: AppColors.green,
        ),
        const SizedBox(height: 18),
        _CompositionRow(
          label: 'Atrasados',
          value: summary.late,
          total: summary.expected,
          color: AppColors.amber,
        ),
        const SizedBox(height: 18),
        _CompositionRow(
          label: 'Ausentes',
          value: summary.absent,
          total: summary.expected,
          color: AppColors.red,
        ),
      ],
    ),
  );
}

class _CompositionRow extends StatelessWidget {
  const _CompositionRow({
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
    final progress = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Semantics(
      label: label,
      value: '$value de $total estudiantes',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                '$value',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: color,
            backgroundColor: AppColors.canvas,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _RecentPanel extends StatelessWidget {
  const _RecentPanel({required this.records});
  final List<AttendanceRecord> records;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Últimos registros',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 14),
        for (final record in records)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _RecordTile(record: record),
          ),
        TextButton(
          onPressed: () => context.go('/asistencia'),
          child: const Text('Ver asistencia diaria'),
        ),
      ],
    ),
  );
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: const [
      LinearProgressIndicator(minHeight: 2),
      SizedBox(height: 18),
      Text('Cargando resumen institucional…', textAlign: TextAlign.center),
    ],
  );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.wifiOff, size: 34, color: AppColors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: retry,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
