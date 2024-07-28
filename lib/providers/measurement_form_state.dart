import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
