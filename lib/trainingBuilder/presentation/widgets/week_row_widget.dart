import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/trainingBuilder/controllers/progression_controllers.dart';
import 'package:alphanessone/trainingBuilder/models/progression_view_model.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/presentation/widgets/progression_field_widgets.dart';

/// Widget for displaying week row with progression data following SRP
class WeekRowWidget extends StatelessWidget {
  final int weekIndex;
  final int sessionIndex;
  final List<ProgressionControllers> sessionControllers;
  final Exercise exercise;
  final num latestMaxWeight;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isSmallScreen;
  final Function(int, int, int) onAddSeriesGroup;
  final Function(int, int, int) onRemoveSeriesGroup;
  final ValueChanged<SeriesUpdateParams> onUpdateSeries;

  const WeekRowWidget({
    super.key,
    required this.weekIndex,
    required this.sessionIndex,
    required this.sessionControllers,
    required this.exercise,
    required this.latestMaxWeight,
    required this.colorScheme,
    required this.theme,
    required this.isSmallScreen,
    required this.onAddSeriesGroup,
    required this.onRemoveSeriesGroup,
    required this.onUpdateSeries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outline.withAlpha(26))),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSmallScreen) _buildWeekHeader(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSmallScreen) _buildWeekColumn(),
                Expanded(flex: isSmallScreen ? 12 : 10, child: _buildGroupsColumn(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekHeader() {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing.md),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.sm,
          vertical: AppTheme.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(76),
          borderRadius: BorderRadius.circular(AppTheme.radii.full),
        ),
        child: Text(
          'Week ${weekIndex + 1}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekColumn() {
    return Expanded(
      flex: 2,
      child: Text(
        '${weekIndex + 1}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildGroupsColumn(BuildContext context) {
    return Column(
      children: [
        ...sessionControllers.asMap().entries.map((entry) {
          final groupIndex = entry.key;
          final controllers = entry.value;
          return Column(
            children: [
              if (groupIndex > 0) SizedBox(height: AppTheme.spacing.sm),
              _buildGroupRow(context, groupIndex, controllers),
            ],
          );
        }),
        _buildAddGroupButton(),
      ],
    );
  }

  Widget _buildGroupRow(BuildContext context, int groupIndex, ProgressionControllers controllers) {
    final groupContent = Row(
      children: [
        Expanded(
          child: ProgressionGroupFields(
            controllers: controllers,
            exercise: exercise,
            latestMaxWeight: latestMaxWeight,
            colorScheme: colorScheme,
            theme: theme,
            isSmallScreen: isSmallScreen,
            onUpdateSeries: onUpdateSeries,
            updateParams: SeriesUpdateParams(
              weekIndex: weekIndex,
              sessionIndex: sessionIndex,
              groupIndex: groupIndex,
            ),
          ),
        ),
        if (!isSmallScreen)
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
            onPressed: () => onRemoveSeriesGroup(weekIndex, sessionIndex, groupIndex),
            tooltip: 'Rimuovi Gruppo',
          ),
      ],
    );

    if (isSmallScreen) {
      return _buildSlidableGroup(groupContent, groupIndex);
    }

    return groupContent;
  }

  Widget _buildSlidableGroup(Widget groupContent, int groupIndex) {
    return Slidable(
      key: ValueKey('group-$weekIndex-$sessionIndex-$groupIndex'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onRemoveSeriesGroup(weekIndex, sessionIndex, groupIndex),
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            icon: Icons.delete,
            label: 'Rimuovi',
          ),
        ],
      ),
      child: groupContent,
    );
  }

  Widget _buildAddGroupButton() {
    return Padding(
      padding: EdgeInsets.only(top: AppTheme.spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () {
              onAddSeriesGroup(weekIndex, sessionIndex, sessionControllers.length);
            },
            icon: Icon(Icons.add_circle_outline, size: 16, color: colorScheme.primary),
            label: Text(
              'Aggiungi Gruppo',
              style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.primary),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing.md,
                vertical: AppTheme.spacing.sm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
