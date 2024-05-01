import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../users_services.dart';
import 'measurements_provider.dart';
import 'measurements_chart.dart';
import 'package:fl_chart/fl_chart.dart';

class ResponsiveText extends StatelessWidget {
  final String text;

  const ResponsiveText(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
            ],
          );
        } else {
          return Text(text);
        }
      },
    );
  }
}

class MeasurementsPage extends ConsumerStatefulWidget {
  final String userId;

  const MeasurementsPage({super.key, required this.userId});

  @override
  ConsumerState<MeasurementsPage> createState() => _MeasurementsPageState();
}

class _MeasurementsPageState extends ConsumerState<MeasurementsPage> {
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
  bool _showAddMeasurementForm = false;

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
  final usersService = ref.watch(usersServiceProvider);
  final selectedDates = ref.watch(measurementsStateNotifierProvider);
  final selectedMeasurements = ref.watch(selectedMeasurementsProvider);

  return Scaffold(
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grafici delle Misurazioni',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<MeasurementModel>>(
              stream: usersService.getMeasurements(userId: widget.userId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final measurements = snapshot.data!;
                  if (measurements.length >= 2) {
                    return Column(
                      children: [
                        _buildDateRangePicker(context, selectedDates),
                        const SizedBox(height: 16),
                        _buildMeasurementsChart(usersService, selectedDates, selectedMeasurements),
                        const SizedBox(height: 32),
                        _buildMeasurementChips(selectedMeasurements),
                        const SizedBox(height: 32),
                      ],
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                } else if (snapshot.hasError) {
                  return Text('Errore: ${snapshot.error}');
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
            Text(
              'Tabella delle Misurazioni',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildMeasurementsTable(usersService),
            const SizedBox(height: 32),
            Text(
              'Misurazioni Esistenti',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildMeasurementsList(usersService),
            const SizedBox(height: 32),
            _buildAddMeasurementExpansionPanel(),
          ],
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        setState(() {
          _showAddMeasurementForm = true;
        });
      },
      child: const Icon(Icons.add),
    ),
  );
}
  Widget _buildDateRangePicker(BuildContext context, MeasurementsState selectedDates) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Seleziona periodo:',
          style: Theme.of(context).textTheme.titleMedium,
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
              ref
                  .read(measurementsStateNotifierProvider.notifier)
                  .setSelectedDates(dateRange.start, dateRange.end);
            }
          },
          icon: const Icon(Icons.date_range),
          label: const Text('Seleziona'),
        ),
      ],
    );
  }

Widget _buildMeasurementsChart(UsersService usersService, MeasurementsState selectedDates,
    Set<String> selectedMeasurements) {
  return StreamBuilder<List<MeasurementModel>>(
    stream: usersService.getMeasurements(userId: widget.userId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return Text('Errore: ${snapshot.error}');
      } else if (snapshot.hasData) {
        final measurements = snapshot.data!;
        if (measurements.length < 2) {
          return const Text('Per visualizzare il grafico sono necessari almeno 2 misurazioni antropometriche');
        }
        final measurementData = _convertMeasurementsToData(measurements);

        return SizedBox(
          height: 300,
          child: MeasurementsChart(
            measurementData: measurementData,
            startDate: selectedDates.startDate,
            endDate: selectedDates.endDate,
            selectedMeasurements: selectedMeasurements,
          ),
        );
      } else {
        return const Text('Nessuna misurazione disponibile.');
      }
    },
  );
}

Widget _buildMeasurementChips(Set<String> selectedMeasurements) {
  return SingleChildScrollView(
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
            ref
                .read(selectedMeasurementsProvider.notifier)
                .toggleSelectedMeasurement('bodyFatPercentage');
          },
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('Circonferenza Vita'),
          selected: selectedMeasurements.contains('waistCircumference'),
          onSelected: (selected) {
            ref
                .read(selectedMeasurementsProvider.notifier)
                .toggleSelectedMeasurement('waistCircumference');
          },
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('Circonferenza Fianchi'),
          selected: selectedMeasurements.contains('hipCircumference'),
          onSelected: (selected) {
            ref
                .read(selectedMeasurementsProvider.notifier)
                .toggleSelectedMeasurement('hipCircumference');
          },
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('Circonferenza Torace'),
          selected: selectedMeasurements.contains('chestCircumference'),
          onSelected: (selected) {
            ref
                .read(selectedMeasurementsProvider.notifier)
                .toggleSelectedMeasurement('chestCircumference');
          },
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('Circonferenza Bicipiti'),
          selected: selectedMeasurements.contains('bicepsCircumference'),
          onSelected: (selected) {
            ref
                .read(selectedMeasurementsProvider.notifier)
                .toggleSelectedMeasurement('bicepsCircumference');
          },
        ),
      ],
    ),
  );
}
Widget _buildMeasurementsTable(UsersService usersService) {
  return StreamBuilder<List<MeasurementModel>>(
    stream: usersService.getMeasurements(userId: widget.userId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return Text('Errore: ${snapshot.error}');
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
        return const Text('Nessuna misurazione disponibile.');
      }
    },
  );
}

Widget _buildDesktopMeasurementsTable(List<MeasurementModel> measurements) {
  return DataTable(
    columns: const [
      DataColumn(label: Text('Data')),
      DataColumn(label: Text('Peso')),
      DataColumn(label: Text('Massa Grassa')),
      DataColumn(label: Text('Circonferenza Vita')),
      DataColumn(label: Text('Circonferenza Fianchi')),
      DataColumn(label: Text('Circonferenza Torace')),
      DataColumn(label: Text('Circonferenza Bicipiti')),
    ],
    rows: measurements.map((measurement) {
      return DataRow(
        cells: [
          DataCell(Text(DateFormat('dd/MM/yyyy').format(measurement.date))),
          DataCell(Text('${measurement.weight.toStringAsFixed(2)} kg')),
          DataCell(Text('${measurement.bodyFatPercentage.toStringAsFixed(2)}%')),
          DataCell(Text('${measurement.waistCircumference.toStringAsFixed(2)} cm')),
          DataCell(Text('${measurement.hipCircumference.toStringAsFixed(2)} cm')),
          DataCell(Text('${measurement.chestCircumference.toStringAsFixed(2)} cm')),
          DataCell(Text('${measurement.bicepsCircumference.toStringAsFixed(2)} cm')),
        ],
      );
    }).toList(),
  );
}

Widget _buildMobileMeasurementsTable(List<MeasurementModel> measurements) {
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: measurements.length,
    itemBuilder: (context, index) {
      final currentMeasurement = measurements[index];
      final previousMeasurement = index < measurements.length - 1 ? measurements[index + 1] : null;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data: ${DateFormat('dd/MM/yyyy').format(currentMeasurement.date)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              _buildMeasurementRow('Peso:', '${currentMeasurement.weight.toStringAsFixed(2)} kg', previousMeasurement?.weight),
              _buildMeasurementRow('Massa Grassa:', '${currentMeasurement.bodyFatPercentage.toStringAsFixed(2)}%', previousMeasurement?.bodyFatPercentage),
              _buildMeasurementRow('Circonferenza Vita:', '${currentMeasurement.waistCircumference.toStringAsFixed(2)} cm', previousMeasurement?.waistCircumference),
              _buildMeasurementRow('Circonferenza Fianchi:', '${currentMeasurement.hipCircumference.toStringAsFixed(2)} cm', previousMeasurement?.hipCircumference),
              _buildMeasurementRow('Circonferenza Torace:', '${currentMeasurement.chestCircumference.toStringAsFixed(2)} cm', previousMeasurement?.chestCircumference),
              _buildMeasurementRow('Circonferenza Bicipiti:', '${currentMeasurement.bicepsCircumference.toStringAsFixed(2)} cm', previousMeasurement?.bicepsCircumference),
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
      Text(label),
      Text('$value${delta != null ? ' ($sign${delta.toStringAsFixed(2)})' : ''}'),
    ],
  );
}



  Widget _buildMeasurementsList(UsersService usersService) {
    return StreamBuilder<List<MeasurementModel>>(
      stream: usersService.getMeasurements(userId: widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Errore: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final measurements = snapshot.data!;

          return ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              DataTable(
                columns: const [
                  DataColumn(label: Text('Data')),
                  DataColumn(label: Text('Peso')),
                  DataColumn(label: Text('Azioni')),
                ],
                rows: measurements.map((measurement) {
                  return DataRow(
                    cells: [
                      DataCell(Text(DateFormat('dd/MM/yyyy').format(measurement.date))),
                      DataCell(Text('${measurement.weight} kg')),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditMeasurementDialog(measurement),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _showDeleteConfirmationDialog(measurement),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          );
        } else {
          return const Text('Nessuna misurazione disponibile.');
        }
      },
    );
  }

  Widget _buildAddMeasurementExpansionPanel() {
    return ExpansionPanelList(
      expansionCallback: (index, isExpanded) {
        setState(() {
          _showAddMeasurementForm = !isExpanded;
        });
      },
      children: [
        ExpansionPanel(
          headerBuilder: (context, isExpanded) {
            return const ListTile(
              title: Text('Aggiungi Misurazione'),
            );
          },
          body: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    hintText: 'gg/mm/aaaa',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci una data';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci un peso';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Altezza (cm)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci un\'altezza';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _bodyFatController,
                  decoration: const InputDecoration(
                    labelText: 'Massa Grassa (%)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci una percentuale di massa grassa';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _waistController,
                  decoration: const InputDecoration(
                    labelText: 'Circonferenza Vita (cm)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci una circonferenza vita';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _hipController,
                  decoration: const InputDecoration(
                    labelText: 'Circonferenza Fianchi (cm)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci una circonferenza fianchi';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _chestController,
                  decoration: const InputDecoration(
                    labelText: 'Circonferenza Torace (cm)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci una circonferenza torace';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _bicepsController,
                  decoration: const InputDecoration(
                    labelText: 'Circonferenza Bicipiti (cm)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci una circonferenza bicipiti';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final usersService = ref.read(usersServiceProvider);
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
                        await usersService.addMeasurement(
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
                        await usersService.updateMeasurement(
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

                      setState(() {
                        _showAddMeasurementForm = false;
                      });
                      _resetForm();
                    }
                  },
                  child: Text(_editMeasurementId == null ? 'Aggiungi' : 'Aggiorna'),
                ),
              ],
            ),
          ),
          isExpanded: _showAddMeasurementForm,
        ),
      ],
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

    setState(() {
      _showAddMeasurementForm = true;
    });
  }

  void _showDeleteConfirmationDialog(MeasurementModel measurement) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Conferma Eliminazione'),
          content: const Text('Sei sicuro di voler eliminare questa misurazione?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                final usersService = ref.read(usersServiceProvider);
                usersService.deleteMeasurement(
                  userId: widget.userId,
                  measurementId: measurement.id,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Elimina'),
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
