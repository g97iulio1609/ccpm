import 'package:alphanessone/trainingBuilder/training_program_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'users_services.dart';

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

  void _navigateTo(String menuItem, bool isLargeScreen) {
    final userRole = ref.watch(userRoleProvider);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final String? route = _getRouteForMenuItem(menuItem, userRole, userId);
    if (route != null) {
      context.go(route);
      if (!isLargeScreen) {
        Navigator.pop(context);
      }
    }
  }

  String? _getRouteForMenuItem(String menuItem, String userRole, String? userId) {
    switch (menuItem) {
      case 'Allenamenti':
        return userRole == 'admin'
            ? '/programs_screen'
            : userId != null
                ? '/programs_screen/user_programs/$userId'
                : null;
      case 'Esercizi':
        return '/exercises_list';
      case 'Massimali':
        return '/maxrmdashboard';
      case 'Profilo Utente':
        return '/user_profile';
      case 'TrainingProgram':
        return '/training_program';
      case 'Gestione Utenti':
        return userRole == 'admin' ? '/users_dashboard' : null;
      case 'Volume Allenamento':
        return '/volume_dashboard';
      default:
        return null;
    }
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

  String _getTitleForRoute(BuildContext context) {
    final String currentPath = GoRouterState.of(context).uri.toString();

    switch (currentPath) {
      case '/programs_screen':
        return 'Allenamenti';
      case '/exercises_list':
        return 'Esercizi';
      case '/maxrmdashboard':
        return 'Massimali';
      case '/user_profile':
        return 'Profilo Utente';
      case '/training_program':
        return 'Programma di Allenamento';
      case '/users_dashboard':
        return 'Gestione Utenti';
      case '/volume_dashboard':
        return 'Volume Allenamento';
      case '/user_programs':
        return 'Programmi Utente';
      default:
        break;
    }

    final pattern1 = RegExp(r'/programs_screen/user_programs/\w+/training_viewer/\w+/week_details/\w+$');
    if (pattern1.hasMatch(currentPath)) {
      return 'Dettagli Settimana';
    }

    final pattern2 = RegExp(r'/programs_screen/user_programs/\w+/training_viewer/\w+/week_details/\w+/workout_details/\w+$');
    if (pattern2.hasMatch(currentPath)) {
      return 'Dettagli Allenamento';
    }

    final pattern3 = RegExp(r'/programs_screen/user_programs/\w+/training_viewer/\w+/week_details/\w+/workout_details/\w+/exercise_details/\w+$');
    if (pattern3.hasMatch(currentPath)) {
      return 'Dettagli Esercizio';
    }

    final pattern4 = RegExp(r'/programs_screen/user_programs/\w+/training_viewer/\w+/week_details/\w+/workout_details/\w+/exercise_details/\w+/timer$');
    if (pattern4.hasMatch(currentPath)) {
      return 'Timer';
    }

    final weekPattern = RegExp(r'/programs_screen/user_programs/\w+/training_program/\w+/week/\d+$');
    if (weekPattern.hasMatch(currentPath)) {
      final weekIndex = int.parse(currentPath.split('/').last);
      return 'Settimana ${weekIndex + 1}';
    }

    return 'Alphaness One';
  }

  bool _isTrainingProgramRoute(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    return currentRoute.startsWith('/programs_screen/user_programs/') &&
        (currentRoute.contains('/training_program/') ||
            currentRoute.contains('/week/'));
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final userRole = ref.watch(userRoleProvider);
    final user = FirebaseAuth.instance.currentUser;
    final controller = ref.watch(trainingProgramControllerProvider);

    final currentRoute = GoRouterState.of(context).uri.toString();
    final isBackButtonVisible = currentRoute.split('/').length > 2;

    return Scaffold(
      appBar: user != null
          ? AppBar(
              title: Text(_getTitleForRoute(context)),
              leading: isBackButtonVisible
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        final currentPath = GoRouterState.of(context).uri.toString();
                        final trainingProgramWeekPattern = RegExp(r'/programs_screen/user_programs/\w+/training_program/\w+/week/\d+$');
                        final trainingProgramPattern = RegExp(r'/programs_screen/user_programs/\w+/training_program/\w+$');

                        if (trainingProgramWeekPattern.hasMatch(currentPath)) {
                          final programId = currentPath.split('/')[5];
                          final userId = currentPath.split('/')[3];
                          context.go('/programs_screen/user_programs/$userId/training_program/$programId');
                        } else if (trainingProgramPattern.hasMatch(currentPath)) {
                          final userId = currentPath.split('/')[3];
                          context.go('/programs_screen/user_programs/$userId');
                        } else {
                          context.pop();
                        }
                      },
                    )
                  : null,
              actions: [
                if (userRole == 'admin' && GoRouterState.of(context).uri.toString() == '/users_dashboard')
                  IconButton(
                    onPressed: () => _showAddUserDialog(context),
                    icon: const Icon(Icons.person_add),
                  ),
                if (_isTrainingProgramRoute(context))
                  IconButton(
                    onPressed: () => controller.submitProgram(context),
                    icon: const Icon(Icons.save),
                  ),
              ],
            )
          : null,
      drawer: user != null && !isLargeScreen
          ? Drawer(
              child: _buildDrawer(isLargeScreen, context, userRole, controller),
            )
          : null,
      body: Row(
        children: [
          if (user != null && isLargeScreen)
            SizedBox(
              width: 300,
              child: _buildDrawer(isLargeScreen, context, userRole, controller),
            ),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(bool isLargeScreen, BuildContext context, String userRole, TrainingProgramController controller) {
    final List<String> menuItems = userRole == 'admin' ? _getAdminMenuItems() : _getClientMenuItems();
    final isTrainingProgramRoute = GoRouterState.of(context).uri.toString().contains('/training_program/');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16.0, 48.0, 16.0, 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Menù', style: Theme.of(context).textTheme.titleLarge),
              if (!isLargeScreen)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: menuItems.length + (isTrainingProgramRoute ? controller.program.weeks.length : 0),
            itemBuilder: (context, index) {
              if (index < menuItems.length) {
                return ListTile(
                  title: Text(menuItems[index]),
                  onTap: () => _navigateTo(menuItems[index], isLargeScreen),
                );
              } else {
                final weekIndex = index - menuItems.length;
                final week = controller.program.weeks[weekIndex];
                return ListTile(
                  title: Text('Week ${week.number}'),
                  onTap: () {
                    context.push('/programs_screen/user_programs/${FirebaseAuth.instance.currentUser?.uid}/training_program/${controller.program.id}/week/$weekIndex/workout_list');
                  },
                );
              }
            },
          ),
        ),
        Consumer(
          builder: (context, ref, child) {
            final userName = ref.watch(userNameProvider);
            final user = FirebaseAuth.instance.currentUser;
            final displayName = user?.displayName ?? userName;
            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(displayName),
              onTap: () => _navigateTo('Profilo Utente', isLargeScreen),
            );
          },
        ),
        ListTile(
          title: const Text('Logout'),
          onTap: _logout,
        ),
      ],
    );
  }

  List<String> _getAdminMenuItems() {
    return [
      'Allenamenti',
      'Esercizi',
      'Massimali',
      'Profilo Utente',
      'Gestione Utenti',
    ];
  }

  List<String> _getClientMenuItems() {
    return [
      'Allenamenti',
      'Massimali',
      'Profilo Utente',
    ];
  }

  void _showAddUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final roleController = TextEditingController(text: 'client');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add User'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Role'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a role';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await ref.read(usersServiceProvider).createUser(
                        name: nameController.text,
                        email: emailController.text,
                        password: passwordController.text,
                        role: roleController.text,
                      );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}