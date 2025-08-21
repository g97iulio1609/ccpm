import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../shared/shared.dart';
import '../shared/widgets/exercise_components.dart';
import '../../Main/app_theme.dart';
import '../../UI/components/button.dart';

/// Widget per mostrare lo stato vuoto della lista esercizi
class EmptyExerciseState extends StatelessWidget {
  final VoidCallback onAddExercise;
  final bool isCompact;
  final ColorScheme colorScheme;

  const EmptyExerciseState({
    required this.onAddExercise,
    required this.isCompact,
    required this.colorScheme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEmptyIcon(),
            SizedBox(height: AppTheme.spacing.lg),
            _buildEmptyTitle(context),
            SizedBox(height: AppTheme.spacing.sm),
            _buildEmptySubtitle(context),
            SizedBox(height: AppTheme.spacing.xl),
            _buildAddButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyIcon() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(76),
        borderRadius: BorderRadius.circular(AppTheme.radii.xl),
      ),
      child: Icon(
        Icons.fitness_center_outlined,
        size: isCompact ? 48 : 64,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildEmptyTitle(BuildContext context) {
    return Text(
      'Nessun esercizio disponibile',
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEmptySubtitle(BuildContext context) {
    return Text(
      'Aggiungi il primo esercizio per iniziare',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAddButton() {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isCompact ? double.infinity : 300),
        child: AppButton(
          label: 'Add Exercise',
          icon: Icons.add_circle_outline,
          variant: AppButtonVariant.primary,
          size: isCompact ? AppButtonSize.sm : AppButtonSize.md,
          block: true,
          onPressed: onAddExercise,
        ),
      ),
    );
  }
}

/// Widget per la card di un esercizio con azioni swipe
class ExerciseCardWithActions extends StatelessWidget {
  final Exercise exercise;
  final List<SuperSet> superSets;
  final Widget seriesSection;
  final VoidCallback onTap;
  final VoidCallback onOptionsPressed;
  final VoidCallback onAddExercise;
  final VoidCallback onDeleteExercise;
  final ColorScheme colorScheme;

  const ExerciseCardWithActions({
    required this.exercise,
    required this.superSets,
    required this.seriesSection,
    required this.onTap,
    required this.onOptionsPressed,
    required this.onAddExercise,
    required this.onDeleteExercise,
    required this.colorScheme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      startActionPane: _buildStartActionPane(),
      endActionPane: _buildEndActionPane(),
      child: ExerciseCard(
        exercise: exercise,
        superSets: superSets,
        seriesSection: seriesSection,
        onTap: onTap,
        onOptionsPressed: onOptionsPressed,
      ),
    );
  }

  ActionPane _buildStartActionPane() {
    return ActionPane(
      motion: const ScrollMotion(),
      children: [
        SlidableAction(
          onPressed: (_) => onAddExercise(),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          borderRadius: BorderRadius.horizontal(left: Radius.circular(AppTheme.radii.lg)),
          icon: Icons.add,
          label: 'Add',
        ),
      ],
    );
  }

  ActionPane _buildEndActionPane() {
    return ActionPane(
      motion: const ScrollMotion(),
      children: [
        SlidableAction(
          onPressed: (_) => onDeleteExercise(),
          backgroundColor: colorScheme.errorContainer,
          foregroundColor: colorScheme.onErrorContainer,
          borderRadius: BorderRadius.horizontal(right: Radius.circular(AppTheme.radii.lg)),
          icon: Icons.delete_outline,
          label: 'Delete',
        ),
      ],
    );
  }
}

/// Widget per il grid/list layout responsivo degli esercizi
class ExerciseLayoutBuilder extends StatelessWidget {
  final List<Exercise> exercises;
  final bool isCompact;
  final double spacing;
  final Widget Function(Exercise exercise) exerciseBuilder;
  final Widget addExerciseButton;

  const ExerciseLayoutBuilder({
    required this.exercises,
    required this.isCompact,
    required this.spacing,
    required this.exerciseBuilder,
    required this.addExerciseButton,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return isCompact ? _buildListLayout(context) : _buildGridLayout(context);
  }

  Widget _buildListLayout(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == exercises.length) {
          return Padding(
            padding: EdgeInsets.only(top: spacing),
            child: addExerciseButton,
          );
        }
        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: exerciseBuilder(exercises[index]),
        );
      }, childCount: exercises.length + 1),
    );
  }

  Widget _buildGridLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1600
        ? 4
        : width >= 1200
        ? 3
        : 2;
    final aspectRatio = width >= 1400 ? 1.0 : 0.9;

    return SliverGrid(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == exercises.length) {
          return addExerciseButton;
        }
        return exerciseBuilder(exercises[index]);
      }, childCount: exercises.length + 1),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
    );
  }
}

/// Widget per il pulsante di aggiunta esercizio
class AddExerciseButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isCompact;

  const AddExerciseButton({required this.onPressed, required this.isCompact, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isCompact ? double.infinity : 300),
        child: AppButton(
          label: 'Add Exercise',
          icon: Icons.add_circle_outline,
          variant: AppButtonVariant.primary,
          size: isCompact ? AppButtonSize.sm : AppButtonSize.md,
          block: true,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// Widget per il FAB di riordino esercizi
class ReorderExercisesFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isCompact;
  final ColorScheme colorScheme;

  const ReorderExercisesFAB({
    required this.onPressed,
    required this.isCompact,
    required this.colorScheme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      icon: const Icon(Icons.reorder),
      label: Text(
        isCompact ? 'Riordina' : 'Riordina Esercizi',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radii.xl)),
    );
  }
}

/// Widget per il gradiente di sfondo della lista esercizi
class ExerciseListBackground extends StatelessWidget {
  final Widget child;
  final ColorScheme colorScheme;

  const ExerciseListBackground({required this.child, required this.colorScheme, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.surface, colorScheme.surfaceContainerHighest.withAlpha(128)],
          stops: const [0.0, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Widget per determinare il layout responsivo
class ResponsiveLayoutHelper {
  static bool isCompact(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static double getSpacing(BuildContext context) {
    return isCompact(context) ? AppTheme.spacing.sm : AppTheme.spacing.md;
  }

  static EdgeInsets getPadding(BuildContext context) {
    final isCompactLayout = isCompact(context);
    return EdgeInsets.all(isCompactLayout ? AppTheme.spacing.md : AppTheme.spacing.lg);
  }

  static int getGridCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 3;
    if (screenWidth > 900) return 2;
    return 1;
  }

  static bool shouldUseGridLayout(BuildContext context) {
    return !isCompact(context);
  }
}
