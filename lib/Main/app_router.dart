// app_router.dart

import 'package:alphanessone/Store/subscriptions_screen.dart';
import 'package:alphanessone/Viewer/models/timer_model.dart';
import 'package:alphanessone/Coaching/coaching_association.dart';
import 'package:alphanessone/exerciseManager/exercise_model.dart';
import 'package:alphanessone/ExerciseRecords/exercise_stats.dart';
import 'package:alphanessone/nutrition/models/diet_plan_model.dart';
import 'package:alphanessone/nutrition/tracker/diet_plan_screen.dart';
import 'package:alphanessone/nutrition/tracker/view_diet_plans_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../auth/auth_screen.dart';
import '../UI/home_screen.dart';
import '../Coaching/coaching_screen.dart';
import '../user_programs.dart';
import '../Viewer/UI/training_viewer.dart';
import '../Viewer/UI/week_details.dart';
import '../Viewer/UI/workout_details.dart';
import '../Viewer/UI/exercise_details.dart';
import '../Viewer/UI/timer.dart';
import '../trainingBuilder/training_program.dart';
import '../training_gallery.dart';
import 'package:alphanessone/ExerciseRecords/maxrmdashboard.dart';
import '../user_profile.dart';
import '../users_dashboard.dart';
import '../measurements/measurements.dart';
import '../nutrition/Calc/tdee.dart';
import '../nutrition/Calc/macros_selector.dart';
import '../nutrition/tracker/food_management.dart';
import '../nutrition/tracker/food_selector.dart';
import '../nutrition/tracker/favorite_meal_detail.dart';
import '../nutrition/tracker/daily_food_tracker.dart';
import '../nutrition/tracker/my_meals.dart';
import '../store/inAppPurchase.dart';
import '../exerciseManager/exercises_manager.dart';
import '../providers/providers.dart';
import '../nutrition/models/meals_model.dart';

class AppRouter {
  static GoRouter router(WidgetRef ref) => GoRouter(
        routes: [
          ShellRoute(
            builder: (context, state, child) => HomeScreen(child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const AuthWrapper(),
              ),
              GoRoute(
                path: '/programs_screen',
                builder: (context, state) {
                  return Consumer(
                    builder: (context, ref, child) {
                      final userRole = ref.watch(userRoleProvider);
                      //debugPrint('Navigating to /programs_screen with userRole: $userRole');
                      if (userRole == 'admin' || userRole == 'coach') {
                        return const CoachingScreen();
                      } else if (userRole.isEmpty) {
                        // User role not yet loaded, show a loading indicator
                        return const Center(child: CircularProgressIndicator());
                      } else {
                        return const Center(child: Text('Access denied'));
                      }
                    },
                  );
                },
              ),
              GoRoute(
                path: '/user_programs/:userId',
                builder: (context, state) {
                  final userId = state.pathParameters['userId'];
                  //debugPrint('Navigating to UserProgramsScreen with userId: $userId');
                  return UserProgramsScreen(userId: userId!);
                },
                routes: [
                  GoRoute(
                    path: 'training_program/:programId',
                    builder: (context, state) {
                      final programId = state.pathParameters['programId'];
                      final userId = state.pathParameters['userId'];
                      //debugPrint('Navigating to TrainingProgramPage with programId: $programId, userId: $userId');
                      return TrainingProgramPage(
                        programId: programId!,
                        userId: userId!,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'week/:weekIndex',
                        builder: (context, state) {
                          final programId = state.pathParameters['programId'];
                          final userId = state.pathParameters['userId'];
                          final weekIndex = state.pathParameters['weekIndex'];
                          //debugPrint('Navigating to TrainingProgramPage with weekIndex: $weekIndex');
                          return TrainingProgramPage(
                            programId: programId!,
                            userId: userId!,
                            weekIndex: int.parse(weekIndex!),
                          );
                        },
                        routes: [
                          GoRoute(
                            path: 'workout/:workoutIndex',
                            builder: (context, state) {
                              final programId =
                                  state.pathParameters['programId'];
                              final userId = state.pathParameters['userId'];
                              final weekIndex =
                                  state.pathParameters['weekIndex'];
                              final workoutIndex =
                                  state.pathParameters['workoutIndex'];
                              //debugPrint('Navigating to TrainingProgramPage with workoutIndex: $workoutIndex');
                              return TrainingProgramPage(
                                programId: programId!,
                                userId: userId!,
                                weekIndex: int.parse(weekIndex!),
                                workoutIndex: int.parse(workoutIndex!),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'training_viewer/:programId',
                    builder: (context, state) {
                      final programId = state.pathParameters['programId'];
                      final userId = state.pathParameters['userId'];
                      //debugPrint('Navigating to TrainingViewer with programId: $programId, userId: $userId');
                      return TrainingViewer(
                        programId: programId!,
                        userId: userId!,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'week_details/:weekId',
                        builder: (context, state) {
                          final programId = state.pathParameters['programId'];
                          final weekId = state.pathParameters['weekId'];
                          final userId = state.pathParameters['userId'];
                          //debugPrint('Navigating to WeekDetails with weekId: $weekId');
                          return WeekDetails(
                            programId: programId!,
                            weekId: weekId!,
                            userId: userId!,
                          );
                        },
                        routes: [
                          GoRoute(
                            path: 'workout_details/:workoutId',
                            builder: (context, state) {
                              final programId =
                                  state.pathParameters['programId'];
                              final weekId = state.pathParameters['weekId'];
                              final workoutId =
                                  state.pathParameters['workoutId'];
                              final userId = state.pathParameters['userId'];
                              //debugPrint('Navigating to WorkoutDetails with workoutId: $workoutId');
                              return WorkoutDetails(
                                programId: programId!,
                                weekId: weekId!,
                                workoutId: workoutId!,
                                userId: userId!,
                              );
                            },
                            routes: [
                              GoRoute(
                                path: 'exercise_details/:exerciseId',
                                builder: (context, state) {
                                  final programId = Uri.decodeComponent(
                                      state.pathParameters['programId']!);
                                  final weekId = Uri.decodeComponent(
                                      state.pathParameters['weekId']!);
                                  final workoutId = Uri.decodeComponent(
                                      state.pathParameters['workoutId']!);
                                  final exerciseId = Uri.decodeComponent(
                                      state.pathParameters['exerciseId']!);
                                  final extra =
                                      state.extra as Map<String, dynamic>?;
                                  //debugPrint('Navigating to ExerciseDetails with exerciseId: $exerciseId');
                                  return ExerciseDetails(
                                    programId: programId,
                                    weekId: weekId,
                                    workoutId: workoutId,
                                    exerciseId: exerciseId,
                                    superSetExercises:
                                        extra?['superSetExercises'] != null
                                            ? List<Map<String, dynamic>>.from(
                                                extra?['superSetExercises'])
                                            : [],
                                    superSetExerciseIndex:
                                        extra?['superSetExerciseIndex'] ?? 0,
                                    seriesList: List<Map<String, dynamic>>.from(
                                        extra?['seriesList'] ?? []),
                                    startIndex: extra?['startIndex'] ?? 0,
                                    userId: state.pathParameters['userId']!,
                                  );
                                },
                                routes: [
                                  GoRoute(
                                    path: 'timer',
                                    builder: (context, state) {
                                      final timerModel =
                                          state.extra as TimerModel;
                                      //debugPrint('Navigating to TimerPage');
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
                ],
              ),
              GoRoute(
                path: '/training_gallery',
                builder: (context, state) => const TrainingGalleryScreen(),
              ),
              GoRoute(
                path: '/subscriptions',
                builder: (context, state) => const InAppSubscriptionsPage(),
              ),
              GoRoute(
                path: '/status',
                builder: (context, state) =>
                    SubscriptionsScreen(), // Standalone SubscriptionsScreen senza userId
              ),
              GoRoute(
                path: '/measurements',
                builder: (context, state) {
                  return const MeasurementsPage();
                },
              ),
              GoRoute(
                path: '/tdee',
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
                path: '/macros_selector',
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
                path: '/mymeals',
                builder: (context, state) => const FavouritesMeals(),
                routes: [
                  GoRoute(
                    path: 'favorite_meal_detail',
                    builder: (context, state) {
                      final meal = state.extra as Meal;
                      // //debugPrint('Navigating to FavoriteMealDetail for meal: ${meal.name}');
                      return FavoriteMealDetail(meal: meal);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/associations',
                builder: (context, state) =>
                    const CoachAthleteAssociationScreen(),
              ),
              GoRoute(
                path: '/food_tracker',
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
                    path: 'food_selector',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>;
                      final mealMap = extra['meal'] as Map<String, dynamic>;
                      final meal = Meal.fromMap(mealMap);
                      final myFoodId = extra['myFoodId'] as String?;
                      final isFavoriteMeal = extra['isFavoriteMeal'] as bool;
                      //     //debugPrint('Navigating to FoodSelector for meal: ${meal.name}');
                      return FoodSelector(
                        meal: meal,
                        myFoodId: myFoodId,
                        isFavoriteMeal: isFavoriteMeal,
                      );
                    },
                  ),
                  // Rotte per Diet Plan
                  GoRoute(
                    path: 'diet_plan',
                    builder: (context, state) {
                      //debugPrint('Navigating to DietPlanScreen (creation mode)');
                      return const DietPlanScreen();
                    },
                  ),
                  GoRoute(
                    path: 'diet_plan/edit',
                    builder: (context, state) {
                      final dietPlan = state.extra as DietPlan;
                      //debugPrint('Navigating to DietPlanScreen (edit mode) for dietPlan: ${dietPlan.name}');
                      return DietPlanScreen(existingDietPlan: dietPlan);
                    },
                  ),
                  GoRoute(
                    path: 'view_diet_plans',
                    builder: (context, state) => const ViewDietPlansScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: '/food_management',
                builder: (context, state) => const FoodManagement(),
              ),
              GoRoute(
                path: '/exercises_list',
                builder: (context, state) => const ExercisesList(),
              ),
              GoRoute(
                path: '/maxrmdashboard',
                builder: (context, state) {
                  //debugPrint('Navigating to MaxRMDashboard');
                  return const MaxRMDashboard();
                },
                routes: [
                  GoRoute(
                    path: 'exercise_stats/:exerciseId',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>;
                      final exercise = extra['exercise'] as ExerciseModel;
                      final userId = extra['userId'] as String;
                      //debugPrint('Navigating to ExerciseStats for exerciseId: ${exercise.id}, userId: $userId');
                      return ExerciseStats(
                        exercise: exercise,
                        userId: userId, // Passing the user ID here
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/users_dashboard',
                builder: (context, state) => const UsersDashboard(),
              ),
              GoRoute(
                path: '/user_profile/:userId',
                builder: (context, state) {
                  final userId = state.pathParameters['userId'];
                  //debugPrint('Navigating to UserProfile with userId: $userId');
                  return UserProfile(userId: userId);
                },
              ),

              // Altre rotte...
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
        //debugPrint('AuthWrapper StreamBuilder: connectionState=${snapshot.connectionState}');
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          //debugPrint('AuthWrapper: user=${user?.uid}');
          if (user == null) {
            return const AuthScreen();
          } else {
            // Usa FutureBuilder per attendere il completamento della fetch del ruolo
            return FutureBuilder(
              future: ref.read(usersServiceProvider).fetchUserRole(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  //debugPrint('AuthWrapper: fetching user role...');
                  return const Center(child: CircularProgressIndicator());
                }
                final userRole = ref.read(userRoleProvider);
                //debugPrint('AuthWrapper: userRole=$userRole');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    if (userRole == 'admin' || userRole == 'coach') {
                      //debugPrint('AuthWrapper: Navigating to /programs_screen');
                      context.go('/programs_screen');
                    } else {
                      //debugPrint('AuthWrapper: Navigating to /user_programs/${user.uid}');
                      context.go('/user_programs/${user.uid}');
                    }
                  }
                });
                return const HomeScreen(child: SizedBox());
              },
            );
          }
        }
        //debugPrint('AuthWrapper: StreamBuilder waiting...');
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
