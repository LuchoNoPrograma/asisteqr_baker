import 'package:asisteqr_baker/app/app.dart';
import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/router/app_router.dart';
import 'package:asisteqr_baker/features/attendance/data/mock_attendance_repository.dart';
import 'package:asisteqr_baker/features/auth/domain/auth_repository.dart';
import 'package:asisteqr_baker/features/courses/data/mock_course_repository.dart';
import 'package:asisteqr_baker/features/credentials/data/mock_credential_repository.dart';
import 'package:asisteqr_baker/features/people/data/mock_people_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CP-15 y CP-16 limitan gestiones administrativas por rol', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          const _FixedAuthRepository(
            SessionUser(
              id: 'teacher-1',
              name: 'Docente Baker',
              role: 'DOCENTE',
            ),
          ),
        ),
        attendanceRepositoryProvider.overrideWithValue(
          MockAttendanceRepository(),
        ),
        peopleRepositoryProvider.overrideWithValue(MockPeopleRepository()),
        courseRepositoryProvider.overrideWithValue(MockCourseRepository()),
        credentialRepositoryProvider.overrideWithValue(
          MockCredentialRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionViewModelProvider).restore();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AsisteQrApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Credenciales'), findsNothing);
    container.read(appRouterProvider).go('/credenciales');
    await tester.pumpAndSettle();
    expect(find.text('Acceso denegado'), findsOneWidget);

    container.read(appRouterProvider).go('/estudiantes');
    await tester.pumpAndSettle();
    expect(find.text('Nuevo estudiante'), findsNothing);
    expect(find.byTooltip('Ver historial'), findsWidgets);

    container.read(appRouterProvider).go('/cursos');
    await tester.pumpAndSettle();
    expect(find.text('Nuevo curso'), findsNothing);
    expect(find.text('Acciones'), findsNothing);
  });
}

class _FixedAuthRepository implements AuthRepository {
  const _FixedAuthRepository(this.user);

  final SessionUser user;

  @override
  Future<SessionUser?> restoreSession() async => user;

  @override
  Future<SessionUser> signIn({
    required String username,
    required String password,
  }) async => user;

  @override
  Future<void> signOut() async {}
}
