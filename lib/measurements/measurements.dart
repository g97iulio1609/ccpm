import 'package:alphanessone/models/measurement_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/services/measurements_services.dart'; // Importa il nuovo servizio
import 'measurements_provider.dart';
import 'measurements_chart.dart';
import 'package:fl_chart/fl_chart.dart';

// Service Provider
final measurementsServiceProvider = Provider<MeasurementsService>((ref) {
  return MeasurementsService(FirebaseFirestore.instance);
});

class MeasurementsPage extends ConsumerStatefulWidget {
  final String userId;

  const MeasurementsPage({super.key, required this.userId});

  @override
  ConsumerState<MeasurementsPage> createState() => _MeasurementsPageState();
}

class _MeasurementsPageState extends ConsumerState<MeasurementsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _chestController = TextEditingController();
  final _bicepsController = TextEditingController();

  String? _editMeasurementId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bodyFatController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _chestController.dispose();
    _bicepsController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _dateController.clear();
    _weightController.clear();
    _heightController.clear();
    _bodyFatController.clear();
    _waistController.clear();
    _hipController.clear();
    _chestController.clear();
    _bicepsController.clear();
    _editMeasurementId = null;
  }

  @override
  Widget build(BuildContext context) {
    final measurementsService = ref.watch(measurementsServiceProvider);
    final selectedDates = ref.watch(measurementsStateNotifierProvider);
    final selectedMeasurements = ref.watch(selectedMeasurementsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                toolbarHeight: 0,
                pinned: true,
                backgroundColor: Colors.black,
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Misurazioni'),
                    Tab(text: 'Grafici'),
                    Tab(text: 'Nuova'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTableSection(measurementsService),
              _buildChartSection(measurementsService, selectedDates, selectedMeasurements),
              _buildAddMeasurementSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(MeasurementsService measurementsService, MeasurementsState selectedDates, Set<String> selectedMeasurements) {
    return StreamBuilder<List<MeasurementModel>>(
      stream: measurementsService.getMeasurements(userId: widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final measurements = snapshot.data!;
          if (measurements.length < 2) {
            return const Center(child: Text('Per visualizzare il grafico sono necessari almeno 2 misurazioni antropometriche'));
          }
          final measurementData = _convertMeasurementsToData(measurements);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Seleziona periodo:',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final dateRange = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2025),
                          initialDateRange: DateTimeRange(
                            start: selectedDates.startDate ?? DateTime.now(),
                            end: selectedDates.endDate ?? DateTime.now(),
                          ),
                        );
                        if (dateRange != null) {
                          ref.read(measurementsStateNotifierProvider.notifier).setSelectedDates(dateRange.start, dateRange.end);
                        }
                      },
                      icon: const Icon(Icons.date_range),
                      label: const Text('Seleziona'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: MeasurementsChart(
                    measurementData: measurementData,
                    startDate: selectedDates.startDate,
                    endDate: selectedDates.endDate,
                    selectedMeasurements: selectedMeasurements,
                  ),
                ),
              ),
              _buildMeasurementChips(selectedMeasurements),
            ],
          );
        } else {
          return const Center(child: Text('Nessuna misurazione disponibile.', style: TextStyle(color: Colors.white)));
        }
      },
    );
  }

  Widget _buildTableSection(MeasurementsService measurementsService) {
    return StreamBuilder<List<MeasurementModel>>(
      stream: measurementsService.getMeasurements(userId: widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
        } else if (snapshot.hasData) {
          final measurements = snapshot.data!;

          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              if (constraints.maxWidth < 600) {
                return _buildMobileMeasurementsTable(measurements);
              } else {
                return _buildDesktopMeasurementsTable(measurements);
              }
            },
          );
        } else {
          return const Center(child: Text('Nessuna misurazione disponibile.', style: TextStyle(color: Colors.white)));
        }
      },
    );
  }

  Widget _buildDesktopMeasurementsTable(List<MeasurementModel> measurements) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Data', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Peso', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Massa Grassa', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Circonferenza Vita', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Circonferenza Fianchi', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Circonferenza Torace', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Circonferenza Bicipiti', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Azioni', style: TextStyle(color: Colors.white))),
        ],
        rows: measurements.map((measurement) {
          return DataRow(
            cells: [
              DataCell(Text(DateFormat('dd/MM/yyyy').format(measurement.date), style: const TextStyle(color: Colors.white))),
              DataCell(Text('${measurement.weight.toStringAsFixed(2)} kg', style: const TextStyle(color: Colors.white))),
              DataCell(Text('${measurement.bodyFatPercentage.toStringAsFixed(2)}%', style: const TextStyle(color: Colors.white))),
              DataCell(Text('${measurement.waistCircumference.toStringAsFixed(2)} cm', style: const TextStyle(color: Colors.white))),
              DataCell(Text('${measurement.hipCircumference.toStringAsFixed(2)} cm', style: const TextStyle(color: Colors.white))),
              DataCell(Text('${measurement.chestCircumference.toStringAsFixed(2)} cm', style: const TextStyle(color: Colors.white))),
              DataCell(Text('${measurement.bicepsCircumference.toStringAsFixed(2)} cm', style: const TextStyle(color: Colors.white))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _showEditMeasurementDialog(measurement),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () => _showDeleteConfirmationDialog(measurement),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileMeasurementsTable(List<MeasurementModel> measurements) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: measurements.length,
      itemBuilder: (context, index) {
        final currentMeasurement = measurements[index];
        final previousMeasurement = index < measurements.length - 1 ? measurements[index + 1] : null;

        return Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data: ${DateFormat('dd/MM/yyyy').format(currentMeasurement.date)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                _buildMeasurementRow('Peso:', '${currentMeasurement.weight.toStringAsFixed(2)} kg', previousMeasurement?.weight),
                _buildMeasurementRow('Massa Grassa:', '${currentMeasurement.bodyFatPercentage.toStringAsFixed(2)}%', previousMeasurement?.bodyFatPercentage),
                _buildMeasurementRow('Circonferenza Vita:', '${currentMeasurement.waistCircumference.toStringAsFixed(2)} cm', previousMeasurement?.waistCircumference),
                _buildMeasurementRow('Circonferenza Fianchi:', '${currentMeasurement.hipCircumference.toStringAsFixed(2)} cm', previousMeasurement?.hipCircumference),
                _buildMeasurementRow('Circonferenza Torace:', '${currentMeasurement.chestCircumference.toStringAsFixed(2)} cm', previousMeasurement?.chestCircumference),
                _buildMeasurementRow('Circonferenza Bicipiti:', '${currentMeasurement.bicepsCircumference.toStringAsFixed(2)} cm', previousMeasurement?.bicepsCircumference),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _showEditMeasurementDialog(currentMeasurement),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () => _showDeleteConfirmationDialog(currentMeasurement),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeasurementRow(String label, String value, double? previousValue) {
    double? delta;
    if (previousValue != null) {
      final currentValue = double.tryParse(value.split(' ')[0]);
      if (currentValue != null) {
        delta = currentValue - previousValue;
      }
    }
    final sign = delta != null && delta >= 0 ? '+' : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        Text('$value${delta != null ? ' ($sign${delta.toStringAsFixed(2)})' : ''}', style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildMeasurementChips(Set<String> selectedMeasurements) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('Peso'),
              selected: selectedMeasurements.contains('weight'),
              onSelected: (selected) {
                ref.read(selectedMeasurementsProvider.notifier).toggleSelectedMeasurement('weight');
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Massa Grassa'),
              selected: selectedMeasurements.contains('bodyFatPercentage'),
              onSelected: (selected) {
                ref.read(selectedMeasurementsProvider.notifier).toggleSelectedMeasurement('bodyFatPercentage');
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Circonferenza Vita'),
              selected: selectedMeasurements.contains('waistCircumference'),
              onSelected: (selected) {
                ref.read(selectedMeasurementsProvider.notifier).toggleSelectedMeasurement('waistCircumference');
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Circonferenza Fianchi'),
              selected: selectedMeasurements.contains('hipCircumference'),
              onSelected: (selected) {
                ref.read(selectedMeasurementsProvider.notifier).toggleSelectedMeasurement('hipCircumference');
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Circonferenza Torace'),
              selected: selectedMeasurements.contains('chestCircumference'),
              onSelected: (selected) {
                ref.read(selectedMeasurementsProvider.notifier).toggleSelectedMeasurement('chestCircumference');
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Circonferenza Bicipiti'),
              selected: selectedMeasurements.contains('bicepsCircumference'),
              onSelected: (selected) {
                ref.read(selectedMeasurementsProvider.notifier).toggleSelectedMeasurement('bicepsCircumference');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMeasurementSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Data',
                hintText: 'gg/mm/aaaa',
                labelStyle: TextStyle(color: Colors.white),
                hintStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci una data';
                }
                return null;
              },
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
            ),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci un peso';
                }
                return null;
              },
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
            ),
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Altezza (cm)',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci un\'altezza';
                }
                return null;
              },
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
            ),
            TextFormField(
              controller: _bodyFatController,
              decoration: const InputDecoration(
                labelText: 'Massa Grassa (%)',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci una percentuale di massa grassa';
                }
                return null;
              },
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
            ),
            TextFormField(
              controller: _waistController,
              decoration: const InputDecoration(
                labelText: 'Circonferenza Vita (cm)',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci una circonferenza vita';
                }
                return null;
              },
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
            ),
            TextFormField(
              controller: _hipController,
              decoration: const InputDecoration(
                labelText: 'Circonferenza Fianchi (cm)',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci una circonferenza fianchi';
                }
                return null;
              },
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
            ),
            TextFormField(
              controller: _chestController,
              decoration: const InputDecoration(
                labelText: 'Circonferenza Torace (cm)',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci una circonferenza torace';
                }
                return null;
              },
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
            ),
            TextFormField(
              controller: _bicepsController,
              decoration: const InputDecoration(
                labelText: 'Circonferenza Bicipiti (cm)',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci una circonferenza bicipiti';
                }
                return null;
              },
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final measurementsService = ref.read(measurementsServiceProvider);
                  final date = DateFormat('dd/MM/yyyy').parse(_dateController.text);
                  final weight = double.parse(_weightController.text);
                  final height = double.parse(_heightController.text);
                  final bodyFat = double.parse(_bodyFatController.text);
                  final waist = double.parse(_waistController.text);
                  final hip = double.parse(_hipController.text);
                  final chest = double.parse(_chestController.text);
                  final biceps = double.parse(_bicepsController.text);

                  final bmi = weight / ((height / 100) * (height / 100));

                  if (_editMeasurementId == null) {
                    await measurementsService.addMeasurement(
                      userId: widget.userId,
                      date: date,
                      weight: weight,
                      height: height,
                      bmi: bmi,
                      bodyFatPercentage: bodyFat,
                      waistCircumference: waist,
                      hipCircumference: hip,
                      chestCircumference: chest,
                      bicepsCircumference: biceps,
                    );
                  } else {
                    await measurementsService.updateMeasurement(
                      userId: widget.userId,
                      measurementId: _editMeasurementId!,
                      date: date,
                      weight: weight,
                      height: height,
                      bmi: bmi,
                      bodyFatPercentage: bodyFat,
                      waistCircumference: waist,
                      hipCircumference: hip,
                      chestCircumference: chest,
                      bicepsCircumference: biceps,
                    );
                  }

                  _resetForm();
                }
              },
              child: Text(_editMeasurementId == null ? 'Aggiungi' : 'Aggiorna', style: const TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMeasurementDialog(MeasurementModel measurement) {
    _dateController.text = DateFormat('dd/MM/yyyy').format(measurement.date);
    _weightController.text = measurement.weight.toString();
    _heightController.text = measurement.height.toString();
    _bodyFatController.text = measurement.bodyFatPercentage.toString();
    _waistController.text = measurement.waistCircumference.toString();
    _hipController.text = measurement.hipCircumference.toString();
    _chestController.text = measurement.chestCircumference.toString();
    _bicepsController.text = measurement.bicepsCircumference.toString();
    _editMeasurementId = measurement.id;

    _tabController.animateTo(2);
  }

  void _showDeleteConfirmationDialog(MeasurementModel measurement) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Conferma Eliminazione', style: TextStyle(color: Colors.white)),
          content: const Text('Sei sicuro di voler eliminare questa misurazione?', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annulla', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                final measurementsService = ref.read(measurementsServiceProvider);
                measurementsService.deleteMeasurement(
                  userId: widget.userId,
                  measurementId: measurement.id,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Elimina', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Map<String, List<FlSpot>> _convertMeasurementsToData(List<MeasurementModel> measurements) {
    final measurementData = {
      'weight': measurements
          .map((m) => FlSpot(m.date.millisecondsSinceEpoch.toDouble(), m.weight))
          .toList(),
      'bodyFatPercentage': measurements
          .map((m) => FlSpot(m.date.millisecondsSinceEpoch.toDouble(), m.bodyFatPercentage))
          .toList(),
      'waistCircumference': measurements
          .map((m) => FlSpot(m.date.millisecondsSinceEpoch.toDouble(), m.waistCircumference))
          .toList(),
      'hipCircumference': measurements
          .map((m) => FlSpot(m.date.millisecondsSinceEpoch.toDouble(), m.hipCircumference))
          .toList(),
      'chestCircumference': measurements
          .map((m) => FlSpot(m.date.millisecondsSinceEpoch.toDouble(), m.chestCircumference))
          .toList(),
      'bicepsCircumference': measurements
          .map((m) => FlSpot(m.date.millisecondsSinceEpoch.toDouble(), m.bicepsCircumference))
          .toList(),
    };
    return measurementData;
  }
}
