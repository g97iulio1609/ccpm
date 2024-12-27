import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/providers/providers.dart';
import './trainingBuilder/controller/training_program_controller.dart';
import './trainingBuilder/services/training_services.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'UI/components/bottom_menu.dart';

class UserProgramsScreen extends HookConsumerWidget {
  final String userId;

  const UserProgramsScreen({super.key, required this.userId});

  int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withAlpha(128),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Add Program Button (if applicable)
              if (userRole == 'admin' ||
                  userRole == 'client_premium' ||
                  userRole == 'coach')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacing.xl),
                    child: _buildAddProgramButton(
                        context, userId, theme, colorScheme),
                  ),
                ),

              // Programs Grid
              SliverPadding(
                padding: EdgeInsets.all(AppTheme.spacing.xl),
                sliver: _buildProgramList(
                    context, ref, userId, userRole, firestoreService),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddProgramButton(BuildContext context, String userId,
      ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withAlpha(204),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addProgram(context, userId),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppTheme.spacing.lg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
                SizedBox(width: AppTheme.spacing.sm),
                Text(
                  'Create New Program',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramCard(
    BuildContext context,
    WidgetRef ref,
    DocumentSnapshot doc,
    String userId,
    String userRole,
    FirestoreService firestoreService,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isHidden = doc['hide'] ?? false;
    final controller = ref.read(trainingProgramControllerProvider);
    final mesocycleNumber = doc['mesocycleNumber'] ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withAlpha(26),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToTrainingViewer(context, userId, doc.id),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con badge e menu
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.md,
                        vertical: AppTheme.spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withAlpha(76),
                        borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
                      ),
                      child: Text(
                        'Mesocycle $mesocycleNumber',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (userRole == 'admin' ||
                        userRole == 'coach' ||
                        userRole == 'client_premium')
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => _showProgramOptions(
                          context,
                          doc,
                          userId,
                          controller,
                          firestoreService,
                          theme,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),

                SizedBox(height: AppTheme.spacing.lg),

                // Nome programma
                Text(
                  doc['name'],
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                if (doc['description']?.isNotEmpty ?? false) ...[
                  SizedBox(height: AppTheme.spacing.sm),
                  Text(
                    doc['description'],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const Spacer(),

                // Hidden badge (se applicabile)
                if (isHidden && (userRole == 'admin' || userRole == 'coach'))
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.md,
                      vertical: AppTheme.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_off,
                          size: 16,
                          color: colorScheme.onErrorContainer,
                        ),
                        SizedBox(width: AppTheme.spacing.xs),
                        Text(
                          'Hidden',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
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
          return SliverToBoxAdapter(
            child: Center(
              child: Text(
                'Si è verificato un errore: ${snapshot.error}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final documents = snapshot.data?.docs ?? [];
        if (documents.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withAlpha(128),
                  ),
                  SizedBox(height: AppTheme.spacing.md),
                  Text(
                    'Nessun programma trovato',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  Text(
                    'Inizia creando un nuovo programma',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withAlpha(179),
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        // Calcola il numero di colonne
        final crossAxisCount = getGridCrossAxisCount(context);

        // Organizza i programmi in righe
        final rows = <List<DocumentSnapshot>>[];
        for (var i = 0; i < documents.length; i += crossAxisCount) {
          rows.add(
            documents.sublist(
              i,
              i + crossAxisCount > documents.length
                  ? documents.length
                  : i + crossAxisCount,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, rowIndex) {
              if (rowIndex >= rows.length) return null;

              final rowPrograms = rows[rowIndex];

              return Padding(
                padding: EdgeInsets.only(bottom: AppTheme.spacing.xl),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < crossAxisCount; i++) ...[
                        if (i < rowPrograms.length)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: i < crossAxisCount - 1
                                    ? AppTheme.spacing.xl
                                    : 0,
                              ),
                              child: _buildProgramCard(
                                context,
                                ref,
                                rowPrograms[i],
                                userId,
                                userRole,
                                firestoreService,
                              ),
                            ),
                          )
                        else
                          Expanded(child: Container()),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
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
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: doc['name'],
        subtitle: doc['description'] ?? '',
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(76),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(
            Icons.fitness_center,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        items: [
          BottomMenuItem(
            title: 'Modifica Programma',
            icon: Icons.edit_outlined,
            onTap: () {
              context.go('/user_programs/training_program',
                  extra: {'userId': userId, 'programId': doc.id});
            },
          ),
          BottomMenuItem(
            title: 'Duplica Programma',
            icon: Icons.content_copy_outlined,
            onTap: () {
              _duplicateProgram(context, doc.id, controller);
            },
          ),
          BottomMenuItem(
            title: 'Cambia Visibilità',
            icon: doc['hide'] ? Icons.visibility : Icons.visibility_off,
            onTap: () {
              _toggleProgramVisibility(doc.id, doc['hide'] ?? false);
            },
          ),
          BottomMenuItem(
            title: 'Elimina Programma',
            icon: Icons.delete_outline,
            onTap: () {
              _deleteProgram(context, doc.id, firestoreService);
            },
            isDestructive: true,
          ),
        ],
      ),
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

  Future<void> _deleteProgram(BuildContext context, String id,
      FirestoreService firestoreService) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma eliminazione'),
          content:
              const Text('Sei sicuro di voler eliminare questo programma?'),
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

  Future<void> _toggleProgramVisibility(
      String id, bool currentVisibility) async {
    await FirebaseFirestore.instance.collection('programs').doc(id).update({
      'hide': !currentVisibility,
    });
  }

  Future<void> _duplicateProgram(BuildContext context, String docId,
      TrainingProgramController controller) async {
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
              onPressed: () =>
                  Navigator.of(context).pop(nameController.text.trim()),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (newProgramName != null && newProgramName.isNotEmpty) {
      try {
        final result =
            await controller.duplicateProgram(docId, newProgramName, context);
        if (context.mounted) {
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Programma duplicato con successo: $newProgramName')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Errore durante la duplicazione del programma')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Errore durante la duplicazione del programma: $e')),
          );
        }
      }
    }
  }

  void _navigateToTrainingViewer(
      BuildContext context, String? userId, String? programId) {
    if (userId == null || programId == null) return;

    context.go('/user_programs/training_viewer',
        extra: {'userId': userId, 'programId': programId});
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radii.xl),
      ),
      title: Text(
        'Create New Program',
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Program Name',
              hint: 'Enter program name',
              icon: Icons.title,
              theme: theme,
              colorScheme: colorScheme,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            SizedBox(height: AppTheme.spacing.md),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Enter program description',
              icon: Icons.description,
              theme: theme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: AppTheme.spacing.md),
            _buildMesocycleDropdown(theme, colorScheme),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: colorScheme.primary),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withAlpha(204),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _submitForm,
              borderRadius: BorderRadius.circular(AppTheme.radii.md),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing.lg,
                  vertical: AppTheme.spacing.sm,
                ),
                child: Text(
                  'Create',
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
          borderSide: BorderSide(
            color: colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
          borderSide: BorderSide(
            color: colorScheme.outline.withAlpha(76),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
    );
  }

  Widget _buildMesocycleDropdown(ThemeData theme, ColorScheme colorScheme) {
    return DropdownButtonFormField<int>(
      value: _mesocycleNumber,
      decoration: InputDecoration(
        labelText: 'Mesocycle Number',
        prefixIcon: Icon(Icons.fitness_center, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
          borderSide: BorderSide(
            color: colorScheme.outline.withAlpha(76),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
      items: List.generate(12, (index) => index + 1)
          .map((number) => DropdownMenuItem(
                value: number,
                child: Text(
                  number.toString(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _mesocycleNumber = value!;
        });
      },
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
