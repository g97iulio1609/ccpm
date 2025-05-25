import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/progression_components.dart';
import 'package:alphanessone/trainingBuilder/models/progression_view_model.dart';
import 'package:alphanessone/trainingBuilder/presentation/widgets/week_row_widget.dart';

/// Widget for displaying progression table following single responsibility principle
class ProgressionTableWidget extends StatelessWidget {
  final ProgressionViewModel viewModel;
  final Function(int, int, int) onAddSeriesGroup;
  final Function(int, int, int) onRemoveSeriesGroup;
  final ValueChanged<SeriesUpdateParams> onUpdateSeries;

  const ProgressionTableWidget({
    super.key,
    required this.viewModel,
    required this.onAddSeriesGroup,
    required this.onRemoveSeriesGroup,
    required this.onUpdateSeries,
  });

  @override
  Widget build(BuildContext context) {
    final nonEmptySessions = viewModel.getNonEmptySessions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nonEmptySessions
          .map((sessionNumber) => _buildSessionTable(sessionNumber, context))
          .toList(),
    );
  }

  Widget _buildSessionTable(int sessionNumber, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSessionHeader(sessionNumber),
        _buildTableContainer(sessionNumber, context),
      ],
    );
  }

  Widget _buildSessionHeader(int sessionNumber) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.lg),
      child: Text(
        'Sessione ${sessionNumber + 1}',
        style: viewModel.theme.textTheme.headlineSmall?.copyWith(
          color: viewModel.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTableContainer(int sessionNumber, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: viewModel.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: viewModel.colorScheme.outline.withAlpha(26),
        ),
      ),
      child: Column(
        children: [
          _buildTableHeader(context),
          ..._buildWeekRows(sessionNumber, context),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return ProgressionTableHeader(
      colorScheme: viewModel.colorScheme,
      theme: viewModel.theme,
      isSmallScreen: viewModel.isSmallScreen(context),
    );
  }

  List<Widget> _buildWeekRows(int sessionIndex, BuildContext context) {
    return viewModel.weekProgressions.asMap().entries.map((entry) {
      final weekIndex = entry.key;
      return _buildWeekRow(weekIndex, sessionIndex, context);
    }).toList();
  }

  Widget _buildWeekRow(int weekIndex, int sessionIndex, BuildContext context) {
    final sessionControllers =
        viewModel.getSessionControllers(weekIndex, sessionIndex);

    if (sessionControllers == null) {
      return const SizedBox.shrink();
    }

    return WeekRowWidget(
      weekIndex: weekIndex,
      sessionIndex: sessionIndex,
      sessionControllers: sessionControllers,
      exercise: viewModel.exercise!,
      latestMaxWeight: viewModel.latestMaxWeight,
      colorScheme: viewModel.colorScheme,
      theme: viewModel.theme,
      isSmallScreen: viewModel.isSmallScreen(context),
      onAddSeriesGroup: onAddSeriesGroup,
      onRemoveSeriesGroup: onRemoveSeriesGroup,
      onUpdateSeries: onUpdateSeries,
    );
  }
}
