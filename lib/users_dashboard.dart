import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import 'package:alphanessone/providers/ui_settings_provider.dart';
import 'package:alphanessone/UI/components/app_card.dart';

class UsersDashboard extends ConsumerStatefulWidget {
  const UsersDashboard({super.key});

  @override
  ConsumerState<UsersDashboard> createState() => _UsersDashboardState();
}

class _UsersDashboardState extends ConsumerState<UsersDashboard> {
  late UsersService _usersService;
  // Track the user currently being deleted to show inline progress
  String? _deletingUserId;

  @override
  void initState() {
    super.initState();
    _usersService = ref.read(usersServiceProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final glassEnabled = ref.watch(uiGlassEnabledProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.surface, colorScheme.surfaceContainerHighest.withAlpha(128)],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing.xl),
                  child: AppCard(
                    glass: glassEnabled,
                    title: 'Gestione Utenti',
                    leadingIcon: Icons.supervised_user_circle_outlined,
                    child: _buildSearchBar(theme, colorScheme),
                  ),
                ),
              ),
              _buildUsersList(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return TextField(
      onChanged: _usersService.searchUsers,
      decoration: InputDecoration(
        hintText: 'Search users',
        hintStyle: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(
          vertical: AppTheme.spacing.sm,
          horizontal: AppTheme.spacing.md,
        ),
      ),
    );
  }

  Widget _buildUsersList(ThemeData theme, ColorScheme colorScheme) {
    return StreamBuilder<List<UserModel>>(
      stream: _usersService.getUsers(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle error state
        if (snapshot.hasError) {
          debugPrint('Users stream error: ${snapshot.error}');
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  SizedBox(height: AppTheme.spacing.md),
                  Text(
                    'Error loading users',
                    style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.error),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Get users data
        final users = snapshot.data ?? [];
        
        // Handle empty state
        if (users.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                  SizedBox(height: AppTheme.spacing.md),
                  Text(
                    'No Users Found',
                    style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        // Build users grid with responsive sizing
        return SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.lg,
            vertical: AppTheme.spacing.sm,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: _getMaxCrossAxisExtent(context),
              crossAxisSpacing: AppTheme.spacing.md,
              mainAxisSpacing: AppTheme.spacing.md,
              childAspectRatio: _getCardAspectRatio(context),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= users.length) return null;
                return _buildUserCard(users[index], theme, colorScheme);
              },
              childCount: users.length,
            ),
          ),
        );
      },
    );
  }

  double _getMaxCrossAxisExtent(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Target approximate card width; grid will auto-fit columns.
    if (width > 1600) return 380; // very wide screens
    if (width > 1400) return 360;
    if (width > 1200) return 340;
    if (width > 900) return 320;
    if (width > 600) return 300;
    return 420; // mobile: prefer 1 column
  }

  double _getCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Make cards shorter (wider than tall) on larger screens
    if (width > 1400) return 1.6; // Desktop large
    if (width > 1200) return 1.45; // Desktop
    if (width > 900) return 1.3;   // Tablet/desktop small
    if (width > 600) return 1.28;  // Tablet piccolo (es. iPad mini), più compatto
    return 1.25; // Mobile: più larga che alta per ridurre l'altezza
  }

  Widget _buildUserCard(UserModel user, ThemeData theme, ColorScheme colorScheme) {
    final String initials = user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?';
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth <= 600;
    final double avatarSize = isMobile ? 28 : 32;
    final double loaderSize = isMobile ? 12 : 14;
    final double headerIconBox = isMobile ? 28 : 32;
    final isDeleting = _deletingUserId == user.id;

    return Stack(
      children: [
        Opacity(
          opacity: isDeleting ? 0.6 : 1.0,
          child: IgnorePointer(
            ignoring: isDeleting,
            child: AppCard(
              glass: ref.watch(uiGlassEnabledProvider),
              onTap: () => _navigateToUserProfile(context, user.id),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? AppTheme.spacing.xs : AppTheme.spacing.sm),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isCompact = isMobile || constraints.maxWidth < 340;
                    // Common avatar widget
                    Widget avatar = Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withAlpha(76),
                        shape: BoxShape.circle,
                      ),
                      child: user.photoURL.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(avatarSize / 2),
                              child: Image.network(
                                user.photoURL,
                                width: avatarSize,
                                height: avatarSize,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      initials,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return SizedBox(
                                    width: loaderSize,
                                    height: loaderSize,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                initials,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    );

                    if (isCompact) {
                      // Inline compact layout for mobile/small tiles
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          avatar,
                          SizedBox(width: AppTheme.spacing.sm),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacing.sm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer.withAlpha(76),
                                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                                  ),
                                  child: Text(
                                    user.role.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: headerIconBox,
                            height: headerIconBox,
                            child: IconButton(
                              icon: Icon(
                                Icons.more_vert,
                                color: colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              onPressed: () => _showUserOptions(context, user),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      );
                    }

                    // Default (non-compact) layout
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            avatar,
                            const Spacer(),
                            SizedBox(
                              width: headerIconBox,
                              height: headerIconBox,
                              child: IconButton(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () => _showUserOptions(context, user),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? AppTheme.spacing.xs : AppTheme.spacing.sm),
                        Text(
                          user.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                          maxLines: isMobile ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isMobile ? 2 : AppTheme.spacing.xs),
                        Text(
                          user.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: isMobile ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isMobile ? AppTheme.spacing.xs : AppTheme.spacing.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing.sm,
                              vertical: isMobile ? 2 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withAlpha(76),
                              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (isDeleting)
          Positioned.fill(
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
      ],
    );
  }

  void _showUserOptions(BuildContext context, UserModel user) {
    if (!mounted) return;
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => BottomMenu(
        title: user.name,
        subtitle: user.email,
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(76),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(Icons.person_outline, color: colorScheme.primary, size: 24),
        ),
        items: [
          BottomMenuItem(
            title: 'Visualizza Profilo',
            icon: Icons.visibility_outlined,
            onTap: () {
              Navigator.pop(bottomSheetContext);
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _navigateToUserProfile(context, user.id);
              });
            },
          ),
          BottomMenuItem(
            title: 'Elimina Utente',
            icon: Icons.delete_outline,
            onTap: () {
              Navigator.pop(bottomSheetContext);
              if (!mounted) return;
              // Apri la conferma dopo che il bottom sheet è stato chiuso
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showDeleteConfirmation(user);
              });
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(UserModel user) {
    if (!mounted) return;
    
    showAppDialog(
      context: context,
      title: const Text('Delete User'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to delete ${user.name}?'),
          SizedBox(height: AppTheme.spacing.sm),
          Text(
            'This action will permanently delete all user data including programs, workouts, and measurements.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        AppDialogHelpers.buildCancelButton(context: context, label: 'Cancel'),
        AppDialogHelpers.buildActionButton(
          context: context,
          label: 'Delete',
          onPressed: () async {
            // Chiudi il dialog sulla root navigator per evitare assert
            await Navigator.of(context, rootNavigator: true).maybePop();
            if (!mounted) return;
            // Esegui la cancellazione fuori dal ciclo di pop
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _deleteUser(user);
            });
          },
          isPrimary: false,
          isDestructive: true,
        ),
      ],
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    if (!mounted) return;
    setState(() => _deletingUserId = user.id);
    try {
      await _usersService.deleteUser(user.id);
      if (!mounted) return;
      setState(() => _deletingUserId = null);
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text('User ${user.name} deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingUserId = null);
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToUserProfile(BuildContext context, String userId) {
    context.go('/user_profile', extra: {'userId': userId});
  }
}
