import 'package:flutter_riverpod/flutter_riverpod.dart';

class MeasurementsStateNotifier extends StateNotifier<MeasurementsState> {
  MeasurementsStateNotifier() : super(const MeasurementsState());

  void setSelectedDates(DateTime? startDate, DateTime? endDate) {
    state = MeasurementsState(startDate: startDate, endDate: endDate);
  }
}

final measurementsStateNotifierProvider =
    StateNotifierProvider<MeasurementsStateNotifier, MeasurementsState>(
        (ref) => MeasurementsStateNotifier());

class MeasurementsState {
  final DateTime? startDate;
  final DateTime? endDate;

  const MeasurementsState({this.startDate, this.endDate});
}

class SelectedMeasurementsNotifier extends StateNotifier<Set<String>> {
  SelectedMeasurementsNotifier()
      : super({'weight', 'bodyFatPercentage'});

  void toggleSelectedMeasurement(String measurement) {
    if (state.contains(measurement)) {
      state = {...state..remove(measurement)};
    } else {
      state = {...state..add(measurement)};
    }
  }
}

final selectedMeasurementsProvider =
    StateNotifierProvider<SelectedMeasurementsNotifier, Set<String>>((ref) {
  return SelectedMeasurementsNotifier();
});