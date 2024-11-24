import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/providers/providers.dart';
import './trainingBuilder/controller/training_program_controller.dart';
import './trainingBuilder/services/training_services.dart';
import 'UI/components/card.dart';

class UserProgramsScreen extends HookConsumerWidget {
  final String userId;

  const UserProgramsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.92),
            ],
          ),
        ),
        child: Column(
          children: [
            if (userRole == 'admin' || userRole == 'client_premium' || userRole == 'coach')
              _buildAddProgramButton(context, userId),
            Expanded(
              child: _buildProgramList(context, ref, userId, userRole, firestoreService),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProgramButton(BuildContext context, String userId) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: MaterialButton(
          onPressed: () => _addProgram(context, userId),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Crea Programma Di Allenamento',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramList(BuildContext context, WidgetRef ref, String userId,
      String userRole, FirestoreService firestoreService) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getProgramsStream(userId, userRole),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Si è verificato un errore: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nessun programma trovato'));
        }

        final documents = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          itemCount: documents.length,
          itemBuilder: (context, index) =>
              _buildProgramCard(context, ref, documents[index], userId, userRole, firestoreService),
        );
      },
    );
  }

  Widget _buildProgramCard(BuildContext context, WidgetRef ref,
      DocumentSnapshot doc, String userId, String userRole, FirestoreService firestoreService) {
    final theme = Theme.of(context);
    final isHidden = doc['hide'] ?? false;
    final controller = ref.read(trainingProgramControllerProvider);
    final mesocycleNumber = doc['mesocycleNumber'] ?? 1;

    return ActionCard(
      onTap: () => context.go('/user_programs/$userId/training_viewer/${doc.id}'),
      title: Text(
        doc['name'],
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      subtitle: Text(
        'Mesociclo $mesocycleNumber',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        if (userRole == 'admin' || userRole == 'coach')
          IconButtonWithBackground(
            icon: isHidden ? Icons.visibility_off : Icons.visibility,
            color: theme.colorScheme.primary,
            onPressed: () => _toggleProgramVisibility(doc.id, isHidden),
          ),
        if (userRole == 'admin' || userRole == 'client_premium' || userRole == 'coach')
          IconButtonWithBackground(
            icon: Icons.more_vert,
            color: theme.colorScheme.primary,
            onPressed: () => _showProgramOptions(
              context,
              doc,
              userId,
              controller,
              firestoreService,
              theme,
            ),
          ),
      ],
      bottomContent: isHidden && (userRole == 'admin' || userRole == 'coach')
          ? [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_off,
                      size: 16,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Nascosto',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ]
          : null,
    );
  }

  void _showProgramOptions(
    BuildContext context,
    DocumentSnapshot doc,
    String userId,
    TrainingProgramController controller,
    FirestoreService firestoreService,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => CustomCard(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionTile(
              context,
              'Modifica',
              Icons.edit_outlined,
              () {
                Navigator.pop(context);
                context.go('/user_programs/$userId/training_program/${doc.id}');
              },
            ),
            _buildOptionTile(
              context,
              'Duplica',
              Icons.content_copy,
              () {
                Navigator.pop(context);
                _duplicateProgram(context, doc.id, controller);
              },
            ),
            _buildOptionTile(
              context,
              'Elimina',
              Icons.delete_outline,
              () {
                Navigator.pop(context);
                _deleteProgram(context, doc.id, firestoreService);
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }

  Stream<QuerySnapshot> _getProgramsStream(String userId, String userRole) {
    Query query = FirebaseFirestore.instance
        .collection('programs')
        .where('athleteId', isEqualTo: userId);
    
    if (userRole != 'admin') {
      query = query.where('hide', isNotEqualTo: true);
    }
    
    return query.orderBy('mesocycleNumber', descending: false).snapshots();
  }

  Future<void> _addProgram(BuildContext context, String userId) async {
    final programDetails = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddProgramDialog(userId: userId),
    );

    if (programDetails != null) {
      await FirebaseFirestore.instance.collection('programs').add({
        'name': programDetails['name'],
        'description': programDetails['description'],
        'mesocycleNumber': programDetails['mesocycleNumber'],
        'athleteId': userId,
        'hide': false,
      });
    }
  }

  Future<void> _deleteProgram(BuildContext context, String id, FirestoreService firestoreService) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma eliminazione'),
          content: const Text('Sei sicuro di voler eliminare questo programma?'),
          actions: [
            TextButton(
              child: const Text('Annulla'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            FilledButton(
              child: const Text('Elimina'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await firestoreService.removeProgram(id);
    }
  }

  Future<void> _toggleProgramVisibility(String id, bool currentVisibility) async {
    await FirebaseFirestore.instance.collection('programs').doc(id).update({
      'hide': !currentVisibility,
    });
  }

  Future<void> _duplicateProgram(BuildContext context, String docId, TrainingProgramController controller) async {
    String? newProgramName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Duplica Programma'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nuovo Nome del Programma',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (newProgramName != null && newProgramName.isNotEmpty) {
      try {
        final result = await controller.duplicateProgram(docId, newProgramName, context);
        if (context.mounted) {
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Programma duplicato con successo: $newProgramName')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Errore durante la duplicazione del programma')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore durante la duplicazione del programma: $e')),
          );
        }
      }
    }
  }
}

class AddProgramDialog extends StatefulWidget {
  final String userId;

  const AddProgramDialog({super.key, required this.userId});

  @override
  AddProgramDialogState createState() => AddProgramDialogState();
}

class AddProgramDialogState extends State<AddProgramDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _mesocycleNumber = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuovo Programma'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci un nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrizione',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _mesocycleNumber,
              decoration: const InputDecoration(
                labelText: 'Numero Mesociclo',
              ),
              items: List.generate(12, (index) => index + 1)
                  .map((number) => DropdownMenuItem(
                        value: number,
                        child: Text(number.toString()),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _mesocycleNumber = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Crea'),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final programDetails = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'mesocycleNumber': _mesocycleNumber,
        'athleteId': widget.userId,
      };
      Navigator.of(context).pop(programDetails);
    }
  }
}