import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'programsScreen.dart';
import 'userProfile.dart';
import 'exerciseList.dart';
import 'maxRMDashboard.dart';
import 'trainingProgram.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<String> pageTitles = [
    'Allenamenti',
    'Esercizi',
    'Massimali',
    'Profilo Utente',
    'TrainingProgram'
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: _selectedIndex != index,
      child: TabNavigator(
        navigatorKey: _navigatorKeys[index],
        tabItem: index,
      ),
    );
  }

  // Aggiungi il metodo per ottenere il nome dell'utente corrente
  String get currentUserName {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? user.displayName ?? 'Nessun nome' : 'Ospite';
  }

  @override
  Widget build(BuildContext context) {
    var isLargeScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]),
      ),
      drawer: isLargeScreen ? null : Drawer(
        child: _buildDrawer(isLargeScreen),
      ),
      body: Row(
        children: [
          if (isLargeScreen)
            SizedBox(
              width: 300,
              child: _buildDrawer(isLargeScreen),
            ),
          Expanded(
            child: Stack(
              children: List<Widget>.generate(_navigatorKeys.length, _buildOffstageNavigator),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(bool isLargeScreen) {
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
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              ListTile(title: const Text('Esercizi'), onTap: () => _navigateTo(1, isLargeScreen)),
              ListTile(title: const Text('Massimali'), onTap: () => _navigateTo(2, isLargeScreen)),
              ListTile(title: const Text('Profilo Utente'), onTap: () => _navigateTo(3, isLargeScreen)),
              ListTile(title: const Text('TrainingProgram'), onTap: () => _navigateTo(4, isLargeScreen)),
              ListTile(title: const Text('Allenamenti'), onTap: () => _navigateTo(0, isLargeScreen)),
            ],
          ),
        ),
        ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: Text(currentUserName),  // Modificato per mostrare il nome dell'utente
          onTap: () => _navigateTo(3, isLargeScreen),
        ),
        ListTile(
          title: const Text('Logout'),
          onTap: () {
            // Implementa la logica di logout qui
          },
        ),
      ],
    );
  }

  void _navigateTo(int index, bool isLargeScreen) {
    _onItemTapped(index);
    if (!isLargeScreen) Navigator.pop(context); // Chiude il drawer solo su schermi piccoli
  }
}

class TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final int tabItem;

  const TabNavigator({super.key, required this.navigatorKey, required this.tabItem});

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (tabItem) {
      case 0:
        child = const ProgramsScreen();
        break;
      case 1:
        child = ExercisesList();
        break;
      case 2:
        child = const MaxRMDashboard();
        break;
      case 3:
        child = const UserProfile();
        break;
      case 4:
        child = TrainingProgramPage();
        break;
      default:
        child = const ProgramsScreen();
    }

    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => child),
    );
  }
}
