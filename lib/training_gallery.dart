import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/button.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';
import './trainingBuilder/providers/training_providers.dart';

class TrainingGalleryScreen extends HookConsumerWidget {
  const TrainingGalleryScreen({super.key});

  int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Future<void> setCurrentProgram(
    BuildContext context,
    WidgetRef ref,
    String programId,
    String programName,
  ) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final controller = ref.read(trainingProgramControllerProvider.notifier);
    final usersService = ref.read(usersServiceProvider);

    await controller
        .duplicateProgram(programId, programName, context, currentUserId: currentUserId)
        .then((newProgramId) async {
          if (newProgramId != null && currentUserId != null) {
            await usersService.updateUser(currentUserId, {'currentProgram': newProgramId});
          }
        });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userRole = ref.watch(userRoleProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final usersService = ref.read(usersServiceProvider);

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
            colors: [colorScheme.surface, colorScheme.surfaceContainerHighest.withAlpha(128)],
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
                              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
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
                                color: colorScheme.onSurfaceVariant.withAlpha(128),
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
                      delegate: SliverChildBuilderDelegate((context, rowIndex) {
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
                                          right: i < crossAxisCount - 1 ? AppTheme.spacing.xl : 0,
                                        ),
                                        child: FutureBuilder<String>(
                                          future: getAuthorName(rowPrograms[i]['athleteId'] ?? ''),
                                          builder: (context, snapshot) {
                                            final athleteName = snapshot.hasData
                                                ? snapshot.data!
                                                : 'Autore sconosciuto';
                                            return _buildProgramCard(
                                              context,
                                              rowPrograms[i],
                                              athleteName,
                                              userRole,
                                              currentUserId,
                                              colorScheme,
                                              theme,
                                              ref,
                                            );
                                          },
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
                      }),
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

  Widget _buildProgramCard(
    BuildContext context,
    DocumentSnapshot doc,
    String athleteName,
    String userRole,
    String? currentUserId,
    ColorScheme colorScheme,
    ThemeData theme,
    WidgetRef ref,
  ) {
    final programName = doc['name'] ?? 'Nome programma non disponibile';
    final mesocycleNumber = doc['mesocycleNumber'] ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(
            '/user_programs/training_viewer',
            extra: {'userId': currentUserId, 'programId': doc.id},
          ),
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
                    if (userRole == 'client_premium' || userRole == 'admin')
                      IconButton(
                        icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                        onPressed: () => _showProgramOptions(
                          context,
                          doc,
                          programName,
                          currentUserId,
                          colorScheme,
                          theme,
                          ref,
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
                  programName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: AppTheme.spacing.sm),

                // Autore
                Text(
                  'Creato da $athleteName',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Badge pubblico
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing.md,
                    vertical: AppTheme.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(76),
                    borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.public, size: 16, color: colorScheme.primary),
                      SizedBox(width: AppTheme.spacing.xs),
                      Text(
                        'Pubblico',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
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

  void _showProgramOptions(
    BuildContext context,
    DocumentSnapshot doc,
    String programName,
    String? currentUserId,
    ColorScheme colorScheme,
    ThemeData theme,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: programName,
        subtitle: 'Programma Pubblico',
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(76),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(Icons.fitness_center, color: colorScheme.primary, size: 24),
        ),
        items: [
          BottomMenuItem(
            title: 'Visualizza Programma',
            icon: Icons.visibility_outlined,
            onTap: () {
              Navigator.pop(context);
              context.go('/programs_screen/training_viewer/${doc.id}');
            },
          ),
          if (currentUserId != null)
            BottomMenuItem(
              title: 'Imposta come Programma Corrente',
              icon: Icons.check_circle_outline,
              onTap: () async {
                Navigator.pop(context);
                final bool? result = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return SetCurrentProgramDialog(programId: doc.id);
                  },
                );
                if (result == true && context.mounted) {
                  await setCurrentProgram(context, ref, doc.id, programName);
                }
              },
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppDialog(
      title: Text(
        'Imposta come Programma Corrente',
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        AppButton(
          label: 'Annulla',
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(label: 'Conferma', onPressed: () => Navigator.of(context).pop(true)),
      ],
      child: Text(
        'Sei sicuro di voler impostare questo programma come programma corrente? Questo sostituirà il tuo programma corrente.',
        style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
