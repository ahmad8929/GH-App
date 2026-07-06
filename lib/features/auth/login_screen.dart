import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../state/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? next;

  const LoginScreen({super.key, this.next});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .login(_email.text.trim(), _password.text);
      if (!mounted) return;
      showSuccess(context, 'Welcome back, ${user.name.split(' ').first}!');
      if (widget.next != null && widget.next!.startsWith('/')) {
        context.go(widget.next!);
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
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
      appBar: AppBar(title: const Text('Login')),
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
                            width: 64, height: 64, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s4),
                    Text('Welcome back 👋',
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: AppTokens.s2),
                    Text('Your orders, favorites, and pickups await.',
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
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: AppTokens.s3),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter your password'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppTokens.s4),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Text(_busy ? 'Logging in…' : 'Login'),
                    ),
                    const SizedBox(height: AppTokens.s3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('Create account'),
                        ),
                        TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text('Forgot password?'),
                        ),
                      ],
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
