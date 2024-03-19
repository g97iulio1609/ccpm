import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'authScreen.dart';
import 'programsScreen.dart';
import 'userProfile.dart';
import '../exerciseManager/exerciseList.dart';
import 'maxRMDashboard.dart';
import 'trainingBuilder/trainingProgram.dart';
import 'usersServices.dart';
import 'users_dashboard.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  List<Widget> _pages = [];
  Map<String, int> menuItemToPageIndex = {};

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

  _pages = [
    const ProgramsScreen(),
    if (userRole == 'admin') ExercisesList(),
    if (userRole == 'admin') const MaxRMDashboard(),
    const UserProfile(),
    if (userRole == 'admin') const TrainingProgramPage(),
    if (userRole == 'admin') const UsersDashboard(),
  ];

  menuItemToPageIndex = {
    'Allenamenti': 0,
    'Esercizi': userRole == 'admin' ? 1 : -1,
    'Massimali': userRole == 'admin' ? 2 : -1,
    'Profilo Utente': userRole == 'admin' ? 3 : _pages.length - 1,
    'TrainingProgram': userRole == 'admin' ? 4 : -1,
    'Gestione Utenti': userRole == 'admin' ? 5 : -1,
  };

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
      print('Errore durante il logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var isLargeScreen = MediaQuery.of(context).size.width > 600;
    final userRole = ref.watch(userRoleProvider);

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
            child: _pages.isNotEmpty ? _pages[_selectedIndex] : const SizedBox(),
          ),
        ],
      ),
    );
  }

  String _getTitleForIndex(int index, String userRole) {
    switch (index) {
      case 0:
        return 'Allenamenti';
      case 1:
        return userRole == 'admin' ? 'Esercizi' : 'Massimali';
      case 2:
        return userRole == 'admin' ? 'Massimali' : 'Profilo Utente';
      case 3:
        return 'Profilo Utente';
      case 4:
        return 'TrainingProgram';
      case 5:
        return 'Gestione Utenti';
      default:
        return 'Allenamenti';
    }
  }

  List<Widget> _getActionsForIndex(int index, String userRole, BuildContext context) {
    switch (index) {
      case 5: // Gestione Utenti
        return [
          IconButton(
            onPressed: () => _showAddUserDialog(context),
            icon: const Icon(Icons.person_add),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildDrawer(bool isLargeScreen, BuildContext context, String userRole) {
    final List<String> menuItems = [
      'Allenamenti',
      if (userRole == 'admin') 'Esercizi',
      if (userRole == 'admin') 'Massimali',
      'Profilo Utente',
      if (userRole == 'admin') 'TrainingProgram',
      if (userRole == 'admin') 'Gestione Utenti',
    ];

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

  void _navigateTo(String menuItem, bool isLargeScreen) {
    final int? pageIndex = menuItemToPageIndex[menuItem];
    if (pageIndex != null && pageIndex >= 0) {
      _onItemTapped(pageIndex);
      if (!isLargeScreen) {
        Navigator.pop(context);
      }
    }
  }

  void _showAddUserDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _roleController = TextEditingController(text: 'client');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add User'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _roleController,
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
                if (_formKey.currentState!.validate()) {
                  await ref.read(usersServiceProvider).createUser(
                        name: _nameController.text,
                        email: _emailController.text,
                        password: _passwordController.text,
                        role: _roleController.text,
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