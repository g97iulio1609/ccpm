import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:alphanessone/models/measurement_model.dart';
import 'package:alphanessone/Main/app_theme.dart';
import '../measurement_constants.dart';

class MeasurementChart extends StatelessWidget {
  final List<MeasurementModel> measurements;
  final bool showWeight;
  final bool showBodyFat;
  final bool showWaist;

  const MeasurementChart({
    super.key,
    required this.measurements,
    this.showWeight = true,
    this.showBodyFat = true,
    this.showWaist = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (measurements.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: _buildGridData(colorScheme),
              titlesData: _buildTitlesData(theme, colorScheme),
              borderData: _buildBorderData(colorScheme),
              lineBarsData: _buildLineBarsData(colorScheme),
              minX: 0,
              maxX: (measurements.length - 1).toDouble(),
              minY: 0,
              maxY: _calculateMaxY(),
              lineTouchData: _buildTouchData(colorScheme),
            ),
          ),
        ),
        SizedBox(height: AppTheme.spacing.lg),
        _buildLegend(theme, colorScheme),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          SizedBox(height: AppTheme.spacing.md),
          Text(
            'Nessuna misurazione disponibile',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppTheme.spacing.sm),
          Text(
            'Aggiungi nuove misurazioni per visualizzare il grafico',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  FlGridData _buildGridData(ColorScheme colorScheme) {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      getDrawingHorizontalLine: (value) => FlLine(
        color: colorScheme.outlineVariant.withOpacity(0.2),
        strokeWidth: 1,
      ),
      getDrawingVerticalLine: (value) => FlLine(
        color: colorScheme.outlineVariant.withOpacity(0.2),
        strokeWidth: 1,
      ),
    );
  }

  FlTitlesData _buildTitlesData(ThemeData theme, ColorScheme colorScheme) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: ChartConfig.yAxisInterval,
          getTitlesWidget: (value, meta) => Text(
            value.toInt().toString(),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 10,
            ),
          ),
          reservedSize: 40,
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 &&
                index < measurements.length &&
                index % ChartConfig.xAxisLabelInterval == 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('dd/MM').format(measurements[index].date),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 10,
                  ),
                ),
              );
            }
            return const Text('');
          },
          reservedSize: 30,
        ),
      ),
    );
  }

  FlBorderData _buildBorderData(ColorScheme colorScheme) {
    return FlBorderData(
      show: true,
      border: Border.all(
        color: colorScheme.outlineVariant.withOpacity(0.2),
        width: 1,
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData(ColorScheme colorScheme) {
    final lines = <LineChartBarData>[];

    if (showWeight) {
      lines.add(_createLineData(
        (m) => m.weight,
        ChartConfig.chartColors['weight']!,
      ));
    }

    if (showBodyFat) {
      lines.add(_createLineData(
        (m) => m.bodyFatPercentage,
        ChartConfig.chartColors['bodyFat']!,
      ));
    }

    if (showWaist) {
      lines.add(_createLineData(
        (m) => m.waistCircumference,
        ChartConfig.chartColors['waist']!,
      ));
    }

    return lines;
  }

  LineChartBarData _createLineData(
      double? Function(MeasurementModel) getValue, Color color) {
    return LineChartBarData(
      spots: measurements.asMap().entries.map((entry) {
        final value = getValue(entry.value);
        return value != null && value > 0
            ? FlSpot(entry.key.toDouble(), value)
            : FlSpot.nullSpot;
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: ChartConfig.lineWidth,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: ChartConfig.dotRadius,
          color: color,
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  LineTouchData _buildTouchData(ColorScheme colorScheme) {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        tooltipRoundedRadius: AppTheme.radii.md,
        tooltipBorder: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        tooltipPadding: EdgeInsets.all(AppTheme.spacing.sm),
        tooltipMargin: AppTheme.spacing.sm,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((LineBarSpot touchedSpot) {
            final date = measurements[touchedSpot.x.toInt()].date;
            final value = touchedSpot.y;
            final measurementType = [
              'Peso',
              'Grasso Corporeo',
              'Circonferenza Vita'
            ][touchedSpot.barIndex];
            return LineTooltipItem(
              '${DateFormat('dd/MM/yyyy').format(date)}\n$measurementType: ${value.toStringAsFixed(1)}',
              TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList();
        },
        fitInsideHorizontally: true,
        fitInsideVertically: true,
      ),
      handleBuiltInTouches: true,
      getTouchLineStart: (data, index) => 0,
    );
  }

  Widget _buildLegend(ThemeData theme, ColorScheme colorScheme) {
    final items = <Widget>[];

    if (showWeight) {
      items.add(_buildLegendItem(
          'Peso', ChartConfig.chartColors['weight']!, theme, colorScheme));
    }
    if (showBodyFat) {
      items.add(_buildLegendItem('Grasso Corporeo',
          ChartConfig.chartColors['bodyFat']!, theme, colorScheme));
    }
    if (showWaist) {
      items.add(_buildLegendItem('Circonferenza Vita',
          ChartConfig.chartColors['waist']!, theme, colorScheme));
    }

    return Wrap(
      spacing: AppTheme.spacing.md,
      runSpacing: AppTheme.spacing.sm,
      children: items,
    );
  }

  Widget _buildLegendItem(
      String label, Color color, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppTheme.spacing.xs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMaxY() {
    if (measurements.isEmpty) {
      return ChartConfig.defaultMaxY;
    }

    final values = <double>[];

    if (showWeight) {
      values.addAll(measurements.map((m) => m.weight).where((v) => v > 0));
    }
    if (showBodyFat) {
      values.addAll(
          measurements.map((m) => m.bodyFatPercentage).where((v) => v > 0));
    }
    if (showWaist) {
      values.addAll(
          measurements.map((m) => m.waistCircumference).where((v) => v > 0));
    }

    if (values.isEmpty) {
      return ChartConfig.defaultMaxY;
    }

    return values.reduce((a, b) => a > b ? a : b) + 10;
  }
}
