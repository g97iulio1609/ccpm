import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'auth_service.dart';
import 'auth_buttons.dart';
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
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title Section
          Center(
            child: Text(
              isLogin.value ? 'Welcome Back' : 'Create Account',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLogin.value
                ? 'Sign in to continue your fitness journey'
                : 'Join us and start your transformation',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Social Sign In
          Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withAlpha(26),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withAlpha(26),
              ),
            ),
            child: const GoogleSignInButtonWrapper(),
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: theme.colorScheme.outline.withAlpha(26),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or continue with',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: theme.colorScheme.outline.withAlpha(26),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Form Fields
          EmailField(userEmail: userEmail),
          const SizedBox(height: 16),
          PasswordField(userPassword: userPassword),

          // Registration Fields
          if (!isLogin.value) ...[
            const SizedBox(height: 16),
            UsernameField(userName: userName),
            const SizedBox(height: 16),
            GenderField(userGender: userGender),
          ],

          const SizedBox(height: 24),

          // Submit Button
          SubmitButton(
            formKey: formKey,
            isLogin: isLogin,
            authService: authService,
            userEmail: userEmail,
            userPassword: userPassword,
            userName: userName,
            userGender: userGender,
          ),

          const SizedBox(height: 16),

          // Toggle Auth Mode
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLogin.value ? 'Not a member? ' : 'Already have an account? ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () => isLogin.value = !isLogin.value,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  isLogin.value ? 'Sign up' : 'Sign in',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          if (isLogin.value) ...[
            TextButton(
              onPressed: () {
                // Implementa la logica per il recupero password
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: Size.zero,
              ),
              child: Text(
                'Forgot password?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
