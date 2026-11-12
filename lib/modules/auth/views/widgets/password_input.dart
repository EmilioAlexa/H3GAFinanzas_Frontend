import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';

class PasswordInput extends StatefulWidget {
  const PasswordInput({
    required this.label,
    required this.controller,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: widget.label,
            controller: widget.controller,
            obscureText: !_visible,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            suffixIcon: IconButton(
              tooltip: _visible ? 'Ocultar contraseña' : 'Mostrar contraseña',
              onPressed: widget.enabled
                  ? () => setState(() => _visible = !_visible)
                  : null,
              icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
            ),
          ),
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                widget.errorText!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.danger),
              ),
            ),
        ],
      );
}
