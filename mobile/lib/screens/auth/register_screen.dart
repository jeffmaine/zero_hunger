import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/geo_provider.dart';
import '../../services/api_service.dart';
import '../../services/token_storage.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../widgets/primary_button.dart';
import 'widgets/auth_shell.dart';
import 'widgets/role_selector.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  UserRole _role = UserRole.receiver;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _password.addListener(() => setState(() {}));
  }

  Future<void> _loadRole() async {
    final pending = await ref.read(tokenStorageProvider).pendingRole();
    if (pending != null && mounted) {
      setState(() => _role = UserRole.values.byName(pending));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  int get _passwordStrength {
    final p = _password.text;
    if (p.length < 8) return 0;
    var score = 1;
    if (p.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[0-9]').hasMatch(p)) score++;
    return score.clamp(0, 3);
  }

  Future<void> _persistRole(UserRole role) {
    return ref.read(tokenStorageProvider).setPendingRole(role.apiValue);
  }

  Future<void> _googleSignIn() async {
    setState(() => _error = null);
    if (blockVolunteerSignup(context, _role)) return;
    try {
      final user = await ref.read(authProvider.notifier).signInWithGoogle(
            role: _role,
            phone: _phone.text.trim().length >= 10 ? _phone.text.trim() : '',
          );
      if (!mounted || user == null) return;
      goAfterAuth(context, user);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    if (blockVolunteerSignup(context, _role)) return;
    final geo = ref.read(geoProvider);

    try {
      final user = await ref.read(authProvider.notifier).register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            role: _role,
            phone: _phone.text.trim(),
            latitude: geo.latitude,
            longitude: geo.longitude,
          );
      if (!mounted || user == null) return;
      goAfterAuth(context, user);
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
      title: 'Join Zero Hunger',
      subtitle: 'Share surplus food or find meals nearby — free and dignified.',
      showBack: true,
      compact: true,
      footer: _AuthLink(
        text: 'Already have an account? ',
        action: 'Log in',
        onTap: () => context.go('/login'),
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
            RoleSelector(
              selected: _role,
              onChanged: (r) {
                setState(() => _role = r);
                _persistRole(r);
              },
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _name,
              label: 'Full name',
              hint: 'Amaka Okafor',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.length < 2 ? 'Enter your name' : null,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _phone,
              label: 'Phone',
              hint: '+2348012345678',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final p = (v ?? '').trim();
                if (p.length < 10) return 'Enter your full phone number';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _email,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _password,
              label: 'Password',
              hint: 'At least 8 characters',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kTextDisabled),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) => v == null || v.length < 8 ? 'At least 8 characters' : null,
            ),
            _PasswordStrengthBars(strength: _passwordStrength),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _confirm,
              label: 'Confirm password',
              hint: 'Repeat password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              validator: (v) => v != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Create account', isLoading: loading, onPressed: _submit),
            const SizedBox(height: 20),
            const AuthDivider(),
            const SizedBox(height: 20),
            GoogleSignInButton(isLoading: loading, onPressed: _googleSignIn),
          ],
        ),
      ),
    );
  }
}

class _PasswordStrengthBars extends StatelessWidget {
  const _PasswordStrengthBars({required this.strength});

  final int strength;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: List.generate(3, (i) {
          final active = i < strength;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: BoxDecoration(
                color: active ? (strength >= 3 ? green500 : green200) : gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
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
