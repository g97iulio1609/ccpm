import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'macros_calc.dart';
import '../users_services.dart';

final macrosProvider =
    StateNotifierProvider<MacrosNotifier, Map<String, double>>((ref) {
  return MacrosNotifier();
});

class MacrosNotifier extends StateNotifier<Map<String, double>> {
  MacrosNotifier() : super({'carbs': 0, 'protein': 0, 'fat': 0});

  void updateMacrosFromPercentages(double tdee, Map<String, double> percentages) {
    state = MacrosCalculator.calculateMacrosFromPercentages(tdee, percentages);
  }

  void updateMacrosFromGramsPerKg(double tdee, double weight, Map<String, double> gramsPerKg) {
    state = MacrosCalculator.calculateMacrosFromGramsPerKg(tdee, weight, gramsPerKg);
  }

  void updateMacrosFromGrams(double tdee, Map<String, double> grams) {
    state = MacrosCalculator.calculateMacrosFromGrams(tdee, grams);
  }
}

class MacrosSelector extends ConsumerStatefulWidget {
  final String userId;

  const MacrosSelector({super.key, required this.userId});

  @override
  _MacrosSelectorState createState() => _MacrosSelectorState();
}

class _MacrosSelectorState extends ConsumerState<MacrosSelector> {
  double _tdee = 0.0;
  double _weight = 0.0;

  final _gramsControllers = {
    'carbs': TextEditingController(),
    'protein': TextEditingController(),
    'fat': TextEditingController(),
  };

  final _gramsPerKgControllers = {
    'carbs': TextEditingController(),
    'protein': TextEditingController(),
    'fat': TextEditingController(),
  };

  final _percentageValueNotifiers = {
    'carbs': ValueNotifier<double>(0.0),
    'protein': ValueNotifier<double>(0.0),
    'fat': ValueNotifier<double>(0.0),
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _disposeControllers();
    _disposeValueNotifiers();
    super.dispose();
  }

  void _disposeControllers() {
    for (var controller in _gramsControllers.values) {
      controller.dispose();
    }
    for (var controller in _gramsPerKgControllers.values) {
      controller.dispose();
    }
  }

  void _disposeValueNotifiers() {
    for (var notifier in _percentageValueNotifiers.values) {
      notifier.dispose();
    }
  }

  Future<void> _loadUserData() async {
    final usersService = ref.read(usersServiceProvider);
    final tdeeData = await usersService.getTDEEData(widget.userId);

    if (tdeeData != null) {
      setState(() {
        _tdee = tdeeData['tdee']!;
        _weight = tdeeData['weight']!.toDouble();
      });

      final macroPercentages = {
        'carbs': 50.0,
        'protein': 20.0,
        'fat': 30.0,
      };
      ref.read(macrosProvider.notifier).updateMacrosFromPercentages(_tdee, macroPercentages);
      _updateInputFields();

      final macros = ref.read(macrosProvider);
      for (final macro in macros.keys) {
        final percentage = macros[macro]! / (_tdee / 100);
        _percentageValueNotifiers[macro]?.value = percentage;
      }
    }
  }

  void _updateInputFields() {
    final macros = ref.read(macrosProvider);
    for (final macro in macros.keys) {
      final grams = macros[macro]!;
      final gramsPerKg = grams / _weight;

      _gramsControllers[macro]?.text = grams.toStringAsFixed(2);
      _gramsPerKgControllers[macro]?.text = gramsPerKg.toStringAsFixed(2);
    }
  }

  void _updateMacroPercentages() {
    final macroPercentages = {
      'carbs': _percentageValueNotifiers['carbs']?.value ?? 0,
      'protein': _percentageValueNotifiers['protein']?.value ?? 0,
      'fat': _percentageValueNotifiers['fat']?.value ?? 0,
    };
    final macros = MacrosCalculator.calculateMacrosFromPercentages(_tdee, macroPercentages);
    ref.read(macrosProvider.notifier).state = macros;
    _updateInputFields();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Your Macronutrient Ratio',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildMacroSection(
            context,
            ref,
            'Carbohydrates',
            _gramsControllers['carbs'],
            _gramsPerKgControllers['carbs'],
          ),
          const SizedBox(height: 16),
          _buildMacroSection(
            context,
            ref,
            'Protein',
            _gramsControllers['protein'],
            _gramsPerKgControllers['protein'],
          ),
          const SizedBox(height: 16),
          _buildMacroSection(
            context,
            ref,
            'Fat',
            _gramsControllers['fat'],
            _gramsPerKgControllers['fat'],
          ),
          const SizedBox(height: 32),
          Text(
            'Macronutrient Breakdown',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildMacroBreakdown(context),
        ],
      ),
    );
  }

  Widget _buildMacroSection(
    BuildContext context,
    WidgetRef ref,
    String macroName,
    TextEditingController? gramsController,
    TextEditingController? gramsPerKgController,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final macroKey = macroName.toLowerCase() == 'carbohydrates' ? 'carbs' : macroName.toLowerCase();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              macroName,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<double>(
              valueListenable: _percentageValueNotifiers[macroKey]!,
              builder: (context, value, child) {
                return Slider(
                  value: value,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${value.toStringAsFixed(0)}%',
                  onChanged: (newValue) {
                    _percentageValueNotifiers[macroKey]?.value = newValue;
                    _updateMacroPercentages();
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: gramsController,
                    labelText: 'Grams',
                    hintText: 'Enter grams',
                    onChanged: (value) {
                      final grams = double.tryParse(value) ?? 0.0;
                      final macroGrams = {macroKey: grams};
                      ref.read(macrosProvider.notifier).updateMacrosFromGrams(_tdee, macroGrams);
                      _updateInputFields();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: gramsPerKgController,
                    labelText: 'Grams per kg',
                    hintText: 'Enter grams per kg',
                    onChanged: (value) {
                      final gramsPerKg = double.tryParse(value) ?? 0.0;
                      final macroGramsPerKg = {macroKey: gramsPerKg};
                      ref.read(macrosProvider.notifier).updateMacrosFromGramsPerKg(_tdee, _weight, macroGramsPerKg);
                      _updateInputFields();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController? controller,
    required String labelText,
    required String hintText,
    required ValueChanged<String> onChanged,
    bool isPercentage = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildMacroBreakdown(BuildContext context) {
    final macros = ref.watch(macrosProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: macros.entries.map((entry) {
            final macroName = entry.key;
            final macroValue = entry.value;
            return _buildMacroBreakdownItem(context, macroName, macroValue);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMacroBreakdownItem(BuildContext context, String macroName, double macroValue) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            macroName.capitalize(),
            style: textTheme.titleMedium,
          ),
          Text(
            '${macroValue.toStringAsFixed(0)} g',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}