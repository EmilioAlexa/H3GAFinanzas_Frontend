import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/config/env.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_error_model.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/widgets/app_button.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_role_model.dart';
import 'password_recovery_dialog.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = Responsive.of(context);
    final compact = size == WindowSizeClass.compacto;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final error = authState.hasError
        ? ApiErrorModel.fromObject(authState.error!).message
        : null;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/login_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) =>
                  const ColoredBox(color: AppTheme.primary),
            ),
            ColoredBox(
              color: compact
                  ? AppTheme.accentDark.withValues(alpha: .84)
                  : AppTheme.primary.withValues(alpha: .80),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(compact ? 16 : 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 608,
                      minHeight: compact
                          ? 0
                          : (constraints.maxHeight - 48)
                              .clamp(0, 804)
                              .toDouble(),
                    ),
                    child: Container(
                      padding: compact
                          ? const EdgeInsets.symmetric(vertical: 20)
                          : const EdgeInsets.symmetric(
                              horizontal: 72,
                              vertical: 52,
                            ),
                      decoration: compact
                          ? null
                          : BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF12444F),
                                  AppTheme.primary,
                                  AppTheme.accentDark,
                                ],
                                stops: [0, .55, 1],
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLoginCard,
                              ),
                              border: Border.all(
                                color:
                                    AppTheme.secondary.withValues(alpha: .14),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x66011818),
                                  blurRadius: 20,
                                  offset: Offset(0, 18),
                                ),
                                BoxShadow(
                                  color: Color(0x0FFCFCFC),
                                  blurRadius: 0,
                                  offset: Offset(0, 1),
                                  spreadRadius: -1,
                                ),
                              ],
                            ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 408),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildIntro(compact),
                                SizedBox(height: compact ? 34 : 48),
                                _buildForm(error, isLoading),
                                if (AppEnv.demoMode) ...[
                                  const SizedBox(height: 18),
                                  _buildDemoRoleSelector(),
                                ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(bool compact) => Column(
        children: [
          SizedBox(
            width: compact ? 180 : 200,
            height: compact ? 180 : 200,
            child: Image.asset(
              'assets/images/h3ga_logo.png',
              fit: BoxFit.contain,
              semanticLabel: 'H3GA Seguros y Pensiones',
            ),
          ),
          SizedBox(height: compact ? 24 : 28),
          Text(
            'Bienvenido de vuelta',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.white,
              fontSize: compact ? 28 : 36,
              fontWeight: FontWeight.w700,
              letterSpacing: compact ? -.56 : -.72,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ingrese sus credenciales para acceder al sistema',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFA9C2C6),
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      );

  Widget _buildForm(String? error, bool isLoading) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLoginField(
            label: 'Usuario',
            controller: _email,
            hint: 'usuario@h3ga.mx',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            icon: Icons.person_outline_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa tu correo electrónico.';
              }
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                  .hasMatch(value.trim())) {
                return 'Ingresa un correo electrónico válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          _buildLoginField(
            label: 'Contraseña',
            controller: _password,
            hint: 'Ingresa tu contraseña',
            obscureText: !_showPassword,
            autofillHints: const [AutofillHints.password],
            icon: Icons.lock_outline_rounded,
            suffix: IconButton(
              tooltip:
                  _showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
              onPressed: () => setState(() => _showPassword = !_showPassword),
              color: const Color(0xFFD5E3E5),
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                size: 19,
              ),
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'Ingresa tu contraseña.'
                : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.secondary,
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: const Size(48, 48),
                textStyle: const TextStyle(fontSize: 15),
              ),
              onPressed: isLoading ? null : _openRecovery,
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ),
          if (AppEnv.demoMode) ...[
            const SizedBox(height: 2),
            Text(
              'Modo demostración · no se consulta el backend',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.white.withValues(alpha: .72),
                fontSize: 12,
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: const TextStyle(
                  color: Color(0xFFFFC5CC),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          AppButton(
            label: isLoading ? 'Verificando acceso…' : 'Iniciar sesión',
            loading: isLoading,
            variant: AppButtonVariant.gold,
            onPressed: isLoading ? null : _submit,
          ),
        ],
      );

  Widget _buildLoginField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FormFieldValidator<String> validator,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    bool obscureText = false,
    Widget? suffix,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(color: Color(0xFFD5E3E5), fontSize: 16),
        cursorColor: AppTheme.secondary,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            color: AppTheme.secondary,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppTheme.secondary,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: const TextStyle(color: Color(0xFFD5E3E5)),
          prefixIcon: Icon(icon, color: const Color(0xFFA9C2C6), size: 20),
          suffixIcon: suffix,
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          errorStyle: const TextStyle(color: Color(0xFFFFC5CC)),
          errorMaxLines: 2,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0x99D5E3E5)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.secondary, width: 2),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF7E8D), width: 1.5),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF7E8D), width: 2),
          ),
        ),
      );

  Widget _buildDemoRoleSelector() {
    final selectedRole = ref.watch(demoRoleProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Rol para probar la navegación',
          style: TextStyle(color: Color(0xFFA9C2C6), fontSize: 12),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<UserRole>(
          initialValue: selectedRole,
          dropdownColor: AppTheme.accentDark,
          style: const TextStyle(color: AppTheme.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.white.withValues(alpha: .08),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(
                color: AppTheme.white.withValues(alpha: .18),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          items: [
            for (final role in UserRole.values)
              DropdownMenuItem(value: role, child: Text(role.apiName)),
          ],
          onChanged: (role) {
            if (role != null) ref.read(demoRoleProvider.notifier).state = role;
          },
        ),
      ],
    );
  }

  Future<void> _openRecovery() => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PasswordRecoveryDialog(),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .login(_email.text.trim(), _password.text);
  }
}
