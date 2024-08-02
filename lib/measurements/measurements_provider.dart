import 'package:flutter/material.dart';
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


class MeasurementFormState {
  final GlobalKey<FormState> formKey;
  final DateTime selectedDate;
  final Map<String, TextEditingController> controllers;
  final String? editMeasurementId;

  MeasurementFormState({
    required this.formKey,
    required this.selectedDate,
    required this.controllers,
    this.editMeasurementId,
  });

  MeasurementFormState copyWith({
    GlobalKey<FormState>? formKey,
    DateTime? selectedDate,
    Map<String, TextEditingController>? controllers,
    String? editMeasurementId,
  }) {
    return MeasurementFormState(
      formKey: formKey ?? this.formKey,
      selectedDate: selectedDate ?? this.selectedDate,
      controllers: controllers ?? this.controllers,
      editMeasurementId: editMeasurementId ?? this.editMeasurementId,
    );
  }
}

class MeasurementFormNotifier extends StateNotifier<MeasurementFormState> {
  MeasurementFormNotifier()
      : super(
          MeasurementFormState(
            formKey: GlobalKey<FormState>(),
            selectedDate: DateTime.now(),
            controllers: {
              'weight': TextEditingController(),
              'height': TextEditingController(),
              'bodyFat': TextEditingController(),
              'waist': TextEditingController(),
              'hip': TextEditingController(),
              'chest': TextEditingController(),
              'biceps': TextEditingController(),
            },
          ),
        );

  void updateSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void updateController(String key, String value) {
    state.controllers[key]?.text = value;
  }

  void setEditMeasurementId(String? id) {
    state = state.copyWith(editMeasurementId: id);
  }

  void resetForm() {
    state.formKey.currentState?.reset();
    state = MeasurementFormState(
      formKey: GlobalKey<FormState>(),
      selectedDate: DateTime.now(),
      controllers: {
        'weight': TextEditingController(),
        'height': TextEditingController(),
        'bodyFat': TextEditingController(),
        'waist': TextEditingController(),
        'hip': TextEditingController(),
        'chest': TextEditingController(),
        'biceps': TextEditingController(),
      },
    );
  }
}
