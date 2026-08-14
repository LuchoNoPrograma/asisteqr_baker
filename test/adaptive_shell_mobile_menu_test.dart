import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_theme.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/features/auth/domain/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in const [Size(320, 640), Size(390, 780)]) {
    testWidgets('el menú móvil funciona a ${size.width.toInt()} px al 130%', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              const _MenuAuthRepository(
                SessionUser(
                  id: 'admin-1',
                  name: 'Administradora Baker',
                  role: 'ADMINISTRADOR',
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: const AdaptiveShell(
                  location: '/inicio',
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Escanear'), findsOneWidget);
      expect(find.text('Asistencia'), findsOneWidget);
      expect(find.text('Menú'), findsOneWidget);

      await tester.tap(find.text('Menú'));
      await tester.pumpAndSettle();

      expect(find.text('ACCESOS'), findsOneWidget);
      expect(find.text('GESTIÓN ACADÉMICA'), findsOneWidget);
      expect(find.text('Administradora Baker'), findsOneWidget);
      expect(find.text('Estudiantes'), findsOneWidget);
      expect(find.text('Docentes'), findsOneWidget);
      expect(find.text('Horarios'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Credenciales'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Credenciales'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Cerrar sesión'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _MenuAuthRepository implements AuthRepository {
  const _MenuAuthRepository(this.user);

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
