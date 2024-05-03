import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MeasurementsChart extends StatefulWidget {
  const MeasurementsChart({
    super.key,
    required this.measurementData,
    required this.startDate,
    required this.endDate,
    required this.selectedMeasurements,
  });

  final Map<String, List<FlSpot>> measurementData;
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<String> selectedMeasurements;

  @override
  State<MeasurementsChart> createState() => _MeasurementsChartState();
}

class _MeasurementsChartState extends State<MeasurementsChart> {
  @override
  Widget build(BuildContext context) {
    List<LineChartBarData> lineBarsData = [];

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var measurement in widget.selectedMeasurements) {
      if (widget.measurementData.containsKey(measurement)) {
        final data = widget.measurementData[measurement]!;
        final color = _getColorForMeasurement(measurement);

        lineBarsData.add(
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: color,
            barWidth: 5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.2),
            ),
          ),
        );

        for (var spot in data) {
          minX = min(minX, spot.x);
          maxX = max(maxX, spot.x);
          minY = min(minY, spot.y);
          maxY = max(maxY, spot.y);
        }
      }
    }

    return SizedBox(
      height: 400,
      child: LineChart(
        LineChartData(
          lineBarsData: lineBarsData,
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('$value');
                },
                reservedSize: 40,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final dateTime = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  final date = DateFormat('MMM dd').format(dateTime);
                  final matchingSpots = lineBarsData
                      .expand((barData) => barData.spots)
                      .where((spot) => spot.x == value);
                  return matchingSpots.isNotEmpty
                      ? SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(date),
                        )
                      : const SideTitleWidget(
                          axisSide: AxisSide.bottom,
                          child: Text(''),
                        );
                },
                reservedSize: 30,
                interval: (maxX - minX) / 5,
              ),
            ),
          ),
          
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Colors.grey,
              width: 1,
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.5),
                strokeWidth: 1,
              );
            },
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final date = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
                  final formattedDate = DateFormat('MMM dd').format(date);
                  final value = touchedSpot.y.toStringAsFixed(2);
                  final measurementName = _getMeasurementName(touchedSpot.barIndex);
                  return LineTooltipItem(
                    '$measurementName\n$formattedDate: $value',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForMeasurement(String measurement) {
    switch (measurement) {
      case 'weight':
        return Colors.blue;
      case 'bodyFatPercentage':
        return Colors.green;
      case 'waistCircumference':
        return Colors.red;
      case 'hipCircumference':
        return Colors.orange;
      case 'chestCircumference':
        return Colors.purple;
      case 'bicepsCircumference':
        return Colors.teal;
      default:
        return Colors.black;
    }
  }

  String _getMeasurementName(int barIndex) {
    final selectedMeasurementsList = widget.selectedMeasurements.toList();
    if (barIndex >= 0 && barIndex < selectedMeasurementsList.length) {
      return selectedMeasurementsList[barIndex];
    }
    return '';
  }
}