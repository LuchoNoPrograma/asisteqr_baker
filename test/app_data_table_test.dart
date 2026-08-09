import 'package:asisteqr_baker/core/widgets/app_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('busca, filtra, ordena y pagina datos dinámicos', (tester) async {
    final items = [
      for (var index = 1; index <= 12; index++)
        _TableItem(name: 'Registro $index', group: index.isEven ? 'A' : 'B'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 650,
            child: AppDataTable<_TableItem>(
              items: items,
              searchHint: 'Buscar registro',
              searchText: (item) => '${item.name} ${item.group}',
              filters: [
                AppDataFilter(
                  label: 'Grupo',
                  options: [
                    AppDataFilterOption(
                      label: 'Grupo A',
                      matches: (item) => item.group == 'A',
                    ),
                    AppDataFilterOption(
                      label: 'Grupo B',
                      matches: (item) => item.group == 'B',
                    ),
                  ],
                ),
              ],
              columns: [
                AppDataColumn(
                  label: 'Nombre',
                  compare: (first, second) => first.name.compareTo(second.name),
                  cellBuilder: (context, item) => Text(item.name),
                ),
                AppDataColumn(
                  label: 'Grupo',
                  cellBuilder: (context, item) => Text(item.group),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final clearFilters = find.widgetWithText(OutlinedButton, 'Limpiar filtros');
    expect(clearFilters, findsOneWidget);
    expect(tester.widget<OutlinedButton>(clearFilters).onPressed, isNull);

    expect(find.text('Registro 11'), findsNothing);
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pump();
    expect(find.text('Registro 11'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Registro 2');
    await tester.pump();
    expect(tester.widget<OutlinedButton>(clearFilters).onPressed, isNotNull);
    expect(
      find.descendant(
        of: find.byType(DataTable),
        matching: find.text('Registro 2'),
      ),
      findsOneWidget,
    );
    expect(find.text('Registro 12'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('data_filter_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grupo A').last);
    await tester.pumpAndSettle();
    expect(find.text('Registro 2'), findsOneWidget);
    expect(find.text('Registro 1'), findsNothing);

    await tester.tap(find.text('Nombre'));
    await tester.pump();
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('permite desplazar horizontalmente columnas anchas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 360,
            child: AppDataTable<_TableItem>(
              items: const [_TableItem(name: 'Registro', group: 'A')],
              searchText: (item) => '${item.name} ${item.group}',
              columns: [
                AppDataColumn(
                  label: 'Nombre',
                  cellBuilder: (context, item) =>
                      SizedBox(width: 360, child: Text(item.name)),
                ),
                AppDataColumn(
                  label: 'Grupo al final',
                  cellBuilder: (context, item) =>
                      SizedBox(width: 360, child: Text(item.group)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final horizontalScroll = find.byKey(
      const ValueKey('app_data_table_horizontal_scroll'),
    );
    final scrollView = tester.widget<SingleChildScrollView>(horizontalScroll);

    expect(
      find.byKey(const ValueKey('app_data_table_horizontal_scrollbar')),
      findsOneWidget,
    );
    expect(scrollView.controller!.position.maxScrollExtent, greaterThan(0));

    await tester.drag(horizontalScroll, const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(scrollView.controller!.offset, greaterThan(0));
  });
}

class _TableItem {
  const _TableItem({required this.name, required this.group});

  final String name;
  final String group;
}
