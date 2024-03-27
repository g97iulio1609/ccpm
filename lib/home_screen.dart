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
    final String? route = _getRouteForMenuItem(menuItem, userRole);
    if (route != null) {
      context.go(route);
      if (!isLargeScreen) {
        Navigator.pop(context);
      }
    }
  }

  String? _getRouteForMenuItem(String menuItem, String userRole) {
    switch (menuItem) {
      case 'Allenamenti':
        return '/programs_screen';
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
        return 'TrainingProgram';
      case '/users_dashboard':
        return 'Gestione Utenti';
      case '/training_viewer':
        return 'Settimane';
      case '/week_details':
        return 'Allenamenti';
      case '/workout_details':
        return 'Allenamento';
      case '/exercise_details':
        return 'Esercizio';
      case '/timer':
        return 'Serie';
      default:
        return 'Alphaness One';
    }
  }

 @override
Widget build(BuildContext context) {
  var isLargeScreen = MediaQuery.of(context).size.width > 600;
  final userRole = ref.watch(userRoleProvider);
  final user = FirebaseAuth.instance.currentUser;

  return Scaffold(
    appBar: user != null
        ? AppBar(
            title: Text(_getTitleForRoute(context)),
            actions: [
              if (userRole == 'admin' &&
                  GoRouterState.of(context).uri.toString() == '/users_dashboard')
                IconButton(
                  onPressed: () => _showAddUserDialog(context),
                  icon: const Icon(Icons.person_add),
                ),
            ],
          )
        : null,
    drawer: user != null && !isLargeScreen
        ? Drawer(
            child: _buildDrawer(isLargeScreen, context, userRole),
          )
        : null,
    body: Row(
      children: [
        if (user != null && isLargeScreen)
          SizedBox(
            width: 300,
            child: _buildDrawer(isLargeScreen, context, userRole),
          ),
        Expanded(
          child: widget.child,
        ),
      ],
    ),
  );
}

  Widget _buildDrawer(
      bool isLargeScreen, BuildContext context, String userRole) {
    final List<String> menuItems =
        userRole == 'admin' ? _getAdminMenuItems() : _getClientMenuItems();

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
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(menuItems[index]),
                onTap: () => _navigateTo(menuItems[index], isLargeScreen),
              );
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
      'TrainingProgram',
      'Gestione Utenti',
      'Volume Allenamento', // Aggiungi questa voce
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
