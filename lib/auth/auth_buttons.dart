import 'package:alphanessone/providers/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  SubmitButtonState createState() => SubmitButtonState();
}

class SubmitButtonState extends ConsumerState<SubmitButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userRole = ref.watch(userRoleProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withAlpha(26),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: MaterialButton(
        onPressed: _isLoading ? null : () => _submit(userRole),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                widget.isLogin.value ? 'Sign In' : 'Create Account',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Future<void> _submit(String userRole) async {
    if (!mounted) return;
    if (widget.formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      widget.formKey.currentState?.save();

      try {
        final email = widget.userEmail.value.trim();
        final password = widget.userPassword.value.trim();
        final UserCredential userCredential =
            await _performAuthentication(email, password);

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
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<UserCredential> _performAuthentication(
      String email, String password) async {
    if (widget.isLogin.value) {
      return await widget.authService
          .signInWithEmailAndPassword(email, password);
    } else {
      return await widget.authService.signUpWithEmailAndPassword(
        email,
        password,
        widget.userName.value,
        widget.userGender.value,
      );
    }
  }

  void _navigateToAppropriateScreen(String userRole, String userId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userRole == 'admin' || userRole == 'coach') {
        context.go('/programs_screen');
      } else {
        context.go('/user_programs', extra: {'userId': userId});
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class GoogleSignInButtonWrapper extends ConsumerWidget {
  const GoogleSignInButtonWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authService = ref.watch(authServiceProvider);
    final userRole = ref.watch(userRoleProvider);

    if (Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      return SignInWithGoogleButton(
        onPressed: () => _handleGoogleSignIn(context, authService, userRole),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: MaterialButton(
        onPressed: () => _handleGoogleSignIn(context, authService, userRole),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withAlpha(26),
          ),
        ),
        color: theme.colorScheme.surface,
        elevation: 0,
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.google,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Center(
              child: Text(
                'Sign in with Google',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(
    BuildContext context,
    AuthService authService,
    String userRole,
  ) async {
    try {
      final userCredential = await authService.signInWithGoogle();
      if (userCredential != null) {
        final userId = userCredential.user?.uid;
        if (userId != null && context.mounted) {
          _showSnackBar(context, 'Google Sign-In successful', Colors.green);
          _navigateToAppropriateScreen(context, userRole, userId);
        }
      }
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(
          context,
          'Failed to sign in with Google: $error',
          Colors.red,
        );
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToAppropriateScreen(
      BuildContext context, String userRole, String userId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userRole == 'admin' || userRole == 'coach') {
        context.go('/programs_screen');
      } else {
        context.go('/user_programs', extra: {'userId': userId});
      }
    });
  }
}

class SignInWithGoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SignInWithGoogleButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: MaterialButton(
        onPressed: onPressed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withAlpha(51),
          ),
        ),
        color: theme.colorScheme.surface,
        elevation: 0,
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Image.asset(
                  'assets/images/google_g_logo.png',
                  height: 24,
                  width: 24,
                ),
              ),
            ),
            Center(
              child: Text(
                'Sign in with Google',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        isLogin.value
            ? 'Not a Member? Create an Account'
            : 'I already have an account',
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 16,
        ),
      ),
    );
  }
}
