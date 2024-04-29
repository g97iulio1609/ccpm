import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'auth_service.dart';
import 'buttons.dart';
import 'form_fields.dart';

class AuthForm extends HookConsumerWidget {
  const AuthForm({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLogin = useState(true);
    final userEmail = useState('');
    final userPassword = useState('');
    final userName = useState('');
    final userGender = useState('');

    return Container(
      color: const Color(0xFF121212),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Begin your journey',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GoogleSignInButtonWrapper(),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Or continue with',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  EmailField(userEmail: userEmail),
                  const SizedBox(height: 16),
                  PasswordField(userPassword: userPassword),
                  if (!isLogin.value) ...[
                    const SizedBox(height: 16),
                    UsernameField(userName: userName),
                    const SizedBox(height: 16),
                    GenderField(userGender: userGender),
                  ],
                  const SizedBox(height: 24),
                  SubmitButton(
                    formKey: formKey,
                    isLogin: isLogin,
                    authService: authService,
                    userEmail: userEmail,
                    userPassword: userPassword,
                    userName: userName,
                    userGender: userGender,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => isLogin.value = !isLogin.value,
                    child: Text(
                      isLogin.value ? 'Not a Member? Create an Account' : 'I already have an account',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}