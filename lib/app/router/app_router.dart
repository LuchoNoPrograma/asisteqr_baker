import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/institution_mark.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:asisteqr_baker/features/attendance/presentation/attendance_page.dart';
import 'package:asisteqr_baker/features/attendance/presentation/scan_result_page.dart';
import 'package:asisteqr_baker/features/attendance/presentation/scanner_page.dart';
import 'package:asisteqr_baker/features/attendance/presentation/student_history_page.dart';
import 'package:asisteqr_baker/features/auth/presentation/login_page.dart';
import 'package:asisteqr_baker/features/auth/presentation/access_denied_page.dart';
import 'package:asisteqr_baker/features/auth/presentation/session_view_model.dart';
import 'package:asisteqr_baker/features/dashboard/presentation/dashboard_page.dart';
import 'package:asisteqr_baker/features/people/presentation/students_page.dart';
import 'package:asisteqr_baker/features/people/presentation/teachers_page.dart';
import 'package:asisteqr_baker/features/credentials/presentation/credentials_page.dart';
import 'package:asisteqr_baker/features/reports/presentation/courses_page.dart';
import 'package:asisteqr_baker/features/reports/presentation/reports_page.dart';
import 'package:asisteqr_baker/features/schedules/presentation/teaching_schedules_page.dart';
import 'package:asisteqr_baker/features/schedules/presentation/teacher_schedule_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.read(sessionViewModelProvider);
  return GoRouter(
    initialLocation: '/inicio',
    refreshListenable: session,
    redirect: (context, state) {
      final atLogin = state.matchedLocation == '/acceso';
      final checking = session.status == SessionStatus.checking;
      if (checking) {
        return state.matchedLocation == '/cargando' ? null : '/cargando';
      }
      final authenticated = session.status == SessionStatus.signedIn;
      if (!authenticated && !atLogin) return '/acceso';
      if (authenticated && (atLogin || state.matchedLocation == '/cargando')) {
        return '/inicio';
      }
      if (authenticated &&
          state.matchedLocation == '/credenciales' &&
          session.user?.isAdministrator != true) {
        return '/acceso-denegado';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/acceso-denegado',
        pageBuilder: (context, state) =>
            _fadePage(state, const AccessDeniedPage()),
      ),
      GoRoute(
        path: '/cargando',
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(
        path: '/acceso',
        pageBuilder: (context, state) => _fadePage(state, const LoginPage()),
      ),
      GoRoute(
        path: '/inicio',
        pageBuilder: (context, state) =>
            _fadePage(state, const DashboardPage()),
      ),
      GoRoute(
        path: '/escaner',
        pageBuilder: (context, state) => _fadePage(state, const ScannerPage()),
      ),
      GoRoute(
        path: '/resultado',
        pageBuilder: (context, state) {
          final result = state.extra as ScanResult?;
          return _slidePage(
            state,
            result == null
                ? const _MissingResultPage()
                : ScanResultPage(result: result),
          );
        },
      ),
      GoRoute(
        path: '/asistencia',
        pageBuilder: (context, state) =>
            _fadePage(state, const AttendancePage()),
      ),
      GoRoute(
        path: '/historial',
        pageBuilder: (context, state) {
          final studentId = state.extra as String?;
          return _slidePage(
            state,
            studentId == null
                ? const _MissingHistoryStudentPage()
                : StudentHistoryPage(studentId: studentId),
          );
        },
      ),
      GoRoute(
        path: '/reportes',
        pageBuilder: (context, state) => _fadePage(state, const ReportsPage()),
      ),
      GoRoute(
        path: '/cursos',
        pageBuilder: (context, state) => _fadePage(state, const CoursesPage()),
      ),
      GoRoute(
        path: '/estudiantes',
        pageBuilder: (context, state) => _fadePage(state, const StudentsPage()),
      ),
      GoRoute(
        path: '/docentes',
        pageBuilder: (context, state) => _fadePage(state, const TeachersPage()),
      ),
      GoRoute(
        path: '/docentes/:docenteId/horario',
        pageBuilder: (context, state) => _slidePage(
          state,
          TeacherScheduleEditorPage(
            teacherId: state.pathParameters['docenteId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/horarios',
        pageBuilder: (context, state) =>
            _fadePage(state, const TeachingSchedulesPage()),
      ),
      GoRoute(
        path: '/credenciales',
        pageBuilder: (context, state) =>
            _fadePage(state, const CredentialsPage()),
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 220),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
    );

CustomTransitionPage<void> _slidePage(
  GoRouterState state,
  Widget child,
) => CustomTransitionPage(
  key: state.pageKey,
  transitionDuration: const Duration(milliseconds: 260),
  child: child,
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      SlideTransition(
        position: Tween(begin: const Offset(.04, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
);

class _SplashPage extends StatelessWidget {
  const _SplashPage();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InstitutionMark(size: 72),
          SizedBox(height: 18),
          Text(
            'AsisteQR Baker',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text('Preparando tu sesión…'),
          SizedBox(height: 18),
          SizedBox(width: 160, child: LinearProgressIndicator(minHeight: 3)),
        ],
      ),
    ),
  );
}

class _MissingResultPage extends StatelessWidget {
  const _MissingResultPage();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.scanLine, size: 36),
          const SizedBox(height: 12),
          const Text('Escanea una credencial para ver el resultado.'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.go('/escaner'),
            child: const Text('Ir al escáner'),
          ),
        ],
      ),
    ),
  );
}

class _MissingHistoryStudentPage extends StatelessWidget {
  const _MissingHistoryStudentPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.userRoundSearch,
            size: 42,
            color: AppColors.inkMuted,
          ),
          const SizedBox(height: 12),
          const Text('Selecciona un estudiante para consultar su historial.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/estudiantes'),
            child: const Text('Ver estudiantes'),
          ),
        ],
      ),
    ),
  );
}
