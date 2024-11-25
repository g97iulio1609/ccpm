import 'package:alphanessone/trainingBuilder/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/dialog/athlete_selection_dialog.dart';
import 'package:alphanessone/trainingBuilder/List/week_list.dart';
import 'package:alphanessone/trainingBuilder/List/workout_list.dart';
import 'package:alphanessone/trainingBuilder/List/exercises_list.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/trainingBuilder/training_volume_dashboard.dart';
import 'package:alphanessone/Main/app_theme.dart';

class TrainingProgramPage extends HookConsumerWidget {
  final String programId;
  final String userId;
  final int? weekIndex;
  final int? workoutIndex;

  const TrainingProgramPage({
    super.key,
    required this.programId,
    required this.userId,
    this.weekIndex,
    this.workoutIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final controller = ref.watch(trainingProgramControllerProvider);
    final program = ref.watch(trainingProgramStateProvider);
    final userRole = ref.watch(userRoleProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    useEffect(() {
      if (programId.isNotEmpty && program.id != programId) {
        controller.loadProgram(programId);
      }
      return null;
    }, [programId]);

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
          child: program != null
              ? weekIndex != null
                  ? workoutIndex != null
                      ? TrainingProgramExerciseList(
                          controller: controller,
                          weekIndex: weekIndex!,
                          workoutIndex: workoutIndex!,
                        )
                      : TrainingProgramWorkoutListPage(
                          controller: controller,
                          weekIndex: weekIndex!,
                        )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(AppTheme.spacing.xl),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProgramForm(
                              controller,
                              userRole,
                              theme,
                              colorScheme,
                              context,
                              ref,
                            ),
                            SizedBox(height: AppTheme.spacing.xl),
                            _buildWeeksList(
                              controller,
                              programId,
                              userId,
                              theme,
                              colorScheme,
                              context,
                            ),
                          ],
                        ),
                      ),
                    )
              : Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProgramForm(
    TrainingProgramController controller,
    String userRole,
    ThemeData theme,
    ColorScheme colorScheme,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: controller.nameController,
            label: 'Program Name',
            hint: 'Enter program name',
            icon: Icons.title,
            theme: theme,
            colorScheme: colorScheme,
          ),
          SizedBox(height: AppTheme.spacing.md),
          _buildTextField(
            controller: controller.descriptionController,
            label: 'Description',
            hint: 'Enter program description',
            icon: Icons.description,
            theme: theme,
            colorScheme: colorScheme,
            maxLines: 3,
          ),
          SizedBox(height: AppTheme.spacing.md),
          if (userRole == 'admin')
            _buildAthleteButton(context, ref, controller, theme, colorScheme),
          SizedBox(height: AppTheme.spacing.md),
          _buildMesocycleField(controller, theme, colorScheme),
          SizedBox(height: AppTheme.spacing.lg),
          _buildProgramOptions(controller, theme, colorScheme),
          SizedBox(height: AppTheme.spacing.lg),
          _buildActionButtons(controller, context, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildAthleteButton(
    BuildContext context,
    WidgetRef ref,
    TrainingProgramController controller,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAthleteSelectionDialog(context, ref, controller),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppTheme.spacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
                SizedBox(width: AppTheme.spacing.sm),
                Text(
                  'Select Athlete',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMesocycleField(
    TrainingProgramController controller,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return TextFormField(
      controller: controller.mesocycleNumberController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Mesocycle Number',
        prefixIcon: Icon(Icons.fitness_center, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildProgramOptions(
    TrainingProgramController controller,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        _buildOptionSwitch(
          'Hide Program',
          controller.program.hide,
          (value) => controller.updateHideProgram(value),
          theme,
          colorScheme,
        ),
        SizedBox(height: AppTheme.spacing.sm),
        _buildOptionSwitch(
          'Public Program',
          controller.program.status == 'public',
          (value) => controller.updateProgramStatus(value ? 'public' : 'private'),
          theme,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildOptionSwitch(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radii.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
            activeTrackColor: colorScheme.primaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    TrainingProgramController controller,
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.add,
            label: 'Add Week',
            onTap: controller.addWeek,
            isPrimary: false,
            theme: theme,
            colorScheme: colorScheme,
          ),
        ),
        SizedBox(width: AppTheme.spacing.md),
        Expanded(
          child: _buildActionButton(
            icon: Icons.save,
            label: 'Save Program',
            onTap: () => controller.submitProgram(context),
            isPrimary: true,
            theme: theme,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPrimary
              ? [colorScheme.primary, colorScheme.primary.withOpacity(0.8)]
              : [colorScheme.surfaceVariant, colorScheme.surfaceVariant.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        boxShadow: isPrimary ? AppTheme.elevations.small : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppTheme.spacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: AppTheme.spacing.sm),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isPrimary ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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
    TrainingProgramController controller,
    String programId,
    String userId,
    ThemeData theme,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Program Weeks',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: AppTheme.spacing.md),
          TrainingProgramWeekList(
            programId: programId,
            userId: userId,
            controller: controller,
          ),
        ],
      ),
    );
  }

  void _showAthleteSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    TrainingProgramController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AthleteSelectionDialog(controller: controller),
    );
  }
}