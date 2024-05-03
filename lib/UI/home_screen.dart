import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'drawer.dart';
import 'appBar_custom.dart';
import '../users_services.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.child});

  final Widget child;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(usersServiceProvider).fetchUserRole();
    });
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      ref.read(usersServiceProvider).clearUserData();
      context.go('/');
    } catch (e) {
      debugPrint('Errore durante il logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final userRole = ref.watch(userRoleProvider);
    final user = FirebaseAuth.instance.currentUser;
    final controller = ref.watch(trainingProgramControllerProvider.notifier);

    return Scaffold(
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
              controller: controller,
              onLogout: _logout,
            )
          : null,
      body: Row(
        children: [
          if (user != null && isLargeScreen)
            SizedBox(
              width: 300,
              child: CustomDrawer(
                isLargeScreen: isLargeScreen,
                userRole: userRole,
                controller: controller,
                onLogout: _logout,
              ),
            ),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}