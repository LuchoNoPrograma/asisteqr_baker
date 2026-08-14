import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/app_person_image.dart';
import 'package:asisteqr_baker/core/widgets/entrance.dart';
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
    final user = ref.watch(sessionViewModelProvider).user;
    final userName = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()
        : 'Usuario Baker';
    final isAdministrator = user?.isAdministrator == true;

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
                ? _DesktopDashboard(
                    summary: summary,
                    userName: userName,
                    isAdministrator: isAdministrator,
                  )
                : _MobileDashboard(
                    summary: summary,
                    userName: userName,
                    isAdministrator: isAdministrator,
                  );
          },
        ),
      ),
    );
  }
}

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({
    required this.summary,
    required this.userName,
    required this.isAdministrator,
  });

  final DashboardSummary summary;
  final String userName;
  final bool isAdministrator;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Entrance(child: _DashboardHeading(userName: userName)),
        const SizedBox(height: 18),
        Entrance(index: 1, child: _ScanAction(summary: summary, compact: true)),
        const SizedBox(height: 22),
        Entrance(
          index: 2,
          child: _SectionTitle(
            title: 'Estado de hoy',
            trailing: '${summary.present} de ${summary.expected}',
          ),
        ),
        const SizedBox(height: 10),
        Entrance(
          index: 3,
          child: _AttendanceOverview(summary: summary, compact: true),
        ),
        const SizedBox(height: 24),
        Entrance(
          index: 4,
          child: _SectionTitle(
            title: 'Matriz de cursos',
            trailing: '${summary.courses.length} cursos',
          ),
        ),
        const SizedBox(height: 10),
        Entrance(
          index: 5,
          child: _CourseMatrix(courses: summary.courses, compact: true),
        ),
        const SizedBox(height: 24),
        Entrance(
          index: 6,
          child: const _SectionTitle(title: 'Accesos rápidos'),
        ),
        const SizedBox(height: 10),
        Entrance(
          index: 7,
          child: _QuickAccessGrid(
            isAdministrator: isAdministrator,
            compact: true,
          ),
        ),
        const SizedBox(height: 24),
        Entrance(
          index: 8,
          child: _RecentActivity(records: summary.recent, compact: true),
        ),
      ],
    );
  }
}

class _DesktopDashboard extends StatelessWidget {
  const _DesktopDashboard({
    required this.summary,
    required this.userName,
    required this.isAdministrator,
  });

  final DashboardSummary summary;
  final String userName;
  final bool isAdministrator;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 36),
      children: [
        Entrance(child: _DashboardHeading(userName: userName)),
        const SizedBox(height: 24),
        Entrance(index: 1, child: _ScanAction(summary: summary)),
        const SizedBox(height: 24),
        Entrance(
          index: 2,
          child: const _SectionTitle(title: 'Jornada en curso'),
        ),
        const SizedBox(height: 10),
        Entrance(index: 3, child: _AttendanceOverview(summary: summary)),
        const SizedBox(height: 24),
        Entrance(
          index: 4,
          child: _SectionTitle(
            title: 'Matriz de cursos',
            trailing: '${summary.courses.length} cursos',
          ),
        ),
        const SizedBox(height: 10),
        Entrance(index: 5, child: _CourseMatrix(courses: summary.courses)),
        const SizedBox(height: 24),
        Entrance(
          index: 6,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 1020;
              final recent = _RecentActivity(records: summary.recent);
              final access = _QuickAccessPanel(
                isAdministrator: isAdministrator,
              );
              if (stacked) {
                return Column(
                  children: [recent, const SizedBox(height: 16), access],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: recent),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: access),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DashboardHeading extends StatelessWidget {
  const _DashboardHeading({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final firstName = userName
        .split(RegExp(r'\s+'))
        .firstWhere((part) => part.isNotEmpty, orElse: () => 'Usuario');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _todayLabel(DateTime.now()),
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hola, $firstName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 2),
        Text(
          'Aquí tienes el estado y los accesos de la gestión escolar.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ScanAction extends StatelessWidget {
  const _ScanAction({required this.summary, this.compact = false});

  final DashboardSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navyDark,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/escaner'),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 22,
            vertical: compact ? 16 : 20,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 46 : 52,
                height: compact ? 46 : 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  LucideIcons.scanLine,
                  size: compact ? 23 : 26,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: compact ? 13 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registrar asistencia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 16 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      summary.expected == 0
                          ? 'Escanea una credencial para iniciar la jornada'
                          : '${summary.present} registrados de ${summary.expected} esperados',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  LucideIcons.arrowRight,
                  size: 18,
                  color: AppColors.navyDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      if (trailing != null)
        Text(
          trailing!,
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
    ],
  );
}

class _AttendanceOverview extends StatelessWidget {
  const _AttendanceOverview({required this.summary, this.compact = false});

  final DashboardSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rate = summary.attendanceRate.clamp(0.0, 1.0);
    final metrics = [
      _StatusMetric('Esperados', summary.expected, AppColors.navy),
      _StatusMetric('Puntuales', summary.punctual, AppColors.green),
      _StatusMetric('Atrasados', summary.late, AppColors.amber),
      _StatusMetric('Ausentes', summary.absent, AppColors.red),
    ];

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A002045),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AttendanceProgress(rate: rate, compact: true),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / 2;
                    return Wrap(
                      runSpacing: 14,
                      children: [
                        for (final metric in metrics)
                          SizedBox(
                            width: itemWidth,
                            child: _StatusValue(metric: metric),
                          ),
                      ],
                    );
                  },
                ),
              ],
            )
          : Row(
              children: [
                SizedBox(width: 210, child: _AttendanceProgress(rate: rate)),
                const SizedBox(width: 24),
                const SizedBox(height: 72, child: VerticalDivider(width: 1)),
                const SizedBox(width: 24),
                for (var index = 0; index < metrics.length; index++) ...[
                  Expanded(child: _StatusValue(metric: metrics[index])),
                  if (index != metrics.length - 1)
                    const SizedBox(
                      height: 48,
                      child: VerticalDivider(width: 24),
                    ),
                ],
              ],
            ),
    );
  }
}

class _AttendanceProgress extends StatelessWidget {
  const _AttendanceProgress({required this.rate, this.compact = false});

  final double rate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final percentage = (rate * 100).toStringAsFixed(rate == 0 ? 0 : 1);
    return Semantics(
      label: 'Asistencia registrada',
      value: '$percentage por ciento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: compact ? 28 : 32,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text(
                    'asistencia registrada',
                    maxLines: 2,
                    style: TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: rate,
            minHeight: 7,
            color: AppColors.green,
            backgroundColor: AppColors.greenSoft,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _CourseMatrix extends StatelessWidget {
  const _CourseMatrix({required this.courses, this.compact = false});

  final List<CourseAttendanceSummary> courses;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No hay cursos con estudiantes inscritos en la jornada actual.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.inkMuted),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact
            ? 1
            : constraints.maxWidth >= 960
            ? 3
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final course in courses)
              SizedBox(
                width: width,
                child: _CourseAttendanceTile(course: course),
              ),
          ],
        );
      },
    );
  }
}

class _CourseAttendanceTile extends StatelessWidget {
  const _CourseAttendanceTile({required this.course});

  final CourseAttendanceSummary course;

  @override
  Widget build(BuildContext context) {
    final rate = course.attendanceRate.clamp(0.0, 1.0);
    final percentage = (rate * 100).round();
    final color = rate >= 0.85
        ? AppColors.green
        : rate >= 0.65
        ? AppColors.amber
        : AppColors.red;
    return Semantics(
      label:
          '${course.course}, $percentage por ciento de asistencia, '
          '${course.male} hombres y ${course.female} mujeres',
      child: Container(
        constraints: const BoxConstraints(minHeight: 174),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    course.course,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '${course.present} de ${course.expected} presentes',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: rate,
              minHeight: 7,
              color: color,
              backgroundColor: AppColors.canvas,
              borderRadius: BorderRadius.circular(4),
            ),
            const Divider(height: 26),
            Row(
              children: [
                Expanded(
                  child: _GenderCount(label: 'Hombres', value: course.male),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderCount(label: 'Mujeres', value: course.female),
                ),
              ],
            ),
            if (course.genderNotRegistered > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Sin dato: ${course.genderNotRegistered}',
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GenderCount extends StatelessWidget {
  const _GenderCount({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(LucideIcons.userRound, size: 16, color: AppColors.inkMuted),
      const SizedBox(width: 7),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
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

class _StatusValue extends StatelessWidget {
  const _StatusValue({required this.metric});

  final _StatusMetric metric;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: metric.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${metric.value}',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metric.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _QuickAccessPanel extends StatelessWidget {
  const _QuickAccessPanel({required this.isAdministrator});

  final bool isAdministrator;

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
          'Gestión académica',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 3),
        Text(
          'Accede a las áreas de trabajo frecuentes.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _QuickAccessGrid(isAdministrator: isAdministrator),
      ],
    ),
  );
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({required this.isAdministrator, this.compact = false});

  final bool isAdministrator;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = _dashboardDestinations
        .where((item) => isAdministrator || !item.administratorOnly)
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 2;
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _QuickAccessTile(item: item, compact: compact),
              ),
          ],
        );
      },
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.item, required this.compact});

  final _DashboardDestination item;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(7),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.go(item.route),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: compact ? 82 : 72),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 13,
            vertical: 12,
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(item.icon, size: 18, color: AppColors.navy),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(item.icon, size: 18, color: AppColors.navy),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: AppColors.inkMuted,
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.records, this.compact = false});

  final List<AttendanceRecord> records;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visibleRecords = records.take(compact ? 4 : 5).toList();
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Actividad reciente',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/asistencia'),
                child: const Text('Ver todo'),
              ),
            ],
          ),
          if (visibleRecords.isEmpty)
            _EmptyActivity(onScan: () => context.go('/escaner'))
          else ...[
            const Divider(height: 16),
            for (var index = 0; index < visibleRecords.length; index++) ...[
              _RecordTile(record: visibleRecords[index]),
              if (index != visibleRecords.length - 1)
                const Divider(height: 1, indent: 50),
            ],
          ],
        ],
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 22, 8, 18),
    child: Column(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(
            LucideIcons.history,
            size: 21,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Aún no hay registros en esta jornada',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Las asistencias aparecerán aquí después del primer escaneo.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onScan,
          icon: const Icon(LucideIcons.scanLine, size: 17),
          label: const Text('Escanear credencial'),
        ),
      ],
    ),
  );
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
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
              const SizedBox(height: 2),
              Text(
                '${DateFormat('HH:mm').format(record.timestamp)} · ${record.student.course}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        StatusBadge(status: record.status),
      ],
    ),
  );
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
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
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 80),
      const Icon(LucideIcons.wifiOff, size: 34, color: AppColors.red),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Center(
        child: OutlinedButton.icon(
          onPressed: retry,
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          label: const Text('Reintentar'),
        ),
      ),
    ],
  );
}

String _todayLabel(DateTime date) {
  const weekdays = [
    'LUNES',
    'MARTES',
    'MIÉRCOLES',
    'JUEVES',
    'VIERNES',
    'SÁBADO',
    'DOMINGO',
  ];
  const months = [
    'ENERO',
    'FEBRERO',
    'MARZO',
    'ABRIL',
    'MAYO',
    'JUNIO',
    'JULIO',
    'AGOSTO',
    'SEPTIEMBRE',
    'OCTUBRE',
    'NOVIEMBRE',
    'DICIEMBRE',
  ];
  return '${weekdays[date.weekday - 1]} ${date.day} DE ${months[date.month - 1]}';
}

class _StatusMetric {
  const _StatusMetric(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _DashboardDestination {
  const _DashboardDestination(
    this.label,
    this.route,
    this.icon, {
    this.administratorOnly = false,
  });

  final String label;
  final String route;
  final IconData icon;
  final bool administratorOnly;
}

const _dashboardDestinations = [
  _DashboardDestination('Cursos', '/cursos', LucideIcons.school),
  _DashboardDestination(
    'Credenciales',
    '/credenciales',
    LucideIcons.idCard,
    administratorOnly: true,
  ),
  _DashboardDestination(
    'Estudiantes',
    '/estudiantes',
    LucideIcons.graduationCap,
  ),
  _DashboardDestination('Docentes', '/docentes', LucideIcons.presentation),
  _DashboardDestination('Horarios', '/horarios', LucideIcons.calendarClock),
  _DashboardDestination(
    'Reportes',
    '/reportes',
    LucideIcons.chartNoAxesCombined,
  ),
];
