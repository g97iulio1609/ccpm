import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_screen.dart';
import 'programs_screen.dart';
import 'user_profile.dart';
import 'exerciseManager/exercise_list.dart';
import 'maxRMDashboard.dart';
import 'trainingBuilder/training_program.dart';
import 'users_services.dart';
import 'users_dashboard.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  List<Widget> _adminPages = [];
  List<Widget> _clientPages = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(usersServiceProvider).fetchUserRole();
      _buildUI();
    });
  }

  void _buildUI() {
    final userRole = ref.read(userRoleProvider);

    _adminPages = [
      const ProgramsScreen(),
      ExercisesList(),
      const MaxRMDashboard(),
      const UserProfile(),
      const TrainingProgramPage(),
      const UsersDashboard(),
    ];

    _clientPages = [
      const ProgramsScreen(),
      const MaxRMDashboard(),
      const UserProfile(),
    ];

    setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      ref.read(usersServiceProvider).clearUserData();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => AuthScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Errore durante il logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var isLargeScreen = MediaQuery.of(context).size.width > 600;
    final userRole = ref.watch(userRoleProvider);
    final pages = userRole == 'admin' ? _adminPages : _clientPages;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleForIndex(_selectedIndex, userRole)),
        actions: _getActionsForIndex(_selectedIndex, userRole, context),
      ),
      drawer: isLargeScreen ? null : Drawer(
        child: _buildDrawer(isLargeScreen, context, userRole),
      ),
      body: Row(
        children: [
          if (isLargeScreen)
            SizedBox(
              width: 300,
              child: _buildDrawer(isLargeScreen, context, userRole),
            ),
          Expanded(
            child: pages.isNotEmpty ? pages[_selectedIndex] : const SizedBox(),
          ),
        ],
      ),
    );
  }

  String _getTitleForIndex(int index, String userRole) {
    final titles = userRole == 'admin' ? _getAdminTitles() : _getClientTitles();
    return titles[index];
  }

  List<String> _getAdminTitles() {
    return [
      'Allenamenti',
      'Esercizi',
      'Massimali',
      'Profilo Utente',
      'TrainingProgram',
      'Gestione Utenti',
    ];
  }

  List<String> _getClientTitles() {
    return [
      'Allenamenti',
      'Massimali',
      'Profilo Utente',
    ];
  }

  List<Widget> _getActionsForIndex(int index, String userRole, BuildContext context) {
    if (userRole == 'admin' && index == 5) { // Gestione Utenti
      return [
        IconButton(
          onPressed: () => _showAddUserDialog(context),
          icon: const Icon(Icons.person_add),
        ),
      ];
    }
    return [];
  }

  Widget _buildDrawer(bool isLargeScreen, BuildContext context, String userRole) {
    final List<String> menuItems = userRole == 'admin' ? _getAdminMenuItems() : _getClientMenuItems();

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
                onTap: () => _navigateTo(menuItems[index], isLargeScreen, userRole),
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
              onTap: () => _navigateTo('Profilo Utente', isLargeScreen, userRole),
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
    ];
  }

  List<String> _getClientMenuItems() {
    return [
      'Allenamenti',
      'Massimali',
      'Profilo Utente',
    ];
  }

  void _navigateTo(String menuItem, bool isLargeScreen, String userRole) {
    final pages = userRole == 'admin' ? _adminPages : _clientPages;
    final int? pageIndex = _getPageIndexForMenuItem(menuItem, userRole);
    if (pageIndex != null && pageIndex >= 0) {
      _onItemTapped(pageIndex);
      if (!isLargeScreen) {
        Navigator.pop(context);
      }
    }
  }

  int? _getPageIndexForMenuItem(String menuItem, String userRole) {
    final menuItems = userRole == 'admin' ? _getAdminMenuItems() : _getClientMenuItems();
    return menuItems.indexOf(menuItem);
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