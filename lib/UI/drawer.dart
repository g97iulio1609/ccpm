import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/badge.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final menuItems = _getMenuItems(userRole);

    return Drawer(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Menu Items
                    SliverPadding(
                      padding: EdgeInsets.all(AppTheme.spacing.lg),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          ...menuItems.map((menuItem) => _buildMenuItem(
                            context,
                            menuItem,
                            userRole,
                            theme,
                            colorScheme,
                          )),
                        ]),
                      ),
                    ),

                    // Current Program Section
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.lg,
                        vertical: AppTheme.spacing.md,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing.md,
                                vertical: AppTheme.spacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(AppTheme.radii.full),
                              ),
                              child: Text(
                                'Programma Corrente',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: AppTheme.spacing.md),
                            _buildCurrentProgram(context, theme, colorScheme),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // User Profile Section
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildUserProfile(context, ref, theme, colorScheme),
                    _buildLogoutButton(context, theme, colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String menuItem,
    String userRole,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final route = _getRouteForMenuItem(menuItem, userRole, userId);
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isSelected = route == currentRoute;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: route != null ? () => _navigateTo(context, route) : null,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.md,
              vertical: AppTheme.spacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppTheme.spacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? colorScheme.primary.withOpacity(0.2)
                        : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radii.md),
                  ),
                  child: Icon(
                    _getIconForMenuItem(menuItem),
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppTheme.spacing.md),
                Expanded(
                  child: Text(
                    menuItem,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  AppBadge(
                    text: 'Attivo',
                    backgroundColor: colorScheme.primary,
                    textColor: colorScheme.onPrimary,
                    size: AppBadgeSize.small,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentProgram(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final programId = snapshot.data!.get('currentProgram') as String?;
          if (programId != null) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
                boxShadow: AppTheme.elevations.small,
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('weeks')
                    .where('programId', isEqualTo: programId)
                    .orderBy('number')
                    .snapshots(),
                builder: (context, weeksSnapshot) {
                  if (!weeksSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final weeks = weeksSnapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: weeks.length,
                    itemBuilder: (context, index) {
                      final weekDoc = weeks[index];
                      return _buildWeekItem(
                        context,
                        weekDoc,
                        programId,
                        theme,
                        colorScheme,
                      );
                    },
                  );
                },
              ),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWeekItem(
    BuildContext context,
    DocumentSnapshot weekDoc,
    String programId,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(
            Icons.calendar_today,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          'Settimana ${weekDoc['number']}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          _buildWorkoutList(
            context,
            weekDoc.id,
            programId,
            theme,
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutList(
    BuildContext context,
    String weekId,
    String programId,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workouts')
          .where('weekId', isEqualTo: weekId)
          .orderBy('order')
          .snapshots(),
      builder: (context, workoutsSnapshot) {
        if (!workoutsSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final workouts = workoutsSnapshot.data!.docs;
        return Column(
          children: workouts.map((workoutDoc) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            final route = '/user_programs/$userId/training_viewer/$programId/week_details/$weekId/workout_details/${workoutDoc.id}';
            
            return Container(
              margin: EdgeInsets.only(
                left: AppTheme.spacing.xl,
                right: AppTheme.spacing.md,
                bottom: AppTheme.spacing.xs,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateTo(context, route),
                  borderRadius: BorderRadius.circular(AppTheme.radii.md),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.md,
                      vertical: AppTheme.spacing.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppTheme.spacing.xs),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(AppTheme.radii.md),
                          ),
                          child: Text(
                            '${workoutDoc['order']}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: AppTheme.spacing.sm),
                        Text(
                          'Allenamento ${workoutDoc['order']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUserProfile(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final userName = ref.watch(userNameProvider);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? userName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateTo(context, '/user_profile/${user?.uid}'),
        child: Container(
          padding: EdgeInsets.all(AppTheme.spacing.lg),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: AppTheme.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing.xs),
                    AppBadge(
                      text: userRole.toUpperCase(),
                      backgroundColor: colorScheme.secondaryContainer,
                      textColor: colorScheme.onSecondaryContainer,
                      size: AppBadgeSize.small,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onLogout,
        child: Container(
          padding: EdgeInsets.all(AppTheme.spacing.lg),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radii.md),
                ),
                child: Icon(
                  Icons.logout,
                  color: colorScheme.error,
                  size: 20,
                ),
              ),
              SizedBox(width: AppTheme.spacing.md),
              Text(
                'Logout',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      'I Miei Allenamenti', 'Association', 'Abbonamenti', 'Esercizi',
      'Massimali', 'Profilo Utente', 'Fabbisogno Calorico',
      'Calcolatore Macronutrienti', 'Food Tracker', 'Misurazioni'
    ];
    return (userRole == 'admin' || userRole == 'coach') ? adminItems : clientItems;
  }
}