import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await ref
        .read(requestPasswordResetUseCaseProvider)(_emailCtl.text.trim());

    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = true;
    });

    result.fold(
      (failure) =>
          showAppSnack(context, failure.message, kind: AppSnackKind.error),
      (_) => showAppSnack(context, 'Reset link sent', kind: AppSnackKind.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Forgot password',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const AppGap.sm(),
                Text(
                  _sent
                      ? 'If an account exists for ${_emailCtl.text}, a reset link is on its way.'
                      : 'Enter your email and we\'ll send you a reset link.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const AppGap.lg(),
                AppEmailField(
                  controller: _emailCtl,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const AppGap.lg(),
                AppPrimaryButton(
                  label: _sent ? 'Resend link' : 'Send reset link',
                  loading: _loading,
                  expand: true,
                  onPressed: _submit,
                ),
                const AppGap.lg(),
                AppTextButton(
                  label: 'Back to sign in',
                  icon: Icons.arrow_back,
                  onPressed: () => context.go(RoutePaths.login),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
