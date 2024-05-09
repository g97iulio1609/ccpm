import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../users_services.dart';

final macrosProvider = StateNotifierProvider<MacrosNotifier, Map<String, double>>((ref) {
  return MacrosNotifier();
});

class MacrosNotifier extends StateNotifier<Map<String, double>> {
  MacrosNotifier() : super({'carbs': 50, 'protein': 25, 'fat': 25});

  void updateMacros(String macro, double value) {
    final newMacros = {...state};
    final availablePercentage = 100 - value;
    final remainingMacros = ['carbs', 'protein', 'fat'].where((m) => m != macro).toList();
    final currentPercentage = newMacros[remainingMacros[0]]! + newMacros[remainingMacros[1]]!;
    final ratio = availablePercentage / currentPercentage;

    newMacros[macro] = value;
    newMacros[remainingMacros[0]] = (newMacros[remainingMacros[0]]! * ratio).roundToDouble();
    newMacros[remainingMacros[1]] = (newMacros[remainingMacros[1]]! * ratio).roundToDouble();

    state = newMacros;
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

  @override
  void initState() {
    super.initState();
    _loadTDEEData();
  }

  void _loadTDEEData() async {
    final usersService = ref.read(usersServiceProvider);
    final tdeeData = await usersService.getTDEEData(widget.userId);

    if (tdeeData != null) {
      setState(() {
        _tdee = tdeeData['tdee'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final macros = ref.watch(macrosProvider);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
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
          const SizedBox(height: 16),
          _buildMacroSlider(
            context,
            ref,
            'Carbohydrates',
            macros['carbs']!,
            (value) => ref.read(macrosProvider.notifier).updateMacros('carbs', value),
          ),
          _buildMacroSlider(
            context,
            ref,
            'Protein',
            macros['protein']!,
            (value) => ref.read(macrosProvider.notifier).updateMacros('protein', value),
          ),
          _buildMacroSlider(
            context,
            ref,
            'Fat',
            macros['fat']!,
            (value) => ref.read(macrosProvider.notifier).updateMacros('fat', value),
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
          _buildMacroDisplay(context, 'Carbohydrates', macros['carbs']! / 100 * _tdee),
          _buildMacroDisplay(context, 'Protein', macros['protein']! / 100 * _tdee),
          _buildMacroDisplay(context, 'Fat', macros['fat']! / 100 * _tdee),
        ],
      ),
    );
  }

  Widget _buildMacroSlider(
    BuildContext context,
    WidgetRef ref,
    String macroName,
    double macroValue,
    ValueChanged<double> onChanged,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$macroName: ${macroValue.toStringAsFixed(0)}%',
          style: textTheme.titleMedium,
        ),
        Slider(
          value: macroValue,
          min: 0,
          max: 100,
          divisions: 100,
          label: '${macroValue.toStringAsFixed(0)}%',
          onChanged: (value) {
            onChanged(value);
          },
        ),
      ],
    );
  }

  Widget _buildMacroDisplay(BuildContext context, String macroName, double macroValue) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            macroName,
            style: textTheme.titleMedium,
          ),
          Text(
            '${macroValue.toStringAsFixed(0)} kcal',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}