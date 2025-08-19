import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/trainingBuilder/providers/training_providers.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/dialog/athlete_selection_dialog.dart';
import 'package:alphanessone/trainingBuilder/presentation/pages/weeks_page.dart';
import 'package:alphanessone/trainingBuilder/presentation/pages/workouts_page.dart';
import 'package:alphanessone/trainingBuilder/presentation/pages/exercises_page.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/widgets/page_scaffold.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import 'package:flutter/services.dart';
import 'package:alphanessone/trainingBuilder/services/io/training_share_io.dart' as share_io;
import 'package:alphanessone/trainingBuilder/services/training_share_service.dart';
import 'package:alphanessone/trainingBuilder/services/training_share_service_async.dart';

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
    final controller = ref.watch(trainingProgramControllerProvider.notifier);
    final programState = ref.watch(trainingProgramControllerProvider);
    final userRole = ref.watch(userRoleProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    useEffect(() {
      if (programId.isNotEmpty && programState.id != programId) {
        controller.loadProgram(programId);
      }
      return null;
    }, [programId, programState.id]);

    if (weekIndex != null) {
      return workoutIndex != null
          ? ExercisesPage(
              controller: controller,
              weekIndex: weekIndex!,
              workoutIndex: workoutIndex!,
            )
          : TrainingProgramWorkoutListPage(
              controller: controller,
              weekIndex: weekIndex!,
            );
    }

    return PageScaffold(
      colorScheme: colorScheme,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(AppTheme.spacing.xl),
          sliver: SliverToBoxAdapter(
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
      ],
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
    BuildContext context,
    WidgetRef ref,
    TrainingProgramController controller,
  ) {
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
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
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
              onTap: () =>
                  _showAthleteSelectionDialog(context, ref, controller),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: controller.addWeek,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add),
                    SizedBox(width: AppTheme.spacing.sm),
                    const Text('Add Week'),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: FilledButton(
                onPressed: () => controller.submitProgram(context),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save),
                    SizedBox(width: AppTheme.spacing.sm),
                    const Text('Save Program'),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.md),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: () async {
                  try {
                    final exportMap = 
                        TrainingShareService.programToExportMap(controller.program);
                    final content = await encodeJsonAsync(exportMap);
                    if (context.mounted) {
                      _showExportDialog(context, title: 'Export JSON', content: content);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Errore export JSON: $e')),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.code),
                    SizedBox(width: AppTheme.spacing.sm),
                    const Text('Export JSON'),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () async {
                  try {
                    final exportMap = 
                        TrainingShareService.programToExportMap(controller.program);
                    final content = await buildCsvAsync(exportMap);
                    if (context.mounted) {
                      _showExportDialog(context, title: 'Export CSV', content: content);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Errore export CSV: $e')),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.table_chart_outlined),
                    SizedBox(width: AppTheme.spacing.sm),
                    const Text('Export CSV'),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => _showImportDialog(context),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.file_upload_outlined),
                    SizedBox(width: AppTheme.spacing.sm),
                    const Text('Import'),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.md),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: () async {
                  try {
                    await const share_io.TrainingShareIO().exportProgramFile(
                      controller.program,
                      format: 'json',
                      suggestedFileName: controller.program.name,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Errore export file JSON: $e')),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.file_download_outlined),
                    SizedBox(width: AppTheme.spacing.sm),
                    const Text('Export .json'),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () async {
                  try {
                    await const share_io.TrainingShareIO().exportProgramFile(
                      controller.program,
                      format: 'csv',
                      suggestedFileName: controller.program.name,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Errore export file CSV: $e')),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.file_download_outlined),
                    SizedBox(width: AppTheme.spacing.sm),
                    const Text('Export .csv'),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () async {
                  try {
                    final imported =
                        await const share_io.TrainingShareIO().importProgramFromFile();
                    if (imported != null) {
                      controller.importProgramFromJson(
                        TrainingShareService.programToJson(imported),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Programma importato da file')),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Errore import da file: $e')),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.file_upload_outlined),
                    SizedBox(width: AppTheme.spacing.sm),
                    const Text('Import da file'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showExportDialog(BuildContext context,
      {required String title, required String content}) {
    final controller = TextEditingController(text: content);
    showAppDialog(
      context: context,
      title: title,
      subtitle: 'Copia e salva in un file',
      maxWidth: 900,
      maxHeight: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            readOnly: true,
            minLines: 12,
            maxLines: 20,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: AppTheme.spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppDialogHelpers.buildCancelButton(context: context),
              AppDialogHelpers.buildActionButton(
                context: context,
                label: 'Copia',
                icon: Icons.copy,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: controller.text));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contenuto copiato')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final inputCtrl = TextEditingController();
    String format = 'json';
    showAppDialog(
      context: context,
      title: 'Import Program',
      subtitle: 'Incolla contenuto JSON o CSV',
      maxWidth: 900,
      maxHeight: 700,
      child: StatefulBuilder(
        builder: (context, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ChoiceChip(
                  label: const Text('JSON'),
                  selected: format == 'json',
                  onSelected: (_) => setState(() => format = 'json'),
                ),
                SizedBox(width: AppTheme.spacing.sm),
                ChoiceChip(
                  label: const Text('CSV'),
                  selected: format == 'csv',
                  onSelected: (_) => setState(() => format = 'csv'),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing.md),
            TextField(
              controller: inputCtrl,
              minLines: 14,
              maxLines: 24,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Incolla qui il contenuto...',
              ),
            ),
            SizedBox(height: AppTheme.spacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppDialogHelpers.buildCancelButton(context: context),
                AppDialogHelpers.buildActionButton(
                  context: context,
                  label: 'Importa',
                  icon: Icons.check,
                  onPressed: () async {
                    try {
                      if (format == 'json') {
                        final map = await parseJsonToExportMapAsync(inputCtrl.text);
                        final program = TrainingShareService.programFromExportMap(
                          Map<String, dynamic>.from(map['program'] as Map),
                        );
                        this.controller.importProgramModel(program);
                      } else {
                        final map = await parseCsvToExportMapAsync(inputCtrl.text);
                        final program = TrainingShareService.programFromExportMap(
                          Map<String, dynamic>.from(map['program'] as Map),
                        );
                        this.controller.importProgramModel(program);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Programma importato')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Errore import: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
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
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
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
          borderSide: BorderSide(color: colorScheme.outline.withAlpha(76)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(76),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
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
                  colorScheme.surfaceContainerHighest.withAlpha(204),
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
