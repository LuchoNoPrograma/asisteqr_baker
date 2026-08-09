import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/institution_mark.dart';
import 'package:asisteqr_baker/features/auth/presentation/session_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  late final AnimationController _controller;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(sessionViewModelProvider)
        .signIn(_username.text, _password.text);
    if (ok && mounted) context.go('/inicio');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionViewModelProvider);
    final busy = session.status == SessionStatus.authenticating;
    final size = MediaQuery.sizeOf(context);
    final desktop = size.width >= 900;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/baker-campus.webp',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
          ),
          const ColoredBox(color: Color(0x6617365F)),
          SafeArea(
            child: Align(
              alignment: desktop ? Alignment.centerRight : Alignment.center,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  desktop ? size.width * .07 : 20,
                  20,
                ),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOut,
                  ),
                  child: SlideTransition(
                    position:
                        Tween(
                          begin: const Offset(0, .05),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        padding: EdgeInsets.all(size.width < 390 ? 20 : 28),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Align(child: InstitutionMark(size: 64)),
                                const SizedBox(height: 18),
                                Text(
                                  'AsisteQR Baker',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Sistema institucional de asistencia',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 28),
                                TextFormField(
                                  controller: _username,
                                  autofillHints: const [AutofillHints.username],
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Usuario',
                                    prefixIcon: Icon(
                                      LucideIcons.userRound,
                                      size: 18,
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().length < 3
                                      ? 'Ingresa un usuario válido'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) =>
                                      busy ? null : _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    prefixIcon: const Icon(
                                      LucideIcons.lockKeyhole,
                                      size: 18,
                                    ),
                                    suffixIcon: IconButton(
                                      tooltip: _obscure
                                          ? 'Mostrar contraseña'
                                          : 'Ocultar contraseña',
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? LucideIcons.eye
                                            : LucideIcons.eyeOff,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == null || value.length < 4
                                      ? 'Ingresa tu contraseña'
                                      : null,
                                ),
                                if (session.errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  _LoginError(message: session.errorMessage!),
                                ],
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: busy ? null : _submit,
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: busy
                                        ? const SizedBox(
                                            key: ValueKey('loading'),
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            LucideIcons.logIn,
                                            key: ValueKey('login'),
                                            size: 18,
                                          ),
                                  ),
                                  label: const Text('Ingresar'),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  '¿Necesita ayuda? Contacte al soporte técnico institucional.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.redSoft,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        const Icon(LucideIcons.circleAlert, size: 17, color: AppColors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
          ),
        ),
      ],
    ),
  );
}
