import 'package:alphanessone/providers/providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../UI/components/user_autocomplete.dart';
import '../UI/components/bottom_menu.dart';
import '../../models/user_model.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/providers/ui_settings_provider.dart';
import 'package:alphanessone/UI/components/glass.dart';

class CoachingScreen extends HookConsumerWidget {
  const CoachingScreen({super.key});

  int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController typeAheadController =
        useTextEditingController();
    final FocusNode focusNode = useFocusNode();
    final usersService = ref.watch(usersServiceProvider);
    final coachingService = ref.watch(coachingServiceProvider);
    final currentUserRole = usersService.getCurrentUserRole();
    final currentUserId = usersService.getCurrentUserId();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final glassEnabled = ref.watch(uiGlassEnabledProvider);

    // Recupero degli utenti in base al ruolo
    final usersFuture = useMemoized(() async {
      if (currentUserRole == 'admin') {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .get();
        return snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList();
      } else if (currentUserRole == 'coach') {
        final associations = await coachingService
            .getCoachAssociations(currentUserId)
            .first;
        List<UserModel> users = [];
        for (var association in associations) {
          if (association.status == 'accepted') {
            final athlete = await usersService.getUserById(
              association.athleteId,
            );
            if (athlete != null) {
              users.add(athlete);
            }
          }
        }
        return users;
      } else {
        return <UserModel>[];
      }
    }, [currentUserRole, currentUserId]);

    final snapshot = useFuture(usersFuture);

    // Aggiornamento della lista degli utenti dopo il caricamento
    useEffect(() {
      if (snapshot.hasData) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(userListProvider.notifier).state = snapshot.data!;
        });
      }
      return null;
    }, [snapshot.data, snapshot.error]);

    final content = SafeArea(
      child: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing.xl),
              child: _buildSearchBar(
                typeAheadController,
                focusNode,
                context,
                ref,
                theme,
                colorScheme,
              ),
            ),
          ),

          // Athletes Grid
          SliverPadding(
            padding: EdgeInsets.all(AppTheme.spacing.xl),
            sliver: _buildAthletesList(
              snapshot,
              theme,
              colorScheme,
              currentUserRole,
              context,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: glassEnabled
          ? GlassLite(padding: EdgeInsets.zero, radius: 0, child: content)
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
              child: content,
            ),
    );
  }

  Widget _buildSearchBar(
    TextEditingController controller,
    FocusNode focusNode,
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
        boxShadow: AppTheme.elevations.small,
      ),
      padding: EdgeInsets.all(AppTheme.spacing.md),
      child: UserTypeAheadField(
        controller: controller,
        focusNode: focusNode,
        onSelected: (UserModel selectedUser) {
          context.go('/user_programs', extra: {'userId': selectedUser.id});
        },
        onChanged: (pattern) {
          final allUsers = ref.read(userListProvider);
          final filteredUsers = allUsers
              .where(
                (user) =>
                    user.name.toLowerCase().contains(pattern.toLowerCase()) ||
                    user.email.toLowerCase().contains(pattern.toLowerCase()),
              )
              .toList();
          ref.read(filteredUserListProvider.notifier).state = filteredUsers;
        },
      ),
    );
  }

  Widget _buildAthletesList(
    AsyncSnapshot<List<UserModel>> snapshot,
    ThemeData theme,
    ColorScheme colorScheme,
    String currentUserRole,
    BuildContext context,
  ) {
    return Builder(
      builder: (context) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                'Error loading athletes: ${snapshot.error}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
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
                    currentUserRole == 'coach'
                        ? 'No Athletes Associated'
                        : 'No Users Found',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  Text(
                    currentUserRole == 'coach'
                        ? 'Start adding athletes to your roster'
                        : 'Try adjusting your search',
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
        final crossAxisCount = getGridCrossAxisCount(context);

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
          delegate: SliverChildBuilderDelegate((context, rowIndex) {
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
                            child: _buildAthleteCard(
                              rowUsers[i],
                              theme,
                              colorScheme,
                              context,
                            ),
                          ),
                        )
                      else
                        Expanded(child: Container()),
                    ],
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildAthleteCard(
    UserModel user,
    ThemeData theme,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    final String initials = user.name.isNotEmpty
        ? user.name.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onAthleteCardTap(context, user.id),
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
                        onPressed: () => _showAthleteOptions(context, user),
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
                    'ATHLETE',
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

  void _onAthleteCardTap(BuildContext context, String userId) {
    try {
      context.go('/user_programs', extra: {'userId': userId});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error navigating to user profile: $e')),
      );
    }
  }

  void _showAthleteOptions(BuildContext context, UserModel user) {
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
            title: 'Visualizza Programmi',
            icon: Icons.visibility_outlined,
            onTap: () {
              Navigator.pop(context);
              _onAthleteCardTap(context, user.id);
            },
          ),
        ],
      ),
    );
  }
}
