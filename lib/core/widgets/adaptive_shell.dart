import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/branded_workspace.dart';
import 'package:asisteqr_baker/core/widgets/institution_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({
    super.key,
    required this.location,
    required this.child,
    this.title,
  });
  final String location;
  final Widget child;
  final String? title;

  static const _mobileItems = [
    _NavItem(
      'Inicio',
      '/inicio',
      LucideIcons.house,
      section: _NavSection.access,
    ),
    _NavItem(
      'Escanear',
      '/escaner',
      LucideIcons.scanLine,
      section: _NavSection.access,
    ),
    _NavItem(
      'Asistencia',
      '/asistencia',
      LucideIcons.clipboardCheck,
      section: _NavSection.access,
    ),
    _NavItem(
      'Estudiantes',
      '/estudiantes',
      LucideIcons.graduationCap,
      section: _NavSection.management,
    ),
    _NavItem(
      'Docentes',
      '/docentes',
      LucideIcons.presentation,
      section: _NavSection.management,
    ),
    _NavItem(
      'Horarios',
      '/horarios',
      LucideIcons.calendarClock,
      section: _NavSection.management,
    ),
    _NavItem(
      'Cursos',
      '/cursos',
      LucideIcons.school,
      section: _NavSection.catalogs,
    ),
    _NavItem(
      'Materias',
      '/materias',
      LucideIcons.bookOpen,
      section: _NavSection.catalogs,
    ),
    _NavItem(
      'Aulas',
      '/aulas',
      LucideIcons.doorOpen,
      section: _NavSection.catalogs,
    ),
    _NavItem(
      'Credenciales',
      '/credenciales',
      LucideIcons.idCard,
      section: _NavSection.reports,
      administratorOnly: true,
    ),
    _NavItem(
      'Reportes',
      '/reportes',
      LucideIcons.chartNoAxesCombined,
      section: _NavSection.reports,
    ),
  ];

  static const _mobilePrimaryItems = [
    _NavItem(
      'Inicio',
      '/inicio',
      LucideIcons.house,
      section: _NavSection.access,
    ),
    _NavItem(
      'Escanear',
      '/escaner',
      LucideIcons.scanLine,
      section: _NavSection.access,
    ),
    _NavItem(
      'Asistencia',
      '/asistencia',
      LucideIcons.clipboardCheck,
      section: _NavSection.access,
    ),
  ];

  static const _desktopItems = _mobileItems;

  int _selectedIndex(List<_NavItem> items) {
    final index = items.indexWhere((item) => _matchesRoute(item.route));
    return index < 0 ? 0 : index;
  }

  bool _matchesRoute(String route) {
    return location == route || location.startsWith('$route/');
  }

  void _showMobileMenu(
    BuildContext context,
    WidgetRef ref,
    List<_NavItem> items,
  ) {
    final user = ref.read(sessionViewModelProvider).user;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.navyDark.withValues(alpha: 0.48),
      builder: (sheetContext) => _MobileMenuSheet(
        items: items,
        location: location,
        userName: user?.name ?? 'Usuario Baker',
        userRole: user?.role ?? 'USUARIO',
        onNavigate: (route) {
          Navigator.of(sheetContext).pop();
          context.go(route);
        },
        onSignOut: () async {
          Navigator.of(sheetContext).pop();
          await ref.read(sessionViewModelProvider).signOut();
          if (context.mounted) context.go('/acceso');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final administrator = ref.watch(
      sessionViewModelProvider.select(
        (session) => session.user?.isAdministrator == true,
      ),
    );
    final mobileItems = _mobileItems
        .where((item) => administrator || !item.administratorOnly)
        .toList();
    final desktopItems = _desktopItems
        .where((item) => administrator || !item.administratorOnly)
        .toList();
    final managementPage =
        _matchesRoute('/estudiantes') ||
        _matchesRoute('/docentes') ||
        _matchesRoute('/horarios') ||
        _matchesRoute('/cursos') ||
        _matchesRoute('/materias') ||
        _matchesRoute('/aulas');
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopNavigation(
              items: desktopItems,
              selectedIndex: _selectedIndex(desktopItems),
              onSelected: (index) => context.go(desktopItems[index].route),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: BrandedWorkspace(child: child)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: location == '/escaner'
          ? null
          : AppBar(
              leading: managementPage
                  ? IconButton(
                      tooltip: 'Volver al inicio',
                      onPressed: () => context.go('/inicio'),
                      icon: const Icon(LucideIcons.arrowLeft, size: 19),
                    )
                  : null,
              title: Row(
                children: [
                  const InstitutionMark(size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title ?? 'AsisteQR Baker',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Abrir menú principal',
                  onPressed: () => _showMobileMenu(context, ref, mobileItems),
                  icon: const Icon(LucideIcons.menu, size: 21),
                ),
                const SizedBox(width: 4),
              ],
            ),
      body: BrandedWorkspace(child: child),
      bottomNavigationBar: _MobileNavigation(
        items: _mobilePrimaryItems,
        selectedIndex: _mobilePrimaryItems.indexWhere(
          (item) => _matchesRoute(item.route),
        ),
        onSelected: (index) => context.go(_mobilePrimaryItems[index].route),
        onOpenMenu: () => _showMobileMenu(context, ref, mobileItems),
      ),
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onOpenMenu,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final menuSelected = selectedIndex < 0;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18002045),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              color: states.contains(WidgetState.selected)
                  ? AppColors.navy
                  : AppColors.inkMuted,
              fontSize: 10.5,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w600,
            );
          }),
        ),
        child: NavigationBar(
          height: 72,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppColors.blueSoft,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: menuSelected ? items.length : selectedIndex,
          onDestinationSelected: (index) {
            if (index == items.length) {
              onOpenMenu();
            } else {
              onSelected(index);
            }
          },
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: Icon(item.icon, size: 20),
                selectedIcon: Icon(item.icon, size: 20),
                label: item.label,
              ),
            const NavigationDestination(
              icon: Icon(LucideIcons.menu, size: 20),
              selectedIcon: Icon(LucideIcons.menu, size: 20),
              label: 'Menú',
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileMenuSheet extends StatelessWidget {
  const _MobileMenuSheet({
    required this.items,
    required this.location,
    required this.userName,
    required this.userRole,
    required this.onNavigate,
    required this.onSignOut,
  });

  final List<_NavItem> items;
  final String location;
  final String userName;
  final String userRole;
  final ValueChanged<String> onNavigate;
  final Future<void> Function() onSignOut;

  bool _isSelected(_NavItem item) {
    return location == item.route || location.startsWith('${item.route}/');
  }

  List<_NavItem> _itemsFor(_NavSection section) =>
      items.where((item) => item.section == section).toList();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final visibleSections = _NavSection.values
        .where((section) => _itemsFor(section).isNotEmpty)
        .toList();
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SizedBox(
          height: height.clamp(0, 720).toDouble(),
          child: Material(
            color: AppColors.surface,
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MobileMenuHeader(
                  userName: userName,
                  userRole: userRole,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                    children: [
                      for (
                        var sectionIndex = 0;
                        sectionIndex < visibleSections.length;
                        sectionIndex++
                      ) ...[
                        if (sectionIndex > 0) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 14),
                        ],
                        _MobileMenuSectionLabel(
                          label: visibleSections[sectionIndex].label,
                        ),
                        for (final item in _itemsFor(
                          visibleSections[sectionIndex],
                        ))
                          _MobileMenuItem(
                            item: item,
                            selected: _isSelected(item),
                            onTap: () => onNavigate(item.route),
                          ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      ListTile(
                        minTileHeight: 50,
                        leading: const Icon(
                          LucideIcons.logOut,
                          size: 19,
                          color: AppColors.red,
                        ),
                        title: const Text(
                          'Cerrar sesión',
                          style: TextStyle(
                            color: AppColors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onTap: onSignOut,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileMenuHeader extends StatelessWidget {
  const _MobileMenuHeader({
    required this.userName,
    required this.userRole,
    required this.onClose,
  });

  final String userName;
  final String userRole;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.navyDark,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 10, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const InstitutionMark(
                  size: 30,
                  variant: InstitutionMarkVariant.white,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'AsisteQR Baker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar menú',
                  onPressed: onClose,
                  style: IconButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(LucideIcons.x, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.userRound,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileMenuSectionLabel extends StatelessWidget {
  const _MobileMenuSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.inkMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MobileMenuItem extends StatelessWidget {
  const _MobileMenuItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? AppColors.blueSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            decoration: BoxDecoration(
              border: selected
                  ? const Border(
                      left: BorderSide(color: AppColors.navy, width: 3),
                    )
                  : null,
            ),
            padding: EdgeInsets.fromLTRB(selected ? 13 : 16, 8, 12, 8),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 19,
                  color: selected ? AppColors.navy : AppColors.inkMuted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? AppColors.navy : AppColors.ink,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 17,
                  color: selected ? AppColors.navy : AppColors.border,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopNavigation extends ConsumerStatefulWidget {
  const _DesktopNavigation({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  ConsumerState<_DesktopNavigation> createState() => _DesktopNavigationState();
}

class _DesktopNavigationState extends ConsumerState<_DesktopNavigation> {
  late bool catalogsExpanded;

  _NavSection? get _selectedSection =>
      widget.selectedIndex >= 0 && widget.selectedIndex < widget.items.length
      ? widget.items[widget.selectedIndex].section
      : null;

  List<_NavItem> _itemsFor(_NavSection section) =>
      widget.items.where((item) => item.section == section).toList();

  bool _isSelected(_NavItem item) =>
      widget.items.indexOf(item) == widget.selectedIndex;

  void _select(_NavItem item) => widget.onSelected(widget.items.indexOf(item));

  @override
  void initState() {
    super.initState();
    catalogsExpanded = _selectedSection == _NavSection.catalogs;
  }

  @override
  void didUpdateWidget(covariant _DesktopNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedSection == _NavSection.catalogs && !catalogsExpanded) {
      catalogsExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionViewModelProvider).user;
    return SizedBox(
      width: 220,
      child: ColoredBox(
        color: AppColors.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Row(
                  children: [
                    InstitutionMark(size: 28),
                    SizedBox(width: 10),
                    Text(
                      'AsisteQR Baker',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.blueSoft,
                      child: Icon(
                        LucideIcons.userRound,
                        size: 18,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Administrador Baker',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            user?.role ?? 'ADMINISTRADOR',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    const _DesktopSectionLabel(label: 'ACCESOS'),
                    for (final item in _itemsFor(_NavSection.access))
                      _DesktopNavTile(
                        item: item,
                        selected: _isSelected(item),
                        onTap: () => _select(item),
                      ),
                    const _DesktopSectionLabel(label: 'GESTIÓN'),
                    for (final item in _itemsFor(_NavSection.management))
                      _DesktopNavTile(
                        item: item,
                        selected: _isSelected(item),
                        onTap: () => _select(item),
                      ),
                    _DesktopCatalogGroup(
                      items: _itemsFor(_NavSection.catalogs),
                      expanded: catalogsExpanded,
                      selected: _selectedSection == _NavSection.catalogs,
                      isSelected: _isSelected,
                      onToggle: () =>
                          setState(() => catalogsExpanded = !catalogsExpanded),
                      onSelected: _select,
                    ),
                    const _DesktopSectionLabel(label: 'CONSULTAS'),
                    for (final item in _itemsFor(_NavSection.reports))
                      _DesktopNavTile(
                        item: item,
                        selected: _isSelected(item),
                        onTap: () => _select(item),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton.icon(
                  onPressed: () async {
                    await ref.read(sessionViewModelProvider).signOut();
                    if (context.mounted) context.go('/acceso');
                  },
                  icon: const Icon(LucideIcons.logOut, size: 18),
                  label: const Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopSectionLabel extends StatelessWidget {
  const _DesktopSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 12, 12, 4),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.inkMuted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _DesktopNavTile extends StatelessWidget {
  const _DesktopNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
    this.indented = false,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool indented;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(indented ? 22 : 10, 1, 10, 1),
    child: Material(
      color: selected ? AppColors.navy : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: ListTile(
        dense: true,
        minTileHeight: 40,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        selected: selected,
        selectedColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        leading: Icon(item.icon, size: 18),
        title: Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        onTap: onTap,
      ),
    ),
  );
}

class _DesktopCatalogGroup extends StatelessWidget {
  const _DesktopCatalogGroup({
    required this.items,
    required this.expanded,
    required this.selected,
    required this.isSelected,
    required this.onToggle,
    required this.onSelected,
  });

  final List<_NavItem> items;
  final bool expanded;
  final bool selected;
  final bool Function(_NavItem) isSelected;
  final VoidCallback onToggle;
  final ValueChanged<_NavItem> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _DesktopSectionLabel(label: 'CATÁLOGOS'),
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 1, 10, 1),
        child: Material(
          color: selected && !expanded
              ? AppColors.blueSoft
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: ListTile(
            dense: true,
            minTileHeight: 40,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: const Icon(LucideIcons.libraryBig, size: 18),
            title: const Text(
              'Ver catálogos',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            trailing: Icon(
              expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 17,
            ),
            onTap: onToggle,
          ),
        ),
      ),
      if (expanded)
        for (final item in items)
          _DesktopNavTile(
            item: item,
            selected: isSelected(item),
            indented: true,
            onTap: () => onSelected(item),
          ),
    ],
  );
}

enum _NavSection { access, management, catalogs, reports }

extension on _NavSection {
  String get label => switch (this) {
    _NavSection.access => 'ACCESOS',
    _NavSection.management => 'GESTIÓN ACADÉMICA',
    _NavSection.catalogs => 'CATÁLOGOS',
    _NavSection.reports => 'CONSULTAS',
  };
}

class _NavItem {
  const _NavItem(
    this.label,
    this.route,
    this.icon, {
    required this.section,
    this.administratorOnly = false,
  });
  final String label;
  final String route;
  final IconData icon;
  final _NavSection section;
  final bool administratorOnly;
}
