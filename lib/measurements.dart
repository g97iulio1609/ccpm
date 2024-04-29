import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'users_services.dart';

class MeasurementsPage extends ConsumerWidget {
  final String userId;

  const MeasurementsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersService = ref.watch(usersServiceProvider);
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    final bodyFatPercentageController = TextEditingController();
    final waistCircumferenceController = TextEditingController();
    final hipCircumferenceController = TextEditingController();
    final chestCircumferenceController = TextEditingController();
    final bicepsCircumferenceController = TextEditingController();
    final dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    String? editMeasurementId;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Misurazioni',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<MeasurementModel>>(
                stream: usersService.getMeasurements(userId: userId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final measurements = snapshot.data!;
                    if (measurements.isNotEmpty) {
                      return ListView.builder(
                        itemCount: measurements.length,
                        itemBuilder: (context, index) {
                          final measurement = measurements[index];
                          return ListTile(
                            title: Text(
                              DateFormat('yyyy-MM-dd').format(measurement.date),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    weightController.text =
                                        measurement.weight.toStringAsFixed(2);
                                    heightController.text =
                                        measurement.height.toStringAsFixed(2);
                                    bodyFatPercentageController.text =
                                        measurement.bodyFatPercentage
                                            .toStringAsFixed(2);
                                    waistCircumferenceController.text =
                                        measurement.waistCircumference
                                            .toStringAsFixed(2);
                                    hipCircumferenceController.text =
                                        measurement.hipCircumference
                                            .toStringAsFixed(2);
                                    chestCircumferenceController.text =
                                        measurement.chestCircumference
                                            .toStringAsFixed(2);
                                    bicepsCircumferenceController.text =
                                        measurement.bicepsCircumference
                                            .toStringAsFixed(2);
                                    dateController.text =
                                        DateFormat('yyyy-MM-dd')
                                            .format(measurement.date);
                                    editMeasurementId = measurement.id;
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title:
                                            const Text('Elimina misurazione'),
                                        content: const Text(
                                            'Sei sicuro di voler eliminare questa misurazione?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text('Annulla'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              usersService.deleteMeasurement(
                                                userId: userId,
                                                measurementId: measurement.id,
                                              );
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Elimina'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    } else {
                      return const Center(
                        child: Text('Non sono disponibili misurazioni'),
                      );
                    }
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Errore: ${snapshot.error}'));
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Aggiungi/Modifica Misurazione',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: 'Data (yyyy-MM-dd)',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Peso (kg)',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Altezza (cm)',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bodyFatPercentageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Percentuale di Massa Grassa',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: waistCircumferenceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Circonferenza Vita (cm)',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hipCircumferenceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Circonferenza Fianchi (cm)',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: chestCircumferenceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Circonferenza Torace (cm)',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bicepsCircumferenceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Circonferenza Bicipiti (cm)',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final weight = double.tryParse(weightController.text) ?? 0.0;
                final height = double.tryParse(heightController.text) ?? 0.0;
                final bodyFatPercentage =
                    double.tryParse(bodyFatPercentageController.text) ?? 0.0;
                final waistCircumference =
                    double.tryParse(waistCircumferenceController.text) ?? 0.0;
                final hipCircumference =
                    double.tryParse(hipCircumferenceController.text) ?? 0.0;
                final chestCircumference =
                    double.tryParse(chestCircumferenceController.text) ?? 0.0;
                final bicepsCircumference =
                    double.tryParse(bicepsCircumferenceController.text) ?? 0.0;
                final dateString = dateController.text;

                final bmi = weight / (height / 100 * height / 100);
                final date = DateFormat('yyyy-MM-dd').parse(dateString);

                String? updatedMeasurementId;

                if (editMeasurementId != null) {
                  // Modifica la misurazione esistente
                  await usersService.updateMeasurement(
                    userId: userId,
                    measurementId: editMeasurementId!,
                    date: date,
                    weight: weight,
                    height: height,
                    bmi: bmi,
                    bodyFatPercentage: bodyFatPercentage,
                    waistCircumference: waistCircumference,
                    hipCircumference: hipCircumference,
                    chestCircumference: chestCircumference,
                    bicepsCircumference: bicepsCircumference,
                  );
                  updatedMeasurementId = editMeasurementId;
                } else {
                  // Aggiungi una nuova misurazione
                  updatedMeasurementId = await usersService.addMeasurement(
                    userId: userId,
                    date: date,
                    weight: weight,
                    height: height,
                    bmi: bmi,
                    bodyFatPercentage: bodyFatPercentage,
                    waistCircumference: waistCircumference,
                    hipCircumference: hipCircumference,
                    chestCircumference: chestCircumference,
                    bicepsCircumference: bicepsCircumference,
                  );
                }

                // Resetta i campi di input dopo l'aggiunta/modifica della misurazione
                weightController.clear();
                heightController.clear();
                bodyFatPercentageController.clear();
                waistCircumferenceController.clear();
                hipCircumferenceController.clear();
                chestCircumferenceController.clear();
                bicepsCircumferenceController.clear();
                dateController.text =
                    DateFormat('yyyy-MM-dd').format(DateTime.now());
                editMeasurementId = updatedMeasurementId;
              },
              child: const Text('Salva Misurazione'),
            ),
            const SizedBox(height: 32),
            Text(
              'Progresso Peso',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<MeasurementModel>>(
                stream: usersService.getMeasurements(userId: userId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final measurements = snapshot.data!;
                    if (measurements.isNotEmpty) {
                      return AspectRatio(
                        aspectRatio: 1.23,
                        child: LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: measurements
                                    .map((m) => FlSpot(
                                          m.date.millisecondsSinceEpoch
                                              .toDouble(),
                                          m.weight,
                                        ))
                                    .toList(),
                                isCurved: true,
                                barWidth: 4,
                                color: Theme.of(context).colorScheme.primary,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                ),
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                            minY: measurements
                                .map((m) => m.weight)
                                .reduce((a, b) => a < b ? a : b),
                            maxY: measurements
                                .map((m) => m.weight)
                                .reduce((a, b) => a > b ? a : b),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text(value.toStringAsFixed(1));
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final date =
                                        DateTime.fromMillisecondsSinceEpoch(
                                            value.toInt());
                                    return Text(
                                        DateFormat('MMM d').format(date));
                                  },
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.2),
                                strokeWidth: 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return const Center(
                        child: Text('Non sono disponibili misurazioni'),
                      );
                    }
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Errore: ${snapshot.error}'));
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
