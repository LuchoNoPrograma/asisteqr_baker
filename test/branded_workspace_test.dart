import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/branded_workspace.dart';
import 'package:asisteqr_baker/core/widgets/institution_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in const [Size(320, 568), Size(390, 844), Size(1280, 1024)]) {
    testWidgets('el fondo de marca se adapta a ${size.width.toInt()} px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BrandedWorkspace(child: SizedBox.expand())),
        ),
      );

      final background = tester.widget<ColoredBox>(
        find.byType(ColoredBox).last,
      );
      expect(background.color, AppColors.canvas);
      expect(
        find.image(const AssetImage(InstitutionMark.blueAsset)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('la marca de agua no agrega semantica ni interacciones', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: BrandedWorkspace(child: Text('Contenido de trabajo')),
      ),
    );

    expect(find.bySemanticsLabel('Unidad Educativa Baker'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is IgnorePointer && widget.ignoring,
      ),
      findsOneWidget,
    );
    expect(find.text('Contenido de trabajo'), findsOneWidget);
    semantics.dispose();
  });
}
