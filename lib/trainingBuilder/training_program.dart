import 'package:alphanessone/trainingBuilder/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/dialog/athlete_selection_dialog.dart';
import 'package:alphanessone/trainingBuilder/List/week_list.dart';
import 'package:alphanessone/trainingBuilder/List/workout_list.dart';
import 'package:alphanessone/trainingBuilder/List/exercise_list.dart';
import 'package:alphanessone/providers/providers.dart';

class TrainingProgramPage extends HookConsumerWidget {
  final String programId;
  final String userId;
  final int? weekIndex;
  final int? workoutIndex;

  const TrainingProgramPage({
    super.key,
    required this.programId,
    required this.userId,
    this.weekIndex,
    this.workoutIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final controller = ref.watch(trainingProgramControllerProvider);
    final program = ref.watch(trainingProgramStateProvider);
    final userRole = ref.watch(userRoleProvider);

    useEffect(() {
      if (programId.isNotEmpty && program.id != programId) {
        controller.loadProgram(programId);
      }
      return null;
    }, [programId]);

    return Scaffold(
      backgroundColor: Colors.black,
      body: program != null
          ? weekIndex != null
              ? workoutIndex != null
                  ? TrainingProgramExerciseList(
                      controller: controller,
                      weekIndex: weekIndex!,
                      workoutIndex: workoutIndex!,
                    )
                  : TrainingProgramWorkoutListPage(
                      controller: controller,
                      weekIndex: weekIndex!,
                    )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 48),
                        const Text(
                          'Crea Programma',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: controller.nameController,
                          decoration: InputDecoration(
                            labelText: 'Nome Programma',
                            labelStyle: const TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) => value?.isEmpty ?? true ? 'Inserisci un nome per il programma' : null,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: controller.descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Descrizione',
                            labelStyle: const TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) => value?.isEmpty ?? true ? 'Inserisci una descrizione' : null,
                        ),
                        const SizedBox(height: 24),
                        if (userRole == 'admin')
                          ElevatedButton.icon(
                            onPressed: () => _showAthleteSelectionDialog(context, ref, controller),
                            icon: const Icon(Icons.person_add),
                            label: const Text(
                              'Seleziona Atleta',
                              style: TextStyle(fontSize: 18),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        if (userRole == 'admin') const SizedBox(height: 24),
                        TextFormField(
                          controller: controller.mesocycleNumberController,
                          decoration: InputDecoration(
                            labelText: 'Numero Mesociclo',
                            labelStyle: const TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty ?? true ? 'Inserisci un numero di mesociclo' : null,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Text(
                              'Nascondi Programma',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: controller.program.hide,
                              onChanged: (value) => controller.updateHideProgram(value),
                              activeColor: Colors.white,
                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Text(
                              'Programma Pubblico',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: controller.program.status == 'public',
                              onChanged: (value) => controller.updateProgramStatus(value ? 'public' : 'private'),
                              activeColor: Colors.white,
                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Settimane del Programma',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TrainingProgramWeekList(
                          programId: programId,
                          userId: userId,
                          controller: controller,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: controller.addWeek,
                                icon: const Icon(Icons.add),
                                label: const Text(
                                  'Aggiungi Settimana',
                                  style: TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => controller.submitProgram(context),
                                icon: const Icon(Icons.save),
                                label: const Text(
                                  'Salva Programma',
                                  style: TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                )
          : const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
    );
  }

  void _showAthleteSelectionDialog(BuildContext context, WidgetRef ref, TrainingProgramController controller) {
    showDialog(
      context: context,
      builder: (context) => AthleteSelectionDialog(controller: controller),
    );
  }
}
