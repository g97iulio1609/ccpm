// view_diet_plans_screen.dart

import 'package:alphanessone/nutrition/models/diet_plan_model.dart';
import 'package:alphanessone/nutrition/services/diet_plan_services.dart';
import 'package:alphanessone/nutrition/models/meals_model.dart';
import 'package:alphanessone/nutrition/services/meals_services.dart';
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
    final currentUserRole = userService.getCurrentUserRole();
    final selectedUserId = ref.read(selectedUserIdProvider);
    final userId = selectedUserId ?? currentUserId;
    final theme = Theme.of(context);

    final dietPlansStream =
        ref.watch(dietPlanServiceProvider).getDietPlansStream(userId);
    final isAdminOrCoach =
        currentUserRole == 'admin' || currentUserRole == 'coach';

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
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radii.full),
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
                              final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Elimina Piano Dietetico'),
                                      content: Text(
                                          'Sei sicuro di voler eliminare questo piano dietetico?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: Text('Annulla'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                theme.colorScheme.error,
                                          ),
                                          child: Text('Elimina'),
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
                                    content: Text('Piano Dietetico Eliminato'),
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
                                  content: Text('Piano Dietetico Applicato'),
                                  backgroundColor: theme.colorScheme.primary,
                                ),
                              );
                            } else if (value == 'duplicate') {
                              final newName = await _promptForDuplicateName(
                                  context, dietPlan.name);
                              if (newName != null && newName.isNotEmpty) {
                                try {
                                  final duplicatedId = await ref
                                      .read(dietPlanServiceProvider)
                                      .duplicateDietPlan(userId, dietPlan.id!,
                                          newName: newName);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Piano Dietetico Duplicato come "$newName"'),
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
                              context.go('/food_tracker/diet_plan/edit',
                                  extra: dietPlan);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'apply',
                              child: Row(
                                children: [
                                  Icon(Icons.check,
                                      color: theme.colorScheme.primary),
                                  SizedBox(width: AppTheme.spacing.sm),
                                  Text('Applica'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'duplicate',
                              child: Row(
                                children: [
                                  Icon(Icons.copy,
                                      color: theme.colorScheme.primary),
                                  SizedBox(width: AppTheme.spacing.sm),
                                  Text('Duplica'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit,
                                      color: theme.colorScheme.primary),
                                  SizedBox(width: AppTheme.spacing.sm),
                                  Text('Modifica'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      color: theme.colorScheme.error),
                                  SizedBox(width: AppTheme.spacing.sm),
                                  Text('Elimina',
                                      style: TextStyle(
                                          color: theme.colorScheme.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showDietPlanDetails(context, dietPlan),
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
        onPressed: () => context.go('/food_tracker/diet_plan'),
        icon: Icon(Icons.add),
        label: Text('Nuovo Piano'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  /// Mostra un dialogo per inserire il nuovo nome del piano dietetico duplicato
  Future<String?> _promptForDuplicateName(
      BuildContext context, String originalName) async {
    String? newName;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Duplicate Diet Plan',
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
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

  /// Seleziona un template da applicare
  Future<DietPlan?> _selectTemplate(BuildContext context) async {
    final userService = ref.read(usersServiceProvider);
    final adminId = userService.getCurrentUserId();
    final templates = await ref
        .read(dietPlanServiceProvider)
        .getDietPlanTemplatesStream(adminId)
        .first;

    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No templates available')));
      return null;
    }

    return showDialog<DietPlan>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select a Template',
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return ListTile(
                  title: Text(template.name, style: GoogleFonts.roboto()),
                  subtitle: Text('Duration: ${template.durationDays} days',
                      style: GoogleFonts.roboto()),
                  onTap: () => Navigator.of(context).pop(template),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.roboto()),
            ),
          ],
        );
      },
    );
  }

  /// Mostra i dettagli del piano dietetico in un dialogo
  void _showDietPlanDetails(BuildContext context, DietPlan dietPlan) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(dietPlan.name,
              style: GoogleFonts.roboto(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Start Date: ${dietPlan.startDate.day}/${dietPlan.startDate.month}/${dietPlan.startDate.year}',
                    style: GoogleFonts.roboto()),
                Text('Duration: ${dietPlan.durationDays} days',
                    style: GoogleFonts.roboto()),
                const SizedBox(height: 16),
                Text('Daily Plans:',
                    style: GoogleFonts.roboto(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                ...dietPlan.days.map((day) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(day.dayOfWeek,
                              style: GoogleFonts.roboto(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          ...day.mealIds.map((mealId) => FutureBuilder<Meal?>(
                                future: ref
                                    .read(mealsServiceProvider)
                                    .getMealById(dietPlan.userId, mealId),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text('- Loading...',
                                        style:
                                            GoogleFonts.roboto(fontSize: 14));
                                  } else if (snapshot.hasError) {
                                    return Text('- Error loading meal',
                                        style: GoogleFonts.roboto(
                                            fontSize: 14, color: Colors.red));
                                  } else if (!snapshot.hasData ||
                                      snapshot.data == null) {
                                    return Text('- Meal not found',
                                        style: GoogleFonts.roboto(
                                            fontSize: 14, color: Colors.red));
                                  } else {
                                    final meal = snapshot.data!;
                                    return Text(
                                        '- ${meal.mealType} (${meal.totalCalories} kcal)',
                                        style:
                                            GoogleFonts.roboto(fontSize: 14));
                                  }
                                },
                              )),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: GoogleFonts.roboto()),
            ),
          ],
        );
      },
    );
  }
}
