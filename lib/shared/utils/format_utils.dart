import 'package:intl/intl.dart';

/// Shared formatting utilities for training models
/// Consolidates formatting logic from both trainingBuilder and Viewer modules
class FormatUtils {
  // Private constructor to prevent instantiation
  FormatUtils._();

  // Date formatters
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM');
  static final DateFormat _monthYearFormat = DateFormat('MMM yyyy');
  static final DateFormat _dayMonthFormat = DateFormat('dd MMM');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  // Number formatters
  static final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '€');

  /// Format date to string (dd/MM/yyyy)
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _dateFormat.format(date);
  }

  /// Format time to string (HH:mm)
  static String formatTime(DateTime? time) {
    if (time == null) return '-';
    return _timeFormat.format(time);
  }

  /// Format date and time to string (dd/MM/yyyy HH:mm)
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _dateTimeFormat.format(dateTime);
  }

  /// Format date to short string (dd/MM)
  static String formatShortDate(DateTime? date) {
    if (date == null) return '-';
    return _shortDateFormat.format(date);
  }

  /// Format date to month and year (MMM yyyy)
  static String formatMonthYear(DateTime? date) {
    if (date == null) return '-';
    return _monthYearFormat.format(date);
  }

  /// Format date to day and month (dd MMM)
  static String formatDayMonth(DateTime? date) {
    if (date == null) return '-';
    return _dayMonthFormat.format(date);
  }

  /// Format date to ISO string (yyyy-MM-dd)
  static String formatIsoDate(DateTime? date) {
    if (date == null) return '';
    return _isoFormat.format(date);
  }

  /// Format relative time (e.g., "2 days ago", "in 3 hours")
  static String formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '-';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      // Future time
      final futureDiff = dateTime.difference(now);
      if (futureDiff.inDays > 0) {
        return 'in ${futureDiff.inDays} day${futureDiff.inDays == 1 ? '' : 's'}';
      } else if (futureDiff.inHours > 0) {
        return 'in ${futureDiff.inHours} hour${futureDiff.inHours == 1 ? '' : 's'}';
      } else if (futureDiff.inMinutes > 0) {
        return 'in ${futureDiff.inMinutes} minute${futureDiff.inMinutes == 1 ? '' : 's'}';
      } else {
        return 'in a moment';
      }
    } else {
      // Past time
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'just now';
      }
    }
  }

  /// Format weight with appropriate unit
  static String formatWeight(double? weight, {String unit = 'kg', int decimals = 1}) {
    if (weight == null) return '-';
    if (decimals == 0) {
      return '${weight.round()}$unit';
    }
    return '${weight.toStringAsFixed(decimals)}$unit';
  }

  /// Format weight range
  static String formatWeightRange(double? minWeight, double? maxWeight, {String unit = 'kg'}) {
    if (minWeight == null) return '-';
    if (maxWeight == null || minWeight == maxWeight) {
      return formatWeight(minWeight, unit: unit);
    }
    return '${formatWeight(minWeight, unit: '')} - ${formatWeight(maxWeight, unit: unit)}';
  }

  /// Format reps
  static String formatReps(int? reps) {
    if (reps == null) return '-';
    return reps.toString();
  }

  /// Format reps range
  static String formatRepsRange(int? minReps, int? maxReps) {
    if (minReps == null) return '-';
    if (maxReps == null || minReps == maxReps) {
      return minReps.toString();
    }
    return '$minReps - $maxReps';
  }

  /// Format sets
  static String formatSets(int? sets) {
    if (sets == null) return '-';
    return sets.toString();
  }

  /// Format RPE
  static String formatRpe(String? rpe) {
    if (rpe == null || rpe.isEmpty) return '-';
    return 'RPE $rpe';
  }

  /// Format RPE range
  static String formatRpeRange(String? minRpe, String? maxRpe) {
    if (minRpe == null || minRpe.isEmpty) return '-';
    if (maxRpe == null || maxRpe.isEmpty || minRpe == maxRpe) {
      return formatRpe(minRpe);
    }
    return 'RPE $minRpe - $maxRpe';
  }

  /// Format intensity
  static String formatIntensity(String? intensity) {
    if (intensity == null || intensity.isEmpty) return '-';

    // If it's already a percentage, return as is
    if (intensity.endsWith('%')) {
      return intensity;
    }

    // Try to parse as decimal and convert to percentage
    final decimalValue = double.tryParse(intensity);
    if (decimalValue != null && decimalValue <= 1.0) {
      return '${(decimalValue * 100).toStringAsFixed(0)}%';
    }

    return intensity;
  }

  /// Format intensity range
  static String formatIntensityRange(String? minIntensity, String? maxIntensity) {
    if (minIntensity == null || minIntensity.isEmpty) return '-';
    if (maxIntensity == null || maxIntensity.isEmpty || minIntensity == maxIntensity) {
      return formatIntensity(minIntensity);
    }
    return '${formatIntensity(minIntensity)} - ${formatIntensity(maxIntensity)}';
  }

  /// Format duration in minutes to human readable format
  static String formatDuration(int? minutes) {
    if (minutes == null || minutes == 0) return '-';

    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      }
      return '${hours}h ${remainingMinutes}min';
    }
  }

  /// Format rest time in seconds
  static String formatRestTime(int? seconds) {
    if (seconds == null || seconds == 0) return '-';

    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}min';
      }
      return '${minutes}min ${remainingSeconds}s';
    } else {
      final hours = seconds ~/ 3600;
      final remainingMinutes = (seconds % 3600) ~/ 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      }
      return '${hours}h ${remainingMinutes}min';
    }
  }

  /// Format percentage
  static String formatPercentage(double? value, {int decimals = 1}) {
    if (value == null) return '-';
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format completion rate
  static String formatCompletionRate(int completed, int total) {
    if (total == 0) return '0%';
    final percentage = (completed / total) * 100;
    return '${percentage.toStringAsFixed(0)}%';
  }

  /// Format progress text
  static String formatProgress(int completed, int total, {String? unit}) {
    final unitText = unit != null ? ' $unit' : '';
    return '$completed/$total$unitText';
  }

  /// Format volume (weight × reps)
  static String formatVolume(double? volume, {String unit = 'kg'}) {
    if (volume == null || volume == 0) return '-';

    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}t';
    }
    return '${volume.toStringAsFixed(0)}$unit';
  }

  /// Format exercise type
  static String formatExerciseType(String? type) {
    if (type == null || type.isEmpty) return '-';
    return type
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Format superset indicator
  static String formatSupersetIndicator(String? supersetId, int? order) {
    if (supersetId == null || supersetId.isEmpty) return '';
    final letter = String.fromCharCode(65 + (order ?? 0)); // A, B, C, etc.
    return '${letter}1, ${letter}2';
  }

  /// Format workout status
  static String formatWorkoutStatus(bool isCompleted, DateTime? lastPerformed) {
    if (isCompleted) {
      if (lastPerformed != null) {
        return 'Completed ${formatRelativeTime(lastPerformed)}';
      }
      return 'Completed';
    }
    return 'Not completed';
  }

  /// Format week status
  static String formatWeekStatus(bool isCompleted, bool isActive, DateTime? startDate) {
    if (isCompleted) return 'Completed';
    if (isActive) return 'Current';
    if (startDate != null) {
      final now = DateTime.now();
      if (startDate.isAfter(now)) {
        return 'Upcoming';
      } else {
        return 'Past';
      }
    }
    return 'Scheduled';
  }

  /// Format series display text
  static String formatSeriesDisplay({
    required int reps,
    required double weight,
    int? maxReps,
    double? maxWeight,
    String? rpe,
    String? maxRpe,
  }) {
    final repsText = formatRepsRange(reps, maxReps);
    final weightText = formatWeightRange(weight, maxWeight);
    final rpeText = formatRpeRange(rpe, maxRpe);

    String display = '$repsText × $weightText';
    if (rpeText != '-') {
      display += ' @ $rpeText';
    }

    return display;
  }

  /// Format exercise summary
  static String formatExerciseSummary(String name, int seriesCount, bool isCompleted) {
    final statusIcon = isCompleted ? '✓' : '○';
    final seriesText = seriesCount == 1 ? 'series' : 'series';
    return '$statusIcon $name ($seriesCount $seriesText)';
  }

  /// Format workout summary
  static String formatWorkoutSummary(String name, int exerciseCount, int completedExercises) {
    final progressText = formatProgress(completedExercises, exerciseCount, unit: 'exercises');
    return '$name ($progressText)';
  }

  /// Format week summary
  static String formatWeekSummary(int weekNumber, int workoutCount, int completedWorkouts) {
    final progressText = formatProgress(completedWorkouts, workoutCount, unit: 'workouts');
    return 'Week $weekNumber ($progressText)';
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Format currency
  static String formatCurrency(double? amount) {
    if (amount == null) return '-';
    return _currencyFormat.format(amount);
  }

  /// Capitalize first letter
  static String capitalize(String? text) {
    if (text == null || text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Format camelCase to readable text
  static String camelCaseToReadable(String camelCase) {
    return camelCase
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map((word) => capitalize(word))
        .join(' ');
  }

  /// Truncate text with ellipsis
  static String truncate(String? text, int maxLength, {String ellipsis = '...'}) {
    if (text == null || text.length <= maxLength) return text ?? '';
    return '${text.substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Format list to readable string
  static String formatList(List<String> items, {String separator = ', ', String? lastSeparator}) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    if (items.length == 2) {
      return '${items.first}${lastSeparator ?? separator}${items.last}';
    }

    final allButLast = items.sublist(0, items.length - 1).join(separator);
    return '$allButLast${lastSeparator ?? separator}${items.last}';
  }

  /// Format tags
  static String formatTags(List<String>? tags) {
    if (tags == null || tags.isEmpty) return '';
    return tags.map((tag) => '#$tag').join(' ');
  }
}

/// Extension methods for easier formatting
extension DateTimeFormatting on DateTime {
  String get formatted => FormatUtils.formatDate(this);
  String get formattedTime => FormatUtils.formatTime(this);
  String get formattedDateTime => FormatUtils.formatDateTime(this);
  String get formattedShort => FormatUtils.formatShortDate(this);
  String get formattedRelative => FormatUtils.formatRelativeTime(this);
  String get formattedMonthYear => FormatUtils.formatMonthYear(this);
  String get formattedDayMonth => FormatUtils.formatDayMonth(this);
  String get formattedIso => FormatUtils.formatIsoDate(this);
}

extension DoubleFormatting on double {
  String formatWeight({String unit = 'kg', int decimals = 1}) =>
      FormatUtils.formatWeight(this, unit: unit, decimals: decimals);
  String formatVolume({String unit = 'kg'}) => FormatUtils.formatVolume(this, unit: unit);
  String formatPercentage({int decimals = 1}) =>
      FormatUtils.formatPercentage(this, decimals: decimals);
  String formatCurrency() => FormatUtils.formatCurrency(this);
}

extension IntFormatting on int {
  String formatReps() => FormatUtils.formatReps(this);
  String formatSets() => FormatUtils.formatSets(this);
  String formatDuration() => FormatUtils.formatDuration(this);
  String formatRestTime() => FormatUtils.formatRestTime(this);
  String formatFileSize() => FormatUtils.formatFileSize(this);
}

extension StringFormatting on String {
  String formatRpe() => FormatUtils.formatRpe(this);
  String formatIntensity() => FormatUtils.formatIntensity(this);
  String formatExerciseType() => FormatUtils.formatExerciseType(this);
  String get capitalized => FormatUtils.capitalize(this);
  String get camelCaseToReadable => FormatUtils.camelCaseToReadable(this);
  String truncate(int maxLength, {String ellipsis = '...'}) =>
      FormatUtils.truncate(this, maxLength, ellipsis: ellipsis);
}

extension ListFormatting on List<String> {
  String formatList({String separator = ', ', String? lastSeparator}) =>
      FormatUtils.formatList(this, separator: separator, lastSeparator: lastSeparator);
  String formatTags() => FormatUtils.formatTags(this);
}
