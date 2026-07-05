import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../state/providers.dart';

enum _Step { email, otp, reset }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  _Step _step = _Step.email;
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    for (final c in [_email, _code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (err) {
      setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendOtp() => _run(() async {
        await ref.read(authApiProvider).forgotPassword(_email.text.trim());
        setState(() {
          _info =
              'If this email is registered, an OTP is on its way. It expires in 10 minutes.';
          _step = _Step.otp;
        });
      });

  Future<void> _verifyOtp() => _run(() async {
        await ref
            .read(authApiProvider)
            .verifyOtp(_email.text.trim(), _code.text.trim());
        setState(() {
          _info = null;
          _step = _Step.reset;
        });
      });

  Future<void> _reset() => _run(() async {
        if (_password.text.length < 8) {
          throw Exception('Password must be at least 8 characters');
        }
        if (_password.text != _confirm.text) {
          throw Exception('Passwords do not match');
        }
        await ref.read(authApiProvider).resetPassword(
            _email.text.trim(), _code.text.trim(), _password.text);
        if (!mounted) return;
        showSuccess(context, 'Password reset! Please log in.');
        context.go('/login');
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (_step) {
      _Step.email => 'Forgot your password?',
      _Step.otp => 'Check your inbox',
      _Step.reset => 'Set a new password',
    };
    final subtitle = switch (_step) {
      _Step.email => "We'll email you a one-time code.",
      _Step.otp => 'Enter the 6-digit code we sent to ${_email.text.trim()}.',
      _Step.reset => 'Almost done — pick something memorable.',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.s4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppTokens.s2),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
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
                  ] else if (_info != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppTokens.s3),
                      decoration: BoxDecoration(
                        color: AppTokens.tint,
                        borderRadius: AppTokens.brSm,
                      ),
                      child: Text(_info!),
                    ),
                    const SizedBox(height: AppTokens.s3),
                  ],
                  if (_step == _Step.email)
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                  if (_step == _Step.otp)
                    TextField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'One-time code'),
                    ),
                  if (_step == _Step.reset) ...[
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'New password'),
                    ),
                    const SizedBox(height: AppTokens.s3),
                    TextField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Confirm new password'),
                    ),
                  ],
                  const SizedBox(height: AppTokens.s4),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : switch (_step) {
                            _Step.email => _sendOtp,
                            _Step.otp => _verifyOtp,
                            _Step.reset => _reset,
                          },
                    child: Text(_busy
                        ? 'Working…'
                        : switch (_step) {
                            _Step.email => 'Send code',
                            _Step.otp => 'Verify code',
                            _Step.reset => 'Reset password',
                          }),
                  ),
                  if (_step == _Step.otp) ...[
                    const SizedBox(height: AppTokens.s2),
                    OutlinedButton(
                      onPressed: _busy ? null : _sendOtp,
                      child: const Text('Resend code'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
