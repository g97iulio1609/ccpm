import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final seriesDialogProvider = ChangeNotifierProvider((ref) => SeriesDialogNotifier());

class SeriesDialogNotifier extends ChangeNotifier {
  double _intensity = 0.0;

  double get intensity => _intensity;

  void updateIntensity(double value) {
    _intensity = value;
    notifyListeners();
  }
}