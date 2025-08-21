import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/shared/shared.dart';

import 'package:alphanessone/trainingBuilder/models/progression_view_model.dart';
import 'package:alphanessone/trainingBuilder/controllers/progression_controllers.dart';
import 'package:alphanessone/trainingBuilder/providers/training_providers.dart';
import 'package:alphanessone/trainingBuilder/services/progression_business_service_optimized.dart';
import 'package:alphanessone/shared/widgets/page_scaffold.dart';
import 'package:alphanessone/shared/widgets/empty_state.dart';
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
  ConsumerState<ProgressionsListPage> createState() => _ProgressionsListPageState();
}

class _ProgressionsListPageState extends ConsumerState<ProgressionsListPage>
    with AutomaticKeepAliveClientMixin, TrainingListMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeControllers());
  }

  void _initializeControllers() {
    if (widget.exercise == null) return;

    final programController = ref.read(trainingProgramControllerProvider.notifier);
    final weekProgressions = ProgressionBusinessServiceOptimized.buildWeekProgressions(
      programController.program.weeks,
      widget.exercise!,
    );

    ref.read(progressionControllersProvider.notifier).initialize(weekProgressions);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.exercise == null) {
      return const _ErrorView(message: 'Exercise data not available');
    }

    final programState = ref.watch(trainingProgramControllerProvider);
    final controllers = ref.watch(progressionControllersProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final weekProgressions = ProgressionBusinessServiceOptimized.buildWeekProgressions(
      programState.weeks,
      widget.exercise!,
    );

    if (controllers.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(progressionControllersProvider.notifier).initialize(weekProgressions);
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
    final programController = ref.read(trainingProgramControllerProvider.notifier);
    final weekProgressions = ProgressionBusinessServiceOptimized.buildWeekProgressions(
      programController.program.weeks,
      widget.exercise!,
    );
    final controllersNotifier = ref.read(progressionControllersProvider.notifier);

    try {
      ProgressionBusinessServiceOptimized.addSeriesGroup(
        weekIndex: weekIndex,
        sessionIndex: sessionIndex,
        groupIndex: groupIndex,
        weekProgressions: weekProgressions,
        exercise: widget.exercise!,
      );

      programController.updateWeekProgressions(weekProgressions, widget.exercise!.exerciseId!);

      controllersNotifier.addControllers(weekIndex, sessionIndex, groupIndex);
    } catch (e) {
      _showErrorMessage('Error adding series group: $e');
    }
  }

  void _removeSeriesGroup(int weekIndex, int sessionIndex, int groupIndex) {
    final programController = ref.read(trainingProgramControllerProvider.notifier);
    final weekProgressions = ProgressionBusinessServiceOptimized.buildWeekProgressions(
      programController.program.weeks,
      widget.exercise!,
    );

    try {
      ProgressionBusinessServiceOptimized.removeSeriesGroup(
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
    final programController = ref.read(trainingProgramControllerProvider.notifier);

    try {
      final weekProgressions = ProgressionBusinessServiceOptimized.buildWeekProgressions(
        programController.program.weeks,
        widget.exercise!,
      );

      // Validate parameters before update
      if (!_validateUpdateParams(params, weekProgressions)) {
        _showErrorMessage('Invalid update parameters');
        return;
      }

      ProgressionBusinessServiceOptimized.updateSeries(
        params: params,
        weekProgressions: weekProgressions,
      );

      _updateProgressionsWithNewSeries(weekProgressions);

      // Update controllers safely
      _updateControllersForSeries(params);

      setState(() {});
    } catch (e) {
      _showErrorMessage('Error updating series: ${e.toString()}');
    }
  }

  /// Validates update parameters
  bool _validateUpdateParams(
    SeriesUpdateParams params,
    List<List<WeekProgression>> weekProgressions,
  ) {
    if (params.weekIndex < 0 || params.sessionIndex < 0 || params.groupIndex < 0) {
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
      final programController = ref.read(trainingProgramControllerProvider.notifier);

      final updatedWeekProgressions = ProgressionBusinessServiceOptimized.buildWeekProgressions(
        programController.program.weeks,
        widget.exercise!,
      );

      // Validate indices before accessing (local validation)
      if (params.weekIndex < 0 ||
          params.weekIndex >= updatedWeekProgressions.length ||
          params.sessionIndex < 0 ||
          params.sessionIndex >= updatedWeekProgressions[params.weekIndex].length) {
        return;
      }

      final session = updatedWeekProgressions[params.weekIndex][params.sessionIndex];
      if (session.series.isEmpty) return;

      // Get the first series as representative if available
      if (session.series.isNotEmpty) {
        final firstSeries = session.series.first;
        final representativeSeries = firstSeries.copyWith(sets: session.series.length);

        controllers.updateControllers(
          params.weekIndex,
          params.sessionIndex,
          params.groupIndex,
          representativeSeries,
        );
      }
    } catch (e) {
      // Ignore controller update failures silently
    }
  }

  Future<void> _handleSave() async {
    final programController = ref.read(trainingProgramControllerProvider.notifier);
    final controllers = ref.read(progressionControllersProvider);

    try {
      final updatedWeekProgressions =
          ProgressionBusinessServiceOptimized.createUpdatedWeekProgressions(
            controllers,
            (text) => int.tryParse(text) ?? 0,
            (text) => double.tryParse(text) ?? 0.0,
          );

      // Validate before saving
      if (!ProgressionBusinessServiceOptimized.validateProgression(
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
      if (!mounted) return;
      _showErrorMessage('Error saving progressions: $e');
    }
  }

  void _updateProgressionsWithNewSeries(List<List<WeekProgression>> weekProgressions) {
    ref
        .read(trainingProgramControllerProvider.notifier)
        .updateWeekProgressions(weekProgressions, widget.exercise!.exerciseId!);
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.primary),
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
    return PageScaffold(
      colorScheme: viewModel.colorScheme,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(AppTheme.spacing.lg),
          sliver: SliverToBoxAdapter(
            child: ProgressionTableWidget(
              viewModel: viewModel,
              onAddSeriesGroup: onAddSeriesGroup,
              onRemoveSeriesGroup: onRemoveSeriesGroup,
              onUpdateSeries: onUpdateSeries,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.lg),
            child: _SaveButton(onSave: onSave, colorScheme: viewModel.colorScheme),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacing.lg)),
      ],
    );
  }
}

/// Reusable save button component following SRP
class _SaveButton extends StatelessWidget {
  final VoidCallback onSave;
  final ColorScheme colorScheme;

  const _SaveButton({required this.onSave, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onSave,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Salva', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    );
  }
}

/// Loading view component following SRP
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PageScaffold(
      colorScheme: colorScheme,
      slivers: const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

/// Error view component following SRP
class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PageScaffold(
      colorScheme: colorScheme,
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Dati non disponibili',
            subtitle: message,
          ),
        ),
      ],
    );
  }
}
