import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_theme.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({
    required this.value,
    required this.onChanged,
    this.invalid = false,
    this.enabled = true,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool invalid;
  final bool enabled;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  static const _digitCount = 6;
  late final List<TextEditingController> _controllers = List.generate(
    _digitCount,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _focusNodes = List.generate(
    _digitCount,
    (_) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
    _syncValue(widget.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) _focusNodes.first.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant OtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _syncValue(widget.value);
    if (!oldWidget.enabled && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusFirstEmpty();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _syncValue(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '').padRight(_digitCount);
    for (var index = 0; index < _digitCount; index++) {
      final next = index < value.length ? digits[index] : '';
      if (_controllers[index].text != next) {
        _controllers[index].value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    }
  }

  String get _currentValue => _controllers.map((item) => item.text).join();

  void _focusFirstEmpty() {
    final index = _controllers.indexWhere((item) => item.text.isEmpty);
    _focusNodes[index < 0 ? _digitCount - 1 : index].requestFocus();
  }

  void _spreadDigits(int start, String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    for (var offset = 0;
        offset < digits.length && start + offset < _digitCount;
        offset++) {
      _controllers[start + offset].text = digits[offset];
    }
    widget.onChanged(_currentValue);
    final next = (start + digits.length).clamp(0, _digitCount - 1);
    _focusNodes[next].requestFocus();
    _controllers[next].selection = TextSelection.collapsed(
      offset: _controllers[next].text.length,
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Código de verificación de 6 dígitos',
        child: Row(
          children: [
            for (var index = 0; index < _digitCount; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    enabled: widget.enabled,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    textInputAction: index == _digitCount - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    autofillHints:
                        index == 0 ? const [AutofillHints.oneTimeCode] : null,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(_digitCount),
                    ],
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w700,
                        ),
                    decoration: InputDecoration(
                      labelText: 'Dígito ${index + 1}',
                      labelStyle: const TextStyle(fontSize: 0),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: widget.invalid
                              ? AppTheme.danger
                              : AppTheme.lineStrong,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: widget.invalid
                              ? AppTheme.danger
                              : AppTheme.lineStrong,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: widget.invalid
                              ? AppTheme.danger
                              : AppTheme.secondaryDark,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length > 1) {
                        _spreadDigits(index, value);
                        return;
                      }
                      widget.onChanged(_currentValue);
                      if (value.isNotEmpty && index < _digitCount - 1) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                    onSubmitted: (_) {
                      if (index < _digitCount - 1) {
                        _focusNodes[index + 1].requestFocus();
                      }
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}
