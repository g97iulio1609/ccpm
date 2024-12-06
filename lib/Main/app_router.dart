// app_router.dart

import 'package:alphanessone/Coaching/coaching_association.dart';
import 'package:alphanessone/ExerciseRecords/exercise_stats.dart';
import 'package:alphanessone/ExerciseRecords/maxrmdashboard.dart';
import 'package:alphanessone/Main/routes.dart';
import 'package:alphanessone/UI/home_screen.dart';
import 'package:alphanessone/Viewer/UI/exercise_details.dart';
import 'package:alphanessone/Viewer/UI/timer.dart';
import 'package:alphanessone/Viewer/UI/training_viewer.dart';
import 'package:alphanessone/Viewer/UI/workout_details.dart';
import 'package:alphanessone/Viewer/models/timer_model.dart';
import 'package:alphanessone/auth/auth_screen.dart';
import 'package:alphanessone/measurements/measurements.dart';
import 'package:alphanessone/nutrition/Calc/macros_selector.dart';
import 'package:alphanessone/nutrition/Calc/tdee.dart';
import 'package:alphanessone/nutrition/models/diet_plan_model.dart';
import 'package:alphanessone/nutrition/models/meals_model.dart';
import 'package:alphanessone/nutrition/tracker/daily_food_tracker.dart';
import 'package:alphanessone/nutrition/tracker/diet_plan_screen.dart';
import 'package:alphanessone/nutrition/tracker/favorite_meal_detail.dart';
import 'package:alphanessone/nutrition/tracker/food_management.dart';
import 'package:alphanessone/nutrition/tracker/food_selector.dart';
import 'package:alphanessone/nutrition/tracker/my_meals.dart';
import 'package:alphanessone/nutrition/tracker/view_diet_plans_screen.dart';
import 'package:alphanessone/training_gallery.dart';
import 'package:alphanessone/user_profile.dart';
import 'package:alphanessone/users_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Store/inAppPurchase.dart';
import '../Store/subscriptions_screen.dart';
import '../trainingBuilder/training_program.dart';
import '../exerciseManager/exercises_manager.dart';
import '../exerciseManager/exercise_model.dart';
import '../Coaching/coaching_screen.dart';
import '../user_programs.dart';
import '../providers/providers.dart';
import 'package:alphanessone/Features/Dashboard/dashboard_screen.dart';

class AppRouter {
  static GoRouter router(WidgetRef ref) => GoRouter(
        routes: [
          ShellRoute(
            builder: (context, state, child) => HomeScreen(child: child),
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const AuthWrapper(),
              ),
              GoRoute(
                path: Routes.programsScreen,
                builder: (context, state) {
                  return Consumer(
                    builder: (context, ref, child) {
                      final userRole = ref.watch(userRoleProvider);
                      if (userRole == 'admin' || userRole == 'coach') {
                        return const CoachingScreen();
                      } else if (userRole.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      } else {
                        return const Center(child: Text('Access denied'));
                      }
                    },
                  );
                },
              ),
              GoRoute(
                path: Routes.userPrograms,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  final userId = extra['userId'] as String;
                  return UserProgramsScreen(userId: userId);
                },
                routes: [
                  GoRoute(
                    path: Routes.trainingProgram,
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>;
                      final programId = extra['programId'] as String;
                      final userId = extra['userId'] as String;
                      return TrainingProgramPage(
                        programId: programId,
                        userId: userId,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: Routes.week,
                        builder: (context, state) {
                          final extra = state.extra as Map<String, dynamic>;
                          final programId = extra['programId'] as String;
                          final userId = extra['userId'] as String;
                          final weekIndex = extra['weekIndex'] as int;
                          return TrainingProgramPage(
                            programId: programId,
                            userId: userId,
                            weekIndex: weekIndex,
                          );
                        },
                        routes: [
                          GoRoute(
                            path: Routes.workout,
                            builder: (context, state) {
                              final extra = state.extra as Map<String, dynamic>;
                              final programId = extra['programId'] as String;
                              final userId = extra['userId'] as String;
                              final weekIndex = extra['weekIndex'] as int;
                              final workoutIndex = extra['workoutIndex'] as int;
                              return TrainingProgramPage(
                                programId: programId,
                                userId: userId,
                                weekIndex: weekIndex,
                                workoutIndex: workoutIndex,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: Routes.trainingViewer,
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>;
                      final programId = extra['programId'] as String;
                      final userId = extra['userId'] as String;
                      return UnifiedTrainingViewer(
                        programId: programId,
                        userId: userId,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: Routes.workoutDetails,
                        builder: (context, state) {
                          final extra = state.extra as Map<String, dynamic>;
                          final programId = extra['programId'] as String;
                          final weekId = extra['weekId'] as String;
                          final workoutId = extra['workoutId'] as String;
                          final userId = extra['userId'] as String;
                          return WorkoutDetails(
                            programId: programId,
                            weekId: weekId,
                            workoutId: workoutId,
                            userId: userId,
                          );
                        },
                        routes: [
                          GoRoute(
                            path: Routes.exerciseDetails,
                            builder: (context, state) {
                              final extra =
                                  state.extra as Map<String, dynamic>;
                              final programId =
                                  extra['programId'] as String;
                              final weekId = extra['weekId'] as String;
                              final workoutId =
                                  extra['workoutId'] as String;
                              final exerciseId =
                                  extra['exerciseId'] as String;
                              final userId = extra['userId'] as String;
                              return ExerciseDetails(
                                programId: programId,
                                weekId: weekId,
                                workoutId: workoutId,
                                exerciseId: exerciseId,
                                superSetExercises:
                                    extra['superSetExercises'] != null
                                        ? List<Map<String, dynamic>>.from(
                                            extra['superSetExercises'])
                                        : [],
                                superSetExerciseIndex:
                                    extra['superSetExerciseIndex'] ?? 0,
                                seriesList: List<Map<String, dynamic>>.from(
                                    extra['seriesList'] ?? []),
                                startIndex: extra['startIndex'] ?? 0,
                                userId: userId,
                              );
                            },
                            routes: [
                              GoRoute(
                                path: Routes.timer,
                                builder: (context, state) {
                                  final timerModel =
                                      state.extra as TimerModel;
                                  return TimerPage(timerModel: timerModel);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: Routes.trainingGallery,
                builder: (context, state) => const TrainingGalleryScreen(),
              ),
              GoRoute(
                path: Routes.subscriptions,
                name: 'subscriptions',
                builder: (context, state) => const InAppPurchaseScreen(),
              ),
              GoRoute(
                path: Routes.status,
                builder: (context, state) => SubscriptionsScreen(),
              ),
              GoRoute(
                path: Routes.measurements,
                builder: (context, state) => const MeasurementsPage(),
              ),
              GoRoute(
                path: Routes.tdee,
                builder: (context, state) {
                  return Consumer(
                    builder: (context, ref, child) {
                      final userAsyncValue = ref.watch(userProvider(
                          FirebaseAuth.instance.currentUser?.uid ?? ''));
                      return userAsyncValue.when(
                        data: (user) {
                          if (user == null) {
                            return const Center(child: Text('User not found'));
                          }
                          return TDEEScreen(userId: user.id);
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) =>
                            Center(child: Text('Error: $err')),
                      );
                    },
                  );
                },
              ),
              GoRoute(
                path: Routes.macrosSelector,
                builder: (context, state) {
                  return Consumer(
                    builder: (context, ref, child) {
                      final userAsyncValue = ref.watch(userProvider(
                          FirebaseAuth.instance.currentUser?.uid ?? ''));
                      return userAsyncValue.when(
                        data: (user) {
                          if (user == null) {
                            return const Center(child: Text('User not found'));
                          }
                          return MacrosSelector(userId: user.id);
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) =>
                            Center(child: Text('Error: $err')),
                      );
                    },
                  );
                },
              ),
              GoRoute(
                path: Routes.myMeals,
                builder: (context, state) => const FavouritesMeals(),
                routes: [
                  GoRoute(
                    path: Routes.favoriteMealDetail,
                    builder: (context, state) {
                      final meal = state.extra as Meal;
                      return FavoriteMealDetail(meal: meal);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: Routes.associations,
                builder: (context, state) =>
                    const CoachAthleteAssociationScreen(),
              ),
              GoRoute(
                path: Routes.foodTracker,
                builder: (context, state) {
                  return Consumer(
                    builder: (context, ref, child) {
                      final selectedUserId = ref.watch(selectedUserIdProvider);
                      final userAsyncValue = ref.watch(userProvider(
                          selectedUserId ??
                              FirebaseAuth.instance.currentUser?.uid ??
                              ''));
                      return userAsyncValue.when(
                        data: (user) {
                          if (user == null) {
                            return const Center(child: Text('User not found'));
                          }
                          return const DailyFoodTracker();
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) =>
                            Center(child: Text('Error: $err')),
                      );
                    },
                  );
                },
                routes: [
                  GoRoute(
                    path: Routes.foodSelector,
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>;
                      final mealMap = extra['meal'] as Map<String, dynamic>;
                      final meal = Meal.fromMap(mealMap);
                      final myFoodId = extra['myFoodId'] as String?;
                      final isFavoriteMeal = extra['isFavoriteMeal'] as bool;
                      return FoodSelector(
                        meal: meal,
                        myFoodId: myFoodId,
                        isFavoriteMeal: isFavoriteMeal,
                      );
                    },
                  ),
                  GoRoute(
                    path: Routes.dietPlan,
                    builder: (context, state) => const DietPlanScreen(),
                  ),
                  GoRoute(
                    path: Routes.dietPlanEdit,
                    builder: (context, state) {
                      final dietPlan = state.extra as DietPlan;
                      return DietPlanScreen(existingDietPlan: dietPlan);
                    },
                  ),
                  GoRoute(
                    path: Routes.viewDietPlans,
                    builder: (context, state) => const ViewDietPlansScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: Routes.foodManagement,
                builder: (context, state) => const FoodManagement(),
              ),
              GoRoute(
                path: Routes.exercisesList,
                builder: (context, state) => const ExercisesList(),
              ),
              GoRoute(
                path: Routes.maxRmDashboard,
                builder: (context, state) => const MaxRMDashboard(),
                routes: [
                  GoRoute(
                    path: Routes.exerciseStats,
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>;
                      final exercise = extra['exercise'] as ExerciseModel;
                      final userId = extra['userId'] as String;
                      return ExerciseStats(
                        exercise: exercise,
                        userId: userId,
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: Routes.usersDashboard,
                builder: (context, state) => const UsersDashboard(),
              ),
              GoRoute(
                path: Routes.userProfile,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  final userId = extra['userId'] as String;
                  return UserProfile(userId: userId);
                },
              ),
              GoRoute(
                path: Routes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
        ],
      );
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          if (user == null) {
            return const AuthScreen();
          } else {
            return FutureBuilder(
              future: ref.read(usersServiceProvider).fetchUserRole(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final userRole = ref.read(userRoleProvider);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    if (userRole == 'admin' || userRole == 'coach') {
                      context.go(Routes.programsScreen);
                    } else {
                      context
                          .go(Routes.userPrograms, extra: {'userId': user.uid});
                    }
                  }
                });
                return const HomeScreen(child: SizedBox());
              },
            );
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
