import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:alphanessone/models/measurement_model.dart';
import 'package:alphanessone/providers/providers.dart';

class MeasurementsPage extends ConsumerWidget {
  final String userId;

  const MeasurementsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurementsAsyncValue = ref.watch(measurementsProvider(userId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: measurementsAsyncValue.when(
          loading: () => Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
          error: (error, stackTrace) => Center(child: Text('Error: $error', style: TextStyle(color: theme.colorScheme.error))),
          data: (measurements) => _MeasurementsContent(measurements: measurements, userId: userId),
        ),
      ),
    );
  }
}

class _MeasurementsContent extends ConsumerWidget {
  final List<MeasurementModel> measurements;
  final String userId;

  const _MeasurementsContent({required this.measurements, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedComparisons = ref.watch(selectedComparisonsProvider);
    Theme.of(context);

    return CustomScrollView(
      slivers: [
        _buildAppBar(context, ref),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildComparisonSelector(context, ref),
                const SizedBox(height: 16),
                _MeasurementCards(measurements: measurements, selectedComparisons: selectedComparisons),
                const SizedBox(height: 16),
                _MeasurementsTrend(measurements: measurements),
                const SizedBox(height: 16),
                _MeasurementsList(measurements: measurements, userId: userId),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SliverAppBar(
      floating: true,
      backgroundColor: theme.colorScheme.surface,
      title: Text('Body Measurements', style: TextStyle(color: theme.colorScheme.onSurface)),
      actions: [
        IconButton(
          icon: Icon(Icons.add, color: theme.colorScheme.primary),
          onPressed: () => _showAddMeasurementDialog(context, ref, null),
        ),
      ],
    );
  }

  Widget _buildComparisonSelector(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Compare measurements:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        ElevatedButton(
          onPressed: () => _showComparisonSelectionDialog(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: const Text('Select'),
        ),
      ],
    );
  }

  void _showComparisonSelectionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _ComparisonSelectionDialog(measurements: measurements),
    );
  }

  void _showAddMeasurementDialog(BuildContext context, WidgetRef ref, MeasurementModel? measurement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => _MeasurementForm(
          scrollController: controller,
          measurement: measurement,
          userId: userId,
        ),
      ),
    );
  }
}

class _MeasurementCards extends ConsumerWidget {
  final List<MeasurementModel> measurements;
  final List<MeasurementModel> selectedComparisons;

  const _MeasurementCards({required this.measurements, required this.selectedComparisons});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referenceMeasurement = _getReferenceMeasurement();
    Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        final width = constraints.maxWidth / crossAxisCount - 16;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMeasurementCard(context, ref, 'Weight', width, referenceMeasurement?.weight, 'kg', _getWeightStatus, _getComparisons(referenceMeasurement, (m) => m.weight)),
            _buildMeasurementCard(context, ref, 'Height', width, referenceMeasurement?.height, 'cm', (_) => 'Normal', _getComparisons(referenceMeasurement, (m) => m.height)),
            _buildMeasurementCard(context, ref, 'BMI', width, referenceMeasurement?.bmi, '', _getBMIStatus, _getComparisons(referenceMeasurement, (m) => m.bmi)),
            _buildMeasurementCard(context, ref, 'Body Fat', width, referenceMeasurement?.bodyFatPercentage, '%', _getBodyFatStatus, _getComparisons(referenceMeasurement, (m) => m.bodyFatPercentage)),
            _buildMeasurementCard(context, ref, 'Waist', width, referenceMeasurement?.waistCircumference, 'cm', _getWaistStatus, _getComparisons(referenceMeasurement, (m) => m.waistCircumference)),
            _buildMeasurementCard(context, ref, 'Hip', width, referenceMeasurement?.hipCircumference, 'cm', (_) => 'Normal', _getComparisons(referenceMeasurement, (m) => m.hipCircumference)),
          ],
        );
      },
    );
  }

  Widget _buildMeasurementCard(BuildContext context, WidgetRef ref, String title, double width, double? currentValue, String unit, String Function(double) getStatus, List<MapEntry<String, double?>> comparisonValues) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Card(
        elevation: 2,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              if (currentValue != null) ...[
                Text('${currentValue.toStringAsFixed(1)} $unit', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                Text(getStatus(currentValue), style: TextStyle(color: _getStatusColor(getStatus(currentValue), theme), fontSize: 16)),
                const SizedBox(height: 8),
                ...comparisonValues.map((entry) => _buildComparisonRow(context, ref, entry, currentValue, unit)),
              ] else
                Text('No data available', style: TextStyle(color: theme.colorScheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonRow(BuildContext context, WidgetRef ref, MapEntry<String, double?> entry, double currentValue, String unit) {
    final theme = Theme.of(context);
    final comparisonDate = entry.key;
    final comparisonValue = entry.value;
    if (comparisonValue != null) {
      final difference = currentValue - comparisonValue;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$comparisonDate: ${difference.toStringAsFixed(1)} $unit',
                style: TextStyle(color: difference < 0 ? theme.colorScheme.tertiary : theme.colorScheme.error, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            GestureDetector(
              onTap: () => _removeComparison(ref, comparisonDate),
              child: Icon(Icons.close, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _removeComparison(WidgetRef ref, String comparisonDate) {
    final selectedComparisons = ref.read(selectedComparisonsProvider);
    ref.read(selectedComparisonsProvider.notifier).state = selectedComparisons
        .where((m) => DateFormat('dd/MM/yyyy').format(m.date) != comparisonDate)
        .toList();
  }

  MeasurementModel? _getReferenceMeasurement() {
    return selectedComparisons.isNotEmpty
        ? selectedComparisons.reduce((a, b) => a.date.isAfter(b.date) ? a : b)
        : (measurements.isNotEmpty ? measurements.first : null);
  }

  List<MapEntry<String, double?>> _getComparisons(MeasurementModel? referenceMeasurement, double Function(MeasurementModel) getValue) {
    if (referenceMeasurement == null || selectedComparisons.isEmpty) {
      return [];
    }
    return selectedComparisons
        .where((m) => m.date != referenceMeasurement.date)
        .map((m) => MapEntry(DateFormat('dd/MM/yyyy').format(m.date), getValue(m)))
        .toList();
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'underweight':
      case 'very low':
        return theme.colorScheme.secondary;
      case 'normal':
      case 'optimal':
      case 'fitness':
        return theme.colorScheme.tertiary;
      case 'overweight':
      case 'high':
        return theme.colorScheme.secondary;
      case 'obese':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  String _getWeightStatus(double value) {
    if (value < 18.5) return 'Underweight';
    if (value < 25) return 'Normal';
    if (value < 30) return 'Overweight';
    return 'Obese';
  }

  String _getBMIStatus(double value) {
    if (value < 18.5) return 'Underweight';
    if (value < 25) return 'Normal';
    if (value < 30) return 'Overweight';
    return 'Obese';
  }

  String _getBodyFatStatus(double value) {
    if (value < 10) return 'Very low';
    if (value < 20) return 'Fitness';
    if (value < 25) return 'Normal';
    if (value < 30) return 'Overweight';
    return 'Obese';
  }

  String _getWaistStatus(double value) {
    if (value < 80) return 'Optimal';
    if (value < 88) return 'Normal';
    return 'High';
  }
}

class _MeasurementsTrend extends StatelessWidget {
  final List<MeasurementModel> measurements;

  const _MeasurementsTrend({required this.measurements});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Measurement Trends', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: _buildTitlesData(theme),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _buildLineChartBarData(measurements, (m) => m.weight, theme.colorScheme.primary),
                    _buildLineChartBarData(measurements, (m) => m.bodyFatPercentage, theme.colorScheme.secondary),
                    _buildLineChartBarData(measurements, (m) => m.waistCircumference, theme.colorScheme.tertiary),
                  ],
                  minX: 0,
                  maxX: (measurements.length - 1).toDouble(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildLegendItem('Weight', theme.colorScheme.primary),
                _buildLegendItem('Body Fat', theme.colorScheme.secondary),
                _buildLegendItem('Waist', theme.colorScheme.tertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  FlTitlesData _buildTitlesData(ThemeData theme) {
    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < measurements.length) {
              return Text(
                DateFormat('dd/MM').format(measurements[index].date),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 10,
                ),
              );
            }
            return const Text('');
          },
          reservedSize: 30,
        ),
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(List<MeasurementModel> measurements, double Function(MeasurementModel) getValue, Color color) {
    return LineChartBarData(
      spots: measurements.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), getValue(entry.value));
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class _MeasurementsList extends ConsumerWidget {
  final List<MeasurementModel> measurements;
  final String userId;

  const _MeasurementsList({required this.measurements, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Measurement History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: measurements.length,
              itemBuilder: (context, index) {
                final measurement = measurements[index];
                return ListTile(
                  title: Text(DateFormat('dd/MM/yyyy').format(measurement.date), style: TextStyle(color: theme.colorScheme.onSurface)),
                  subtitle: Text('Weight: ${measurement.weight.toStringAsFixed(1)} kg, Body Fat: ${measurement.bodyFatPercentage.toStringAsFixed(1)}%', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                        onPressed: () => _showEditMeasurementDialog(context, ref, measurement),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: theme.colorScheme.error),
                        onPressed: () => _showDeleteConfirmationDialog(context, ref, measurement),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMeasurementDialog(BuildContext context, WidgetRef ref, MeasurementModel measurement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) {
          return _MeasurementForm(
            scrollController: controller,
            measurement: measurement,
            userId: userId,
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, MeasurementModel measurement) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text('Confirm Deletion', style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text('Are you sure you want to delete this measurement?', style: TextStyle(color: theme.colorScheme.onSurface)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: theme.colorScheme.primary)),
            ),
            TextButton(
              onPressed: () {
                ref.read(measurementsServiceProvider).deleteMeasurement(
                  userId: userId,
                  measurementId: measurement.id,
                );
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        );
      },
    );
  }
}

class _ComparisonSelectionDialog extends ConsumerStatefulWidget {
  final List<MeasurementModel> measurements;

  const _ComparisonSelectionDialog({required this.measurements});

  @override
  _ComparisonSelectionDialogState createState() => _ComparisonSelectionDialogState();
}

class _ComparisonSelectionDialogState extends ConsumerState<_ComparisonSelectionDialog> {
  late List<MeasurementModel> selectedTemp;

  @override
  void initState() {
    super.initState();
    selectedTemp = List<MeasurementModel>.from(ref.read(selectedComparisonsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text('Select measurements', style: TextStyle(color: theme.colorScheme.onSurface)),
      content: SingleChildScrollView(
        child: Column(
          children: widget.measurements.map((measurement) {
            return CheckboxListTile(
              title: Text(DateFormat('dd/MM/yyyy').format(measurement.date), style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Weight: ${measurement.weight.toStringAsFixed(1)} kg', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
              value: selectedTemp.contains(measurement),
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true && !selectedTemp.contains(measurement)) {
                    selectedTemp.add(measurement);
                  } else if (selected == false) {
                    if (selectedTemp.length > 1 || measurement != selectedTemp.first) {
                      selectedTemp.remove(measurement);
                    }
                  }
                });
              },
              activeColor: theme.colorScheme.primary,
              checkColor: theme.colorScheme.onPrimary,
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: theme.colorScheme.primary)),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(selectedComparisonsProvider.notifier).state = selectedTemp;
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _MeasurementForm extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final MeasurementModel? measurement;
  final String userId;

  const _MeasurementForm({
    required this.scrollController,
    this.measurement,
    required this.userId,
  });

  @override
  _MeasurementFormState createState() => _MeasurementFormState();
}

class _MeasurementFormState extends ConsumerState<_MeasurementForm> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _bodyFatController;
  late final TextEditingController _waistController;
  late final TextEditingController _hipController;
  late final TextEditingController _chestController; // Aggiunto
  late final TextEditingController _bicepsController; // Aggiunto
  late DateTime _selectedDate;

   @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _weightController = TextEditingController(text: widget.measurement?.weight.toString());
    _heightController = TextEditingController(text: widget.measurement?.height.toString());
    _bodyFatController = TextEditingController(text: widget.measurement?.bodyFatPercentage.toString());
    _waistController = TextEditingController(text: widget.measurement?.waistCircumference.toString());
    _hipController = TextEditingController(text: widget.measurement?.hipCircumference.toString());
    _chestController = TextEditingController(text: widget.measurement?.chestCircumference.toString()); // Aggiunto
    _bicepsController = TextEditingController(text: widget.measurement?.bicepsCircumference.toString()); // Aggiunto
    _selectedDate = widget.measurement?.date ?? DateTime.now();
  }

   @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _bodyFatController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _chestController.dispose(); // Aggiunto
    _bicepsController.dispose(); // Aggiunto
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.measurement == null ? 'Add New Measurement' : 'Edit Measurement',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildDatePicker(context),
                  _buildTextField(_weightController, 'Weight (kg)'),
                  _buildTextField(_heightController, 'Height (cm)'),
                  _buildTextField(_bodyFatController, 'Body Fat (%)'),
                  _buildTextField(_waistController, 'Waist (cm)'),
                  _buildTextField(_hipController, 'Hip (cm)'),
                  _buildTextField(_chestController, 'Chest (cm)'), // Aggiunto
                  _buildTextField(_bicepsController, 'Biceps (cm)'), // Aggiunto
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitMeasurement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    ),
                    child: Text(widget.measurement == null ? 'Add' : 'Update'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
            builder: (BuildContext context, Widget? child) {
              return Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: theme.colorScheme,
                  dialogBackgroundColor: theme.colorScheme.surface,
                ),
                child: child!,
              );
            },
          );
          if (picked != null && picked != _selectedDate) {
            setState(() {
              _selectedDate = picked;
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date',
            labelStyle: TextStyle(color: theme.colorScheme.onSurface),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: TextStyle(color: theme.colorScheme.onSurface)),
              Icon(Icons.calendar_today, color: theme.colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.colorScheme.onSurface),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

 void _submitMeasurement() {
    if (_formKey.currentState!.validate()) {
      final measurementsService = ref.read(measurementsServiceProvider);
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);
      final bodyFat = double.parse(_bodyFatController.text);
      final waist = double.parse(_waistController.text);
      final hip = double.parse(_hipController.text);
      final chest = double.parse(_chestController.text); // Aggiunto
      final biceps = double.parse(_bicepsController.text); // Aggiunto

      final bmi = weight / ((height / 100) * (height / 100));

      // Store the context before the async gap
      final currentContext = context;

      Future<void> performOperation() async {
        if (widget.measurement == null) {
          await measurementsService.addMeasurement(
            userId: widget.userId,
            date: _selectedDate,
            weight: weight,
            height: height,
            bmi: bmi,
            bodyFatPercentage: bodyFat,
            waistCircumference: waist,
            hipCircumference: hip,
            chestCircumference: chest, // Aggiunto
            bicepsCircumference: biceps, // Aggiunto
          );
        } else {
          await measurementsService.updateMeasurement(
            userId: widget.userId,
            measurementId: widget.measurement!.id,
            date: _selectedDate,
            weight: weight,
            height: height,
            bmi: bmi,
            bodyFatPercentage: bodyFat,
            waistCircumference: waist,
            hipCircumference: hip,
            chestCircumference: chest, // Aggiunto
            bicepsCircumference: biceps, // Aggiunto
          );
        }
      }

      performOperation().then((_) {
        // Use the stored context to check if the widget is still mounted
        if (currentContext.mounted) {
          Navigator.of(currentContext).pop();
        }
      }).catchError((error) {
        // Handle any errors here
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Theme.of(currentContext).colorScheme.error,
            ),
          );
        }
      });
    }
  }
}
