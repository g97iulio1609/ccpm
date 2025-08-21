/// Utility class for formatting numbers and values in the training builder
class FormatUtils {
  FormatUtils._();

  /// Formats a number value to string with consistent rules
  static String formatNumber(dynamic value) {
    if (value == null) return '';
    if (value is int) return value.toString();
    if (value is double) {
      return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
    }
    if (value is String) {
      if (value.isEmpty) return '';
      final doubleValue = double.tryParse(value);
      return doubleValue != null ? formatNumber(doubleValue) : value;
    }
    return value.toString();
  }

  /// Formats a range from min and max values
  static String formatRange(String minValue, String? maxValue) {
    final minText = formatNumber(minValue);
    final maxText = formatNumber(maxValue);
    if (maxText.isEmpty) return minText;
    if (minText.isEmpty) return maxText;
    return "$minText-$maxText";
  }

  /// Formats series information for display
  static String formatSeriesInfo({
    required int reps,
    int? maxReps,
    required double weight,
    double? maxWeight,
  }) {
    final repsText = formatRange(reps.toString(), maxReps?.toString());
    final weightText = formatRange(weight.toString(), maxWeight?.toString());
    return '$repsText reps x $weightText kg';
  }

  /// Validates if a string is a valid number
  static bool isValidNumber(String value) {
    return double.tryParse(value) != null;
  }

  /// Parses a range string to min/max values
  static ({String min, String max}) parseRange(String range) {
    if (range.contains('-')) {
      final parts = range.split('-');
      return (
        min: parts.isNotEmpty ? parts[0].trim() : '',
        max: parts.length > 1 ? parts[1].trim() : '',
      );
    }
    return (min: range.trim(), max: '');
  }
}
