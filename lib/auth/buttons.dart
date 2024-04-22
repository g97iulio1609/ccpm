import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';

import '../users_services.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_service.dart';

class SubmitButton extends ConsumerStatefulWidget {
  const SubmitButton({
    super.key,
    required this.formKey,
    required this.isLogin,
    required this.authService,
    required this.userEmail,
    required this.userPassword,
    required this.userName,
    required this.userGender,
  });

  final GlobalKey<FormState> formKey;
  final ValueNotifier<bool> isLogin;
  final AuthService authService;
  final ValueNotifier<String> userEmail;
  final ValueNotifier<String> userPassword;
  final ValueNotifier<String> userName;
  final ValueNotifier<String> userGender;

  @override
  _SubmitButtonState createState() => _SubmitButtonState();
}

class _SubmitButtonState extends ConsumerState<SubmitButton> {
  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(userRoleProvider);

    return ElevatedButton(
      onPressed: () => _submit(context, userRole),
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
      child: Text(widget.isLogin.value ? 'Login' : 'Sign Up'),
    );
  }

  Future<void> _submit(BuildContext context, String userRole) async {
    if (widget.formKey.currentState?.validate() ?? false) {
      widget.formKey.currentState?.save();
      final email = widget.userEmail.value.trim();
      final password = widget.userPassword.value.trim();
      try {
        final UserCredential userCredential;
        if (widget.isLogin.value) {
          userCredential = await widget.authService.signInWithEmailAndPassword(email, password);
        } else {
          userCredential = await widget.authService.signUpWithEmailAndPassword(
              email, password, widget.userName.value, widget.userGender.value);
        }
        final userId = userCredential.user?.uid;
        if (userId != null) {
          await widget.authService.updateUserName(userCredential.user!);
          if (mounted) {
            _showSnackBar(context, 'Authentication successful', Colors.green);
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (userRole == 'admin') {
                context.go('/programs_screen');
              } else {
                context.go('/programs_screen/user_programs/$userId');
              }
            });
          }
        } else {
          if (mounted) {
            _showSnackBar(context, 'Failed to retrieve user ID', Colors.red);
          }
        }
      } catch (error) {
        if (mounted) {
          _showSnackBar(context, error.toString(), Colors.red);
        }
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}

class GoogleSignInButtonWrapper extends ConsumerWidget {
  const GoogleSignInButtonWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final userRole = ref.watch(userRoleProvider);

    return authService.renderGoogleSignInButton(context, userRole);
  }
}

class ToggleAuthModeButton extends StatelessWidget {
  const ToggleAuthModeButton({super.key, required this.isLogin});

  final ValueNotifier<bool> isLogin;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(
          isLogin.value ? 'Create new account' : 'I already have an account'),
      onPressed: () => isLogin.value = !isLogin.value,
    );
  }
}