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
import 'package:alphanessone/UI/components/button.dart';
import 'package:alphanessone/trainingBuilder/services/training_share_service.dart';
import 'package:alphanessone/trainingBuilder/services/training_share_service_async.dart';
import 'package:alphanessone/trainingBuilder/models/training_model.dart';
import 'package:alphanessone/trainingBuilder/models/progressions_model.dart';

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
          : TrainingProgramWorkoutListPage(controller: controller, weekIndex: weekIndex!);
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
            AppButton(
              icon: Icons.person_add,
              label: 'Select Athlete',
              variant: AppButtonVariant.subtle,
              onPressed: () => _showAthleteSelectionDialog(context, ref, controller),
              block: true,
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
          _ProgramOptions(controller: controller, theme: theme, colorScheme: colorScheme),
          SizedBox(height: AppTheme.spacing.lg),
          _ActionButtons(controller: controller, theme: theme, colorScheme: colorScheme),
        ],
      ),
    );
  }
}

class _ProgramOptions extends StatelessWidget {
  final TrainingProgramController controller;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ProgramOptions({required this.controller, required this.theme, required this.colorScheme});

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
          onChanged: (value) => controller.updateProgramStatus(value ? 'public' : 'private'),
          theme: theme,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  final TrainingProgramController controller;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ActionButtons({required this.controller, required this.theme, required this.colorScheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                icon: Icons.add,
                label: 'Add Week',
                variant: AppButtonVariant.subtle,
                onPressed: controller.addWeek,
                block: true,
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: AppButton(
                icon: Icons.save,
                label: 'Save',
                variant: AppButtonVariant.primary,
                onPressed: () => controller.submitProgram(context),
                block: true,
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.md),
        // Simplified actions: only Export and Import
        Row(
          children: [
            Expanded(
              child: AppButton(
                icon: Icons.file_download_outlined,
                label: 'Export',
                variant: AppButtonVariant.subtle,
                onPressed: () => _showUnifiedExportDialog(context),
                block: true,
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: AppButton(
                icon: Icons.file_upload_outlined,
                label: 'Import',
                variant: AppButtonVariant.subtle,
                onPressed: () => _showImportDialog(context, ref),
                block: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showExportDialog(BuildContext context, {required String title, required String content}) {
    final controller = TextEditingController(text: content);
    // Capture messenger from the caller context; pop the root navigator to close only the dialog.
    final messenger = ScaffoldMessenger.of(context);
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
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          SizedBox(height: AppTheme.spacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: AppTheme.spacing.sm,
              runSpacing: AppTheme.spacing.xs,
              children: [
                AppDialogHelpers.buildCancelButton(context: context),
                AppDialogHelpers.buildActionButton(
                  context: context,
                  label: 'Copia',
                  icon: Icons.copy,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: controller.text));
                    Navigator.of(context, rootNavigator: true).pop();
                    messenger.showSnackBar(const SnackBar(content: Text('Contenuto copiato')));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUnifiedExportDialog(BuildContext context) async {
    String format = 'json';
    String content = '';
    bool loading = true;
    final exportMap = TrainingShareService.programToExportMap(controller.program);
    final messenger = ScaffoldMessenger.of(context);
    final textCtrl = TextEditingController();

    Future<void> _loadContent() async {
      loading = true;
      try {
        content = (format == 'csv')
            ? await buildCsvAsync(exportMap)
            : await encodeJsonAsync(exportMap);
        textCtrl.text = content;
      } catch (e) {
        content = 'Errore generazione contenuto: $e';
        textCtrl.text = content;
      } finally {
        loading = false;
      }
    }

    await _loadContent();

    showAppDialog(
      context: context,
      title: 'Export Program',
      subtitle: 'Scegli formato e azione',
      maxWidth: 900,
      maxHeight: 700,
      child: StatefulBuilder(
        builder: (context, setState) {
          final mq = MediaQuery.of(context);
          final isCompact = mq.size.width < 700 || mq.size.height < 800;
          final editorHeight = (isCompact ? mq.size.height * 0.35 : mq.size.height * 0.45)
              .clamp(220.0, 480.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppTheme.spacing.sm,
                runSpacing: AppTheme.spacing.xs,
                children: [
                  ChoiceChip(
                    label: const Text('JSON'),
                    selected: format == 'json',
                    onSelected: (_) async {
                      setState(() => format = 'json');
                      await _loadContent();
                      // ignore: use_build_context_synchronously
                      setState(() {});
                    },
                  ),
                  ChoiceChip(
                    label: const Text('CSV'),
                    selected: format == 'csv',
                    onSelected: (_) async {
                      setState(() => format = 'csv');
                      await _loadContent();
                      // ignore: use_build_context_synchronously
                      setState(() {});
                    },
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacing.md),
              if (loading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ))
              else
                SizedBox(
                  height: editorHeight,
                  child: TextField(
                    controller: textCtrl,
                    readOnly: true,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
              SizedBox(height: AppTheme.spacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppTheme.spacing.sm,
                  runSpacing: AppTheme.spacing.xs,
                  children: [
                    AppDialogHelpers.buildCancelButton(context: context),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          await const share_io.TrainingShareIO().exportProgramFile(
                            controller.program,
                            format: format,
                            suggestedFileName: controller.program.name,
                          );
                          // ignore: use_build_context_synchronously
                          Navigator.of(context, rootNavigator: true).pop();
                          messenger.showSnackBar(
                            SnackBar(content: Text('File ${format.toUpperCase()} esportato')),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Errore export file: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Salva file'),
                    ),
                    AppDialogHelpers.buildActionButton(
                      context: context,
                      label: 'Copia',
                      icon: Icons.copy,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: content));
                        // ignore: use_build_context_synchronously
                        Navigator.of(context, rootNavigator: true).pop();
                        messenger.showSnackBar(const SnackBar(content: Text('Contenuto copiato')));
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final inputCtrl = TextEditingController();
    String format = 'json';
    Map<String, dynamic>? previewData;
    String? previewError;
    // Capture messenger from the page context; avoid using dialog context after pop.
    final messenger = ScaffoldMessenger.of(context);
    showAppDialog(
      context: context,
      title: 'Import Program',
      subtitle: 'Incolla contenuto JSON o CSV',
      maxWidth: 900,
      maxHeight: 700,
      child: StatefulBuilder(
        builder: (context, setState) {
          final mq = MediaQuery.of(context);
          final isCompact = mq.size.width < 700 || mq.size.height < 800;
          final editorHeight = isCompact ? mq.size.height * 0.35 : mq.size.height * 0.45;
          final theme = Theme.of(context);
          final cs = theme.colorScheme;
          Widget buildPreview() {
            if (previewError != null) {
              return Container(
                decoration: BoxDecoration(
                  color: cs.errorContainer.withAlpha(64),
                  borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                  border: Border.all(color: cs.error.withAlpha(128)),
                ),
                padding: EdgeInsets.all(AppTheme.spacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: cs.error),
                    SizedBox(width: AppTheme.spacing.sm),
                    Expanded(
                      child: Text(
                        'Errore anteprima: $previewError',
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (previewData == null) return const SizedBox.shrink();
            final p = Map<String, dynamic>.from(previewData!['program'] as Map);
            final weeks = (p['weeks'] as List?) ?? const [];
            int workoutCount = 0;
            int exerciseCount = 0;
            int seriesCount = 0;
            for (final w in weeks) {
              final week = Map<String, dynamic>.from(w as Map);
              final wos = (week['workouts'] as List?) ?? const [];
              workoutCount += wos.length;
              for (final wo in wos) {
                final wod = Map<String, dynamic>.from(wo as Map);
                final exs = (wod['exercises'] as List?) ?? const [];
                exerciseCount += exs.length;
                for (final ex in exs) {
                  final exMap = Map<String, dynamic>.from(ex as Map);
                  final ser = (exMap['series'] as List?) ?? const [];
                  seriesCount += ser.length;
                }
              }
            }
            return Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(84),
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                border: Border.all(color: cs.outline.withAlpha(54)),
              ),
              padding: EdgeInsets.all(AppTheme.spacing.md),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: cs.primary),
                    SizedBox(width: AppTheme.spacing.sm),
                    Expanded(
                      child: Wrap(
                        spacing: AppTheme.spacing.lg,
                        runSpacing: AppTheme.spacing.xs,
                        children: [
                          Text('Nome: ${p['name'] ?? '-'}'),
                          Text('Settimane: ${weeks.length}'),
                          Text('Workouts: $workoutCount'),
                          Text('Esercizi: $exerciseCount'),
                          Text('Serie: $seriesCount'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppTheme.spacing.sm,
                runSpacing: AppTheme.spacing.xs,
                children: [
                  ChoiceChip(
                    label: const Text('JSON'),
                    selected: format == 'json',
                    onSelected: (_) => setState(() => format = 'json'),
                  ),
                  ChoiceChip(
                    label: const Text('CSV'),
                    selected: format == 'csv',
                    onSelected: (_) => setState(() => format = 'csv'),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacing.md),
              SizedBox(
                height: editorHeight.clamp(220, 420),
                child: TextField(
                  controller: inputCtrl,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Incolla qui il contenuto...',
                  ),
                ),
              ),
              SizedBox(height: AppTheme.spacing.md),
              // Preview area (on-demand, no slowdown during typing)
              buildPreview(),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppTheme.spacing.sm,
                  runSpacing: AppTheme.spacing.xs,
                  children: [
                    AppDialogHelpers.buildCancelButton(context: context),
                    TextButton.icon(
                      onPressed: () async {
                        setState(() {
                          previewError = null;
                          previewData = null;
                        });
                        try {
                          final map = (format == 'json')
                              ? await parseJsonToExportMapAsync(inputCtrl.text)
                              : await parseCsvToExportMapAsync(inputCtrl.text);
                          setState(() {
                            previewData = map;
                            previewError = null;
                          });
                        } catch (e) {
                          setState(() {
                            previewError = e.toString();
                            previewData = null;
                          });
                        }
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Anteprima'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        // Import from file picker
                        Navigator.of(context, rootNavigator: true).pop();
                        try {
                          final imported = await const share_io.TrainingShareIO().importProgramFromFile();
                          if (imported != null) {
                            await _finalizeImport(imported, ref, messenger);
                            return;
                          }
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Nessun file selezionato')),
                          );
                        } catch (e) {
                          messenger.showSnackBar(SnackBar(content: Text('Errore import da file: $e')));
                        }
                      },
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('Importa da file'),
                    ),
                    AppDialogHelpers.buildActionButton(
                      context: context,
                      label: 'Importa',
                      icon: Icons.check,
                      onPressed: () async {
                        // Chiudi il dialog immediatamente per evitare problemi di lifecycle
                        Navigator.of(context, rootNavigator: true).pop();

                        try {
                          TrainingProgram program;
                          if (format == 'json') {
                            final map = await parseJsonToExportMapAsync(inputCtrl.text);
                            program = TrainingShareService.programFromExportMap(
                              Map<String, dynamic>.from(map['program'] as Map),
                            );
                          } else {
                            final map = await parseCsvToExportMapAsync(inputCtrl.text);
                            program = TrainingShareService.programFromExportMap(
                              Map<String, dynamic>.from(map['program'] as Map),
                            );
                          }

                          await _finalizeImport(program, ref, messenger);
                        } catch (e) {
                          messenger.showSnackBar(SnackBar(content: Text('Errore import: $e')));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _finalizeImport(
    TrainingProgram program,
    WidgetRef ref,
    ScaffoldMessengerState messenger,
  ) async {
    try {
      final ctrl = ref.read(trainingProgramControllerProvider.notifier);
      final currentAthleteId = ctrl.program.athleteId;

      var importedProgram = program;

      // Se l'atleta differisce, imposta quello corrente e resetta i dati esecuzione
      if (currentAthleteId.isNotEmpty && program.athleteId != currentAthleteId) {
        importedProgram = _adaptProgramForAthlete(program, currentAthleteId);
        await ctrl.updateProgramWeights(importedProgram);
      }

      // Aggiungi suffisso al nome per chiarezza
      importedProgram = importedProgram.copyWith(
        name: importedProgram.name.isNotEmpty
            ? '${importedProgram.name} (import)'
            : 'Programma Importato',
      );

      // Import nel controller mantenendo l'ID corrente se presente
      ctrl.importProgramModel(importedProgram);

      messenger.showSnackBar(
        const SnackBar(content: Text('Programma importato con successo')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Errore durante import: $e')));
    }
  }

  TrainingProgram _adaptProgramForAthlete(TrainingProgram program, String athleteId) {
    final adaptedWeeks = program.weeks.map((w) {
      final adaptedWorkouts = w.workouts.map((wo) {
        final adaptedExercises = wo.exercises.map((ex) {
          final adaptedSeries = ex.series
              .map(
                (s) => s.copyWith(
                  done: false,
                  isCompleted: false,
                  repsDone: 0,
                  weightDone: 0.0,
                ),
              )
              .toList();

          // Reset anche le serie nelle progressioni settimanali
          List<List<WeekProgression>>? adaptedProgressions;
          if (ex.weekProgressions != null && ex.weekProgressions!.isNotEmpty) {
            adaptedProgressions = ex.weekProgressions!
                .map(
                  (weekList) => weekList
                      .map((wp) => wp.copyWith(resetCompletionData: true))
                      .toList(),
                )
                .toList();
          }

          return ex.copyWith(series: adaptedSeries, weekProgressions: adaptedProgressions);
        }).toList();
        return wo.copyWith(exercises: adaptedExercises);
      }).toList();
      return w.copyWith(workouts: adaptedWorkouts);
    }).toList();

    return program.copyWith(athleteId: athleteId, weeks: adaptedWeeks);
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
          TrainingProgramWeekList(programId: programId, userId: userId, controller: controller),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radii.md)),
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
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md, vertical: AppTheme.spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(76),
        borderRadius: BorderRadius.circular(AppTheme.radii.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
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
