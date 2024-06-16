import 'package:alphanessone/Store/inAppSubscriptions.dart';
import 'package:alphanessone/Viewer/models/timer_model.dart';
import 'package:alphanessone/measurements/measurements.dart';
import 'package:alphanessone/nutrition/models&Services/meals_model.dart'
    as meals;
import 'package:alphanessone/nutrition/tracker/daily_food_tracker.dart';
import 'package:alphanessone/nutrition/tracker/my_meals.dart';
import 'package:alphanessone/nutrition/tracker/food_management.dart';
import 'package:alphanessone/nutrition/Calc/macros_selector.dart';
import 'package:alphanessone/nutrition/Calc/tdee.dart';
import 'package:alphanessone/training_gallery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth/auth_screen.dart';
import 'UI/home_screen.dart';
import 'exerciseManager/exercises_manager.dart';
import 'maxRMDashboard.dart';
import 'trainingBuilder/training_program.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'trainingBuilder/volume_dashboard.dart';
import 'user_profile.dart';
import 'users_dashboard.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'programs_screen.dart';
import 'user_programs.dart';
import 'Viewer/UI/training_viewer.dart';
import 'Viewer/UI/week_details.dart';
import 'Viewer/UI/workout_details.dart';
import 'Viewer/UI/exercise_details.dart';
import 'Viewer/UI/timer.dart';
import 'app_services.dart';
import 'nutrition/tracker/food_selector.dart';
import 'nutrition/tracker/favorite_meal_detail.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> requestNotificationPermission() async {
  if (!kIsWeb) {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      // I permessi delle notifiche sono stati concessi.
    } else {
      // I permessi delle notifiche sono stati negati o l'utente ha selezionato "Non chiedere più".
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await requestNotificationPermission();
  if (!kIsWeb) {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  await AppServices().initialize();

  final bool isVersionSupported = await AppServices().isAppVersionSupported();
  if (isVersionSupported) {
    runApp(const ProviderScope(child: MyApp()));
  } else {
    runApp(const UnsupportedVersionApp());
  }
}

class UnsupportedVersionApp extends StatelessWidget {
  const UnsupportedVersionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.update,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  "L'App Deve Essere Aggiornata",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Aggiorna L'applicazione all'ultima versione per continaure ad usarla",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await AppServices().checkForUpdate();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Aggiorna',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1976D2),
      primary: const Color(0xFFFFD700),
      secondary: const Color(0xFFFF9800),
      tertiary: const Color(0xFF4CAF50),
      error: const Color(0xFFF44336),
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onTertiary: Colors.black,
      onError: Colors.white,
      onBackground: Colors.white,
      onSurface: Colors.white,
      brightness: Brightness.dark,
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

final GoRouter router = GoRouter(
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
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userRole == 'admin') {
              return const ProgramsScreen();
            } else {
              return userId != null
                  ? UserProgramsScreen(userId: userId)
                  : const SizedBox();
            }
          },
          routes: [
            GoRoute(
              path: 'user_programs/:userId',
              builder: (context, state) => UserProgramsScreen(
                  userId: state.pathParameters['userId']!),
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
                        weekIndex: int.parse(state.pathParameters['weekIndex']!),
                      ),
                      routes: [
                        GoRoute(
                          path: 'workout/:workoutIndex',
                          builder: (context, state) => TrainingProgramPage(
                            programId: state.pathParameters['programId']!,
                            userId: state.pathParameters['userId']!,
                            weekIndex: int.parse(state.pathParameters['weekIndex']!),
                            workoutIndex: int.parse(state.pathParameters['workoutIndex']!),
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
                                final extra = state.extra as Map<String, dynamic>?;
                                return ExerciseDetails(
                                  programId: Uri.decodeComponent(state.pathParameters['programId']!),
                                  weekId: Uri.decodeComponent(state.pathParameters['weekId']!),
                                  workoutId: Uri.decodeComponent(state.pathParameters['workoutId']!),
                                  exerciseId: Uri.decodeComponent(state.pathParameters['exerciseId']!),
                                  superSetExercises: extra?['superSetExercises'] != null
                                      ? List<Map<String, dynamic>>.from(extra?['superSetExercises'])
                                      : [],
                                  superSetExerciseIndex: extra?['superSetExerciseIndex'] ?? 0,
                                  seriesList: List<Map<String, dynamic>>.from(extra?['seriesList'] ?? []),
                                  startIndex: extra?['startIndex'] ?? 0,
                                  userId: state.pathParameters['userId']!,
                                );
                              },
                              routes: [
                                GoRoute(
                                  path: 'timer',
                                  builder: (context, state) {
                                    final timerModel = state.extra as TimerModel;
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
          ],
        ),
        GoRoute(
          path: '/training_gallery',
          builder: (context, state) => const TrainingGalleryScreen(),
        ),
        GoRoute(
          path: '/subscriptions',
          builder: (context, state) => InAppSubscriptionsPage(),
        ),
        GoRoute(
          path: '/measurements',
          builder: (context, state) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            return userId != null ? MeasurementsPage(userId: userId) : const SizedBox();
          },
        ),
        GoRoute(
          path: '/tdee',
          builder: (context, state) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            return userId != null ? TDEEScreen(userId: userId) : const SizedBox();
          },
        ),
        GoRoute(
          path: '/macros_selector',
          builder: (context, state) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            return userId != null ? MacrosSelector(userId: userId) : const SizedBox();
          },
        ),
        GoRoute(
          path: '/mymeals',
          builder: (context, state) => const FavouritesMeals(),
          routes: [
            GoRoute(
              path: 'favorite_meal_detail',
              builder: (context, state) {
                final meal = state.extra as meals.Meal;
                return FavoriteMealDetail(meal: meal);
              },
            ),
          ],
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
                final meal = meals.Meal.fromMap(mealMap);
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
        ),
        GoRoute(
          path: '/users_dashboard',
          builder: (context, state) => const UsersDashboard(),
          routes: [
            GoRoute(
              path: 'user_profile',
              builder: (context, state) => UserProfile(userId: state.extra as String),
            ),
          ],
        ),
        GoRoute(
          path: '/user_profile',
          builder: (context, state) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            return userId != null ? UserProfile(userId: userId) : const SizedBox();
          },
        ),
      ],
    ),
  ],
);

return MaterialApp.router(
  routerConfig: router,
  title: 'AlphanessOne',
  darkTheme: darkTheme,
  themeMode: ThemeMode.dark,
);

  }
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
            final userRole = ref.read(userRoleProvider);
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await ref.read(usersServiceProvider).fetchUserRole();
              if (context.mounted) {
                if (userRole == 'admin') {
                  context.go('/programs_screen');
                } else {
                  context.go('/programs_screen/user_programs/${user.uid}');
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
