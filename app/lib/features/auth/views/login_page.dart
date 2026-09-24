import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  String? _validateEmail(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return 'Enter your email.';

    final parts = value.split('@');
    if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
      return 'Enter a valid email.';
    }
    return null;
  }

  String? _validatePassword(String? input) {
    return input == null || input.isEmpty ? 'Enter your password.' : null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text("Authentication isn't connected yet.")),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in to BICTC')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign-in is a preview and is not connected yet.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('email-field'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('password-field'),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      enableSuggestions: false,
                      autocorrect: false,
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Sign in'),
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
