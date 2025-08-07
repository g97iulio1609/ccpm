import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import '../measurement_constants.dart';

class MeasurementCard extends StatelessWidget {
  final String title;
  final double? value;
  final String unit;
  final IconData icon;
  final MeasurementStatus status;
  final List<MapEntry<String, double?>> comparisonValues;

  const MeasurementCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.status,
    required this.comparisonValues,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Container(
      constraints: BoxConstraints(minHeight: isSmallScreen ? 120 : 150),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
        boxShadow: AppTheme.elevations.small,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {}, // Gestire il tap se necessario
            child: Padding(
              padding: EdgeInsets.all(
                isSmallScreen ? AppTheme.spacing.md : AppTheme.spacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, colorScheme, isSmallScreen),
                  if (value != null) ...[
                    SizedBox(
                      height: isSmallScreen
                          ? AppTheme.spacing.sm
                          : AppTheme.spacing.md,
                    ),
                    _buildValue(theme, colorScheme, isSmallScreen),
                    SizedBox(height: AppTheme.spacing.xs),
                    _buildStatus(theme, colorScheme),
                    if (comparisonValues.isNotEmpty) ...[
                      SizedBox(height: AppTheme.spacing.md),
                      Divider(color: colorScheme.outline.withAlpha(26)),
                      SizedBox(height: AppTheme.spacing.sm),
                      ..._buildComparisons(theme, colorScheme, isSmallScreen),
                    ],
                  ] else
                    _buildNoData(theme, colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isSmallScreen,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(
            isSmallScreen ? AppTheme.spacing.xs : AppTheme.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(76),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: isSmallScreen ? 16 : 20,
          ),
        ),
        SizedBox(
          width: isSmallScreen ? AppTheme.spacing.xs : AppTheme.spacing.sm,
        ),
        Expanded(
          child: Text(
            title,
            style:
                (isSmallScreen
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.titleMedium)
                    ?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildValue(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isSmallScreen,
  ) {
    final textStyle = isSmallScreen
        ? theme.textTheme.headlineSmall
        : theme.textTheme.headlineMedium;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${value!.toStringAsFixed(1)} $unit',
              style: textStyle?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatus(ThemeData theme, ColorScheme colorScheme) {
    final statusColor = _getStatusColor(status, colorScheme);
    return Container(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.sm,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(26),
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
      ),
      child: Text(
        _getStatusText(status),
        style: theme.textTheme.labelMedium?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  List<Widget> _buildComparisons(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isSmallScreen,
  ) {
    return comparisonValues.map((entry) {
      final difference = value! - (entry.value ?? 0);
      final isPositive = difference >= 0;
      return Container(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        padding: EdgeInsets.only(bottom: AppTheme.spacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                entry.key,
                style:
                    (isSmallScreen
                            ? theme.textTheme.labelSmall
                            : theme.textTheme.bodySmall)
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: isSmallScreen ? 14 : 16,
                  color: isPositive ? colorScheme.error : colorScheme.tertiary,
                ),
                const SizedBox(width: 2),
                Text(
                  '${difference.abs().toStringAsFixed(1)} $unit',
                  style:
                      (isSmallScreen
                              ? theme.textTheme.labelSmall
                              : theme.textTheme.bodySmall)
                          ?.copyWith(
                            color: isPositive
                                ? colorScheme.error
                                : colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildNoData(ThemeData theme, ColorScheme colorScheme) {
    return Text(
      'Nessun dato disponibile',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Color _getStatusColor(MeasurementStatus status, ColorScheme colorScheme) {
    switch (status) {
      case MeasurementStatus.underweight:
      case MeasurementStatus.veryLow:
        return colorScheme.secondary;
      case MeasurementStatus.normal:
      case MeasurementStatus.optimal:
      case MeasurementStatus.fitness:
        return colorScheme.tertiary;
      case MeasurementStatus.overweight:
      case MeasurementStatus.high:
        return colorScheme.secondary;
      case MeasurementStatus.obese:
        return colorScheme.error;
      case MeasurementStatus.essentialFat:
      case MeasurementStatus.athletes:
        return colorScheme.onSurface;
    }
  }

  String _getStatusText(MeasurementStatus status) {
    switch (status) {
      case MeasurementStatus.underweight:
        return 'Sottopeso';
      case MeasurementStatus.normal:
        return 'Normale';
      case MeasurementStatus.overweight:
        return 'Sovrappeso';
      case MeasurementStatus.obese:
        return 'Obeso';
      case MeasurementStatus.essentialFat:
        return 'Grasso Essenziale';
      case MeasurementStatus.athletes:
        return 'Atleta';
      case MeasurementStatus.fitness:
        return 'Fitness';
      case MeasurementStatus.veryLow:
        return 'Molto Basso';
      case MeasurementStatus.high:
        return 'Alto';
      case MeasurementStatus.optimal:
        return 'Ottimale';
    }
  }
}
