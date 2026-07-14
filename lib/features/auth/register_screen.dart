import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../state/auth_state.dart';

const _roles = [
  ('student', 'Student'),
  ('parent', 'Parent'),
  ('school', 'School'),
  ('tuition', 'Tuition / Coaching Institute'),
];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _userType = 'student';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await ref.read(authControllerProvider.notifier).register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
            userType: _userType,
          );
      if (!mounted) return;
      showSuccess(context, 'Welcome to Gyan Hub, ${user.name.split(' ').first}! 🎒');
      context.go('/home');
    } catch (err) {
      setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.s4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: AppTokens.brMd,
                        child: Image.asset('assets/images/logo.png',
                            width: 64 * AppTokens.scale, height: 64 * AppTokens.scale, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s4),
                    Text('Join the club 🎉',
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: AppTokens.s2),
                    Text(
                        'One account for shopping, selling back, and donating.',
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: AppTokens.s5),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppTokens.s3),
                        decoration: BoxDecoration(
                          color: AppTokens.danger.withValues(alpha: 0.1),
                          borderRadius: AppTokens.brSm,
                        ),
                        child: Text(_error!,
                            style: TextStyle(color: AppTokens.danger)),
                      ),
                      const SizedBox(height: AppTokens.s3),
                    ],
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppTokens.s3),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: AppTokens.s3),
                    DropdownButtonFormField<String>(
                      initialValue: _userType,
                      decoration: const InputDecoration(labelText: 'I am a…'),
                      items: _roles
                          .map((role) => DropdownMenuItem(
                              value: role.$1, child: Text(role.$2)))
                          .toList(),
                      onChanged: (v) => setState(() => _userType = v!),
                    ),
                    const SizedBox(height: AppTokens.s3),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: 'Phone (optional)'),
                    ),
                    const SizedBox(height: AppTokens.s3),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Password (min 8 characters)'),
                      validator: (v) => (v == null || v.length < 8)
                          ? 'At least 8 characters'
                          : null,
                    ),
                    const SizedBox(height: AppTokens.s3),
                    TextFormField(
                      controller: _confirm,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Confirm password'),
                      validator: (v) =>
                          v != _password.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: AppTokens.s4),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child:
                          Text(_busy ? 'Creating account…' : 'Create account'),
                    ),
                    const SizedBox(height: AppTokens.s2),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Already have an account? Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
