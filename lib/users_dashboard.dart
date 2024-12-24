import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';

class UsersDashboard extends ConsumerStatefulWidget {
  const UsersDashboard({super.key});

  @override
  ConsumerState<UsersDashboard> createState() => _UsersDashboardState();
}

class _UsersDashboardState extends ConsumerState<UsersDashboard> {
  late UsersService _usersService;

  @override
  void initState() {
    super.initState();
    _usersService = ref.read(usersServiceProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
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
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing.xl),
                  child: _buildSearchBar(theme, colorScheme),
                ),
              ),

              // Users Grid
              SliverPadding(
                padding: EdgeInsets.all(AppTheme.spacing.xl),
                sliver: _buildUsersList(theme, colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withAlpha(26),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      padding: EdgeInsets.all(AppTheme.spacing.md),
      child: TextField(
        onChanged: _usersService.searchUsers,
        decoration: InputDecoration(
          hintText: 'Search users',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: AppTheme.spacing.sm,
            horizontal: AppTheme.spacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList(ThemeData theme, ColorScheme colorScheme) {
    return StreamBuilder<List<UserModel>>(
      stream: _usersService.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: colorScheme.error.withAlpha(128),
                  ),
                  SizedBox(height: AppTheme.spacing.md),
                  Text(
                    'Error loading users',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  Text(
                    snapshot.error.toString(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withAlpha(128),
                  ),
                  SizedBox(height: AppTheme.spacing.md),
                  Text(
                    'No Users Found',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  Text(
                    'Try adjusting your search',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Calcola il numero di colonne
        final crossAxisCount = _getGridCrossAxisCount(context);

        // Organizza gli utenti in righe
        final rows = <List<UserModel>>[];
        for (var i = 0; i < users.length; i += crossAxisCount) {
          rows.add(
            users.sublist(
              i,
              i + crossAxisCount > users.length
                  ? users.length
                  : i + crossAxisCount,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, rowIndex) {
              if (rowIndex >= rows.length) return null;

              final rowUsers = rows[rowIndex];

              return Padding(
                padding: EdgeInsets.only(bottom: AppTheme.spacing.xl),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < crossAxisCount; i++) ...[
                        if (i < rowUsers.length)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: i < crossAxisCount - 1
                                    ? AppTheme.spacing.xl
                                    : 0,
                              ),
                              child: _buildUserCard(
                                  rowUsers[i], theme, colorScheme),
                            ),
                          )
                        else
                          Expanded(child: Container()),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  int _getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildUserCard(
      UserModel user, ThemeData theme, ColorScheme colorScheme) {
    final String initials =
        user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withAlpha(26),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToUserProfile(context, user.id),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar e menu
                SizedBox(
                  height: 40,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withAlpha(76),
                          shape: BoxShape.circle,
                          image: user.photoURL.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(user.photoURL),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user.photoURL.isEmpty
                            ? Center(
                                child: Text(
                                  initials,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => _showUserOptions(context, user),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppTheme.spacing.lg),

                // Nome utente
                Text(
                  user.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppTheme.spacing.sm),

                // Email
                Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: AppTheme.spacing.xl),

                // Role Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing.md,
                    vertical: AppTheme.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(76),
                    borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUserOptions(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: user.name,
        subtitle: user.email,
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(76),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(
            Icons.person_outline,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        items: [
          BottomMenuItem(
            title: 'Visualizza Profilo',
            icon: Icons.visibility_outlined,
            onTap: () {
              Navigator.pop(context);
              _navigateToUserProfile(context, user.id);
            },
          ),
          BottomMenuItem(
            title: 'Elimina Utente',
            icon: Icons.delete_outline,
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(user);
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.xl),
          ),
          title: Text(
            'Delete User',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${user.name}?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppTheme.radii.md),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _deleteUser(user);
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    try {
      await _usersService.deleteUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${user.name} deleted successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _navigateToUserProfile(BuildContext context, String userId) {
    context.go('/user_profile', extra: {'userId': userId});
  }
}
