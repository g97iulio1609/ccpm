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

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLogin.value) UsernameField(userName: userName),
          const SizedBox(height: 10),
          if (!isLogin.value) GenderField(userGender: userGender),
          const SizedBox(height: 10),
          EmailField(userEmail: userEmail),
          const SizedBox(height: 10),
          PasswordField(userPassword: userPassword),
          const SizedBox(height: 20),
          SubmitButton(
            formKey: formKey,
            isLogin: isLogin,
            authService: authService,
            userEmail: userEmail,
            userPassword: userPassword,
            userName: userName,
            userGender: userGender,
          ),
          ToggleAuthModeButton(isLogin: isLogin),
          const GoogleSignInButtonWrapper(),
        ],
      ),
    );
  }
}