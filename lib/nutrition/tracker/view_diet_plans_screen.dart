import 'package:alphanessone/nutrition/models&Services/diet_plan_model.dart';
import 'package:alphanessone/nutrition/models&Services/diet_plan_services.dart';
import 'package:alphanessone/nutrition/models&Services/meals_model.dart';
import 'package:alphanessone/nutrition/models&Services/meals_services.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewDietPlansScreen extends ConsumerStatefulWidget {
  const ViewDietPlansScreen({super.key});

  @override
  ConsumerState<ViewDietPlansScreen> createState() => _ViewDietPlansScreenState();
}

class _ViewDietPlansScreenState extends ConsumerState<ViewDietPlansScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = ref.read(usersServiceProvider).getCurrentUserId();
    final dietPlansStream = ref.watch(dietPlanServiceProvider).getDietPlansStream(userId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Diet Plans', style: GoogleFonts.roboto()),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<List<DietPlan>>(
        stream: dietPlansStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final dietPlans = snapshot.data!;
            if (dietPlans.isEmpty) {
              return Center(child: Text('No Diet Plans Found', style: GoogleFonts.roboto()));
            }
            return ListView.builder(
              itemCount: dietPlans.length,
              itemBuilder: (context, index) {
                final dietPlan = dietPlans[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                      dietPlan.name,
                      style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Start Date: ${dietPlan.startDate.day}/${dietPlan.startDate.month}/${dietPlan.startDate.year}\nDuration: ${dietPlan.durationDays} days',
                      style: GoogleFonts.roboto(),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await ref.read(dietPlanServiceProvider).deleteDietPlan(userId, dietPlan.id!);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diet Plan Deleted')));
                        } else if (value == 'apply') {
                          await ref.read(dietPlanServiceProvider).applyDietPlan(dietPlan);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diet Plan Applied')));
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'apply', child: Text('Apply')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () {
                      _showDietPlanDetails(context, dietPlan);
                    },
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.roboto(color: Theme.of(context).colorScheme.error)));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/diet_plan');
        },
        tooltip: 'Create Diet Plan',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDietPlanDetails(BuildContext context, DietPlan dietPlan) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(dietPlan.name, style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start Date: ${dietPlan.startDate.day}/${dietPlan.startDate.month}/${dietPlan.startDate.year}', style: GoogleFonts.roboto()),
                Text('Duration: ${dietPlan.durationDays} days', style: GoogleFonts.roboto()),
                const SizedBox(height: 16),
                Text('Daily Plans:', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold)),
                ...dietPlan.days.map((day) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(day.dayOfWeek, style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.bold)),
                          ...day.mealIds.map((mealId) => FutureBuilder<Meal?>(
                                future: ref.read(mealsServiceProvider).getMealById(dietPlan.userId, mealId),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Text('- Loading...', style: GoogleFonts.roboto(fontSize: 14));
                                  } else if (snapshot.hasError || !snapshot.hasData) {
                                    return Text('- Meal not found', style: GoogleFonts.roboto(fontSize: 14, color: Colors.red));
                                  } else {
                                    final meal = snapshot.data!;
                                    return Text('- ${meal.mealType} (${meal.totalCalories} kcal)', style: GoogleFonts.roboto(fontSize: 14));
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