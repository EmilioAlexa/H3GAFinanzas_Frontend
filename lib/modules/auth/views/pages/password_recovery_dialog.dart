import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../models/recovery_step_model.dart';
import '../widgets/otp_input.dart';
import '../widgets/password_input.dart';

class PasswordRecoveryDialog extends StatefulWidget {
  const PasswordRecoveryDialog({super.key});

  @override
  State<PasswordRecoveryDialog> createState() => _PasswordRecoveryDialogState();
}

class _PasswordRecoveryDialogState extends State<PasswordRecoveryDialog> {
  static const _demoCode = '482916';
  static const _expiredDemoCode = '000000';
  static const _resetCodeSeconds = 600;
  static const _passwordMinLength = 8;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  RecoveryStep _step = RecoveryStep.email;
  String _code = '';
  String? _emailError;
  String? _codeError;
  String? _passwordError;
  String? _confirmationError;
  String? _requestError;
  int _secondsLeft = _resetCodeSeconds;
  bool _expired = false;
  bool _loading = false;
  bool _resending = false;
  bool _resendNotice = false;
  Timer? _countdown;

  @override
  void dispose() {
    _countdown?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _runDemo(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _requestError = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() {
          _requestError =
              'No pudimos completar la solicitud. Inténtalo de nuevo en unos momentos.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _validEmail(String value) => RegExp(
        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
      ).hasMatch(value.trim());

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Ingresa tu correo electrónico.');
      return;
    }
    if (!_validEmail(email)) {
      setState(() => _emailError = 'Ingresa un correo electrónico válido.');
      return;
    }

    setState(() => _emailError = null);
    await _runDemo(() async {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() {
        _code = '';
        _codeError = null;
        _expired = false;
        _secondsLeft = _resetCodeSeconds;
        _resendNotice = false;
        _step = RecoveryStep.code;
      });
      _startCountdown();
    });
  }

  void _startCountdown() {
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          _expired = true;
          _codeError = 'El código ha expirado. Solicita uno nuevo.';
        });
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _resendCode() async {
    setState(() {
      _resending = true;
      _requestError = null;
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() {
        _code = '';
        _codeError = null;
        _expired = false;
        _secondsLeft = _resetCodeSeconds;
        _resendNotice = true;
      });
      _startCountdown();
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_expired) return;
    if (_code.length != 6) {
      setState(() => _codeError = 'Ingresa los 6 dígitos del código.');
      return;
    }
    await _runDemo(() async {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      if (_code == _expiredDemoCode) {
        setState(() {
          _expired = true;
          _codeError = 'El código ha expirado. Solicita uno nuevo.';
        });
        _countdown?.cancel();
        return;
      }
      if (_code != _demoCode) {
        setState(() => _codeError = 'El código ingresado no es correcto.');
        return;
      }
      _countdown?.cancel();
      setState(() {
        _codeError = null;
        _step = RecoveryStep.password;
      });
    });
  }

  Future<void> _changePassword() async {
    final password = _passwordController.text;
    final confirmation = _confirmationController.text;
    var valid = true;

    if (password.isEmpty) {
      _passwordError = 'Ingresa una nueva contraseña.';
      valid = false;
    } else if (password.length < _passwordMinLength) {
      _passwordError =
          'La contraseña debe tener al menos $_passwordMinLength caracteres.';
      valid = false;
    } else {
      _passwordError = null;
    }

    if (confirmation.isEmpty) {
      _confirmationError = 'Confirma tu nueva contraseña.';
      valid = false;
    } else if (confirmation != password) {
      _confirmationError = 'Las contraseñas no coinciden.';
      valid = false;
    } else {
      _confirmationError = null;
    }

    setState(() {});
    if (!valid) return;

    await _runDemo(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _step = RecoveryStep.success);
    });
  }

  int get _stepIndex => RecoveryStep.values.indexOf(_step);

  String _maskedEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts.first.isEmpty) return email;
    final visible =
        parts.first.length == 1 ? parts.first : parts.first.substring(0, 2);
    return '$visible•••@${parts.last}';
  }

  String get _title => switch (_step) {
        RecoveryStep.email => 'Recuperar contraseña',
        RecoveryStep.code => 'Verificar identidad',
        RecoveryStep.password => 'Crear nueva contraseña',
        RecoveryStep.success => 'Contraseña restablecida',
      };

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.of(context) == WindowSizeClass.compacto;
    return PopScope(
      canPop: !_loading,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(compact ? 12 : 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.line),
              boxShadow: const [AppTheme.shadowLarge],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 20 : 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed:
                            _loading ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (_stepIndex + 1) / RecoveryStep.values.length,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    backgroundColor: AppTheme.line,
                    color: AppTheme.secondaryDark,
                  ),
                  const SizedBox(height: 20),
                  _buildStepBody(context),
                  if (_requestError != null) ...[
                    const SizedBox(height: 14),
                    AppNotice(
                      text: _requestError!,
                      type: AppNoticeType.error,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildActions(compact),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody(BuildContext context) => switch (_step) {
        RecoveryStep.email => _buildEmailStep(),
        RecoveryStep.code => _buildCodeStep(context),
        RecoveryStep.password => _buildPasswordStep(context),
        RecoveryStep.success => _buildSuccessStep(context),
      };

  Widget _buildEmailStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ingresa el correo electrónico asociado a tu cuenta y te enviaremos '
            'un código para confirmar tu identidad.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Correo electrónico',
            hint: 'usuario@h3ga.mx',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.mail_outline),
            autofocus: true,
            onFieldSubmitted: (_) => _requestCode(),
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
          ),
          if (_emailError != null) ...[
            const SizedBox(height: 6),
            _FieldError(text: _emailError!),
          ],
        ],
      );

  Widget _buildCodeStep(BuildContext context) {
    final remaining = Duration(seconds: _secondsLeft);
    final timerLabel =
        '${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: 'Enviamos un código de seis dígitos a ',
            children: [
              TextSpan(
                text: _maskedEmail(_emailController.text.trim()),
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'Código de verificación',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.inkSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        OtpInput(
          value: _code,
          invalid: _codeError != null,
          enabled: !_loading && !_resending && !_expired,
          onChanged: (value) => setState(() {
            _code = value;
            _codeError = null;
            _resendNotice = false;
          }),
        ),
        if (_codeError != null) ...[
          const SizedBox(height: 8),
          _FieldError(text: _codeError!),
        ],
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expired ? Icons.timer_off_outlined : Icons.schedule,
                  size: 16,
                  color: _expired ? AppTheme.danger : AppTheme.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  _expired ? 'Código expirado' : 'Válido durante $timerLabel',
                  style: TextStyle(
                    color: _expired ? AppTheme.danger : AppTheme.muted,
                    fontWeight: _expired ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _loading || _resending ? null : _resendCode,
              child: Text(_resending ? 'Reenviando…' : 'Reenviar código'),
            ),
          ],
        ),
        if (_resendNotice) ...[
          const SizedBox(height: 8),
          const AppNotice(
            text: 'Enviamos un nuevo código a tu correo.',
            type: AppNoticeType.success,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPasswordStep(BuildContext context) {
    final lengthMet = _passwordController.text.length >= _passwordMinLength;
    final matches = _confirmationController.text.isNotEmpty &&
        _confirmationController.text == _passwordController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Crea una nueva contraseña para proteger tu cuenta.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        PasswordInput(
          label: 'Nueva contraseña',
          controller: _passwordController,
          errorText: _passwordError,
          autofocus: true,
          onChanged: (_) => setState(() => _passwordError = null),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              lengthMet ? Icons.check_circle : Icons.circle_outlined,
              size: 17,
              color: lengthMet ? AppTheme.success : AppTheme.faint,
            ),
            const SizedBox(width: 8),
            Text(
              'Mínimo $_passwordMinLength caracteres',
              style: TextStyle(
                color: lengthMet ? AppTheme.success : AppTheme.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        PasswordInput(
          label: 'Confirmar contraseña',
          controller: _confirmationController,
          errorText: _confirmationError,
          onChanged: (_) => setState(() => _confirmationError = null),
        ),
        if (_confirmationController.text.isNotEmpty &&
            _confirmationError == null) ...[
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(
                matches ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 16,
                color: matches ? AppTheme.success : AppTheme.danger,
              ),
              const SizedBox(width: 6),
              Text(
                matches
                    ? 'Las contraseñas coinciden'
                    : 'Las contraseñas no coinciden',
                style: TextStyle(
                  color: matches ? AppTheme.success : AppTheme.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSuccessStep(BuildContext context) => Column(
        children: [
          Text(
            'Tu contraseña se cambió correctamente.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ahora puedes iniciar sesión con tus nuevas credenciales.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.muted,
                ),
          ),
          const SizedBox(height: 12),
        ],
      );

  Widget _buildActions(bool compact) {
    if (_step == RecoveryStep.success) {
      return AppButton(
        label: 'Iniciar sesión',
        onPressed: () => Navigator.of(context).pop(),
      );
    }

    final submit = AppButton(
      label: switch (_step) {
        RecoveryStep.email => 'Restablecer contraseña',
        RecoveryStep.code => 'Verificar código',
        RecoveryStep.password => 'Cambiar contraseña',
        RecoveryStep.success => 'Iniciar sesión',
      },
      loading: _loading,
      onPressed: _loading || (_step == RecoveryStep.code && _expired)
          ? null
          : switch (_step) {
              RecoveryStep.email => _requestCode,
              RecoveryStep.code => _verifyCode,
              RecoveryStep.password => _changePassword,
              RecoveryStep.success => null,
            },
      variant: AppButtonVariant.primary,
    );
    final cancel = AppButton(
      label: 'Cancelar',
      onPressed: _loading ? null : () => Navigator.of(context).pop(),
      variant: AppButtonVariant.secondary,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [submit, const SizedBox(height: 8), cancel],
      );
    }
    return Row(
      children: [
        Expanded(child: cancel),
        const SizedBox(width: 10),
        Expanded(child: submit),
      ],
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.danger,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
}
