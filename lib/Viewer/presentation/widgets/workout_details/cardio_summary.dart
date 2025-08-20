import 'package:flutter/material.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/Main/app_theme.dart';

class CardioSummary extends StatelessWidget {
  final Exercise exercise;
  const CardioSummary({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final totalDur = _sum<int?>(exercise.series.map((s) => s.executedDurationSeconds ?? s.durationSeconds)) ?? 0;
    final totalDist = _sum<int?>(exercise.series.map((s) => s.executedDistanceMeters ?? s.distanceMeters)) ?? 0;
    final avgHr = _avg<int?>(exercise.series.map((s) => s.executedAvgHr))?.round();

    final hasPace = totalDist > 0 && totalDur > 0;
    final paceSecPerKm = hasPace ? (totalDur / (totalDist / 1000)).round() : null;
    final speedKmh = hasPace ? (3.6 * totalDist / totalDur) : null;

    final plannedIncline = _avg<double?>(exercise.series.map((s) => s.inclinePercent));
    final plannedHrPct = _avg<double?>(exercise.series.map((s) => s.hrPercent));
    final plannedKcal = _sum<int?>(exercise.series.map((s) => s.kcal));

    List<_ChipData> chips = [];
    if (totalDur > 0) chips.add(_ChipData(Icons.timer, _fmtDuration(totalDur)));
    if (totalDist > 0) chips.add(_ChipData(Icons.route, _fmtDistance(totalDist)));
    if (paceSecPerKm != null) chips.add(_ChipData(Icons.directions_run, _fmtPace(paceSecPerKm)));
    if (speedKmh != null) chips.add(_ChipData(Icons.speed, '${speedKmh.toStringAsFixed(1)} km/h'));
    if (avgHr != null && avgHr > 0) chips.add(_ChipData(Icons.monitor_heart, '$avgHr bpm'));
    if (plannedHrPct != null) chips.add(_ChipData(Icons.favorite, '${plannedHrPct.toStringAsFixed(0)}% HRmax'));
    if (plannedIncline != null) chips.add(_ChipData(Icons.trending_up, '${plannedIncline.toStringAsFixed(1)}%'));
    if (plannedKcal != null && plannedKcal > 0) chips.add(_ChipData(Icons.local_fire_department, '$plannedKcal kcal'));

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(38),
        borderRadius: BorderRadius.circular(AppTheme.radii.md),
        border: Border.all(color: cs.outlineVariant.withAlpha(38)),
      ),
      child: Wrap(
        spacing: AppTheme.spacing.sm,
        runSpacing: AppTheme.spacing.sm,
        children: chips
            .map((c) => _MetricChip(icon: c.icon, label: c.label))
            .toList(),
      ),
    );
  }

  T? _sum<T extends num?>(Iterable<T> values) {
    num total = 0;
    bool any = false;
    for (final v in values) {
      if (v != null) {
        total += v;
        any = true;
      }
    }
    return any ? (total as T) : null;
  }

  double? _avg<T extends num?>(Iterable<T> values) {
    num total = 0;
    int count = 0;
    for (final v in values) {
      if (v != null) {
        total += v;
        count++;
      }
    }
    if (count == 0) return null;
    return total / count;
  }

  String _fmtDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _fmtDistance(int meters) => '${(meters / 1000).toStringAsFixed(2)} km';
  String _fmtPace(int secPerKm) {
    final m = (secPerKm ~/ 60).toString().padLeft(2, '0');
    final s = (secPerKm % 60).toString().padLeft(2, '0');
    return '$m:$s/km';
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.sm, vertical: AppTheme.spacing.xs),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withAlpha(38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          SizedBox(width: AppTheme.spacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _ChipData {
  final IconData icon;
  final String label;
  _ChipData(this.icon, this.label);
}
