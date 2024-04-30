import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'users_services.dart';

class MeasurementsList extends StatelessWidget {
  final UsersService usersService;
  final String userId;
  final Function(MeasurementModel) onEdit;
  final Function(MeasurementModel) onDelete;

  const MeasurementsList({
    super.key,
    required this.usersService,
    required this.userId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MeasurementModel>>(
      stream: usersService.getMeasurements(userId: userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final measurements = snapshot.data!;
          return ListView.builder(
            itemCount: measurements.length,
            itemBuilder: (context, index) {
              final measurement = measurements[index];
              return _buildMeasurementItem(measurement);
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}'));
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildMeasurementItem(MeasurementModel measurement) {
    return ListTile(
      title: Text(DateFormat('yyyy-MM-dd').format(measurement.date)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Peso: ${measurement.weight.toStringAsFixed(2)} kg'),
          Text('Altezza: ${measurement.height.toStringAsFixed(2)} cm'),
          Text('BMI: ${measurement.bmi.toStringAsFixed(2)}'),
          Text(
              'Massa Grassa: ${measurement.bodyFatPercentage.toStringAsFixed(2)}%'),
          Text(
              'Vita: ${measurement.waistCircumference.toStringAsFixed(2)} cm'),
          Text(
              'Fianchi: ${measurement.hipCircumference.toStringAsFixed(2)} cm'),
          Text(
              'Torace: ${measurement.chestCircumference.toStringAsFixed(2)} cm'),
          Text(
              'Bicipiti: ${measurement.bicepsCircumference.toStringAsFixed(2)} cm'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => onEdit(measurement),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => onDelete(measurement),
          ),
        ],
      ),
    );
  }
}