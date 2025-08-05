// view_diet_plans_screen.dart

import 'package:alphanessone/nutrition/models/diet_plan_model.dart';
import 'package:alphanessone/nutrition/services/diet_plan_services.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class ViewDietPlansScreen extends ConsumerStatefulWidget {
  const ViewDietPlansScreen({super.key});

  @override
  ConsumerState<ViewDietPlansScreen> createState() =>
      _ViewDietPlansScreenState();
}

class _ViewDietPlansScreenState extends ConsumerState<ViewDietPlansScreen> {
  @override
  Widget build(BuildContext context) {
    final userService = ref.read(usersServiceProvider);
    final currentUserId = userService.getCurrentUserId();
    final selectedUserId = ref.read(selectedUserIdProvider);
    final userId = selectedUserId ?? currentUserId;
    final theme = Theme.of(context);

    final dietPlansStream = ref
        .watch(dietPlanServiceProvider)
        .getDietPlansStream(userId);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: StreamBuilder<List<DietPlan>>(
        stream: dietPlansStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final dietPlans = snapshot.data!;
            if (dietPlans.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(height: AppTheme.spacing.md),
                    Text(
                      'Nessun Piano Dietetico',
                      style: theme.textTheme.headlineSmall,
                    ),
                    SizedBox(height: AppTheme.spacing.sm),
                    Text(
                      'Crea il tuo primo piano dietetico',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              itemCount: dietPlans.length,
              itemBuilder: (context, index) {
                final dietPlan = dietPlans[index];
                return Card(
                  margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.all(AppTheme.spacing.md),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                dietPlan.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing.sm,
                                vertical: AppTheme.spacing.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(77),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radii.full,
                                ),
                              ),
                              child: Text(
                                '${dietPlan.durationDays} giorni',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: AppTheme.spacing.sm),
                            Text(
                              'Data Inizio: ${dietPlan.startDate.day}/${dietPlan.startDate.month}/${dietPlan.startDate.year}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: theme.colorScheme.onSurface,
                          ),
                          onSelected: (value) async {
                            if (value == 'delete') {
                              final confirm =
                                  await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text(
                                        'Elimina Piano Dietetico',
                                      ),
                                      content: const Text(
                                        'Sei sicuro di voler eliminare questo piano dietetico?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Annulla'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                theme.colorScheme.error,
                                          ),
                                          child: const Text('Elimina'),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;

                              if (confirm) {
                                await ref
                                    .read(dietPlanServiceProvider)
                                    .deleteDietPlan(userId, dietPlan.id!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Piano Dietetico Eliminato',
                                    ),
                                    backgroundColor: theme.colorScheme.error,
                                  ),
                                );
                              }
                            } else if (value == 'apply') {
                              await ref
                                  .read(dietPlanServiceProvider)
                                  .applyDietPlan(dietPlan);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Piano Dietetico Applicato',
                                  ),
                                  backgroundColor: theme.colorScheme.primary,
                                ),
                              );
                            } else if (value == 'duplicate') {
                              final newName = await _promptForDuplicateName(
                                context,
                                dietPlan.name,
                              );
                              if (newName != null && newName.isNotEmpty) {
                                try {
                                  await ref
                                      .read(dietPlanServiceProvider)
                                      .duplicateDietPlan(
                                        userId,
                                        dietPlan.id!,
                                        newName: newName,
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Piano Dietetico Duplicato come "$newName"',
                                      ),
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Errore: ${e.toString()}'),
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            } else if (value == 'edit') {
                              _navigateToEditDietPlan(context, dietPlan);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'apply',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check,
                                    color: theme.colorScheme.primary,
                                  ),
                                  SizedBox(width: AppTheme.spacing.sm),
                                  const Text('Applica'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'duplicate',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.copy,
                                    color: theme.colorScheme.primary,
                                  ),
                                  SizedBox(width: AppTheme.spacing.sm),
                                  const Text('Duplica'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    color: theme.colorScheme.primary,
                                  ),
                                  SizedBox(width: AppTheme.spacing.sm),
                                  const Text('Modifica'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: theme.colorScheme.error,
                                  ),
                                  SizedBox(width: AppTheme.spacing.sm),
                                  Text(
                                    'Elimina',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _navigateToEditDietPlan(context, dietPlan),
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  SizedBox(height: AppTheme.spacing.md),
                  Text(
                    'Errore: ${snapshot.error}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToNewDietPlan(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuovo Piano'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  /// Mostra un dialogo per inserire il nuovo nome del piano dietetico duplicato
  Future<String?> _promptForDuplicateName(
    BuildContext context,
    String originalName,
  ) async {
    String? newName;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Duplicate Diet Plan',
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'New Diet Plan Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              newName = value;
            },
            controller: TextEditingController(text: '$originalName (Copy)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.roboto()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(newName),
              child: Text('Duplicate', style: GoogleFonts.roboto()),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditDietPlan(BuildContext context, DietPlan dietPlan) {
    context.go('/food_tracker/diet_plan/edit', extra: {'dietPlan': dietPlan});
  }

  void _navigateToNewDietPlan(BuildContext context) {
    context.go('/food_tracker/diet_plan');
  }
}
