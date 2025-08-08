import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_input_form.dart';
import 'package:flutter/services.dart';
import 'package:alphanessone/UI/components/date_picker_field.dart';

// Constants
const Map<int, String> genderMap = {0: 'Altro', 1: 'Maschio', 2: 'Femmina'};

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
  late ThemeData theme;
  late ColorScheme colorScheme;

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
      final measurements = await measurementsService
          .getMeasurements(userId: widget.userId)
          .first;
      if (measurements.isNotEmpty) {
        final recentMeasurement = measurements.first;
        _weight = recentMeasurement.weight;
      }

      // Get most recent nutrition data
      final nutritionData = await tdeeService.getMostRecentNutritionData(
        widget.userId,
      );
      if (nutritionData != null) {
        _activityLevel = nutritionData['activityLevel'] as double? ?? 1.2;
        _tdee = (nutritionData['tdee'] as num?)?.toInt() ?? 0;
        _weight = nutritionData['weight'] as double? ?? _weight;
      }

      setState(() {
        _ageController.text = _birthdate != null
            ? _calculateAge(_birthdate!).toString()
            : '';
        _heightController.text = _height.toString();
        _weightController.text = _weight.toString();
      });
    } catch (e) {
      debugPrint('Error loading TDEE data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Errore nel caricamento dei dati. Riprova più tardi.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _calculateTDEE() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_birthdate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seleziona una data di nascita valida.'),
          ),
        );
        return;
      }

      final age = _calculateAge(_birthdate!);

      double bmr;
      if (_gender == 1) {
        // Maschio
        bmr = 88.362 + (13.397 * _weight) + (4.799 * _height) - (5.677 * age);
      } else if (_gender == 2) {
        // Femmina
        bmr = 447.593 + (9.247 * _weight) + (3.098 * _height) - (4.330 * age);
      } else {
        // Altro o non specificato
        bmr =
            (88.362 + 447.593) / 2 +
            (11.322 * _weight) +
            (3.9485 * _height) -
            (5.0035 * age);
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
            const SnackBar(
              content: Text(
                'TDEE e macronutrienti calcolati e salvati con successo!',
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error saving TDEE data: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Errore nel salvataggio dei dati. Riprova più tardi.',
              ),
            ),
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
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withAlpha(128),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.spacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacing.lg),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(76),
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      border: Border.all(
                        color: colorScheme.outline.withAlpha(26),
                      ),
                      boxShadow: AppTheme.elevations.small,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppTheme.spacing.md),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withAlpha(76),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_fire_department,
                            color: colorScheme.primary,
                            size: 32,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacing.md),
                        Text(
                          'Calcola il tuo TDEE',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppTheme.spacing.sm),
                        Text(
                          'Scopri il tuo fabbisogno calorico giornaliero',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacing.xl),

                  // Form Content
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacing.lg),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      border: Border.all(
                        color: colorScheme.outline.withAlpha(26),
                      ),
                      boxShadow: AppTheme.elevations.small,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_buildTDEEForm(context)],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacing.xl),

                  // Calculate Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withAlpha(204),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(51),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _calculateTDEE,
                        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                        child: Padding(
                          padding: EdgeInsets.all(AppTheme.spacing.lg),
                          child: Text(
                            'Calcola TDEE',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_tdee > 0) ...[
                    SizedBox(height: AppTheme.spacing.xl),
                    _buildTDEEResult(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTDEEForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DatePickerField(
          value: _birthdate,
          label: 'Data di Nascita',
          helperText: 'Seleziona la tua data di nascita',
          onDateSelected: (date) {
            setState(() {
              _birthdate = date;
              _ageController.text = _calculateAge(date).toString();
            });
          },
          validator: (date) {
            if (date == null) {
              return 'Seleziona una data di nascita';
            }
            if (date.isAfter(DateTime.now())) {
              return 'La data non può essere nel futuro';
            }
            return null;
          },
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          icon: Icons.cake,
        ),
        SizedBox(height: AppTheme.spacing.lg),

        BottomInputForm.buildTextInput(
          controller: _heightController,
          hint: "Inserisci l'altezza in cm",
          icon: Icons.height,
          theme: theme,
          colorScheme: colorScheme,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          suffixText: "cm",
        ),
        SizedBox(height: AppTheme.spacing.lg),

        BottomInputForm.buildTextInput(
          controller: _weightController,
          hint: "Inserisci il peso in kg",
          icon: Icons.monitor_weight,
          theme: theme,
          colorScheme: colorScheme,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          suffixText: "kg",
        ),
        SizedBox(height: AppTheme.spacing.lg),

        // Campo per il genere usando BottomInputForm
        BottomInputForm.buildFormField(
          label: 'Genere',
          theme: theme,
          colorScheme: colorScheme,
          helperText: 'Seleziona il tuo genere',
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(76),
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              border: Border.all(color: colorScheme.outline.withAlpha(26)),
            ),
            child: DropdownButtonFormField<int>(
              value: _gender,
              isExpanded: true,
              items: genderMap.entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: colorScheme.primary,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(AppTheme.spacing.md),
              ),
              onChanged: (value) => setState(() => _gender = value!),
              dropdownColor: colorScheme.surface,
            ),
          ),
        ),
        SizedBox(height: AppTheme.spacing.lg),

        // Campo per il livello di attività usando BottomInputForm
        BottomInputForm.buildFormField(
          label: 'Livello di Attività',
          theme: theme,
          colorScheme: colorScheme,
          helperText: 'Seleziona il tuo livello di attività fisica settimanale',
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(76),
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              border: Border.all(color: colorScheme.outline.withAlpha(26)),
            ),
            child: DropdownButtonFormField<double>(
              value: _activityLevel,
              isExpanded: true,
              items: activityLevels.entries.map((entry) {
                return DropdownMenuItem<double>(
                  value: entry.value,
                  child: Text(
                    _getActivityLevelDescription(entry.key),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.directions_run,
                  color: colorScheme.primary,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(AppTheme.spacing.md),
              ),
              onChanged: (value) => setState(() => _activityLevel = value!),
              dropdownColor: colorScheme.surface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTDEEResult() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        children: [
          // Header con icona e titolo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(76),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_fire_department,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
              SizedBox(width: AppTheme.spacing.md),
              Text(
                'Il tuo TDEE è:',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing.lg),

          // Valore TDEE
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.xl,
              vertical: AppTheme.spacing.lg,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withAlpha(76),
                  colorScheme.primaryContainer.withAlpha(26),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_tdee',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: AppTheme.spacing.sm),
                Text(
                  'kcal',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary.withAlpha(179),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppTheme.spacing.lg),

          // Descrizione
          Text(
            'Questo è il tuo fabbisogno calorico giornaliero stimato per mantenere il tuo peso attuale.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppTheme.spacing.lg),

          // Azioni
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.save_alt,
                label: 'Salva',
                onTap: () => _saveTDEE(),
                colorScheme: colorScheme,
                theme: theme,
                isPrimary: true,
              ),
              SizedBox(width: AppTheme.spacing.md),
              _buildActionButton(
                icon: Icons.share,
                label: 'Condividi',
                onTap: () => _shareTDEE(),
                colorScheme: colorScheme,
                theme: theme,
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required ThemeData theme,
    required bool isPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withAlpha(204),
                ],
              )
            : null,
        color: isPrimary
            ? null
            : colorScheme.surfaceContainerHighest.withAlpha(76),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(51),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.lg,
              vertical: AppTheme.spacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isPrimary
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: AppTheme.spacing.sm),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isPrimary
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveTDEE() async {
    try {
      final tdeeService = ref.read(tdeeServiceProvider);
      await tdeeService.saveNutritionData(widget.userId, {
        'birthdate': _birthdate!.toIso8601String(),
        'height': _height,
        'weight': _weight,
        'gender': _gender,
        'activityLevel': _activityLevel,
        'tdee': _tdee,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'TDEE salvato con successo!',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Errore nel salvataggio del TDEE: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _shareTDEE() {
    // Implementa la condivisione del TDEE
  }

  int _calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  String _getActivityLevelDescription(String level) {
    switch (level) {
      case 'Sedentary':
        return 'Sedentario (poco o nessun esercizio)';
      case 'Lightly Active':
        return 'Leggermente Attivo (1-3 giorni/settimana)';
      case 'Moderately Active':
        return 'Moderatamente Attivo (3-5 giorni/settimana)';
      case 'Very Active':
        return 'Molto Attivo (6-7 giorni/settimana)';
      case 'Extremely Active':
        return 'Estremamente Attivo (2x al giorno)';
      default:
        return level;
    }
  }
}
