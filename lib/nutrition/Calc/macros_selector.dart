import 'package:alphanessone/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'macros_calc.dart';

// Provider for user data
final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData>((ref) {
  return UserDataNotifier();
});

// Provider for macros
final macrosProvider = StateNotifierProvider<MacrosNotifier, Map<String, double>>((ref) {
  return MacrosNotifier(ref);
});

// UserData class
class UserData {
  final double tdee;
  final double weight;

  UserData({this.tdee = 0.0, this.weight = 0.0});

  UserData copyWith({double? tdee, double? weight}) {
    return UserData(
      tdee: tdee ?? this.tdee,
      weight: weight ?? this.weight,
    );
  }
}

// UserDataNotifier class
class UserDataNotifier extends StateNotifier<UserData> {
  UserDataNotifier() : super(UserData());

  void updateUserData({double? tdee, double? weight}) {
    state = state.copyWith(tdee: tdee, weight: weight);
  }
}

// MacrosNotifier class
class MacrosNotifier extends StateNotifier<Map<String, double>> {
  final StateNotifierProviderRef<MacrosNotifier, Map<String, double>> ref;

  MacrosNotifier(this.ref) : super({'carbs': 0, 'protein': 0, 'fat': 0});

  void updateMacros(double tdee, double weight, Map<String, double> values, MacroUpdateType type) {
    debugPrint('weight:$weight');
    Map<String, double> newMacros;
    switch (type) {
      case MacroUpdateType.percentage:
        newMacros = MacrosCalculator.calculateMacrosFromPercentages(tdee, values);
        break;
      case MacroUpdateType.gramsPerKg:
        newMacros = MacrosCalculator.calculateMacrosFromGramsPerKg(tdee, weight, values);
        break;
      case MacroUpdateType.grams:
        newMacros = MacrosCalculator.calculateMacrosFromGrams(tdee, values);
        break;
    }
    state = newMacros;
    _saveMacrosToFirebase(newMacros);
  }

  Future<void> _saveMacrosToFirebase(Map<String, double> macros) async {
    final tdeeService = ref.read(tdeeServiceProvider);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await tdeeService.updateMacros(userId, macros);
    }
  }
}

// MacroUpdateType enum
enum MacroUpdateType { percentage, gramsPerKg, grams }

// MacrosSelector widget
class MacrosSelector extends ConsumerStatefulWidget {
  final String userId;

  const MacrosSelector({super.key, required this.userId});

  @override
  MacrosSelectorState createState() => MacrosSelectorState();
}

class MacrosSelectorState extends ConsumerState<MacrosSelector> {
  final Map<String, Map<MacroUpdateType, TextEditingController>> _controllers = {
    'carbs': {},
    'protein': {},
    'fat': {},
  };

  final Map<String, Map<MacroUpdateType, FocusNode>> _focusNodes = {
    'carbs': {},
    'protein': {},
    'fat': {},
  };

  final Map<String, TextEditingController> _calorieControllers = {
    'carbs': TextEditingController(),
    'protein': TextEditingController(),
    'fat': TextEditingController(),
  };

  bool _autoAdjustMacros = true;

  @override
  void initState() {
    super.initState();
    for (var macro in _controllers.keys) {
      for (var type in MacroUpdateType.values) {
        _controllers[macro]![type] = TextEditingController();
        _focusNodes[macro]![type] = FocusNode();
        _focusNodes[macro]![type]!.addListener(() {
          if (!_focusNodes[macro]![type]!.hasFocus) {
            final controller = _controllers[macro]![type]!;
            final value = controller.text;
            if (type == MacroUpdateType.gramsPerKg) {
              if (value.isNotEmpty) {
                final formattedValue = double.parse(value).toStringAsFixed(2);
                controller.text = formattedValue;
              }
            }
          }
        });
      }
    }
    _loadUserData();
  }

  @override
  void dispose() {
    for (var controllerMap in _controllers.values) {
      for (var controller in controllerMap.values) {
        controller.dispose();
      }
    }
    for (var focusNodeMap in _focusNodes.values) {
      for (var focusNode in focusNodeMap.values) {
        focusNode.dispose();
      }
    }
    for (var controller in _calorieControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final tdeeService = ref.read(tdeeServiceProvider);
    final tdeeData = await tdeeService.getTDEEData(widget.userId);
    final userMacros = await tdeeService.getUserMacros(widget.userId);

    if (tdeeData != null) {
      ref.read(userDataProvider.notifier).updateUserData(
        tdee: tdeeData['tdee'] ?? 0.0,
        weight: tdeeData['weight'] ?? 0.0,
      );
      ref.read(macrosProvider.notifier).updateMacros(
        ref.read(userDataProvider).tdee,
        ref.read(userDataProvider).weight,
        userMacros,
        MacroUpdateType.grams,
      );
    }
    _updateInputFields();
  }

  void _updateInputFields() {
    final macros = ref.read(macrosProvider);
    final userData = ref.read(userDataProvider);

    for (final macro in macros.keys) {
      final grams = macros[macro]!;
      final gramsPerKg = userData.weight > 0 ? grams / userData.weight : 0.0;
      final calories = MacrosCalculator.calculateCaloriesFromGrams(macro, grams);
      final percentage = userData.tdee > 0 ? (calories / userData.tdee * 100) : 0.0;

      if (!_focusNodes[macro]![MacroUpdateType.grams]!.hasFocus) {
        _setControllerValue(_controllers[macro]![MacroUpdateType.grams], grams.toStringAsFixed(1));
      }
      if (!_focusNodes[macro]![MacroUpdateType.gramsPerKg]!.hasFocus) {
        _setControllerValue(_controllers[macro]![MacroUpdateType.gramsPerKg], gramsPerKg.toStringAsFixed(2));
      }
      if (!_focusNodes[macro]![MacroUpdateType.percentage]!.hasFocus) {
        _setControllerValue(_controllers[macro]![MacroUpdateType.percentage], percentage.toStringAsFixed(1));
      }
      _setControllerValue(_calorieControllers[macro], calories.toStringAsFixed(1));
    }
  }

  void _setControllerValue(TextEditingController? controller, String value) {
    if (controller != null && controller.text != value) {
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.fromPosition(TextPosition(offset: value.length)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Your Macronutrient Ratio',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildAutoAdjustSwitch(),
          const SizedBox(height: 16),
          ..._controllers.keys.map((macro) => _buildMacroSection(context, macro)),
          const SizedBox(height: 32),
          Text(
            'Macronutrient Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildMacroBreakdown(context),
        ],
      ),
    );
  }

  Widget _buildAutoAdjustSwitch() {
    return SwitchListTile(
      title: const Text('Auto Adjust Macros'),
      value: _autoAdjustMacros,
      onChanged: (value) {
        setState(() {
          _autoAdjustMacros = value;
        });
      },
    );
  }

  Widget _buildMacroSection(BuildContext context, String macroName) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              macroName.capitalize(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._buildMacroInputs(macroName),
            const SizedBox(height: 16),
            _buildCalorieField(macroName),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMacroInputs(String macroName) {
    return MacroUpdateType.values.map((type) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildTextField(
          controller: _controllers[macroName]![type],
          focusNode: _focusNodes[macroName]![type],
          labelText: type.toString().split('.').last.capitalize(),
          hintText: 'Enter ${type.toString().split('.').last}',
          onChanged: (value) => _updateMacro(macroName, type, value),
          type: type,
        ),
      );
    }).toList();
  }

  Widget _buildTextField({
    required TextEditingController? controller,
    required FocusNode? focusNode,
    required String labelText,
    required String hintText,
    required ValueChanged<String> onChanged,
    MacroUpdateType? type,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildCalorieField(String macroName) {
    return TextFormField(
      controller: _calorieControllers[macroName],
      decoration: InputDecoration(
        labelText: '${macroName.capitalize()} Calories',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      readOnly: true,
    );
  }

  void _updateMacro(String macroName, MacroUpdateType type, String value) {
    final numericValue = double.tryParse(value) ?? 0.0;
    final userData = ref.read(userDataProvider);
    final currentMacros = ref.read(macrosProvider);
    
    Map<String, double> updatedMacros = Map.from(currentMacros);

    switch (type) {
      case MacroUpdateType.percentage:
        _updateFromPercentage(macroName, numericValue, updatedMacros);
        break;
      case MacroUpdateType.gramsPerKg:
        updatedMacros[macroName] = numericValue * userData.weight;
        break;
      case MacroUpdateType.grams:
        _updateFromGrams(macroName, numericValue, updatedMacros, userData.tdee);
        break;
    }

    ref.read(macrosProvider.notifier).updateMacros(userData.tdee, userData.weight, updatedMacros, type);
    _updateInputFields();
  }

  void _updateFromPercentage(String macroName, double percentage, Map<String, double> updatedMacros) {
    if (_autoAdjustMacros) {
      updatedMacros[macroName] = percentage;
      final otherMacros = updatedMacros.keys.where((m) => m != macroName).toList();
      final remainingPercentage = 100 - percentage;
      final adjustedValue = remainingPercentage / 2;
      for (var macro in otherMacros) {
        updatedMacros[macro] = adjustedValue;
      }
    } else {
      updatedMacros[macroName] = percentage;
    }
  }

  void _updateFromGrams(String macroName, double grams, Map<String, double> updatedMacros, double tdee) {
    final calories = MacrosCalculator.calculateCaloriesFromGrams(macroName, grams);
    
    if (_autoAdjustMacros) {
      updatedMacros[macroName] = grams;
      final otherMacros = updatedMacros.keys.where((m) => m != macroName).toList();
      final remainingCalories = tdee - calories;
      
      if (remainingCalories <= 0) {
        for (var macro in otherMacros) {
          updatedMacros[macro] = 1;
        }
      } else {
        final caloriesPerMacro = remainingCalories / 2;
        for (var macro in otherMacros) {
          updatedMacros[macro] = MacrosCalculator.calculateGramsFromCalories(macro, caloriesPerMacro);
        }
      }
    } else {
      updatedMacros[macroName] = grams;
    }
  }

  Widget _buildMacroBreakdown(BuildContext context) {
    final macros = ref.watch(macrosProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: macros.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key.capitalize(), style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${entry.value.toStringAsFixed(1)} g',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
