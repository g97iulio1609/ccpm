import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/presentation/pages/progressions_list_page.dart';
import 'package:alphanessone/trainingBuilder/shared/utils/format_utils.dart';

// Backward compatibility - utility function for number formatting
String formatNumber(dynamic value) {
  return FormatUtils.formatNumber(value);
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
