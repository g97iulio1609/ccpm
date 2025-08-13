import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/badge.dart';
import 'package:alphanessone/UI/components/app_card.dart';
import 'package:alphanessone/UI/components/glass.dart';
import 'package:alphanessone/providers/ui_settings_provider.dart';
import 'package:alphanessone/Main/route_metadata.dart';

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

  void _navigateTo(
    BuildContext context,
    String route, [
    Map<String, dynamic>? extra,
  ]) {
    if (route != GoRouterState.of(context).uri.toString()) {
      if (route.contains('/user_programs/')) {
        final userId = route.split('/user_programs/')[1];
        context.go('/user_programs', extra: {'userId': userId});
      } else if (route.contains('/user_profile/')) {
        final userId = route.split('/user_profile/')[1];
        context.go('/user_profile', extra: {'userId': userId});
      } else if (extra != null) {
        context.go(route, extra: extra);
      } else {
        context.go(route);
      }
      if (!isLargeScreen) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final glassEnabled = ref.watch(uiGlassEnabledProvider);
    final menuItems = _getTopLevelMenuItems(userRole);

    final childShell = SafeArea(
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
                      ...menuItems.map(
                        (menuItem) => _buildMenuItem(
                          context,
                          menuItem,
                          userRole,
                          theme,
                          colorScheme,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSecondaryGroups(
                        context,
                        theme,
                        colorScheme,
                        userRole,
                      ),
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
                        AppBadge(
                          label: 'Programma Corrente',
                          variant: AppBadgeVariant.filled,
                          status: AppBadgeStatus.info,
                          size: AppBadgeSize.medium,
                        ),
                        SizedBox(height: AppTheme.spacing.md),
                        _buildCurrentProgram(
                          context,
                          theme,
                          colorScheme,
                          glassEnabled,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User Profile Section (AppCard per coerenza con il design system)
          Padding(
            padding: EdgeInsets.only(
              left: AppTheme.spacing.lg,
              right: AppTheme.spacing.lg,
              bottom: AppTheme.spacing.lg,
            ),
            child: AppCard(
              glass: true,
              glassTint: colorScheme.surface.withAlpha(172),
              glassBlur: 16,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildUserProfile(context, ref, theme, colorScheme),
                  Divider(color: colorScheme.outline.withAlpha(38), height: 1),
                  _buildLogoutButton(context, theme, colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Drawer(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: glassEnabled
          ? GlassLite(
              padding: EdgeInsets.zero,
              radius: 0,
              blur: 16,
              tint: colorScheme.brightness == Brightness.dark
                  ? colorScheme.surface.withAlpha(172)
                  : colorScheme.surface.withAlpha(212),
              border: Border.all(
                color: colorScheme.outline.withAlpha(38),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withAlpha(20),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              child: childShell,
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surfaceContainerHighest.withAlpha(128),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: childShell,
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
        color: isSelected
            ? colorScheme.surfaceContainerHighest.withAlpha(128)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: isSelected
            ? Border.all(color: colorScheme.outline.withAlpha(38))
            : null,
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
                        ? colorScheme.primary.withAlpha(38)
                        : colorScheme.surfaceContainerHighest.withAlpha(76),
                    borderRadius: BorderRadius.circular(AppTheme.radii.md),
                  ),
                  child: Icon(
                    _getIconForMenuItem(menuItem),
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppTheme.spacing.md),
                Expanded(
                  child: Text(
                    menuItem,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  const AppBadge(
                    label: 'Attivo',
                    variant: AppBadgeVariant.filled,
                    status: AppBadgeStatus.success,
                    size: AppBadgeSize.small,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryGroups(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String userRole,
  ) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final groups = <String, List<String>>{
      'Nutrizione': ['Diet Plans', 'Meals Preferiti', 'Food Management'],
      'Impostazioni': ['Impostazioni AI'],
      if (userRole == 'admin' || userRole == 'coach')
        'Admin': ['Gestione Utenti'],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((entry) {
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md),
            childrenPadding: EdgeInsets.only(
              left: AppTheme.spacing.lg,
              right: AppTheme.spacing.md,
              bottom: AppTheme.spacing.sm,
            ),
            leading: Icon(Icons.folder, color: colorScheme.onSurfaceVariant),
            title: Text(
              entry.key,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: entry.value.map((label) {
              final route = _getRouteForMenuItem(label, userRole, userId);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing.md,
                  vertical: AppTheme.spacing.xs,
                ),
                leading: Icon(
                  _getIconForMenuItem(label),
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: Text(label, style: theme.textTheme.bodyMedium),
                onTap: route != null ? () => _navigateTo(context, route) : null,
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCurrentProgram(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool glassEnabled,
  ) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final programId = snapshot.data!.get('currentProgram') as String?;
          if (programId != null) {
            return AppCard(
              glass: glassEnabled,
              padding: EdgeInsets.zero,
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
            color: colorScheme.primaryContainer.withAlpha(76),
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
          _buildWorkoutList(context, weekDoc.id, programId, theme, colorScheme),
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
            final route =
                '/user_programs/$userId/training_viewer/$programId/week_details/$weekId/workout_details/${workoutDoc.id}';

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
                            color: colorScheme.surfaceContainerHighest
                                .withAlpha(76),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radii.md,
                            ),
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
        onTap: () =>
            _navigateTo(context, '/user_profile', {'userId': user?.uid}),
        child: Container(
          padding: EdgeInsets.all(AppTheme.spacing.lg),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(76),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: colorScheme.primary, size: 24),
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
                      label: userRole.toUpperCase(),
                      variant: AppBadgeVariant.filled,
                      status: AppBadgeStatus.info,
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

  Widget _buildLogoutButton(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
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
                  color: colorScheme.errorContainer.withAlpha(76),
                  borderRadius: BorderRadius.circular(AppTheme.radii.md),
                ),
                child: Icon(Icons.logout, color: colorScheme.error, size: 20),
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

  String? _getRouteForMenuItem(
    String menuItem,
    String userRole,
    String? userId,
  ) {
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
      'Diet Plans': '/food_tracker/view_diet_plans',
      'Meals Preferiti': '/mymeals',
      'Abbonamenti': '/subscriptions',
      'Impostazioni AI': '/settings/ai',
      'Chat AI': '/ai/chat',
    };
    return routes[menuItem];
  }

  IconData _getIconForMenuItem(String menuItem) {
    final route = _getRouteForMenuItem(
      menuItem,
      userRole,
      FirebaseAuth.instance.currentUser?.uid,
    );
    if (route != null) {
      final meta = RouteMetadata.resolveByCurrentPath(route);
      if (meta != null) return meta.icon;
    }
    // Fallback locale minimale per etichette non mappate
    switch (menuItem) {
      case 'I Miei Allenamenti':
        return Icons.fitness_center;
      case 'Food Tracker':
        return Icons.restaurant_menu;
      case 'Misurazioni':
        return Icons.straighten;
      case 'Massimali':
        return Icons.trending_up;
      case 'Esercizi':
        return Icons.sports;
      case 'Abbonamenti':
        return Icons.subscriptions;
      case 'Profilo Utente':
        return Icons.person;
      default:
        return Icons.menu;
    }
  }

  List<String> _getTopLevelMenuItems(String userRole) {
    // Limitiamo a 5-7 voci principali
    final admin = [
      'Coaching',
      'I Miei Allenamenti',
      'Food Tracker',
      'Misurazioni',
      'Massimali',
      'Esercizi',
      'Abbonamenti',
      'Profilo Utente',
    ];
    final client = [
      'I Miei Allenamenti',
      'Food Tracker',
      'Misurazioni',
      'Massimali',
      'Esercizi',
      'Profilo Utente',
    ];
    return (userRole == 'admin' || userRole == 'coach') ? admin : client;
  }
}
