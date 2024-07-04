import 'package:alphanessone/providers/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      onPressed: () => _submit(userRole),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
      child: Text(
        widget.isLogin.value ? 'Login' : 'Sign Up',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Future<void> _submit(String userRole) async {
    if (!mounted) return;
    if (widget.formKey.currentState?.validate() ?? false) {
      widget.formKey.currentState?.save();
      final email = widget.userEmail.value.trim();
      final password = widget.userPassword.value.trim();
      try {
        final UserCredential userCredential = await _performAuthentication(email, password);
        final userId = userCredential.user?.uid;
        if (userId != null) {
          await widget.authService.updateUserName(userCredential.user!);
          if (!mounted) return;
          _showSnackBar('Authentication successful', Colors.green);
          _navigateToAppropriateScreen(userRole, userId);
        } else {
          if (!mounted) return;
          _showSnackBar('Failed to retrieve user ID', Colors.red);
        }
      } catch (error) {
        if (!mounted) return;
        _showSnackBar(error.toString(), Colors.red);
      }
    }
  }

  Future<UserCredential> _performAuthentication(String email, String password) async {
    if (widget.isLogin.value) {
      return await widget.authService.signInWithEmailAndPassword(email, password);
    } else {
      return await widget.authService.signUpWithEmailAndPassword(
          email, password, widget.userName.value, widget.userGender.value);
    }
  }

  void _navigateToAppropriateScreen(String userRole, String userId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userRole == 'admin') {
        context.go('/programs_screen');
      } else {
        context.go('/programs_screen/user_programs/$userId');
      }
    });
  }

  void _showSnackBar(String message, Color color) {
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
      onPressed: () => isLogin.value = !isLogin.value,
      child: Text(
        isLogin.value ? 'Not a Member? Create an Account' : 'I already have an account',
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 16,
        ),
      ),
    );
  }
}