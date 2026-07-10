import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/auth_providers.dart';
import '../providers/session_provider.dart';
import '../widgets/auth_header.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _loading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      showAppSnack(context, 'Please accept the terms to continue',
          kind: AppSnackKind.warning);
      return;
    }
    if (_passwordCtl.text != _confirmCtl.text) {
      showAppSnack(context, 'Passwords do not match',
          kind: AppSnackKind.error);
      return;
    }
    setState(() => _loading = true);

    final result = await ref.read(registerUseCaseProvider)(
      email: _emailCtl.text.trim(),
      password: _passwordCtl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (failure) => showAppSnack(context, failure.message, kind: AppSnackKind.error),
      (session) async {
        await ref.read(sessionProvider.notifier).signIn(
              userId: session.user.id,
              email: session.user.email,
            );
        if (!mounted) return;
        context.go(RoutePaths.profileSetup);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(
                  title: 'Create your account',
                  subtitle: 'Start your photography intelligence journey.',
                ),
                const AppGap.xl(),
                AppEmailField(
                  controller: _emailCtl,
                  textInputAction: TextInputAction.next,
                ),
                const AppGap.md(),
                AppPasswordField(
                  controller: _passwordCtl,
                  textInputAction: TextInputAction.next,
                ),
                const AppGap.md(),
                AppPasswordField(
                  controller: _confirmCtl,
                  label: 'Confirm password',
                  textInputAction: TextInputAction.done,
                  validator: (v) => v != _passwordCtl.text
                      ? 'Passwords do not match'
                      : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const AppGap.sm(),
                CheckboxListTile(
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text.rich(
                    TextSpan(
                      text: 'I agree to the ',
                      style: Theme.of(context).textTheme.bodySmall,
                      children: [
                        TextSpan(
                          text: 'Terms',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const AppGap.md(),
                AppPrimaryButton(
                  label: 'Create account',
                  loading: _loading,
                  expand: true,
                  onPressed: _submit,
                ),
                const AppGap.xl(),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: 'Sign in',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.go(RoutePaths.login),
                        ),
                      ],
                    ),
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
