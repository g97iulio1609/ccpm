class ExerciseStats {
  final double volume;
  final int numberOfLifts;
  final double averageIntensity;
  final double maxWeight;
  final DateTime lastPerformed;

  const ExerciseStats({
    required this.volume,
    required this.numberOfLifts,
    required this.averageIntensity,
    required this.maxWeight,
    required this.lastPerformed,
  });

  ExerciseStats copyWith({
    double? volume,
    int? numberOfLifts,
    double? averageIntensity,
    double? maxWeight,
    DateTime? lastPerformed,
  }) {
    return ExerciseStats(
      volume: volume ?? this.volume,
      numberOfLifts: numberOfLifts ?? this.numberOfLifts,
      averageIntensity: averageIntensity ?? this.averageIntensity,
      maxWeight: maxWeight ?? this.maxWeight,
      lastPerformed: lastPerformed ?? this.lastPerformed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExerciseStats &&
        other.volume == volume &&
        other.numberOfLifts == numberOfLifts &&
        other.averageIntensity == averageIntensity &&
        other.maxWeight == maxWeight &&
        other.lastPerformed == lastPerformed;
  }

  @override
  int get hashCode {
    return volume.hashCode ^
        numberOfLifts.hashCode ^
        averageIntensity.hashCode ^
        maxWeight.hashCode ^
        lastPerformed.hashCode;
  }

  @override
  String toString() {
    return 'ExerciseStats(volume: $volume, numberOfLifts: $numberOfLifts, averageIntensity: $averageIntensity, maxWeight: $maxWeight, lastPerformed: $lastPerformed)';
  }
}
