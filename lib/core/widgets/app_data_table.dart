import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppDataColumn<T> {
  const AppDataColumn({
    required this.label,
    required this.cellBuilder,
    this.compare,
    this.numeric = false,
    this.columnWidth,
  });

  final String label;
  final Widget Function(BuildContext context, T item) cellBuilder;
  final int Function(T first, T second)? compare;
  final bool numeric;
  final TableColumnWidth? columnWidth;
}

class AppDataFilterOption<T> {
  const AppDataFilterOption({required this.label, required this.matches});

  final String label;
  final bool Function(T item) matches;
}

class AppDataFilter<T> {
  const AppDataFilter({required this.label, required this.options});

  final String label;
  final List<AppDataFilterOption<T>> options;
}

class AppDataTable<T> extends StatefulWidget {
  const AppDataTable({
    super.key,
    required this.items,
    required this.columns,
    required this.searchText,
    this.filters = const [],
    this.searchHint = 'Buscar',
    this.emptyMessage = 'No hay registros para mostrar.',
    this.rowsPerPage = 10,
    this.dataRowMinHeight = 48,
    this.dataRowMaxHeight = 60,
    this.columnSpacing = 44,
  });

  final List<T> items;
  final List<AppDataColumn<T>> columns;
  final String Function(T item) searchText;
  final List<AppDataFilter<T>> filters;
  final String searchHint;
  final String emptyMessage;
  final int rowsPerPage;
  final double dataRowMinHeight;
  final double dataRowMaxHeight;
  final double columnSpacing;

  @override
  State<AppDataTable<T>> createState() => _AppDataTableState<T>();
}

class _AppDataTableState<T> extends State<AppDataTable<T>> {
  final _searchController = TextEditingController();
  final _horizontalScrollController = ScrollController();
  late int _rowsPerPage = widget.rowsPerPage;
  late List<int?> _selectedFilters = List.filled(widget.filters.length, null);
  int _page = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void didUpdateWidget(covariant AppDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters.length != widget.filters.length) {
      _selectedFilters = List.filled(widget.filters.length, null);
    } else {
      for (var index = 0; index < widget.filters.length; index++) {
        final selected = _selectedFilters[index];
        if (selected != null &&
            selected >= widget.filters[index].options.length) {
          _selectedFilters[index] = null;
        }
      }
    }
    _page = 0;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    final items = widget.items.where((item) {
      if (query.isNotEmpty &&
          !widget.searchText(item).toLowerCase().contains(query)) {
        return false;
      }
      for (var index = 0; index < widget.filters.length; index++) {
        final selected = _selectedFilters[index];
        if (selected != null &&
            !widget.filters[index].options[selected].matches(item)) {
          return false;
        }
      }
      return true;
    }).toList();

    final sortIndex = _sortColumnIndex;
    if (sortIndex != null) {
      final compare = widget.columns[sortIndex].compare;
      if (compare != null) {
        items.sort(
          (first, second) =>
              _sortAscending ? compare(first, second) : compare(second, first),
        );
      }
    }
    return items;
  }

  bool get _hasActiveFilters =>
      _searchController.text.isNotEmpty ||
      _selectedFilters.any((selected) => selected != null);

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedFilters = List.filled(widget.filters.length, null);
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final pageCount = filtered.isEmpty
        ? 1
        : (filtered.length / _rowsPerPage).ceil();
    if (_page >= pageCount) _page = pageCount - 1;
    final start = _page * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    final pageItems = filtered.sublist(start, end);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final table = filtered.isEmpty
              ? _EmptyDataTable(message: widget.emptyMessage)
              : _buildTable(pageItems);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToolbar(),
              const Divider(height: 1),
              if (constraints.hasBoundedHeight)
                Expanded(child: table)
              else
                table,
              if (filtered.isNotEmpty) ...[
                const Divider(height: 1),
                _buildPagination(
                  total: filtered.length,
                  start: start,
                  end: end,
                  pageCount: pageCount,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar() => Padding(
    padding: const EdgeInsets.all(12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final searchWidth = constraints.maxWidth < 320
            ? constraints.maxWidth
            : 300.0;
        final filterWidth = constraints.maxWidth < 190
            ? constraints.maxWidth
            : 160.0;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: searchWidth,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() => _page = 0),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _page = 0);
                          },
                          icon: const Icon(LucideIcons.x, size: 17),
                        ),
                  isDense: true,
                ),
              ),
            ),
            for (var index = 0; index < widget.filters.length; index++)
              SizedBox(
                width: filterWidth,
                child: DropdownButtonFormField<int>(
                  key: ValueKey('data_filter_$index'),
                  initialValue: _selectedFilters[index],
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: widget.filters[index].label,
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    for (
                      var optionIndex = 0;
                      optionIndex < widget.filters[index].options.length;
                      optionIndex++
                    )
                      DropdownMenuItem(
                        value: optionIndex,
                        child: Text(
                          widget.filters[index].options[optionIndex].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _selectedFilters[index] = value;
                    _page = 0;
                  }),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _hasActiveFilters ? _resetFilters : null,
              icon: const Icon(LucideIcons.filterX, size: 18),
              label: const Text('Limpiar filtros'),
            ),
          ],
        );
      },
    ),
  );

  Widget _buildTable(List<T> items) => LayoutBuilder(
    builder: (context, constraints) => Scrollbar(
      key: const ValueKey('app_data_table_horizontal_scrollbar'),
      controller: _horizontalScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: SingleChildScrollView(
        key: const ValueKey('app_data_table_horizontal_scroll'),
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: SingleChildScrollView(
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              dataRowMinHeight: widget.dataRowMinHeight,
              dataRowMaxHeight: widget.dataRowMaxHeight,
              columnSpacing: widget.columnSpacing,
              headingRowColor: WidgetStateProperty.all(AppColors.canvas),
              columns: [
                for (var index = 0; index < widget.columns.length; index++)
                  DataColumn(
                    label: Text(widget.columns[index].label),
                    columnWidth: widget.columns[index].columnWidth,
                    numeric: widget.columns[index].numeric,
                    onSort: widget.columns[index].compare == null
                        ? null
                        : (_, ascending) => setState(() {
                            _sortColumnIndex = index;
                            _sortAscending = ascending;
                            _page = 0;
                          }),
                  ),
              ],
              rows: [
                for (final item in items)
                  DataRow(
                    cells: [
                      for (final column in widget.columns)
                        DataCell(column.cellBuilder(context, item)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildPagination({
    required int total,
    required int start,
    required int end,
    required int pageCount,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(
          '${start + 1}-$end de $total',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        DropdownButton<int>(
          value: _rowsPerPage,
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(value: 10, child: Text('10 filas')),
            DropdownMenuItem(value: 25, child: Text('25 filas')),
            DropdownMenuItem(value: 50, child: Text('50 filas')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _rowsPerPage = value;
              _page = 0;
            });
          },
        ),
        IconButton(
          tooltip: 'Página anterior',
          onPressed: _page == 0 ? null : () => setState(() => _page--),
          icon: const Icon(LucideIcons.chevronLeft, size: 19),
        ),
        IconButton(
          tooltip: 'Página siguiente',
          onPressed: _page >= pageCount - 1
              ? null
              : () => setState(() => _page++),
          icon: const Icon(LucideIcons.chevronRight, size: 19),
        ),
      ],
    ),
  );
}

class _EmptyDataTable extends StatelessWidget {
  const _EmptyDataTable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.listFilter, color: AppColors.inkMuted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}
