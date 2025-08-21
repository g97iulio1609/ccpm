import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/models/measurement_model.dart';
import 'package:alphanessone/services/measurements_service.dart';
import 'measurement_constants.dart';

class MeasurementController extends StateNotifier<AsyncValue<List<MeasurementModel>>> {
  final MeasurementsService _measurementsService;
  final String userId;

  MeasurementController(this._measurementsService, this.userId)
    : super(const AsyncValue.loading()) {
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    try {
      state = const AsyncValue.loading();
      final measurements = await _measurementsService.getMeasurements(userId);
      state = AsyncValue.data(measurements);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addMeasurement(MeasurementModel measurement) async {
    try {
      await _measurementsService.addMeasurement(
        userId: userId,
        date: measurement.date,
        weight: measurement.weight,
        height: measurement.height,
        bmi: measurement.bmi,
        bodyFatPercentage: measurement.bodyFatPercentage,
        waistCircumference: measurement.waistCircumference,
        hipCircumference: measurement.hipCircumference,
        chestCircumference: measurement.chestCircumference,
        bicepsCircumference: measurement.bicepsCircumference,
      );
      _loadMeasurements();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateMeasurement(String measurementId, MeasurementModel measurement) async {
    try {
      await _measurementsService.updateMeasurement(
        userId: userId,
        measurementId: measurementId,
        date: measurement.date,
        weight: measurement.weight,
        height: measurement.height,
        bmi: measurement.bmi,
        bodyFatPercentage: measurement.bodyFatPercentage,
        waistCircumference: measurement.waistCircumference,
        hipCircumference: measurement.hipCircumference,
        chestCircumference: measurement.chestCircumference,
        bicepsCircumference: measurement.bicepsCircumference,
      );
      _loadMeasurements();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteMeasurement(String measurementId) async {
    try {
      await _measurementsService.deleteMeasurement(userId: userId, measurementId: measurementId);
      _loadMeasurements();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  MeasurementStatus getWeightStatus(double bodyFatPercentage, int gender) {
    if (gender == 1) {
      // Male
      if (bodyFatPercentage < 6) return MeasurementStatus.essentialFat;
      if (bodyFatPercentage < 14) return MeasurementStatus.athletes;
      if (bodyFatPercentage < 18) return MeasurementStatus.fitness;
      if (bodyFatPercentage < 25) return MeasurementStatus.normal;
      if (bodyFatPercentage < 32) return MeasurementStatus.overweight;
    } else if (gender == 2) {
      // Female
      if (bodyFatPercentage < 16) return MeasurementStatus.essentialFat;
      if (bodyFatPercentage < 20) return MeasurementStatus.athletes;
      if (bodyFatPercentage < 24) return MeasurementStatus.fitness;
      if (bodyFatPercentage < 31) return MeasurementStatus.normal;
      if (bodyFatPercentage < 39) return MeasurementStatus.overweight;
    }
    return MeasurementStatus.obese;
  }

  MeasurementStatus getBMIStatus(double value) {
    if (value < 18.5) return MeasurementStatus.underweight;
    if (value < 25) return MeasurementStatus.normal;
    if (value < 30) return MeasurementStatus.overweight;
    return MeasurementStatus.obese;
  }

  MeasurementStatus getBodyFatStatus(double value) {
    if (value < 10) return MeasurementStatus.veryLow;
    if (value < 20) return MeasurementStatus.fitness;
    if (value < 25) return MeasurementStatus.normal;
    if (value < 30) return MeasurementStatus.overweight;
    return MeasurementStatus.obese;
  }

  MeasurementStatus getWaistStatus(double value) {
    if (value < 80) return MeasurementStatus.optimal;
    if (value < 88) return MeasurementStatus.normal;
    return MeasurementStatus.high;
  }
}

// Providers
final measurementControllerProvider =
    StateNotifierProvider.family<MeasurementController, AsyncValue<List<MeasurementModel>>, String>(
      (ref, userId) => MeasurementController(ref.watch(measurementsServiceProvider), userId),
    );

final selectedMeasurementsProvider = StateProvider<List<MeasurementModel>>((ref) => []);
