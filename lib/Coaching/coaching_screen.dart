import 'package:alphanessone/providers/providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../user_autocomplete.dart';
import '../../models/user_model.dart';
import '../UI/components/card.dart';
import 'package:alphanessone/Main/app_theme.dart';

class CoachingScreen extends HookConsumerWidget {
  const CoachingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController typeAheadController = useTextEditingController();
    final FocusNode focusNode = useFocusNode();
    final usersService = ref.watch(usersServiceProvider);
    final coachingService = ref.watch(coachingServiceProvider);
    final currentUserRole = usersService.getCurrentUserRole();
    final currentUserId = usersService.getCurrentUserId();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Recupero degli utenti in base al ruolo
    final usersFuture = useMemoized(() async {
      if (currentUserRole == 'admin') {
        final snapshot = await FirebaseFirestore.instance.collection('users').get();
        return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      } else if (currentUserRole == 'coach') {
        final associations = await coachingService.getCoachAssociations(currentUserId).first;
        List<UserModel> users = [];
        for (var association in associations) {
          if (association.status == 'accepted') {
            final athlete = await usersService.getUserById(association.athleteId);
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

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.5),
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
                ),
              ),
            ],
          ),
        ),
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
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      padding: EdgeInsets.all(AppTheme.spacing.md),
      child: UserTypeAheadField(
        controller: controller,
        focusNode: focusNode,
        onSelected: (UserModel selectedUser) {
          context.go('/user_programs/${selectedUser.id}');
        },
        onChanged: (pattern) {
          final allUsers = ref.read(userListProvider);
          final filteredUsers = allUsers.where((user) =>
            user.name.toLowerCase().contains(pattern.toLowerCase()) ||
            user.email.toLowerCase().contains(pattern.toLowerCase())
          ).toList();
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
  ) {
    return Builder(builder: (context) {
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

      if (snapshot.data == null || snapshot.data!.isEmpty) {
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
          (context, index) => _buildAthleteCard(
            snapshot.data![index],
            theme,
            colorScheme,
            context,
          ),
          childCount: snapshot.data!.length,
        ),
      );
    });
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
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatarCircle(initials, theme, colorScheme),
                SizedBox(height: AppTheme.spacing.md),
                _buildAthleteInfo(user, theme, colorScheme),
                SizedBox(height: AppTheme.spacing.md),
                _buildViewProfileButton(theme, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCircle(String initials, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAthleteInfo(UserModel user, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          user.name,
          style: theme.textTheme.titleLarge?.copyWith(
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
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildViewProfileButton(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.md,
          vertical: AppTheme.spacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_outlined,
              color: colorScheme.onPrimary,
              size: 18,
            ),
            SizedBox(width: AppTheme.spacing.xs),
            Text(
              'View Profile',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAthleteCardTap(BuildContext context, String userId) {
    try {
      context.go('/user_programs/$userId');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error navigating to user profile: $e')),
      );
    }
  }
}