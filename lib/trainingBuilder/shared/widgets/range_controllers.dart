import 'package:flutter/material.dart';
import 'package:alphanessone/trainingBuilder/shared/utils/format_utils.dart';

/// Reusable controller class for handling range inputs (min/max values)
class RangeControllers {
  final TextEditingController min;
  final TextEditingController max;

  RangeControllers()
      : min = TextEditingController(),
        max = TextEditingController();

  void dispose() {
    min.dispose();
    max.dispose();
  }

  String get displayText {
    return FormatUtils.formatRange(min.text, max.text);
  }

  void updateFromDialog(String minValue, String maxValue) {
    min.text = minValue;
    max.text = maxValue;
  }

  void updateFromRange(String range) {
    final parsed = FormatUtils.parseRange(range);
    min.text = parsed.min;
    max.text = parsed.max;
  }

  bool get hasValues => min.text.isNotEmpty || max.text.isNotEmpty;

  bool get isValid =>
      FormatUtils.isValidNumber(min.text) &&
      (max.text.isEmpty || FormatUtils.isValidNumber(max.text));
}
