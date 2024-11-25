import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/training_program_provider.dart';
import '../../UI/components/card.dart';
import 'package:alphanessone/Main/app_theme.dart';

class WeekDetails extends ConsumerStatefulWidget {
  final String programId;
  final String weekId;
  final String userId;

  const WeekDetails({
    super.key,
    required this.programId,
    required this.weekId,
    required this.userId,
  });

  @override
  ConsumerState<WeekDetails> createState() => _WeekDetailsState();
}

class _WeekDetailsState extends ConsumerState<WeekDetails> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeWeekName();
      _isInitialized = true;
    }
  }

  Future<void> _initializeWeekName() async {
    final weekService = ref.read(trainingProgramServicesProvider);
    final weekName = await weekService.fetchWeekName(widget.weekId);
    if (mounted) {
      ref.read(currentWeekNameProvider.notifier).state = weekName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekService = ref.watch(trainingProgramServicesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          child: StreamBuilder<QuerySnapshot>(
            stream: weekService.getWorkouts(widget.weekId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Errore: ${snapshot.error}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                );
              }

              final workouts = snapshot.data!.docs
                  .map((doc) => {
                        'id': doc.id,
                        ...doc.data() as Map<String, dynamic>,
                      })
                  .toList();

              return CustomScrollView(
                slivers: [
                  // Header Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacing.xl),
                      child: _buildWeekHeader(theme, colorScheme),
                    ),
                  ),

                  // Workouts Grid/List
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.xl,
                      vertical: AppTheme.spacing.md,
                    ),
                    sliver: _buildWorkoutsList(workouts, theme, colorScheme),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWeekHeader(ThemeData theme, ColorScheme colorScheme) {
    final weekName = ref.watch(currentWeekNameProvider);
    
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
            weekName,
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
              'Training Program',
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

  Widget _buildWorkoutCard(Map<String, dynamic> workout, ThemeData theme, ColorScheme colorScheme) {
    final workoutId = workout['id'];
    
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
          onTap: () {
            if (workoutId != null) {
              context.go(
                '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/$workoutId',
              );
            }
          },
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Workout Number Badge
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
                    'Workout ${workout['order']}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                if (workout['description'] != null &&
                    workout['description'].toString().isNotEmpty) ...[
                  SizedBox(height: AppTheme.spacing.md),
                  Text(
                    workout['description'],
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                SizedBox(height: AppTheme.spacing.lg),
                
                // Start Button
                Container(
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
                      horizontal: AppTheme.spacing.lg,
                      vertical: AppTheme.spacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: colorScheme.onPrimary,
                          size: 20,
                        ),
                        SizedBox(width: AppTheme.spacing.xs),
                        Text(
                          'START',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutsList(List<Map<String, dynamic>> workouts, ThemeData theme, ColorScheme colorScheme) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildWorkoutCard(workouts[index], theme, colorScheme),
        childCount: workouts.length,
      ),
    );
  }
}