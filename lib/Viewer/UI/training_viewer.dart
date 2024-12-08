import 'package:alphanessone/Viewer/UI/workout_provider.dart' as workout_provider;
import 'package:alphanessone/Viewer/UI/workout_provider.dart';
import 'package:alphanessone/Viewer/providers/training_program_provider.dart';
import 'package:alphanessone/providers/providers.dart' as app_providers;
import 'package:alphanessone/Viewer/providers/training_program_provider.dart' as program_providers;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Main/app_theme.dart';
import '../../Store/inAppPurchase_services.dart';
import '../../utils/subscription_checker.dart';

final expandedWeekProvider = StateProvider<String?>((ref) => null);

class UnifiedTrainingViewer extends ConsumerStatefulWidget {
  final String programId;
  final String userId;

  const UnifiedTrainingViewer({
    super.key,
    required this.programId,
    required this.userId,
  });

  @override
  UnifiedTrainingViewerState createState() => UnifiedTrainingViewerState();
}

class UnifiedTrainingViewerState extends ConsumerState<UnifiedTrainingViewer> {
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mounted) {
        _checkSubscriptionAndFetch();
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _checkSubscriptionAndFetch() async {
    if (!_mounted) return;
    
    try {
      final userRole = ref.read(app_providers.userRoleProvider);

      if (userRole == 'admin') {
        if (_mounted) {
          await fetchTrainingWeeks();
        }
        return;
      }

      final subscriptionChecker = SubscriptionChecker();
      final hasValidSubscription = await subscriptionChecker.checkSubscription(context);

      if (!_mounted) return;

      if (!hasValidSubscription) {
        if (_mounted) {
          await showSubscriptionExpiredDialog(context);
          if (_mounted) {
            context.go('/subscriptions');
          }
          return;
        }
      }

      if (_mounted) {
        await fetchTrainingWeeks();
      }
    } catch (e) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> fetchTrainingWeeks() async {
    if (!_mounted) return;
    
    try {
      ref.read(trainingLoadingProvider.notifier).state = true;
      
      final weeks = await ref
          .read(program_providers.trainingProgramServicesProvider)
          .fetchTrainingWeeks(widget.programId);
          
      if (!_mounted) return;
      
      ref.read(trainingWeeksProvider.notifier).state = weeks;
    } catch (e) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading training weeks: $e'),
          ),
        );
      }
    } finally {
      if (_mounted) {
        ref.read(trainingLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(trainingLoadingProvider);
    final weeks = ref.watch(trainingWeeksProvider);
    final expandedWeekId = ref.watch(expandedWeekProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

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
          child: loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? AppTheme.spacing.md : AppTheme.spacing.xl),
                        child: _buildHeader(theme, colorScheme, isSmallScreen),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? AppTheme.spacing.md : AppTheme.spacing.xl,
                        vertical: AppTheme.spacing.md,
                      ),
                      sliver: _buildWeeksList(weeks, theme, colorScheme, isSmallScreen),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? AppTheme.spacing.md : AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.xl),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Training Program',
              style: (isSmallScreen ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall)?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isSmallScreen ? AppTheme.spacing.xs : AppTheme.spacing.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? AppTheme.spacing.sm : AppTheme.spacing.md,
              vertical: AppTheme.spacing.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppTheme.radii.sm),
            ),
            child: Text(
              'Your Journey to Excellence',
              style: (isSmallScreen ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableWeekCard(
    Map<String, dynamic> week,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isExpanded = ref.watch(expandedWeekProvider) == week['id'];

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.lg),
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
        child: Column(
          children: [
            InkWell(
              onTap: () {
                ref.read(expandedWeekProvider.notifier).state =
                    isExpanded ? null : week['id'];
                
                // Precarica i workout quando la settimana viene espansa
                if (!isExpanded) {
                  final workouts = week['workouts'] as List<dynamic>;
                  final workoutIds = workouts
                      .map((w) => w['id'] as String)
                      .toList();
                  ref
                      .read(workoutServiceProvider)
                      .prefetchWeekWorkouts(workoutIds);
                }
              },
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.md,
                            vertical: AppTheme.spacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
                          ),
                          child: Text(
                            'Week ${week['number']}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                    if (week['description'] != null &&
                        week['description'].toString().isNotEmpty) ...[
                      SizedBox(height: AppTheme.spacing.md),
                      Text(
                        week['description'],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isExpanded) _buildWorkoutsSection(week['id'], theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutsSection(
    String weekId,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final weekService = ref.watch(program_providers.trainingProgramServicesProvider);

    return StreamBuilder<QuerySnapshot>(
      stream: weekService.getWorkouts(weekId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Text(
              'Error: ${snapshot.error}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.error,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            ),
          );
        }

        final workouts = snapshot.data!.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();

        return Column(
          children: [
            Divider(
              color: colorScheme.outline.withOpacity(0.1),
              height: 1,
            ),
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: workouts.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: AppTheme.spacing.md),
                itemBuilder: (context, index) =>
                    _buildWorkoutCard(workouts[index], theme, colorScheme),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorkoutCard(
    Map<String, dynamic> workout,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return MouseRegion(
      onEnter: (event) {
        ref
            .read(workoutServiceProvider)
            .prefetchWorkout(workout['id']);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surfaceContainerHighest,
              colorScheme.surfaceContainerHighest.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radii.xl),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.05),
              offset: const Offset(0, 4),
              blurRadius: 20,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => navigateToWorkoutDetails(workout['id']),
            borderRadius: BorderRadius.circular(AppTheme.radii.xl),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? AppTheme.spacing.lg : AppTheme.spacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppTheme.spacing.md),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withOpacity(0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          '${workout['order']}',
                          style: (isSmallScreen ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall)?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? AppTheme.spacing.md : AppTheme.spacing.lg),
                      Text(
                        'Workout ${workout['order']}',
                        style: (isSmallScreen ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall)?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  if (workout['description'] != null &&
                      workout['description'].toString().isNotEmpty) ...[
                    SizedBox(height: AppTheme.spacing.md),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.md,
                        vertical: AppTheme.spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radii.full),
                      ),
                      child: Text(
                        workout['description'],
                        style: (isSmallScreen ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  SizedBox(height: AppTheme.spacing.lg),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.md,
                      vertical: AppTheme.spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: colorScheme.onPrimary,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        SizedBox(width: AppTheme.spacing.xs),
                        Text(
                          'START',
                          style: (isSmallScreen ? theme.textTheme.labelLarge : theme.textTheme.titleMedium)?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeksList(
    List<Map<String, dynamic>> weeks,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isSmallScreen,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) =>
            _buildExpandableWeekCard(weeks[index], theme, colorScheme),
        childCount: weeks.length,
      ),
    );
  }

  Future<void> showSubscriptionExpiredDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final inAppPurchaseService = InAppPurchaseService();
    final subscriptionDetails =
        await inAppPurchaseService.getSubscriptionDetails();
    final platform = subscriptionDetails?.platform ?? 'stripe';

    if (!_mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            'Abbonamento Scaduto',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Il tuo abbonamento è scaduto. Per continuare ad accedere ai contenuti, '
            'è necessario rinnovare l\'abbonamento.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/subscriptions');
              },
              child: Text(
                'Rinnova Abbonamento',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/');
              },
              child: Text(
                'Torna Indietro',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  void navigateToWorkoutDetails(String workoutId) {
    if (!mounted) return;
    
    // Clear any existing workout state before navigation
    ref.read(workout_provider.exercisesProvider.notifier).state = [];
    
    if (mounted) {
      context.go('/user_programs/training_viewer/workout_details', extra: {
        'programId': widget.programId,
        'userId': widget.userId,
        'workoutId': workoutId,
        'weekId': '' // Add an empty weekId since it's required by the WorkoutDetails widget
      });
    }
  }
}
