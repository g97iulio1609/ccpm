import 'package:alphanessone/trainingBuilder/providers/training_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/dialog/athlete_selection_dialog.dart';
import 'package:alphanessone/trainingBuilder/List/week_list.dart';
import 'package:alphanessone/trainingBuilder/List/workout_list.dart';
import 'package:alphanessone/trainingBuilder/List/exercises_list.dart';
import 'package:alphanessone/providers/providers.dart';
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
      backgroundColor: colorScheme.surface,
      body: Container(
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
        child: SafeArea(
          child: weekIndex != null
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
                        _ProgramDetailsForm(
                          controller: controller,
                          userRole: userRole,
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                        SizedBox(height: AppTheme.spacing.xl),
                        _ProgramWeeksSection(
                          controller: controller,
                          programId: programId,
                          userId: userId,
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ProgramDetailsForm extends ConsumerWidget {
  final TrainingProgramController controller;
  final String userRole;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ProgramDetailsForm({
    required this.controller,
    required this.userRole,
    required this.theme,
    required this.colorScheme,
  });

  void _showAthleteSelectionDialog(
      BuildContext context, WidgetRef ref, TrainingProgramController controller) {
    showDialog(
      context: context,
      builder: (context) => AthleteSelectionDialog(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withAlpha(26),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CustomTextFormField(
            controller: controller.nameController,
            labelText: 'Program Name',
            hintText: 'Enter program name',
            icon: Icons.title,
            theme: theme,
            colorScheme: colorScheme,
          ),
          SizedBox(height: AppTheme.spacing.md),
          _CustomTextFormField(
            controller: controller.descriptionController,
            labelText: 'Description',
            hintText: 'Enter program description',
            icon: Icons.description,
            theme: theme,
            colorScheme: colorScheme,
            maxLines: 3,
          ),
          SizedBox(height: AppTheme.spacing.md),
          if (userRole == 'admin')
            _GradientElevatedButton(
              onTap: () => _showAthleteSelectionDialog(context, ref, controller),
              label: 'Select Athlete',
              icon: Icons.person_add,
              theme: theme,
              colorScheme: colorScheme,
              isPrimary: true, // Assuming this is a primary action
            ),
          SizedBox(height: AppTheme.spacing.md),
          _CustomTextFormField(
            controller: controller.mesocycleNumberController,
            labelText: 'Mesocycle Number',
            hintText: 'Enter mesocycle number',
            icon: Icons.fitness_center,
            theme: theme,
            colorScheme: colorScheme,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: AppTheme.spacing.lg),
          _ProgramOptions(
            controller: controller,
            theme: theme,
            colorScheme: colorScheme,
          ),
          SizedBox(height: AppTheme.spacing.lg),
          _ActionButtons(
            controller: controller,
            theme: theme,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

class _ProgramOptions extends StatelessWidget {
  final TrainingProgramController controller;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ProgramOptions({
    required this.controller,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OptionSwitch(
          label: 'Hide Program',
          value: controller.program.hide,
          onChanged: (value) => controller.updateHideProgram(value),
          theme: theme,
          colorScheme: colorScheme,
        ),
        SizedBox(height: AppTheme.spacing.sm),
        _OptionSwitch(
          label: 'Public Program',
          value: controller.program.status == 'public',
          onChanged: (value) =>
              controller.updateProgramStatus(value ? 'public' : 'private'),
          theme: theme,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final TrainingProgramController controller;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ActionButtons({
    required this.controller,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GradientElevatedButton(
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
          child: _GradientElevatedButton(
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
}

class _ProgramWeeksSection extends StatelessWidget {
  final TrainingProgramController controller;
  final String programId;
  final String userId;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ProgramWeeksSection({
    required this.controller,
    required this.programId,
    required this.userId,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withAlpha(26),
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
}

class _CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData icon;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final int? maxLines;
  final TextInputType? keyboardType;

  const _CustomTextFormField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.icon,
    required this.theme,
    required this.colorScheme,
    this.maxLines,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
          borderSide: BorderSide(
            color: colorScheme.outline.withAlpha(76),
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
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(76),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
    );
  }
}

class _GradientElevatedButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _GradientElevatedButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPrimary
              ? [colorScheme.primary, colorScheme.primary.withAlpha(204)]
              : [
                  colorScheme.surfaceContainerHighest,
                  colorScheme.surfaceContainerHighest.withAlpha(204)
                ],
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
              horizontal: AppTheme.spacing.lg, // Added for better padding
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: AppTheme.spacing.sm),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isPrimary
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
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
}

class _OptionSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _OptionSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(76),
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
            activeTrackColor: colorScheme.primaryContainer.withAlpha(76),
            inactiveThumbColor: colorScheme.onSurfaceVariant,
            inactiveTrackColor: colorScheme.surfaceContainer.withAlpha(76),
          ),
        ],
      ),
    );
  }
}
