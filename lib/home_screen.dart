import 'package:flutter/material.dart';
import 'programs_screen.dart'; // Allenamenti
import 'user_profile.dart'; // Profilo Utente
import 'exercises_list.dart'; // Esercizi
import 'maxrmdashboard.dart'; // Massimali

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Allenamenti
    GlobalKey<NavigatorState>(), // Esercizi
    GlobalKey<NavigatorState>(), // Massimali
    GlobalKey<NavigatorState>(), // Profilo Utente
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

  @override
  Widget build(BuildContext context) {
    var isLargeScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Fitness'),
      ),
      drawer: isLargeScreen ? null : Drawer(
        child: _buildDrawer(),
      ),
      body: Row(
        children: [
          if (isLargeScreen) 
            Container(
              width: 300,
              child: _buildDrawer(),
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

  Widget _buildDrawer() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16.0, 48.0, 16.0, 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Menù', style: Theme.of(context).textTheme.titleLarge),
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
              ListTile(title: const Text('Esercizi'), onTap: () => _navigateTo(1)),
              ListTile(title: const Text('Massimali'), onTap: () => _navigateTo(2)),
              ListTile(title: const Text('Profilo Utente'), onTap: () => _navigateTo(3)),
              ListTile(title: const Text('Allenamenti'), onTap: () => _navigateTo(0)),
            ],
          ),
        ),
        ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: const Text('prova'),
          onTap: () => _navigateTo(3), // Modificato per navigare alla pagina del profilo utente
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

  void _navigateTo(int index) {
    _onItemTapped(index);
    Navigator.pop(context); // Chiude il drawer
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
        child = const ProgramsScreen(); // Allenamenti
        break;
      case 1:
        child = ExercisesList(); // Esercizi
        break;
      case 2:
        child = MaxRMDashboard(); // Massimali
        break;
      case 3:
        child = UserProfile(); // Profilo Utente
        break;
      default:
        child = const ProgramsScreen(); // Default a Allenamenti se non corrisponde
    }

    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => child),
    );
  }
}
