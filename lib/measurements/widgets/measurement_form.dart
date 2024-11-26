import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../measurement_constants.dart';
import '../measurement_controller.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/models/measurement_model.dart';

class MeasurementForm extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final MeasurementModel? measurement;
  final String userId;

  const MeasurementForm({
    super.key,
    required this.scrollController,
    this.measurement,
    required this.userId,
  });

  @override
  ConsumerState<MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends ConsumerState<MeasurementForm> {
  late final GlobalKey<FormState> _formKey;
  late final Map<String, TextEditingController> _controllers;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _controllers = {
      'weight': TextEditingController(
          text: widget.measurement?.weight.toString() ?? ''),
      'height': TextEditingController(
          text: widget.measurement?.height.toString() ?? ''),
      'bodyFat': TextEditingController(
          text: widget.measurement?.bodyFatPercentage.toString() ?? ''),
      'waist': TextEditingController(
          text: widget.measurement?.waistCircumference.toString() ?? ''),
      'hip': TextEditingController(
          text: widget.measurement?.hipCircumference.toString() ?? ''),
      'chest': TextEditingController(
          text: widget.measurement?.chestCircumference.toString() ?? ''),
      'biceps': TextEditingController(
          text: widget.measurement?.bicepsCircumference.toString() ?? ''),
    };
    _selectedDate = widget.measurement?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radii.xl),
        ),
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme, colorScheme),
            _buildForm(theme, colorScheme),
            _buildActions(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radii.xl),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.sm,
              vertical: AppTheme.spacing.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppTheme.radii.full),
            ),
            child: Icon(
              widget.measurement == null
                  ? Icons.add_circle_outline
                  : Icons.edit_outlined,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          SizedBox(width: AppTheme.spacing.md),
          Text(
            widget.measurement == null
                ? 'Nuova Misurazione'
                : 'Modifica Misurazione',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.all(AppTheme.spacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDatePicker(theme, colorScheme),
            SizedBox(height: AppTheme.spacing.lg),
            ...MeasurementConstants.measurementLabels.entries.map((entry) {
              return Column(
                children: [
                  _buildMeasurementField(
                    controller: _controllers[entry.key]!,
                    label: entry.value,
                    hint: 'Inserisci ${entry.value.toLowerCase()}',
                    icon: MeasurementConstants.measurementIcons[entry.key]!,
                    unit: MeasurementConstants.measurementUnits[entry.key]!,
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  SizedBox(height: AppTheme.spacing.lg),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppTheme.spacing.xs),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: AppTheme.spacing.md),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String unit,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppTheme.spacing.xs),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                icon,
                color: colorScheme.primary,
                size: 20,
              ),
              suffixText: unit,
              suffixStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(AppTheme.spacing.md),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return null;
              }
              final number = double.tryParse(value);
              if (number == null) {
                return 'Inserisci un numero valido';
              }
              if (number < 0) {
                return 'Il valore non può essere negativo';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing.lg,
                vertical: AppTheme.spacing.md,
              ),
            ),
            child: Text(
              'Annulla',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacing.md),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _submitMeasurement,
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing.lg,
                    vertical: AppTheme.spacing.md,
                  ),
                  child: Text(
                    widget.measurement == null ? 'Aggiungi' : 'Aggiorna',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitMeasurement() {
    if (_formKey.currentState!.validate()) {
      final controller =
          ref.read(measurementControllerProvider(widget.userId).notifier);

      final weight = double.tryParse(_controllers['weight']!.text) ?? 0.0;
      final height = double.tryParse(_controllers['height']!.text) ?? 0.0;
      final bmi = height > 0 ? weight / ((height / 100) * (height / 100)) : 0.0;

      final measurement = MeasurementModel(
        id: widget.measurement?.id ?? '',
        userId: widget.userId,
        date: _selectedDate,
        weight: weight,
        height: height,
        bmi: bmi,
        bodyFatPercentage:
            double.tryParse(_controllers['bodyFat']!.text) ?? 0.0,
        waistCircumference: double.tryParse(_controllers['waist']!.text) ?? 0.0,
        hipCircumference: double.tryParse(_controllers['hip']!.text) ?? 0.0,
        chestCircumference: double.tryParse(_controllers['chest']!.text) ?? 0.0,
        bicepsCircumference:
            double.tryParse(_controllers['biceps']!.text) ?? 0.0,
      );

      if (widget.measurement == null) {
        controller.addMeasurement(measurement);
      } else {
        controller.updateMeasurement(widget.measurement!.id, measurement);
      }

      Navigator.pop(context);
    }
  }
}
