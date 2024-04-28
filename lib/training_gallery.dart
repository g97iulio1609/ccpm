import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'users_services.dart';
import './trainingBuilder/controller/training_program_controller.dart';

class TrainingGalleryScreen extends HookConsumerWidget {
  const TrainingGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final usersService = ref.read(usersServiceProvider);

    Future<void> setCurrentProgram(String programId, String programName) async {
      final controller = ref.read(trainingProgramControllerProvider);
      await controller.duplicateProgram(programId, programName, context, currentUserId: currentUserId).then((newProgramId) async {
        if (newProgramId != null && currentUserId != null) {
          await usersService.updateUser(currentUserId, {'currentProgram': newProgramId});
        }
      });
    }

    Future<String> getAuthorName(String authorId) async {
      final user = await usersService.getUserById(authorId);
      return user?.name ?? 'Autore sconosciuto';
    }

    Stream<QuerySnapshot> getPublicProgramsStream() {
      final query = FirebaseFirestore.instance
          .collection('programs')
          .where('hide', isEqualTo: false);

      return query.snapshots();
    }

    return Scaffold(
  
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getPublicProgramsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Si è verificato un errore'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final documents = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    final programName = doc['name'] ?? 'Nome programma non disponibile';
                    final authorId = doc['athleteId'] ?? '';

                    return FutureBuilder<String>(
                      future: getAuthorName(authorId),
                      builder: (context, snapshot) {
                        final athleteName = snapshot.hasData
                            ? snapshot.data!
                            : 'Autore sconosciuto';

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          color: Theme.of(context).colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  programName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Autore: $athleteName',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (userRole == 'client_premium' || userRole == 'admin')
                                      ElevatedButton(
                                        onPressed: () async {
                                          final bool? result = await showDialog<bool>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return SetCurrentProgramDialog(programId: doc.id);
                                            },
                                          );
                                          if (result == true && currentUserId != null) {
                                            await setCurrentProgram(doc.id, programName);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                        ),
                                        child: const Text('Imposta come Corrente'),
                                      ),
                                    const SizedBox(width: 8.0),
                                    OutlinedButton(
                                      onPressed: () => context.go(
                                          '/programs_screen/training_viewer/${doc.id}'),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      child: Text(
                                        'Visualizza',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SetCurrentProgramDialog extends StatelessWidget {
  final String programId;

  const SetCurrentProgramDialog({super.key, required this.programId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Imposta come Programma Corrente'),
      content: const Text(
          'Sei sicuro di voler impostare questo programma come programma corrente? Questo sostituirà il tuo programma corrente.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text('Conferma'),
        ),
      ],
    );
  }
}