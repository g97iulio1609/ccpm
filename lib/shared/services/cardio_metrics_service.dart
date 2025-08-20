class CardioMetricsService {
  const CardioMetricsService();

  // HRmax using Tanaka et al. (2001): 208 − 0.7 × age
  double hrMaxTanaka(int ageYears) => 208 - 0.7 * ageYears;

  int bpmFromPercent({required double hrPercent, required double hrMax}) {
    if (hrPercent.isNaN) return 0;
    final v = (hrMax * (hrPercent / 100)).round();
    return v < 0 ? 0 : v;
  }

  double percentFromBpm({required int hrBpm, required double hrMax}) {
    if (hrMax <= 0) return 0;
    final v = (hrBpm / hrMax) * 100;
    return v.isNaN ? 0 : v;
  }

  // Pace [sec/km] ↔ speed [km/h]
  double speedFromPaceSecPerKm(int paceSecPerKm) {
    if (paceSecPerKm <= 0) return 0;
    return 3600 / paceSecPerKm;
  }

  int paceSecPerKmFromSpeed(double speedKmh) {
    if (speedKmh <= 0) return 0;
    return (3600 / speedKmh).round();
  }

  // Derive one of (duration, distance) given the other and pace/speed
  int? deriveDurationSeconds({int? distanceMeters, int? paceSecPerKm, double? speedKmh}) {
    if ((distanceMeters ?? 0) <= 0) return null;
    if (paceSecPerKm != null && paceSecPerKm > 0) {
      final km = (distanceMeters! / 1000);
      return (km * paceSecPerKm).round();
    }
    if (speedKmh != null && speedKmh > 0) {
      final hours = (distanceMeters! / 1000) / speedKmh;
      return (hours * 3600).round();
    }
    return null;
  }

  int? deriveDistanceMeters({int? durationSeconds, int? paceSecPerKm, double? speedKmh}) {
    if ((durationSeconds ?? 0) <= 0) return null;
    if (paceSecPerKm != null && paceSecPerKm > 0) {
      final km = durationSeconds! / paceSecPerKm;
      return (km * 1000).round();
    }
    if (speedKmh != null && speedKmh > 0) {
      final km = (durationSeconds! / 3600) * speedKmh;
      return (km * 1000).round();
    }
    return null;
  }
}
