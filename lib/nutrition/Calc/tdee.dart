import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/providers/providers.dart';

// Constants
const Map<int, String> genderMap = {
  0: 'Altro',
  1: 'Maschio',
  2: 'Femmina',
};

const Map<String, double> activityLevels = {
  'Sedentary': 1.2,
  'Lightly Active': 1.375,
  'Moderately Active': 1.55,
  'Very Active': 1.725,
  'Extremely Active': 1.9,
};

class TDEEScreen extends ConsumerStatefulWidget {
  final String userId;

  const TDEEScreen({super.key, required this.userId});

  @override
  ConsumerState<TDEEScreen> createState() => TDEEScreenState();
}

class TDEEScreenState extends ConsumerState<TDEEScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _birthdate;
  double _height = 0;
  double _weight = 0;
  int _gender = 0;
  double _activityLevel = 1.2;
  int _tdee = 0;

  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _loadTDEEData();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadTDEEData() async {
    try {
      final usersService = ref.read(usersServiceProvider);
      final measurementsService = ref.read(measurementsServiceProvider);
      final tdeeService = ref.read(tdeeServiceProvider);

      // Get user data
      final user = await usersService.getUserById(widget.userId);
      if (user != null) {
        _birthdate = user.birthdate;
        _height = user.height ?? 0;
        _gender = user.gender;
      }

      // Get most recent measurement
      final measurements = await measurementsService.getMeasurements(userId: widget.userId).first;
      if (measurements.isNotEmpty) {
        final recentMeasurement = measurements.first;
        _weight = recentMeasurement.weight;
      }

      // Get most recent nutrition data
      final nutritionData = await tdeeService.getMostRecentNutritionData(widget.userId);
      if (nutritionData != null) {
        _activityLevel = nutritionData['activityLevel'] as double? ?? 1.2;
        _tdee = (nutritionData['tdee'] as num?)?.toInt() ?? 0;
        _weight = nutritionData['weight'] as double? ?? _weight;
      }

      setState(() {
        _ageController.text = _birthdate != null ? _calculateAge(_birthdate!).toString() : '';
        _heightController.text = _height.toString();
        _weightController.text = _weight.toString();
      });
    } catch (e) {
      debugPrint('Error loading TDEE data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nel caricamento dei dati. Riprova più tardi.')),
        );
      }
    }
  }

 Future<void> _calculateTDEE() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_birthdate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona una data di nascita valida.')),
        );
        return;
      }

      final age = _calculateAge(_birthdate!);

      double bmr;
      if (_gender == 1) { // Maschio
        bmr = 88.362 + (13.397 * _weight) + (4.799 * _height) - (5.677 * age);
      } else if (_gender == 2) { // Femmina
        bmr = 447.593 + (9.247 * _weight) + (3.098 * _height) - (4.330 * age);
      } else { // Altro o non specificato
        bmr = (88.362 + 447.593) / 2 + (11.322 * _weight) + (3.9485 * _height) - (5.0035 * age);
      }

      _tdee = (bmr * _activityLevel).round();

      // Calculate macronutrients (example distribution: 40% carbs, 30% protein, 30% fat)
      double carbs = (_tdee * 0.4) / 4; // 4 calories per gram of carbs
      double protein = (_tdee * 0.3) / 4; // 4 calories per gram of protein
      double fat = (_tdee * 0.3) / 9; // 9 calories per gram of fat

      // Round to 2 decimal places using a helper function
      carbs = _roundToTwoDecimals(carbs);
      protein = _roundToTwoDecimals(protein);
      fat = _roundToTwoDecimals(fat);

      try {
        final tdeeService = ref.read(tdeeServiceProvider);
        await tdeeService.saveNutritionData(widget.userId, {
          'birthdate': _birthdate!.toIso8601String(),
          'height': _height,
          'weight': _weight,
          'gender': _gender,
          'activityLevel': _activityLevel,
          'tdee': _tdee,
          'carbs': carbs,
          'protein': protein,
          'fat': fat,
        });

        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('TDEE e macronutrienti calcolati e salvati con successo!')),
          );
        }
      } catch (e) {
        debugPrint('Error saving TDEE data: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Errore nel salvataggio dei dati. Riprova più tardi.')),
          );
        }
      }
    }
  }

  // Helper function to round to two decimal places
  double _roundToTwoDecimals(double value) {
    return double.parse((value).toStringAsFixed(2));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoText(),
              const SizedBox(height: 32),
              _buildAgeField(),
              const SizedBox(height: 16),
              _buildHeightField(),
              const SizedBox(height: 16),
              _buildWeightField(),
              const SizedBox(height: 16),
              _buildGenderDropdown(),
              const SizedBox(height: 16),
              _buildActivityLevelDropdown(),
              const SizedBox(height: 32),
              _buildCalculateButton(),
              const SizedBox(height: 32),
              _buildTDEEResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoText() {
    return Column(
      children: [
        Text(
          'Calcola il tuo TDEE',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Conosci il tuo TDEE inserendo dettagli di base come età, peso, altezza e livello di attività.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAgeField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Età',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      controller: _ageController,
      readOnly: true,
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _birthdate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() {
            _birthdate = pickedDate;
            _ageController.text = _calculateAge(_birthdate!).toString();
          });
        }
      },
    );
  }

  Widget _buildHeightField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Altezza (cm)",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      controller: _heightController,
      keyboardType: TextInputType.number,
      validator: (value) => value?.isEmpty ?? true ? 'Inserisci la tua altezza' : null,
      onSaved: (value) => _height = double.parse(value!),
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Peso (kg)",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      controller: _weightController,
      keyboardType: TextInputType.number,
      validator: (value) => value?.isEmpty ?? true ? 'Inserisci il tuo peso' : null,
      onSaved: (value) => _weight = double.parse(value!),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: 'Genere',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      value: _gender,
      items: genderMap.entries.map((entry) {
        return DropdownMenuItem<int>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      validator: (value) => value == null ? 'Seleziona il tuo genere' : null,
      onChanged: (value) => setState(() => _gender = value!),
    );
  }

  Widget _buildActivityLevelDropdown() {
    return DropdownButtonFormField<double>(
      decoration: InputDecoration(
        labelText: 'Livello di Attività',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      value: _activityLevel,
      items: activityLevels.entries.map((entry) {
        return DropdownMenuItem<double>(
          value: entry.value,
          child: Text(entry.key),
        );
      }).toList(),
      validator: (value) => value == null ? 'Seleziona il tuo livello di attività' : null,
      onChanged: (value) => setState(() => _activityLevel = value!),
    );
  }

  Widget _buildCalculateButton() {
    return ElevatedButton(
      onPressed: _calculateTDEE,
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        'Calcola il mio TDEE',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTDEEResult() {
    return Text(
      'Il tuo TDEE è: $_tdee',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  int _calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month || (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }
}