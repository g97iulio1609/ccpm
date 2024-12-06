import 'package:alphanessone/providers/providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/training_program_provider.dart';
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
  @override
  void initState() {
    super.initState();
    _checkSubscriptionAndFetch();
  }

  Future<void> _checkSubscriptionAndFetch() async {
    final userRole = ref.read(userRoleProvider);

    if (userRole == 'admin') {
      Future.microtask(() => fetchTrainingWeeks());
      return;
    }

    final subscriptionChecker = SubscriptionChecker();
    final hasValidSubscription = await subscriptionChecker.checkSubscription(context);

    if (!hasValidSubscription) {
      if (mounted) {
        await showSubscriptionExpiredDialog(context);
        context.go('/subscriptions');
        return;
      }
    }

    Future.microtask(() => fetchTrainingWeeks());
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(trainingLoadingProvider);
    final weeks = ref.watch(trainingWeeksProvider);
    final expandedWeekId = ref.watch(expandedWeekProvider);
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
                        padding: EdgeInsets.all(AppTheme.spacing.xl),
                        child: _buildHeader(theme, colorScheme),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.xl,
                        vertical: AppTheme.spacing.md,
                      ),
                      sliver: _buildWeeksList(weeks, theme, colorScheme),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
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
          Text(
            'Training Program',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spacing.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.md,
              vertical: AppTheme.spacing.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppTheme.radii.sm),
            ),
            child: Text(
              'Your Journey to Excellence',
              style: theme.textTheme.titleMedium?.copyWith(
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
    final weekService = ref.watch(trainingProgramServicesProvider);

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
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToWorkoutDetails(context, workout['id']),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppTheme.spacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${workout['order']}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workout ${workout['order']}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (workout['description'] != null &&
                          workout['description'].toString().isNotEmpty) ...[
                        SizedBox(height: AppTheme.spacing.xs),
                        Text(
                          workout['description'],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing.md,
                    vertical: AppTheme.spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: colorScheme.onPrimary,
                        size: 18,
                      ),
                      SizedBox(width: AppTheme.spacing.xs),
                      Text(
                        'START',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildWeeksList(
    List<Map<String, dynamic>> weeks,
    ThemeData theme,
    ColorScheme colorScheme,
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

    if (!mounted) return;

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

  Future<void> fetchTrainingWeeks() async {
    ref.read(trainingLoadingProvider.notifier).state = true;
    try {
      final weeks = await ref
          .read(trainingProgramServicesProvider)
          .fetchTrainingWeeks(widget.programId);
      if (mounted) {
        ref.read(trainingWeeksProvider.notifier).state = weeks;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading training weeks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(trainingLoadingProvider.notifier).state = false;
      }
    }
  }

  void _navigateToWorkoutDetails(BuildContext context, String workoutId) {
    final expandedWeekId = ref.read(expandedWeekProvider);
    if (expandedWeekId == null) return;

    context.go('/user_programs/training_viewer/workout_details',
        extra: {
          'programId': widget.programId,
          'weekId': expandedWeekId,
          'workoutId': workoutId,
          'userId': widget.userId
        });
  }
}
