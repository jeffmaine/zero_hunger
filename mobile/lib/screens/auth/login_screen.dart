import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../widgets/primary_button.dart';
import 'widgets/auth_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _googleSignIn() async {
    setState(() => _error = null);
    try {
      final user = await ref.read(authProvider.notifier).signInWithGoogle(role: UserRole.receiver);
      if (!mounted || user == null) return;
      context.go(user.role == UserRole.donor ? '/donor' : '/receiver');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      final user = await ref.read(authProvider.notifier).login(_email.text.trim(), _password.text);
      if (!mounted || user == null) return;
      context.go(user.role == UserRole.donor ? '/donor' : '/receiver');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    final displayError = _error ?? ref.watch(authProvider).error;

    return AuthShell(
      title: 'Welcome back',
      subtitle: 'Log in to find or share food nearby.',
      footer: _AuthLink(
        text: "Don't have an account? ",
        action: 'Create account',
        onTap: () => context.push('/register'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (displayError != null) ...[
              AuthErrorBanner(message: displayError),
              const SizedBox(height: 16),
            ],
            AuthTextField(
              controller: _email,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _password,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kTextDisabled),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) => v == null || v.length < 8 ? 'At least 8 characters' : null,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Log in', isLoading: loading, onPressed: _submit),
            const SizedBox(height: 20),
            const AuthDivider(),
            const SizedBox(height: 20),
            GoogleSignInButton(
              isLoading: loading,
              onPressed: _googleSignIn,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthLink extends StatelessWidget {
  const _AuthLink({required this.text, required this.action, required this.onTap});

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: kTextSecondary),
            children: [
              TextSpan(text: text),
              TextSpan(
                text: action,
                style: const TextStyle(color: green500, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
