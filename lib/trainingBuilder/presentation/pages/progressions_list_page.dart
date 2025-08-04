import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/models/progressions_model.dart';
import 'package:alphanessone/trainingBuilder/models/progression_view_model.dart';
import 'package:alphanessone/trainingBuilder/controllers/progression_controllers.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/services/progression_business_service.dart';
import 'package:alphanessone/trainingBuilder/presentation/widgets/progression_table_widget.dart';
import 'package:alphanessone/trainingBuilder/shared/mixins/training_list_mixin.dart';
import 'package:alphanessone/Main/app_theme.dart';

/// Main progressions list page following SOLID principles and MVVM pattern
class ProgressionsListPage extends ConsumerStatefulWidget {
  final String exerciseId;
  final Exercise? exercise;
  final num latestMaxWeight;

  const ProgressionsListPage({
    super.key,
    required this.exerciseId,
    this.exercise,
    required this.latestMaxWeight,
  });

  @override
  ConsumerState<ProgressionsListPage> createState() =>
      _ProgressionsListPageState();
}

class _ProgressionsListPageState extends ConsumerState<ProgressionsListPage>
    with AutomaticKeepAliveClientMixin, TrainingListMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _initializeControllers());
  }

  void _initializeControllers() {
    if (widget.exercise == null) return;

    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = ProgressionBusinessService.buildWeekProgressions(
      programController.program.weeks,
      widget.exercise!,
    );

    ref
        .read(progressionControllersProvider.notifier)
        .initialize(weekProgressions);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.exercise == null) {
      return const _ErrorView(message: 'Exercise data not available');
    }

    final programController = ref.watch(trainingProgramControllerProvider);
    final controllers = ref.watch(progressionControllersProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final weekProgressions = ProgressionBusinessService.buildWeekProgressions(
      programController.program.weeks,
      widget.exercise!,
    );

    if (controllers.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(progressionControllersProvider.notifier)
            .initialize(weekProgressions);
      });
      return const _LoadingView();
    }

    final viewModel = ProgressionViewModel(
      exerciseId: widget.exerciseId,
      exercise: widget.exercise,
      latestMaxWeight: widget.latestMaxWeight,
      weekProgressions: weekProgressions,
      controllers: controllers,
      colorScheme: colorScheme,
      theme: theme,
    );

    return _ProgressionsView(
      viewModel: viewModel,
      onSave: _handleSave,
      onAddSeriesGroup: _addSeriesGroup,
      onRemoveSeriesGroup: _removeSeriesGroup,
      onUpdateSeries: _updateSeries,
    );
  }

  void _addSeriesGroup(int weekIndex, int sessionIndex, int groupIndex) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = ProgressionBusinessService.buildWeekProgressions(
      programController.program.weeks,
      widget.exercise!,
    );
    final controllersNotifier =
        ref.read(progressionControllersProvider.notifier);

    try {
      ProgressionBusinessService.addSeriesGroup(
        weekIndex: weekIndex,
        sessionIndex: sessionIndex,
        groupIndex: groupIndex,
        weekProgressions: weekProgressions,
        exercise: widget.exercise!,
      );

      programController.updateWeekProgressions(
        weekProgressions,
        widget.exercise!.exerciseId!,
      );

      controllersNotifier.addControllers(weekIndex, sessionIndex, groupIndex);
    } catch (e) {
      _showErrorMessage('Error adding series group: $e');
    }
  }

  void _removeSeriesGroup(int weekIndex, int sessionIndex, int groupIndex) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = ProgressionBusinessService.buildWeekProgressions(
      programController.program.weeks,
      widget.exercise!,
    );

    try {
      ProgressionBusinessService.removeSeriesGroup(
        weekIndex: weekIndex,
        sessionIndex: sessionIndex,
        groupIndex: groupIndex,
        weekProgressions: weekProgressions,
      );

      _updateProgressionsWithNewSeries(weekProgressions);

      ref
          .read(progressionControllersProvider.notifier)
          .removeControllers(weekIndex, sessionIndex, groupIndex);
    } catch (e) {
      _showErrorMessage('Error removing series group: $e');
    }
  }

  void _updateSeries(SeriesUpdateParams params) {
    final programController = ref.read(trainingProgramControllerProvider);

    try {
      final weekProgressions = ProgressionBusinessService.buildWeekProgressions(
        programController.program.weeks,
        widget.exercise!,
      );

      // Validate parameters before update
      if (!_validateUpdateParams(params, weekProgressions)) {
        _showErrorMessage('Invalid update parameters');
        return;
      }

      ProgressionBusinessService.updateSeries(
        params: params,
        weekProgressions: weekProgressions,
      );

      _updateProgressionsWithNewSeries(weekProgressions);

      // Update controllers safely
      _updateControllersForSeries(params);

      setState(() {});
    } catch (e) {
      debugPrint('ERROR: Failed to update series: $e');
      _showErrorMessage('Error updating series: ${e.toString()}');
    }
  }

  /// Validates update parameters
  bool _validateUpdateParams(
      SeriesUpdateParams params, List<List<WeekProgression>> weekProgressions) {
    if (params.weekIndex < 0 ||
        params.sessionIndex < 0 ||
        params.groupIndex < 0) {
      return false;
    }

    if (params.weekIndex >= weekProgressions.length) {
      return false;
    }

    if (params.sessionIndex >= weekProgressions[params.weekIndex].length) {
      return false;
    }

    return true;
  }

  /// Updates controllers for series safely
  void _updateControllersForSeries(SeriesUpdateParams params) {
    try {
      final controllers = ref.read(progressionControllersProvider.notifier);
      final programController = ref.read(trainingProgramControllerProvider);

      final updatedWeekProgressions =
          ProgressionBusinessService.buildWeekProgressions(
        programController.program.weeks,
        widget.exercise!,
      );

      // Validate indices before accessing
      if (!ProgressionBusinessService.isValidIndex(
          updatedWeekProgressions, params.weekIndex, params.sessionIndex)) {
        return;
      }

      final session =
          updatedWeekProgressions[params.weekIndex][params.sessionIndex];
      if (session.series.isEmpty) return;

      // Get the first series as representative if available
      final firstSeries = session.series.first;
      if (firstSeries != null) {
        final representativeSeries =
            firstSeries.copyWith(sets: session.series.length);

        controllers.updateControllers(
          params.weekIndex,
          params.sessionIndex,
          params.groupIndex,
          representativeSeries,
        );
      }
    } catch (e) {
      debugPrint('WARNING: Failed to update controllers: $e');
      // Don't throw here, just log the warning
    }
  }

  Future<void> _handleSave() async {
    final programController = ref.read(trainingProgramControllerProvider);
    final controllers = ref.read(progressionControllersProvider);

    try {
      final updatedWeekProgressions =
          ProgressionBusinessService.createUpdatedWeekProgressions(
        controllers,
        (text) => int.tryParse(text) ?? 0,
        (text) => double.tryParse(text) ?? 0.0,
      );

      // Validate before saving
      if (!ProgressionBusinessService.validateProgression(
        exercise: widget.exercise!,
        weekProgressions: updatedWeekProgressions,
      )) {
        _showErrorMessage('Validation failed. Please check your data.');
        return;
      }

      programController.updateWeekProgressions(
        updatedWeekProgressions,
        widget.exercise!.exerciseId!,
      );

      if (!mounted) return;

      _showSuccessMessage('Progressions saved successfully');
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('ERROR: Failed to save changes: $e');
      if (!mounted) return;
      _showErrorMessage('Error saving progressions: $e');
    }
  }

  void _updateProgressionsWithNewSeries(weekProgressions) {
    ref
        .read(trainingProgramControllerProvider)
        .updateWeekProgressions(weekProgressions, widget.exercise!.exerciseId!);
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Separated view component for progressions display following SRP
class _ProgressionsView extends StatelessWidget {
  final ProgressionViewModel viewModel;
  final VoidCallback onSave;
  final Function(int, int, int) onAddSeriesGroup;
  final Function(int, int, int) onRemoveSeriesGroup;
  final ValueChanged<SeriesUpdateParams> onUpdateSeries;

  const _ProgressionsView({
    required this.viewModel,
    required this.onSave,
    required this.onAddSeriesGroup,
    required this.onRemoveSeriesGroup,
    required this.onUpdateSeries,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: viewModel.colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing.lg),
                child: ProgressionTableWidget(
                  viewModel: viewModel,
                  onAddSeriesGroup: onAddSeriesGroup,
                  onRemoveSeriesGroup: onRemoveSeriesGroup,
                  onUpdateSeries: onUpdateSeries,
                ),
              ),
            ),
          ),
          _SaveButton(
            onSave: onSave,
            colorScheme: viewModel.colorScheme,
          ),
          SizedBox(height: AppTheme.spacing.lg),
        ],
      ),
    );
  }
}

/// Reusable save button component following SRP
class _SaveButton extends StatelessWidget {
  final VoidCallback onSave;
  final ColorScheme colorScheme;

  const _SaveButton({
    required this.onSave,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Salva',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Loading view component following SRP
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Error view component following SRP
class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: AppTheme.spacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
