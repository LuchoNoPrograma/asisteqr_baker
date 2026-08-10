import 'package:asisteqr_baker/core/widgets/app_table_actions_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('unifica iconos, etiquetas y acción destructiva', (tester) async {
    var selected = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTableActionsMenu(
            tooltip: 'Acciones del registro',
            actions: [
              AppTableAction(
                label: 'Editar',
                icon: LucideIcons.pencil,
                onSelected: () => selected = 'edit',
              ),
              AppTableAction.deactivate(
                onSelected: () => selected = 'deactivate',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Acciones del registro'));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Desactivar'), findsOneWidget);
    expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
    expect(find.byIcon(LucideIcons.circleOff), findsOneWidget);
    expect(find.byType(PopupMenuDivider), findsOneWidget);

    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();
    expect(selected, 'deactivate');
    expect(tester.takeException(), isNull);
  });
}
