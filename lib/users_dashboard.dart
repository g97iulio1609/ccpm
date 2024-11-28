import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:alphanessone/Main/app_theme.dart';

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
              colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
          color: colorScheme.outline.withOpacity(0.1),
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
                    color: colorScheme.error.withOpacity(0.5),
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
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
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
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.2,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildUserCard(
              users[index],
              theme,
              colorScheme,
            ),
            childCount: users.length,
          ),
        );
      },
    );
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
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToUserProfile(context, user.id),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // User Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
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

                SizedBox(height: AppTheme.spacing.xs),

                // User Info
                Text(
                  user.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: AppTheme.spacing.xs),

                Text(
                  user.email,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: AppTheme.spacing.xs),

                // Role Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing.sm,
                    vertical: AppTheme.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Spacer(),

                // Action Buttons
                Wrap(
                  spacing: AppTheme.spacing.xs,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildActionButton(
                      icon: Icons.visibility_outlined,
                      label: 'View',
                      onTap: () => _navigateToUserProfile(context, user.id),
                      colorScheme: colorScheme,
                      theme: theme,
                    ),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onTap: () => _showDeleteConfirmation(user),
                      colorScheme: colorScheme,
                      theme: theme,
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.sm,
            vertical: AppTheme.spacing.xs,
          ),
          decoration: BoxDecoration(
            color: isDestructive
                ? colorScheme.errorContainer.withOpacity(0.2)
                : colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDestructive ? colorScheme.error : colorScheme.primary,
              ),
              SizedBox(width: AppTheme.spacing.xs),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      isDestructive ? colorScheme.error : colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
