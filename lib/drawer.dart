import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'users_services.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({
    super.key,
    required this.isLargeScreen,
    required this.userRole,
    required this.controller,
    required this.onLogout,
  });

  final bool isLargeScreen;
  final String userRole;
  final TrainingProgramController controller;
  final VoidCallback onLogout;

  void _navigateTo(BuildContext context, String menuItem) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final String? route = _getRouteForMenuItem(menuItem, userRole, userId);
    if (route != null) {
      context.go(route);
      if (!isLargeScreen) {
        Navigator.of(context).pop();
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

  IconData _getIconForMenuItem(String menuItem) {
    switch (menuItem) {
      case 'Allenamenti':
        return Icons.fitness_center;
      case 'Esercizi':
        return Icons.sports;
      case 'Massimali':
        return Icons.trending_up;
      case 'Profilo Utente':
        return Icons.person;
      case 'TrainingProgram':
        return Icons.schedule;
      case 'Gestione Utenti':
        return Icons.supervised_user_circle;
      case 'Volume Allenamento':
        return Icons.bar_chart;
      default:
        return Icons.menu;
    }
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

  Future<String?> getCurrentProgramId(WidgetRef ref) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userDoc.data()?['currentProgram'] as String?;
    }
    return null;
  }

Widget _buildWeekLinks(BuildContext context, String programId, bool isDarkMode) {
  return FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance
        .collection('weeks')
        .where('programId', isEqualTo: programId)
        .orderBy('number')
        .get(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final weeks = snapshot.data!.docs;
        return Column(
          children: [
            for (var weekDoc in weeks)
              ListTile(
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
                onTap: () {
                  context.go(
                    '/programs_screen/user_programs/${FirebaseAuth.instance.currentUser?.uid}/training_viewer/$programId/week_details/${weekDoc.id}',
                  );
                },
                hoverColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                selectedTileColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              ),
          ],
        );
      } else {
        return const SizedBox.shrink();
      }
    },
  );
}


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> menuItems = userRole == 'admin' ? _getAdminMenuItems() : _getClientMenuItems();
    final isTrainingProgramRoute = GoRouterState.of(context).uri.toString().contains('/training_program/');
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Drawer(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            color: Colors.black.withOpacity(0.5),
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
                      ...menuItems.map(
                        (menuItem) => ListTile(
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
                          onTap: () => _navigateTo(context, menuItem),
                          hoverColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          selectedTileColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                      FutureBuilder<String?>(
                        future: getCurrentProgramId(ref),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            final programId = snapshot.data!;
                            return _buildWeekLinks(context, programId, isDarkMode);
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final userName = ref.watch(userNameProvider);
                    final user = FirebaseAuth.instance.currentUser;
                    final displayName = user?.displayName ?? userName;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          color: isDarkMode ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () => _navigateTo(context, 'Profilo Utente'),
                      hoverColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      selectedTileColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: isDarkMode ? Colors.white : Colors.grey[700],
                  ),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: onLogout,
                  hoverColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  selectedTileColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}