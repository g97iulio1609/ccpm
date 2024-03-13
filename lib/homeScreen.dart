import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'programsScreen.dart';
import 'userProfile.dart';
import 'exerciseList.dart';
import 'maxRMDashboard.dart';
import 'trainingProgram.dart';
import 'usersServices.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];
  late Map<String, int> menuItemToPageIndex;

  @override
  void initState() {
    super.initState();
    final userRole = ref.read(userRoleProvider);
    _pages.add(const ProgramsScreen());
    if (userRole == 'admin') {
      _pages.add(ExercisesList());
    }
    _pages.add(const MaxRMDashboard());
    _pages.add(const UserProfile());
    if (userRole == 'admin') {
      _pages.add(TrainingProgramPage());
    }

    menuItemToPageIndex = {
      'Allenamenti': 0,
      'Esercizi': userRole == 'admin' ? 1 : -1,
      'Massimali': userRole == 'admin' ? 2 : 1,
      'Profilo Utente': userRole == 'admin' ? 3 : 2,
      'TrainingProgram': userRole == 'admin' ? 4 : -1,
    };
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    try {
      // Esegui il logout dell'utente
      await FirebaseAuth.instance.signOut();
      // Naviga alla schermata di autenticazione o esegui altre azioni necessarie
    Navigator.pushNamed(context, '/auth');
    } catch (e) {
      // Gestisci eventuali errori durante il logout
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
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }

  String _getTitleForIndex(int index, String userRole) {
    if (userRole == 'admin') {
      switch (index) {
        case 0:
          return 'Allenamenti';
        case 1:
          return 'Esercizi';
        case 2:
          return 'Massimali';
        case 3:
          return 'Profilo Utente';
        case 4:
          return 'TrainingProgram';
        default:
          return 'Allenamenti';
      }
    } else {
      switch (index) {
        case 0:
          return 'Allenamenti';
        case 1:
          return 'Massimali';
        case 2:
          return 'Profilo Utente';
        default:
          return 'Allenamenti';
      }
    }
  }

  Widget _buildDrawer(bool isLargeScreen, BuildContext context, String userRole) {
    final List<String> menuItems = [
      'Allenamenti',
      if (userRole == 'admin') 'Esercizi',
      'Massimali',
      'Profilo Utente',
      if (userRole == 'admin') 'TrainingProgram',
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
}