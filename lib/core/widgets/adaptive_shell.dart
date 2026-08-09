import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
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
    _NavItem('Inicio', '/inicio', LucideIcons.house),
    _NavItem('Escanear', '/escaner', LucideIcons.scanLine),
    _NavItem('Asistencia', '/asistencia', LucideIcons.clipboardCheck),
    _NavItem('Reportes', '/reportes', LucideIcons.chartNoAxesCombined),
    _NavItem('Cursos', '/cursos', LucideIcons.school),
    _NavItem(
      'Credenciales',
      '/credenciales',
      LucideIcons.idCard,
      administratorOnly: true,
    ),
  ];

  static const _desktopItems = [
    _NavItem('Inicio', '/inicio', LucideIcons.house),
    _NavItem('Escanear', '/escaner', LucideIcons.scanLine),
    _NavItem('Asistencia', '/asistencia', LucideIcons.clipboardCheck),
    _NavItem('Estudiantes', '/estudiantes', LucideIcons.graduationCap),
    _NavItem('Docentes', '/docentes', LucideIcons.presentation),
    _NavItem('Horarios', '/horarios', LucideIcons.calendarClock),
    _NavItem('Reportes', '/reportes', LucideIcons.chartNoAxesCombined),
    _NavItem('Cursos', '/cursos', LucideIcons.school),
    _NavItem(
      'Credenciales',
      '/credenciales',
      LucideIcons.idCard,
      administratorOnly: true,
    ),
  ];

  int _selectedIndex(List<_NavItem> items) {
    final index = items.indexWhere((item) => location.startsWith(item.route));
    return index < 0 ? 0 : index;
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
        location == '/estudiantes' ||
        location == '/docentes' ||
        location == '/horarios';
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
            Expanded(child: child),
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
                PopupMenuButton<String>(
                  tooltip: 'Gestión académica',
                  icon: const Icon(LucideIcons.usersRound, size: 19),
                  onSelected: context.go,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: '/estudiantes',
                      child: ListTile(
                        leading: Icon(LucideIcons.graduationCap, size: 18),
                        title: Text('Estudiantes'),
                      ),
                    ),
                    PopupMenuItem(
                      value: '/docentes',
                      child: ListTile(
                        leading: Icon(LucideIcons.presentation, size: 18),
                        title: Text('Docentes'),
                      ),
                    ),
                    PopupMenuItem(
                      value: '/horarios',
                      child: ListTile(
                        leading: Icon(LucideIcons.calendarClock, size: 18),
                        title: Text('Horarios'),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: () async {
                    await ref.read(sessionViewModelProvider).signOut();
                    if (context.mounted) context.go('/acceso');
                  },
                  icon: const Icon(LucideIcons.logOut, size: 19),
                ),
                const SizedBox(width: 4),
              ],
            ),
      body: child,
      bottomNavigationBar: managementPage
          ? null
          : NavigationBar(
              height: 66,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              selectedIndex: _selectedIndex(mobileItems),
              onDestinationSelected: (index) =>
                  context.go(mobileItems[index].route),
              destinations: mobileItems
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon, size: 20),
                      selectedIcon: Icon(item.icon, size: 20),
                      label: item.route == '/credenciales'
                          ? 'Carnets'
                          : item.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _DesktopNavigation extends ConsumerWidget {
  const _DesktopNavigation({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              for (var index = 0; index < items.length; index++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  child: Material(
                    color: selectedIndex == index
                        ? AppColors.navy
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    child: ListTile(
                      dense: true,
                      minTileHeight: 44,
                      selected: selectedIndex == index,
                      selectedColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      leading: Icon(items[index].icon, size: 18),
                      title: Text(
                        items[index].label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => onSelected(index),
                    ),
                  ),
                ),
              const Spacer(),
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

class _NavItem {
  const _NavItem(
    this.label,
    this.route,
    this.icon, {
    this.administratorOnly = false,
  });
  final String label;
  final String route;
  final IconData icon;
  final bool administratorOnly;
}
