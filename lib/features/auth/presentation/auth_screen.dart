// Email/password sign in and sign up. Shows clear errors and handles the
// email-confirmation case (account created, no session yet).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../data/auth_repository.dart';
import 'auth_providers.dart';

enum AuthMode { signIn, signUp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.mode});

  final AuthMode mode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _confirmationPending = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _confirmationPending = false;
    });
    try {
      final AuthRepository auth = ref.read(authRepositoryProvider);
      final String email = _email.text.trim();
      final String password = _password.text;
      if (widget.mode == AuthMode.signUp) {
        final bool sessionCreated = await auth.signUp(
          email: email,
          password: password,
        );
        if (!mounted) {
          return;
        }
        if (!sessionCreated) {
          setState(() {
            _isLoading = false;
            _confirmationPending = true;
          });
          return;
        }
      } else {
        await auth.signIn(email: email, password: password);
        if (!mounted) {
          return;
        }
      }
      // Router redirect takes over from here.
    } on AuthFailure catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isSignUp = widget.mode == AuthMode.signUp;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const SizedBox(height: 32),
            Text('Receipts', style: theme.textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
              isSignUp
                  ? 'Create your account. 90 days. No hiding.'
                  : 'Welcome back. Your ledger kept score while you were gone.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your email.';
                      }
                      if (!value.contains('@')) {
                        return 'That email does not look right.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const <String>[AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your password.';
                      }
                      if (isSignUp && value.length < 6) {
                        return 'Use at least 6 characters.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                semanticsLabel: 'Error: $_error',
              ),
            ],
            if (_confirmationPending) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                'Account created. Open the confirmation link on this device '
                '— it signs you in automatically.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: isSignUp ? 'Create account' : 'Sign in',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(isSignUp ? '/signin' : '/signup'),
              child: Text(
                isSignUp
                    ? 'Already have an account? Sign in'
                    : 'New here? Create an account',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sign-out action used in signed-in app bars (with confirm).
class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Sign out',
      onPressed: () async {
        final bool confirmed = await showFinalConfirm(
          context: context,
          title: 'Sign out?',
          body:
              'Your ledger stays safe on the server. '
              'Signing out only ends this session.',
          confirmLabel: 'Sign out',
        );
        if (!confirmed || !context.mounted) {
          return;
        }
        try {
          await ref.read(authRepositoryProvider).signOut();
        } on AuthFailure catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.message)));
          }
        }
      },
    );
  }
}
