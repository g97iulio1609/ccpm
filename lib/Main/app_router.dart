import 'package:alphanessone/Viewer/models/timer_model.dart';
import 'package:alphanessone/Coaching/coaching_association.dart';
import 'package:alphanessone/exerciseManager/exercise_model.dart';
import 'package:alphanessone/exercise_stats.dart';
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
import '../maxRMDashboard.dart';
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
import '../nutrition/models&Services/meals_model.dart';

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
                  final userRole = ref.read(userRoleProvider);
                  if (userRole == 'admin' || userRole == 'coach') {
                    return const ProgramsScreen();
                  } else {
                    return const Center(child: Text('Access denied'));
                  }
                },
              ),
              GoRoute(
                path: '/user_programs/:userId',
                builder: (context, state) =>
                    UserProgramsScreen(userId: state.pathParameters['userId']!),
                routes: [
                  GoRoute(
                    path: 'training_program/:programId',
                    builder: (context, state) => TrainingProgramPage(
                      programId: state.pathParameters['programId']!,
                      userId: state.pathParameters['userId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'week/:weekIndex',
                        builder: (context, state) => TrainingProgramPage(
                          programId: state.pathParameters['programId']!,
                          userId: state.pathParameters['userId']!,
                          weekIndex:
                              int.parse(state.pathParameters['weekIndex']!),
                        ),
                        routes: [
                          GoRoute(
                            path: 'workout/:workoutIndex',
                            builder: (context, state) => TrainingProgramPage(
                              programId: state.pathParameters['programId']!,
                              userId: state.pathParameters['userId']!,
                              weekIndex:
                                  int.parse(state.pathParameters['weekIndex']!),
                              workoutIndex: int.parse(
                                  state.pathParameters['workoutIndex']!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'training_viewer/:programId',
                    builder: (context, state) => TrainingViewer(
                      programId: state.pathParameters['programId']!,
                      userId: state.pathParameters['userId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'week_details/:weekId',
                        builder: (context, state) => WeekDetails(
                          programId: state.pathParameters['programId']!,
                          weekId: state.pathParameters['weekId']!,
                          userId: state.pathParameters['userId']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'workout_details/:workoutId',
                            builder: (context, state) => WorkoutDetails(
                              programId: state.pathParameters['programId']!,
                              weekId: state.pathParameters['weekId']!,
                              workoutId: state.pathParameters['workoutId']!,
                              userId: state.pathParameters['userId']!,
                            ),
                            routes: [
                              GoRoute(
                                path: 'exercise_details/:exerciseId',
                                builder: (context, state) {
                                  final extra =
                                      state.extra as Map<String, dynamic>?;
                                  return ExerciseDetails(
                                    programId: Uri.decodeComponent(
                                        state.pathParameters['programId']!),
                                    weekId: Uri.decodeComponent(
                                        state.pathParameters['weekId']!),
                                    workoutId: Uri.decodeComponent(
                                        state.pathParameters['workoutId']!),
                                    exerciseId: Uri.decodeComponent(
                                        state.pathParameters['exerciseId']!),
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
                path: '/measurements',
                builder: (context, state) {
                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  return userId != null
                      ? MeasurementsPage(userId: userId)
                      : const SizedBox();
                },
              ),
              GoRoute(
                path: '/tdee',
                builder: (context, state) {
                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  return userId != null
                      ? TDEEScreen(userId: userId)
                      : const SizedBox();
                },
              ),
              GoRoute(
                path: '/macros_selector',
                builder: (context, state) {
                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  return userId != null
                      ? MacrosSelector(userId: userId)
                      : const SizedBox();
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
                builder: (context, state) => const DailyFoodTracker(),
                routes: [
                  GoRoute(
                    path: 'food_selector',
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
  builder: (context, state) => const MaxRMDashboard(),
  routes: [
    GoRoute(
      path: 'exercise_stats/:exerciseId',
      builder: (context, state) {
        final exerciseId = state.pathParameters['exerciseId']!;
        final extra = state.extra as Map<String, dynamic>;
        final exercise = extra['exercise'] as ExerciseModel;
        final userId = extra['userId'] as String;
        debugPrint('userId: $userId');

        return ExerciseStats(
          exercise: exercise,
          userId: userId, // Passaggio dell'ID utente qui
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
                  return UserProfile(userId: userId);
                },
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
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await ref.read(usersServiceProvider).fetchUserRole();
              final userRole = ref.read(userRoleProvider);
              if (context.mounted) {
                if (userRole == 'admin' || userRole == 'coach') {
                  context.go('/programs_screen');
                } else {
                  context.go('/user_programs/${user.uid}');
                }
              }
            });
            return const HomeScreen(child: SizedBox());
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
