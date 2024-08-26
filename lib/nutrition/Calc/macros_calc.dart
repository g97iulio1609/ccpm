class MacrosCalculator {
  static const double carbsCaloriesPerGram = 4;
  static const double proteinCaloriesPerGram = 4;
  static const double fatCaloriesPerGram = 9;

  static Map<String, double> calculateMacrosFromPercentages(
      double tdee, Map<String, double> macroPercentages) {
    final macros = <String, double>{};
    final totalPercentage = macroPercentages.values.fold(0.0, (sum, percentage) => sum + percentage);

    if (totalPercentage != 100) {
      final unsetMacros = ['carbs', 'protein', 'fat']
          .where((macro) => !macroPercentages.containsKey(macro))
          .toList();

      if (unsetMacros.isNotEmpty) {
        final distributedPercentage = (100 - totalPercentage) / unsetMacros.length;
        for (final macro in unsetMacros) {
          macroPercentages[macro] = distributedPercentage;
        }
      } else {
        final factor = 100 / totalPercentage;
        for (final macro in macroPercentages.keys) {
          macroPercentages[macro] = macroPercentages[macro]! * factor;
        }
      }
    }

    for (final macro in macroPercentages.keys) {
      final percentage = macroPercentages[macro]!;
      final calories = tdee * percentage / 100;
      final grams = calculateGramsFromCalories(macro, calories);
      macros[macro] = grams;
    }

    return macros;
  }

  static Map<String, double> calculateMacrosFromGramsPerKg(
      double tdee, double weight, Map<String, double> macroGramsPerKg) {
    final macros = <String, double>{};
    final macroPercentages = <String, double>{};

    for (final macro in macroGramsPerKg.keys) {
      final gramsPerKg = macroGramsPerKg[macro]!;
      final grams = gramsPerKg * weight;
      final calories = calculateCaloriesFromGrams(macro, grams);
      final percentage = calories / tdee * 100;
      macros[macro] = grams;
      macroPercentages[macro] = percentage;
    }

    _adjustMacroPercentages(macroPercentages);

    // Recalculate grams based on adjusted percentages
    for (final macro in macroPercentages.keys) {
      final adjustedCalories = tdee * macroPercentages[macro]! / 100;
      macros[macro] = calculateGramsFromCalories(macro, adjustedCalories);
    }

    return macros;
  }

  static Map<String, double> calculatePercentagesFromGrams(
      double tdee, Map<String, double> macroGrams) {
    final macroPercentages = <String, double>{};

    for (final macro in macroGrams.keys) {
      final grams = macroGrams[macro]!;
      final calories = calculateCaloriesFromGrams(macro, grams);
      final percentage = calories / tdee * 100;
      macroPercentages[macro] = percentage;
    }

    _adjustMacroPercentages(macroPercentages);

    return macroPercentages;
  }

  static Map<String, double> calculatePercentagesFromGramsPerKg(
      double tdee, double weight, Map<String, double> macroGramsPerKg) {
    final macroGrams = <String, double>{};

    for (final macro in macroGramsPerKg.keys) {
      final gramsPerKg = macroGramsPerKg[macro]!;
      final grams = gramsPerKg * weight;
      macroGrams[macro] = grams;
    }

    return calculatePercentagesFromGrams(tdee, macroGrams);
  }

  static Map<String, double> calculateMacrosFromGrams(
      double tdee, Map<String, double> macroGrams) {
    final macros = <String, double>{};
    final macroPercentages = <String, double>{};

    for (final macro in macroGrams.keys) {
      final grams = macroGrams[macro]!;
      final calories = calculateCaloriesFromGrams(macro, grams);
      final percentage = calories / tdee * 100;
      macros[macro] = grams;
      macroPercentages[macro] = percentage;
    }

    _adjustMacroPercentages(macroPercentages);

    return macros;
  }

  static double calculateGramsFromCalories(String macro, double calories) {
    switch (macro) {
      case 'carbs':
        return calories / carbsCaloriesPerGram;
      case 'protein':
        return calories / proteinCaloriesPerGram;
      case 'fat':
        return calories / fatCaloriesPerGram;
      default:
        throw ArgumentError('Invalid macro: $macro');
    }
  }

  static double calculateCaloriesFromGrams(String macro, double grams) {
    switch (macro) {
      case 'carbs':
        return grams * carbsCaloriesPerGram;
      case 'protein':
        return grams * proteinCaloriesPerGram;
      case 'fat':
        return grams * fatCaloriesPerGram;
      default:
        throw ArgumentError('Invalid macro: $macro');
    }
  }

  static void _adjustMacroPercentages(Map<String, double> macroPercentages) {
    final totalPercentage = macroPercentages.values.fold(0.0, (sum, percentage) => sum + percentage);

    if (totalPercentage != 100) {
      final unsetMacros = ['carbs', 'protein', 'fat'].where((macro) => !macroPercentages.containsKey(macro)).toList();

      if (unsetMacros.isNotEmpty) {
        final remainingPercentage = 100 - totalPercentage;
        final distributedPercentage = remainingPercentage / unsetMacros.length;

        for (final macro in unsetMacros) {
          macroPercentages[macro] = distributedPercentage;
        }
      } else {
        // Adjust percentages proportionally
        final factor = 100 / totalPercentage;
        for (final macro in macroPercentages.keys) {
          macroPercentages[macro] = macroPercentages[macro]! * factor;
        }
      }
    }
  }

  static double calculateTotalCalories(Map<String, double> macros) {
    double totalCalories = 0;
    macros.forEach((macro, grams) {
      totalCalories += calculateCaloriesFromGrams(macro, grams);
    });
    return totalCalories;
  }
}