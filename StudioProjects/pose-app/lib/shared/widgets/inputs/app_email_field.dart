import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import 'app_text_field.dart';

/// Email input with built-in validation.
class AppEmailField extends StatelessWidget {
  const AppEmailField({
    super.key,
    this.controller,
    this.focusNode,
    this.label = 'Email',
    this.hint = 'you@example.com',
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.autofillHints = const ['username'],
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      focusNode: focusNode,
      label: label,
      hint: hint,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      autofillHints: autofillHints,
      prefixIcon: const Icon(Icons.mail_outline, size: 20),
      validator: Validators.email,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
