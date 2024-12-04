import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/button.dart';
import './trainingBuilder/controller/training_program_controller.dart';

class TrainingGalleryScreen extends HookConsumerWidget {
  const TrainingGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userRole = ref.watch(userRoleProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final usersService = ref.read(usersServiceProvider);

    Future<void> setCurrentProgram(String programId, String programName) async {
      final controller = ref.read(trainingProgramControllerProvider);
      await controller
          .duplicateProgram(programId, programName, context,
              currentUserId: currentUserId)
          .then((newProgramId) async {
        if (newProgramId != null && currentUserId != null) {
          await usersService
              .updateUser(currentUserId, {'currentProgram': newProgramId});
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
          .where('status', isEqualTo: 'public');

      return query.snapshots();
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(AppTheme.spacing.xl),
                sliver: StreamBuilder<QuerySnapshot>(
                  stream: getPublicProgramsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: colorScheme.error,
                              ),
                              SizedBox(height: AppTheme.spacing.md),
                              Text(
                                'Si è verificato un errore',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fitness_center_outlined,
                                size: 64,
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.5),
                              ),
                              SizedBox(height: AppTheme.spacing.md),
                              Text(
                                'Nessun Programma Disponibile',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: AppTheme.spacing.sm),
                              Text(
                                'Al momento non ci sono programmi nella galleria',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final crossAxisCount =
                        switch (MediaQuery.of(context).size.width) {
                      > 1200 => 3, // Desktop large
                      > 900 => 2, // Desktop
                      > 600 => 2, // Tablet
                      _ => 1, // Mobile
                    };

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: crossAxisCount == 1 ? 1.2 : 1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = documents[index];
                          final programName =
                              doc['name'] ?? 'Nome programma non disponibile';
                          final authorId = doc['athleteId'] ?? '';
                          final mesocycleNumber = doc['mesocycleNumber'] ?? 1;

                          return FutureBuilder<String>(
                            future: getAuthorName(authorId),
                            builder: (context, snapshot) {
                              final athleteName = snapshot.hasData
                                  ? snapshot.data!
                                  : 'Autore sconosciuto';

                              return Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radii.lg),
                                  border: Border.all(
                                    color: colorScheme.outline.withOpacity(0.1),
                                  ),
                                  boxShadow: AppTheme.elevations.small,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radii.lg),
                                  child: InkWell(
                                    onTap: () => context.go(
                                        '/user_programs/training_viewer',
                                        extra: {
                                          'userId': currentUserId,
                                          'programId': doc.id
                                        }),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radii.lg),
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(AppTheme.spacing.lg),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Program Badge
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: AppTheme.spacing.md,
                                              vertical: AppTheme.spacing.xs,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .primaryContainer
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppTheme.radii.xxl),
                                            ),
                                            child: Text(
                                              'Mesocycle $mesocycleNumber',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),

                                          SizedBox(height: AppTheme.spacing.md),

                                          Text(
                                            programName,
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.5,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          SizedBox(height: AppTheme.spacing.sm),
                                          Text(
                                            'Creato da $athleteName',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          SizedBox(height: AppTheme.spacing.lg),

                                          // Action Buttons Row
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              if (userRole ==
                                                      'client_premium' ||
                                                  userRole == 'admin')
                                                _buildActionButton(
                                                  icon: Icons
                                                      .check_circle_outline,
                                                  label: 'Imposta',
                                                  onTap: () async {
                                                    final bool? result =
                                                        await showDialog<bool>(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return SetCurrentProgramDialog(
                                                            programId: doc.id);
                                                      },
                                                    );
                                                    if (result == true &&
                                                        currentUserId != null) {
                                                      await setCurrentProgram(
                                                          doc.id, programName);
                                                    }
                                                  },
                                                  colorScheme: colorScheme,
                                                  theme: theme,
                                                ),
                                              SizedBox(
                                                  width: AppTheme.spacing.sm),
                                              _buildActionButton(
                                                icon: Icons.visibility_outlined,
                                                label: 'Visualizza',
                                                onTap: () => context.go(
                                                    '/programs_screen/training_viewer/${doc.id}'),
                                                colorScheme: colorScheme,
                                                theme: theme,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: documents.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.md,
            vertical: AppTheme.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: colorScheme.primary,
              ),
              SizedBox(width: AppTheme.spacing.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SetCurrentProgramDialog extends StatelessWidget {
  final String programId;

  const SetCurrentProgramDialog({super.key, required this.programId});

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
        'Imposta come Programma Corrente',
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        'Sei sicuro di voler impostare questo programma come programma corrente? Questo sostituirà il tuo programma corrente.',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        AppButton(
          label: 'Annulla',
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: 'Conferma',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
