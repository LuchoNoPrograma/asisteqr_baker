import 'package:asisteqr_baker/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la pantalla de acceso sin sesion', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AsisteQrApp()));
    await tester.pumpAndSettle();

    expect(find.text('AsisteQR Baker'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
  });
}
