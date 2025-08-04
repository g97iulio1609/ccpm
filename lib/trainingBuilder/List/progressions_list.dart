import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/presentation/pages/progressions_list_page.dart';
// Backward compatibility - utility function for number formatting
String formatNumber(dynamic value) {
  if (value == null) return '0';
  if (value is num) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }
  return value.toString();
}

/// Main progressions list widget - now acts as a wrapper for the new modular architecture
/// This maintains backward compatibility while delegating to the new refactored components
class ProgressionsList extends ConsumerStatefulWidget {
  final String exerciseId;
  final Exercise? exercise;
  final num latestMaxWeight;

  const ProgressionsList({
    super.key,
    required this.exerciseId,
    this.exercise,
    required this.latestMaxWeight,
  });

  @override
  ConsumerState<ProgressionsList> createState() => _ProgressionsListState();
}

class _ProgressionsListState extends ConsumerState<ProgressionsList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Delegate to the new refactored page
    return ProgressionsListPage(
      exerciseId: widget.exerciseId,
      exercise: widget.exercise,
      latestMaxWeight: widget.latestMaxWeight,
    );
  }
}
