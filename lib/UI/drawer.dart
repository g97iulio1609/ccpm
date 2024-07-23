import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/providers/providers.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({
    super.key,
    required this.isLargeScreen,
    required this.userRole,
    required this.onLogout,
  });

  final bool isLargeScreen;
  final String userRole;
  final VoidCallback onLogout;

  void _navigateTo(BuildContext context, String route) {
    if (route != GoRouterState.of(context).uri.toString()) {
      context.go(route);
      if (!isLargeScreen) {
        Navigator.of(context).pop();
      }
    }
  }

  String? _getRouteForMenuItem(String menuItem, String userRole, String? userId) {
    final routes = {
      'Coaching': '/programs_screen',
      'Association': '/associations',
      'I Miei Allenamenti': '/user_programs/$userId',
      'Galleria Allenamenti': '/training_gallery',
      'Esercizi': '/exercises_list',
      'Massimali': '/maxrmdashboard',
      'Profilo Utente': '/user_profile/$userId',
      'Gestione Utenti': userRole == 'admin' ? '/users_dashboard' : null,
      'Fabbisogno Calorico': '/tdee',
      'Food Tracker': '/food_tracker',
      'Food Management': '/food_management',
      'Calcolatore Macronutrienti': '/macros_selector',
      'Misurazioni': '/measurements',
      'Meals Preferiti': '/mymeals',
      'Abbonamenti': '/subscriptions',

    };
    return routes[menuItem];
  }

  IconData _getIconForMenuItem(String menuItem) {
    final icons = {
      'Coaching': Icons.school,
      'Association': Icons.people,
      'I Miei Allenamenti': Icons.fitness_center,
      'Galleria Allenamenti': Icons.collections_bookmark,
      'Esercizi': Icons.sports,
      'Massimali': Icons.trending_up,
      'Profilo Utente': Icons.person,
      'Gestione Utenti': Icons.supervised_user_circle,
      'Fabbisogno Calorico': Icons.local_dining,
      'Calcolatore Macronutrienti': Icons.calculate,
      'Food Tracker': Icons.restaurant_menu,
      'Food Management': Icons.fastfood,
      'Misurazioni': Icons.straighten,
      'Meals Preferiti': Icons.favorite,
      'Abbonamenti': Icons.subscriptions,

    };
    return icons[menuItem] ?? Icons.menu;
  }

  List<String> _getMenuItems(String userRole) {
    final adminItems = [
      'Coaching', 'Association', 'I Miei Allenamenti', 'Abbonamenti',
      'Galleria Allenamenti', 'Esercizi', 'Massimali', 'Profilo Utente',
      'Gestione Utenti', 'Fabbisogno Calorico', 'Calcolatore Macronutrienti',
      'Food Tracker', 'Food Management', 'Misurazioni', 'Meals Preferiti'
    ];
    final clientItems = [
      'I Miei Allenamenti','Association', 'Abbonamenti', 'Esercizi',
      'Massimali', 'Profilo Utente', 'Fabbisogno Calorico',
      'Calcolatore Macronutrienti', 'Food Tracker', 'Misurazioni'
    ];
    return (userRole == 'admin' || userRole == 'coach') ? adminItems : clientItems;
  }

  Widget _buildMenuItem(BuildContext context, String menuItem, String userRole, bool isDarkMode) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final route = _getRouteForMenuItem(menuItem, userRole, userId);
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isSelected = route == currentRoute;

    return ListTile(
      leading: Icon(
        _getIconForMenuItem(menuItem),
        color: isDarkMode ? Colors.white : Colors.grey[700],
      ),
      title: Text(
        menuItem,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: route != null && !isSelected ? () => _navigateTo(context, route) : null,
      hoverColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      selectedTileColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
      selected: isSelected,
    );
  }

  Widget _buildWeekLinks(BuildContext context, String programId, bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('weeks')
          .where('programId', isEqualTo: programId)
          .orderBy('number')
          .snapshots(),
      builder: (context, weeksSnapshot) {
        if (!weeksSnapshot.hasData) return const SizedBox.shrink();
        
        final weeks = weeksSnapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: weeks.length,
          itemBuilder: (context, index) {
            final weekDoc = weeks[index];
            return ExpansionTile(
              leading: Icon(
                Icons.calendar_today,
                color: isDarkMode ? Colors.white : Colors.grey[700],
              ),
              title: Text(
                'Settimana ${weekDoc['number']}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                _buildWorkoutList(context, weekDoc.id, programId, isDarkMode),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWorkoutList(BuildContext context, String weekId, String programId, bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workouts')
          .where('weekId', isEqualTo: weekId)
          .orderBy('order')
          .snapshots(),
      builder: (context, workoutsSnapshot) {
        if (!workoutsSnapshot.hasData) return const SizedBox.shrink();
        
        final workouts = workoutsSnapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workoutDoc = workouts[index];
            final userId = FirebaseAuth.instance.currentUser?.uid;
            final route = '/user_programs/$userId/training_viewer/$programId/week_details/$weekId/workout_details/${workoutDoc.id}';
            
            return ListTile(
              title: Text(
                'Allenamento ${workoutDoc['order']}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _navigateTo(context, route),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final menuItems = _getMenuItems(userRole);

    return Drawer(
      child: Container(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16.0, 48.0, 16.0, 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Menù', style: theme.textTheme.titleLarge),
                  if (!isLargeScreen)
                    IconButton(
                      icon: Icon(Icons.close, color: isDarkMode ? Colors.white : Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ...menuItems.map((menuItem) => _buildMenuItem(context, menuItem, userRole, isDarkMode)),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final programId = snapshot.data!.get('currentProgram') as String?;
                        if (programId != null) {
                          return _buildWeekLinks(context, programId, isDarkMode);
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Consumer(
              builder: (context, ref, _) {
                final userName = ref.watch(userNameProvider);
                final user = FirebaseAuth.instance.currentUser;
                final displayName = user?.displayName ?? userName;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    child: Icon(Icons.person, color: isDarkMode ? Colors.white : Colors.grey[800]),
                  ),
                  title: Text(
                    displayName,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => _navigateTo(context, '/user_profile/${user?.uid}'),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: isDarkMode ? Colors.white : Colors.grey[700]),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}