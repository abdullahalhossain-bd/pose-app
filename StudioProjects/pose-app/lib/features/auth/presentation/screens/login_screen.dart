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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await ref.read(signInUseCaseProvider)(
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
        // The router's redirect will route to profile setup or home.
        context.go(RoutePaths.home);
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
                  title: 'Welcome back',
                  subtitle: 'Sign in to continue to AI Visual Director.',
                ),
                const AppGap.xl(),
                AppEmailField(
                  controller: _emailCtl,
                  textInputAction: TextInputAction.next,
                ),
                const AppGap.md(),
                AppPasswordField(
                  controller: _passwordCtl,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppTextButton(
                    label: 'Forgot password?',
                    onPressed: () => context.push(RoutePaths.forgotPassword),
                  ),
                ),
                const AppGap.lg(),
                AppPrimaryButton(
                  label: 'Sign in',
                  loading: _loading,
                  expand: true,
                  onPressed: _submit,
                ),
                const AppGap.xl(),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: 'Sign up',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.go(RoutePaths.register),
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
