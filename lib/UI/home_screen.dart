import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/spinner.dart';
import 'package:alphanessone/UI/components/snackbar.dart';
import 'drawer.dart';
import 'appBar_custom.dart';
import 'package:alphanessone/providers/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.child});

  final Widget child;

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUser();
    });
  }

  Future<void> _initializeUser() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(usersServiceProvider).fetchUserRole();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          message: 'Errore durante il caricamento del profilo: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      ref.read(usersServiceProvider).clearUserData();
      if (mounted) {
        context.go('/');
        AppSnackbar.success(
          context,
          message: 'Logout effettuato con successo',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          message: 'Errore durante il logout: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final userRole = ref.watch(userRoleProvider);
    final user = FirebaseAuth.instance.currentUser;
    final controller = ref.watch(trainingProgramControllerProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: AppSpinner(
            message: 'Caricamento...',
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: user != null
          ? CustomAppBar(
              userRole: userRole,
              controller: controller,
              isLargeScreen: isLargeScreen,
            )
          : null,
      drawer: user != null && !isLargeScreen
          ? CustomDrawer(
              isLargeScreen: isLargeScreen,
              userRole: userRole,
              onLogout: _logout,
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Row(
          children: [
            if (user != null && isLargeScreen)
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: CustomDrawer(
                  isLargeScreen: isLargeScreen,
                  userRole: userRole,
                  onLogout: _logout,
                ),
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: isLargeScreen ? Radius.circular(AppTheme.radii.xl) : Radius.zero,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: isLargeScreen ? Radius.circular(AppTheme.radii.xl) : Radius.zero,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}