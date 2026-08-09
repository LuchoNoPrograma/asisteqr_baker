import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_theme.dart';
import 'package:asisteqr_baker/features/auth/domain/auth_repository.dart';
import 'package:asisteqr_baker/features/credentials/domain/credential_models.dart';
import 'package:asisteqr_baker/features/credentials/domain/credential_repository.dart';
import 'package:asisteqr_baker/features/credentials/presentation/credentials_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCredentials(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            const _CredentialAuthRepository(),
          ),
          credentialRepositoryProvider.overrideWithValue(
            const _CredentialRepositoryStub(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CredentialsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'prioriza selección y mantiene la vista previa accesible en móvil',
    (tester) async {
      await pumpCredentials(tester, size: const Size(320, 568), textScale: 1.3);

      expect(tester.takeException(), isNull);
      expect(find.text('3 estudiantes'), findsOneWidget);
      expect(find.text('Vista previa'), findsNothing);

      final pageScroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      pageScroll.position.jumpTo(160);
      await tester.pump();
      await tester.tap(find.text('Valeria Mendoza Rojas'));
      await tester.pump();
      expect(find.text('1 seleccionado en esta lista'), findsOneWidget);

      pageScroll.position.jumpTo(pageScroll.position.maxScrollExtent);
      await tester.pump();
      final previewOffset = (pageScroll.position.maxScrollExtent - 420).clamp(
        pageScroll.position.minScrollExtent,
        pageScroll.position.maxScrollExtent,
      );
      pageScroll.position.jumpTo(previewOffset);
      await tester.pump();
      await tester.tap(find.text('Reverso'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('usa dos paneles administrativos en escritorio', (tester) async {
    await pumpCredentials(tester, size: const Size(1280, 1024));

    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.text('Vista previa')).dx,
      greaterThan(tester.getTopLeft(find.text('3 estudiantes')).dx),
    );
    expect(find.text('Descargar 0 en PDF'), findsOneWidget);
  });

  testWidgets('encaja en 390 px con texto ampliado', (tester) async {
    await pumpCredentials(tester, size: const Size(390, 844), textScale: 1.3);

    expect(tester.takeException(), isNull);
    final pageScroll = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    pageScroll.position.jumpTo(pageScroll.position.maxScrollExtent);
    await tester.pump();
    expect(find.text('Vista previa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _CredentialAuthRepository implements AuthRepository {
  const _CredentialAuthRepository();

  static const _user = SessionUser(
    id: 'admin-test',
    name: 'Administrador de pruebas',
    role: 'ADMINISTRADOR',
  );

  @override
  Future<SessionUser?> restoreSession() async => _user;

  @override
  Future<SessionUser> signIn({
    required String username,
    required String password,
  }) async => _user;

  @override
  Future<void> signOut() async {}
}

class _CredentialRepositoryStub implements CredentialRepository {
  const _CredentialRepositoryStub();

  @override
  Future<List<CredentialStudent>> getStudents() async => const [
    CredentialStudent(
      id: '1',
      code: 'EST-2026-0148',
      fullName: 'Valeria Mendoza Rojas',
      course: '4.º Secundaria B',
      qrPayload: 'AQB1.test_0148',
    ),
    CredentialStudent(
      id: '2',
      code: 'EST-2026-0109',
      fullName: 'Carlos Martínez Silva',
      course: '4.º Secundaria A',
      qrPayload: 'AQB1.test_0109',
    ),
    CredentialStudent(
      id: '3',
      code: 'EST-2026-0201',
      fullName: 'Ana Lucía Torres',
      course: '5.º Secundaria C',
      qrPayload: 'AQB1.test_0201',
    ),
  ];
}
