import 'package:sis_amerinst/core/config/app_brand.dart';
import 'package:sis_amerinst/app/router/app_router.dart';
import 'package:sis_amerinst/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SisAmerinstApp extends ConsumerWidget {
  const SisAmerinstApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppBrand.name,
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'BO'),
      supportedLocales: const [Locale('es', 'BO'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
