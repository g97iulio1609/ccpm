import 'package:alphanessone/UI/components/badge.dart';
import 'package:alphanessone/UI/components/button.dart';
import 'package:alphanessone/UI/components/card.dart';
import 'package:alphanessone/UI/components/checkbox.dart';
import 'package:alphanessone/UI/components/column.dart';
import 'package:alphanessone/UI/components/input.dart';
import 'package:alphanessone/UI/components/radio_select.dart';
import 'package:alphanessone/UI/components/slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show min;

import '../../Main/app_theme.dart';
import '../../UI/components/spinner.dart';

// Domain Models
class UserData {
  final double tdee;
  final double weight;

  UserData({required this.tdee, required this.weight});

  UserData copyWith({double? tdee, double? weight}) {
    return UserData(
      tdee: tdee ?? this.tdee,
      weight: weight ?? this.weight,
    );
  }
}

class MacroData {
  final double carbs;
  final double protein;
  final double fat;

  MacroData({required this.carbs, required this.protein, required this.fat});

  MacroData copyWith({double? carbs, double? protein, double? fat}) {
    return MacroData(
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
    );
  }

  Map<String, double> toMap() {
    return {'carbs': carbs, 'protein': protein, 'fat': fat};
  }

  factory MacroData.fromMap(Map<String, dynamic> map) {
    return MacroData(
      carbs: map['carbs']?.toDouble() ?? 0,
      protein: map['protein']?.toDouble() ?? 0,
      fat: map['fat']?.toDouble() ?? 0,
    );
  }
}

// Enums
enum MacroUpdateType { percentage, gramsPerKg, grams }

// Providers
final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData>(
    (ref) => UserDataNotifier());

final macrosProvider = StateNotifierProvider<MacrosNotifier, MacroData>(
    (ref) => MacrosNotifier(ref));

// Notifiers
class UserDataNotifier extends StateNotifier<UserData> {
  UserDataNotifier() : super(UserData(tdee: 0, weight: 0));

  void updateUserData({double? tdee, double? weight}) {
    state = state.copyWith(tdee: tdee, weight: weight);
  }
}

class MacrosNotifier extends StateNotifier<MacroData> {
  final Ref ref;

  MacrosNotifier(this.ref) : super(MacroData(carbs: 0, protein: 0, fat: 0));

  void updateMacros(MacroData newMacros) {
    state = newMacros;
    final userData = ref.read(userDataProvider);
    _saveMacrosToFirebase({
      'carbs': double.parse(newMacros.carbs.toStringAsFixed(2)),
      'protein': double.parse(newMacros.protein.toStringAsFixed(2)),
      'fat': double.parse(newMacros.fat.toStringAsFixed(2)),
      'tdee': userData.tdee,
    });
  }

  Future<void> _saveMacrosToFirebase(Map<String, dynamic> data) async {
    try {
      final tdeeService = ref.read(tdeeServiceProvider);
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Assicurati che i valori siano double
        final sanitizedData = {
          'carbs': (data['carbs'] as num).toDouble(),
          'protein': (data['protein'] as num).toDouble(),
          'fat': (data['fat'] as num).toDouble(),
          'tdee': (data['tdee'] as num).toDouble(),
        };
        await tdeeService.saveNutritionData(userId, sanitizedData);
      }
    } catch (e) {
      debugPrint('Error saving macros to Firebase: $e');
    }
  }
}

// Utilities
class MacrosCalculator {
  static const double carbsCaloriesPerGram = 4;
  static const double proteinCaloriesPerGram = 4;
  static const double fatCaloriesPerGram = 9;

  static MacroData calculateMacrosFromPercentages(
      double tdee, MacroData percentages) {
    double carbsCalories = tdee * percentages.carbs / 100;
    double proteinCalories = tdee * percentages.protein / 100;
    double fatCalories = tdee * percentages.fat / 100;

    return MacroData(
      carbs: carbsCalories / carbsCaloriesPerGram,
      protein: proteinCalories / proteinCaloriesPerGram,
      fat: fatCalories / fatCaloriesPerGram,
    );
  }

  static MacroData calculateMacrosFromGramsPerKg(
      double weight, MacroData gramsPerKg) {
    return MacroData(
      carbs: gramsPerKg.carbs * weight,
      protein: gramsPerKg.protein * weight,
      fat: gramsPerKg.fat * weight,
    );
  }

  static double calculateTotalCalories(MacroData macros) {
    return macros.carbs * carbsCaloriesPerGram +
        macros.protein * proteinCaloriesPerGram +
        macros.fat * fatCaloriesPerGram;
  }
}

// UI Components
class MacrosSelector extends ConsumerStatefulWidget {
  final String userId;

  const MacrosSelector({super.key, required this.userId});

  @override
  MacrosSelectorState createState() => MacrosSelectorState();
}

class MacrosSelectorState extends ConsumerState<MacrosSelector> {
  late MacroData _tempMacros;
  late MacroData _tempMacrosPercentages;
  MacroUpdateType _currentUpdateType = MacroUpdateType.grams;
  bool _autoAdjustMacros = true;
  bool _isLoading = true;

  final Map<String, Map<MacroUpdateType, TextEditingController>> _controllers =
      {
    'carbs': {},
    'protein': {},
    'fat': {},
  };

  @override
  void initState() {
    super.initState();
    _tempMacros = MacroData(carbs: 0, protein: 0, fat: 0);
    _tempMacrosPercentages = MacroData(carbs: 0, protein: 0, fat: 0);
    _initializeControllers();
    _loadUserData();
  }

  void _initializeControllers() {
    for (var macro in ['carbs', 'protein', 'fat']) {
      for (var type in MacroUpdateType.values) {
        _controllers[macro]![type] = TextEditingController(text: '0.00');
      }
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    debugPrint('_loadUserData chiamato');

    try {
      ref.read(tdeeServiceProvider);
      final measurementsService = ref.read(measurementsServiceProvider);
      final nutritionData = await _getMostRecentNutritionData(widget.userId);
      debugPrint('nutritionData $nutritionData');

      final measurements = await measurementsService
          .getMeasurements(userId: widget.userId)
          .first;
      final mostRecentWeight =
          measurements.isNotEmpty ? measurements.first.weight : 0.0;

      if (nutritionData != null) {
        debugPrint('nutritionData non è null');
        ref.read(userDataProvider.notifier).updateUserData(
              tdee: nutritionData['tdee']?.toDouble() ?? 0.0,
              weight: mostRecentWeight,
            );

        final macroData = MacroData(
          carbs: nutritionData['carbs']?.toDouble() ?? 0.0,
          protein: nutritionData['protein']?.toDouble() ?? 0.0,
          fat: nutritionData['fat']?.toDouble() ?? 0.0,
        );

        debugPrint('MacroData creato: ${macroData.toMap()}');

        if (!mounted) return;

        setState(() {
          _tempMacros = macroData;
          _tempMacrosPercentages = _calculatePercentagesFromGrams(macroData);
          _isLoading = false;
        });

        ref.read(macrosProvider.notifier).updateMacros(macroData);
        _updateInputFields();
      } else {
        debugPrint('Nessun dato di nutrizione trovato per l\'utente.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Errore durante il caricamento dei dati: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _getMostRecentNutritionData(
      String userId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('mynutrition')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
  }

  MacroData _calculatePercentagesFromGrams(MacroData macrosGrams) {
    try {
      double totalCalories =
          MacrosCalculator.calculateTotalCalories(macrosGrams);
      if (totalCalories <= 0) return MacroData(carbs: 0, protein: 0, fat: 0);

      return MacroData(
        carbs: ((macrosGrams.carbs *
                    MacrosCalculator.carbsCaloriesPerGram /
                    totalCalories *
                    100)
                .clamp(0.0, 100.0))
            .roundToDouble(),
        protein: ((macrosGrams.protein *
                    MacrosCalculator.proteinCaloriesPerGram /
                    totalCalories *
                    100)
                .clamp(0.0, 100.0))
            .roundToDouble(),
        fat: ((macrosGrams.fat *
                    MacrosCalculator.fatCaloriesPerGram /
                    totalCalories *
                    100)
                .clamp(0.0, 100.0))
            .roundToDouble(),
      );
    } catch (e) {
      debugPrint('Error in _calculatePercentagesFromGrams: $e');
      return MacroData(carbs: 0, protein: 0, fat: 0);
    }
  }

  void _updateInputFields() {
    debugPrint('_updateInputFields chiamato');
    final userData = ref.read(userDataProvider);

    void updateController(String macro, MacroUpdateType type, double value) {
      _controllers[macro]![type]?.text = value.toStringAsFixed(2);
      debugPrint(
          'Controller aggiornato - Macro: $macro, Tipo: $type, Valore: ${value.toStringAsFixed(2)}');
    }

    for (var macro in ['carbs', 'protein', 'fat']) {
      updateController(
          macro, MacroUpdateType.grams, _getMacroValue(_tempMacros, macro));
      updateController(macro, MacroUpdateType.percentage,
          _getMacroValue(_tempMacrosPercentages, macro));
      if (userData.weight > 0) {
        updateController(macro, MacroUpdateType.gramsPerKg,
            _getMacroValue(_tempMacros, macro) / userData.weight);
      }
    }

    setState(() {});
    debugPrint('_updateInputFields completato');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: AppSpinner());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            title: 'Macro Distribution',
            subtitle: 'Daily macronutrient breakdown',
            leadingIcon: Icons.pie_chart,
            child: Column(
              children: [
                SizedBox(height: AppTheme.spacing.lg),
                _buildMacroChart(_tempMacros),
                SizedBox(height: AppTheme.spacing.xl),
                _buildTotalCaloriesInfo(colorScheme),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacing.xl),
          AppCard(
            title: 'Macro Settings',
            subtitle: 'Adjust your macronutrient ratios',
            leadingIcon: Icons.tune,
            child: Column(
              children: [
                SizedBox(height: AppTheme.spacing.lg),
                _buildUpdateTypeSelector(),
                SizedBox(height: AppTheme.spacing.xl),
                _buildMacroInputs(_tempMacros, ref.watch(userDataProvider)),
                SizedBox(height: AppTheme.spacing.lg),
                _buildAutoAdjustSwitch(),
                SizedBox(height: AppTheme.spacing.lg),
                AppButton(
                  label: 'Applica',
                  onPressed: _applyChanges,
                  icon: Icons.check,
                  size: AppButtonSize.full,
                  variant: AppButtonVariant.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCaloriesInfo(ColorScheme colorScheme) {
    final totalCalories = MacrosCalculator.calculateTotalCalories(_tempMacros);

    return AppColumn(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppBadge(
          label: 'Daily Total',
          icon: Icons.local_fire_department,
          variant: AppBadgeVariant.gradient,
          status: AppBadgeStatus.primary,
        ),
        SizedBox(height: AppTheme.spacing.sm),
        Text(
          '${totalCalories.toStringAsFixed(0)} kcal',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateTypeSelector() {
    return AppRadioSelect<MacroUpdateType>(
      label: 'Input Type',
      options: MacroUpdateType.values,
      value: _currentUpdateType,
      getLabel: (type) => switch (type) {
        MacroUpdateType.grams => 'Grams',
        MacroUpdateType.gramsPerKg => 'g/kg',
        MacroUpdateType.percentage => 'Percentage',
      },
      getIcon: (type) => switch (type) {
        MacroUpdateType.grams => Icons.scale,
        MacroUpdateType.gramsPerKg => Icons.monitor_weight,
        MacroUpdateType.percentage => Icons.percent,
      },
      onChanged: (type) {
        if (type != null) {
          setState(() {
            _currentUpdateType = type;
            _updateInputFields();
          });
        }
      },
    );
  }

  Widget _buildMacroInputs(MacroData macros, UserData userData) {
    return Column(
      children: ['carbs', 'protein', 'fat'].map((macro) {
        final value = _getDisplayValue(macro, userData);
        final calories = _getCalories(macro, macros);
        final percentage = userData.tdee > 0
            ? (calories / userData.tdee * 100).clamp(0, 100)
            : 0.0;
        final maxValue = _getSliderMax(
            macro, userData, MacrosCalculator.calculateTotalCalories(macros));

        return AppColumn(
          title: macro.capitalize(),
          leading: Container(
            padding: EdgeInsets.all(AppTheme.spacing.sm),
            decoration: BoxDecoration(
              color: _getMacroColor(macro).withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radii.md),
            ),
            child: Icon(
              _getMacroIcon(macro),
              color: _getMacroColor(macro),
              size: 20,
            ),
          ),
          children: [
            Row(
              children: [
                Expanded(
                  flex: 7,
                  child: AppSlider(
                    label: '',
                    value: value.clamp(0, maxValue),
                    min: 0,
                    max: maxValue,
                    onChanged: (newValue) =>
                        _updateMacro(macro, newValue, userData),
                    activeColor: _getMacroColor(macro),
                  ),
                ),
                SizedBox(width: AppTheme.spacing.md),
                Expanded(
                  flex: 3,
                  child: AppInput(
                    controller: _controllers[macro]![_currentUpdateType]!,
                    label: '',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    suffixText: _getSuffixText(),
                    onChanged: (value) =>
                        _handleTextFieldChange(macro, value, userData),
                  ),
                ),
              ],
            ),
            Text(
              '${calories.toStringAsFixed(0)} kcal (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(color: _getMacroColor(macro)),
            ),
          ],
        );
      }).toList(),
    );
  }

  IconData _getMacroIcon(String macro) {
    switch (macro) {
      case 'carbs':
        return Icons.grain;
      case 'protein':
        return Icons.egg_alt;
      case 'fat':
        return Icons.water_drop;
      default:
        return Icons.circle;
    }
  }

  Widget _buildAutoAdjustSwitch() {
    return AppCheckbox(
      value: _autoAdjustMacros,
      onChanged: (value) {
        setState(() {
          _autoAdjustMacros = value ?? false;
        });
      },
      label: 'Auto Adjust Macros',
      helperText:
          'Automatically adjust macros to match your daily calorie target',
      icon: Icons.auto_fix_high,
    );
  }

  Widget _buildMacroChart(MacroData macros) {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: Colors.orange,
                  value: macros.carbs,
                  title: '${macros.carbs.toStringAsFixed(1)}g',
                  radius: 100,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.blue,
                  value: macros.protein,
                  title: '${macros.protein.toStringAsFixed(1)}g',
                  radius: 100,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.green,
                  value: macros.fat,
                  title: '${macros.fat.toStringAsFixed(1)}g',
                  radius: 100,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 50,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  '${MacrosCalculator.calculateTotalCalories(macros).toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getDisplayValue(String macro, UserData userData) {
    switch (_currentUpdateType) {
      case MacroUpdateType.grams:
        return _getMacroValue(_tempMacros, macro);
      case MacroUpdateType.gramsPerKg:
        return userData.weight > 0
            ? _getMacroValue(_tempMacros, macro) / userData.weight
            : 0.0;
      case MacroUpdateType.percentage:
        return _getMacroValue(_tempMacrosPercentages, macro);
    }
  }

  void _updateMacro(String macro, double value, UserData userData) {
    try {
      setState(() {
        switch (_currentUpdateType) {
          case MacroUpdateType.grams:
            _tempMacros = _setMacroValue(_tempMacros, macro, value.abs());
            _tempMacrosPercentages =
                _calculatePercentagesFromGrams(_tempMacros);
            break;
          case MacroUpdateType.gramsPerKg:
            if (userData.weight > 0) {
              _tempMacros = _setMacroValue(
                  _tempMacros, macro, (value * userData.weight).abs());
              _tempMacrosPercentages =
                  _calculatePercentagesFromGrams(_tempMacros);
            }
            break;
          case MacroUpdateType.percentage:
            _tempMacrosPercentages = _setMacroValue(
                _tempMacrosPercentages, macro, value.clamp(0.0, 100.0));
            _tempMacros = MacrosCalculator.calculateMacrosFromPercentages(
                userData.tdee, _tempMacrosPercentages);
            break;
        }

        _updateInputFields();
      });
    } catch (e) {
      debugPrint('Error in _updateMacro: $e');
    }
  }

  void _applyChanges() async {
    final userData = ref.read(userDataProvider);
    MacroData finalMacros;

    if (_currentUpdateType == MacroUpdateType.percentage) {
      if (_autoAdjustMacros) {
        _tempMacrosPercentages =
            _adjustMacroPercentages(_tempMacrosPercentages);
      }
      finalMacros = MacrosCalculator.calculateMacrosFromPercentages(
          userData.tdee, _tempMacrosPercentages);
    } else if (_currentUpdateType == MacroUpdateType.gramsPerKg) {
      finalMacros = _tempMacros;
      if (_autoAdjustMacros) {
        finalMacros = _adjustMacros(finalMacros, userData.tdee);
      }
    } else {
      if (_autoAdjustMacros) {
        finalMacros = _adjustMacros(_tempMacros, userData.tdee);
      } else {
        finalMacros = _tempMacros;
      }
    }

    finalMacros = MacroData(
      carbs: double.parse(finalMacros.carbs.toStringAsFixed(2)),
      protein: double.parse(finalMacros.protein.toStringAsFixed(2)),
      fat: double.parse(finalMacros.fat.toStringAsFixed(2)),
    );

    setState(() {
      _tempMacros = finalMacros;
      _tempMacrosPercentages = _calculatePercentagesFromGrams(finalMacros);
    });

    ref.read(macrosProvider.notifier).updateMacros(finalMacros);

    _updateInputFields();

    // Save data to Firestore
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final firestore = FirebaseFirestore.instance;
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        final querySnapshot = await firestore
            .collection('users')
            .doc(userId)
            .collection('mynutrition')
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
            .orderBy('date', descending: true)
            .limit(1)
            .get();

        final nutritionData = {
          'carbs': finalMacros.carbs,
          'protein': finalMacros.protein,
          'fat': finalMacros.fat,
          'tdee': userData.tdee,
          'weight': userData.weight,
          'date': Timestamp.now(),
        };

        if (querySnapshot.docs.isNotEmpty) {
          // Update existing document
          await firestore
              .collection('users')
              .doc(userId)
              .collection('mynutrition')
              .doc(querySnapshot.docs.first.id)
              .update(nutritionData);
        } else {
          // Create new document
          await firestore
              .collection('users')
              .doc(userId)
              .collection('mynutrition')
              .add(nutritionData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_autoAdjustMacros
                  ? 'Macros auto-adjusted, applied, and saved'
                  : 'Changes applied and saved'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving nutrition data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving data. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  MacroData _adjustMacroPercentages(MacroData percentages) {
    double total = percentages.carbs + percentages.protein + percentages.fat;
    if (total.roundToDouble() == 100) {
      return percentages;
    }

    double factor = 100 / total;
    return MacroData(
      carbs: percentages.carbs * factor,
      protein: percentages.protein * factor,
      fat: percentages.fat * factor,
    );
  }

  MacroData _adjustMacros(MacroData macros, double tdee) {
    final totalCalories = MacrosCalculator.calculateTotalCalories(macros);
    final remainingCalories = tdee - totalCalories;

    if (remainingCalories.abs() < 1) {
      return macros;
    }

    double totalCarbsCalories =
        macros.carbs * MacrosCalculator.carbsCaloriesPerGram;
    double totalProteinCalories =
        macros.protein * MacrosCalculator.proteinCaloriesPerGram;
    double totalFatCalories = macros.fat * MacrosCalculator.fatCaloriesPerGram;

    double carbsRatio = totalCarbsCalories / totalCalories;
    double proteinRatio = totalProteinCalories / totalCalories;
    double fatRatio = totalFatCalories / totalCalories;

    double newCarbsCalories =
        totalCarbsCalories + remainingCalories * carbsRatio;
    double newProteinCalories =
        totalProteinCalories + remainingCalories * proteinRatio;
    double newFatCalories = totalFatCalories + remainingCalories * fatRatio;

    double newCarbs = (newCarbsCalories / MacrosCalculator.carbsCaloriesPerGram)
        .clamp(0, double.infinity);
    double newProtein =
        (newProteinCalories / MacrosCalculator.proteinCaloriesPerGram)
            .clamp(0, double.infinity);
    double newFat = (newFatCalories / MacrosCalculator.fatCaloriesPerGram)
        .clamp(0, double.infinity);

    return MacroData(carbs: newCarbs, protein: newProtein, fat: newFat);
  }

  double _getSliderMax(String macro, UserData userData, double totalCalories) {
    double remainingCalories =
        userData.tdee - totalCalories + _getCalories(macro, _tempMacros);
    double maxForMacro = _calculateGramsFromCalories(macro, remainingCalories);

    switch (_currentUpdateType) {
      case MacroUpdateType.grams:
        return maxForMacro;
      case MacroUpdateType.gramsPerKg:
        return userData.weight > 0 ? maxForMacro / userData.weight : 10.0;
      case MacroUpdateType.percentage:
        return 100.0;
    }
  }

  String _getSuffixText() {
    switch (_currentUpdateType) {
      case MacroUpdateType.grams:
        return 'g';
      case MacroUpdateType.gramsPerKg:
        return 'g/kg';
      case MacroUpdateType.percentage:
        return '%';
    }
  }

  Color _getMacroColor(String macroName) {
    switch (macroName) {
      case 'carbs':
        return Colors.orange;
      case 'protein':
        return Colors.blue;
      case 'fat':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _handleTextFieldChange(String macro, String value, UserData userData) {
    try {
      // Mantieni la posizione del cursore
      final cursorPosition =
          _controllers[macro]![_currentUpdateType]!.selection.base.offset;

      // Pulisci l'input mantenendo solo numeri e punto decimale
      String cleanedValue = value.replaceAll(RegExp(r'[^0-9.]'), '');

      // Gestisci correttamente i decimali
      final parts = cleanedValue.split('.');
      if (parts.length > 2) {
        cleanedValue = '${parts[0]}.${parts.sublist(1).join('')}';
      }

      // Converti in double con gestione degli errori
      double? newValue;
      if (cleanedValue.isNotEmpty) {
        newValue = double.tryParse(cleanedValue);
      }

      // Aggiorna solo se il valore è valido
      if (newValue != null) {
        _updateMacro(macro, newValue, userData);
      }

      // Aggiorna il controller mantenendo la posizione del cursore
      _controllers[macro]![_currentUpdateType]!.value = TextEditingValue(
        text: cleanedValue,
        selection: TextSelection.collapsed(
          offset: min(cursorPosition ?? 0, cleanedValue.length),
        ),
      );
    } catch (e) {
      debugPrint('Error in _handleTextFieldChange: $e');
    }
  }

  double _getMacroValue(MacroData macros, String macro) {
    switch (macro) {
      case 'carbs':
        return macros.carbs;
      case 'protein':
        return macros.protein;
      case 'fat':
        return macros.fat;
      default:
        throw ArgumentError('Invalid macro: $macro');
    }
  }

  MacroData _setMacroValue(MacroData macros, String macro, double value) {
    switch (macro) {
      case 'carbs':
        return macros.copyWith(carbs: value);
      case 'protein':
        return macros.copyWith(protein: value);
      case 'fat':
        return macros.copyWith(fat: value);
      default:
        throw ArgumentError('Invalid macro: $macro');
    }
  }

  double _getCalories(String macro, MacroData macros) {
    switch (macro) {
      case 'carbs':
        return macros.carbs * MacrosCalculator.carbsCaloriesPerGram;
      case 'protein':
        return macros.protein * MacrosCalculator.proteinCaloriesPerGram;
      case 'fat':
        return macros.fat * MacrosCalculator.fatCaloriesPerGram;
      default:
        throw ArgumentError('Invalid macro: $macro');
    }
  }

  double _calculateGramsFromCalories(String macro, double calories) {
    switch (macro) {
      case 'carbs':
        return calories / MacrosCalculator.carbsCaloriesPerGram;
      case 'protein':
        return calories / MacrosCalculator.proteinCaloriesPerGram;
      case 'fat':
        return calories / MacrosCalculator.fatCaloriesPerGram;
      default:
        throw ArgumentError('Invalid macro: $macro');
    }
  }

  @override
  void dispose() {
    for (var controllerMap in _controllers.values) {
      for (var controller in controllerMap.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
