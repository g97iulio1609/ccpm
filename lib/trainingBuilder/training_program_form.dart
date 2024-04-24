import 'package:alphanessone/trainingBuilder/athlete_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'controller/training_program_controller.dart';
import '../users_services.dart'; // Aggiungi questa importazione

class TrainingProgramForm extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final TrainingProgramController controller;
  final VoidCallback onSubmit;
  final Widget child;

  const TrainingProgramForm({
    required this.formKey,
    required this.controller,
    required this.onSubmit,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider); // Ottieni il ruolo dell'utente corrente

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: controller.nameController,
              decoration: const InputDecoration(labelText: 'Program Name'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a program name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a description' : null,
            ),
            const SizedBox(height: 16),
            if (userRole == 'admin') // Mostra il pulsante solo se l'utente è admin
              ElevatedButton(
                onPressed: () => _showAthleteSelectionDialog(context, ref),
                child: const Text('Select Athlete'),
              ),
            if (userRole == 'admin') const SizedBox(height: 16), // Aggiungi uno spazio se il pulsante è visibile
            TextFormField(
              controller: controller.mesocycleNumberController,
              decoration: const InputDecoration(labelText: 'Mesocycle Number'),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a mesocycle number' : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Hide Program'),
              value: controller.program.hide,
              onChanged: (value) {
                controller.updateHideProgram(value);
              },
            ),
            const SizedBox(height: 16),
            child,
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onSubmit,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAthleteSelectionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AthleteSelectionDialog(controller: controller),
    );
  }
}
