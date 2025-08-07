import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';

/// Component for displaying exercise card header with type badge
class ExerciseCardHeader extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onOptionsPressed;

  const ExerciseCardHeader({
    super.key,
    required this.exercise,
    required this.onOptionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        _buildTypeBadge(theme, colorScheme),
        const Spacer(),
        _buildOptionsButton(colorScheme),
      ],
    );
  }

  Widget _buildTypeBadge(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(76),
        borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
      ),
      child: Text(
        exercise.type,
        style: theme.textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOptionsButton(ColorScheme colorScheme) {
    return IconButton(
      icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
      onPressed: onOptionsPressed,
    );
  }
}

/// Component for displaying exercise title and variant
class ExerciseTitleSection extends StatelessWidget {
  final Exercise exercise;

  const ExerciseTitleSection({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exercise.name,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (exercise.variant?.isNotEmpty == true && exercise.variant != '') ...[
          SizedBox(height: AppTheme.spacing.xs),
          Text(
            exercise.variant!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Component for displaying superset badge
class SupersetBadge extends StatelessWidget {
  final List<SuperSet> superSets;

  const SupersetBadge({super.key, required this.superSets});

  @override
  Widget build(BuildContext context) {
    if (superSets.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_work, size: 18, color: colorScheme.secondary),
          SizedBox(width: AppTheme.spacing.xs),
          Text(
            'Superset',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Component for exercise card layout
class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final List<SuperSet> superSets;
  final Widget seriesSection;
  final VoidCallback onTap;
  final VoidCallback onOptionsPressed;
  final VoidCallback? onAddPressed;
  final VoidCallback? onDeletePressed;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.superSets,
    required this.seriesSection,
    required this.onTap,
    required this.onOptionsPressed,
    this.onAddPressed,
    this.onDeletePressed,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: _buildCardContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExerciseCardHeader(
          exercise: widget.exercise,
          onOptionsPressed: widget.onOptionsPressed,
        ),
        SizedBox(height: AppTheme.spacing.md),
        ExerciseTitleSection(exercise: widget.exercise),
        SizedBox(height: AppTheme.spacing.md),
        // Contenitore scrollabile con estetica migliorata
        Flexible(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radii.md),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withAlpha(26),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withAlpha(26),
                        ),
                      ),
                    ),
                    Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      interactive: true,
                      radius: Radius.circular(AppTheme.radii.full),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing.xs,
                          vertical: AppTheme.spacing.xs,
                        ),
                        child: widget.seriesSection,
                      ),
                    ),
                    // Fade top
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.surface.withAlpha(180),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Fade bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.surface.withAlpha(180),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: AppTheme.spacing.sm),
        SupersetBadge(superSets: widget.superSets),
      ],
    );
  }
}
