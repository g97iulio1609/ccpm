import 'package:flutter/material.dart';

// Costanti per le misurazioni
class MeasurementConstants {
  static const Map<String, String> measurementUnits = {
    'weight': 'kg',
    'height': 'cm',
    'bodyFat': '%',
    'waist': 'cm',
    'hip': 'cm',
    'chest': 'cm',
    'biceps': 'cm',
  };

  static const Map<String, String> measurementLabels = {
    'weight': 'Peso',
    'height': 'Altezza',
    'bodyFat': 'Grasso Corporeo',
    'waist': 'Vita',
    'hip': 'Fianchi',
    'chest': 'Torace',
    'biceps': 'Bicipiti',
  };

  static final Map<String, IconData> measurementIcons = {
    'weight': Icons.monitor_weight_outlined,
    'height': Icons.height,
    'bodyFat': Icons.pie_chart_outline,
    'waist': Icons.straighten,
    'hip': Icons.straighten,
    'chest': Icons.straighten,
    'biceps': Icons.straighten,
  };
}

// Enums per stati e tipi
enum MeasurementStatus {
  underweight,
  normal,
  overweight,
  obese,
  essentialFat,
  athletes,
  fitness,
  veryLow,
  high,
  optimal
}

// Configurazioni per il grafico
class ChartConfig {
  static const double defaultMaxY = 100.0;
  static const double yAxisInterval = 10.0;
  static const int xAxisLabelInterval = 2;
  static const double dotRadius = 4.0;
  static const double lineWidth = 3.0;

  static final Map<String, Color> chartColors = {
    'weight': Colors.blue,
    'bodyFat': Colors.orange,
    'waist': Colors.green,
  };
}
