import 'package:alphanessone/trainingBuilder/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/training_program_workout_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'exerciseManager/exercise_list.dart';
import 'maxRMDashboard.dart';
import 'trainingBuilder/training_program.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'trainingBuilder/volume_dashboard.dart';
import 'user_profile.dart';
import 'users_dashboard.dart';
import 'users_services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'programs_screen.dart';
import 'user_programs.dart';
import 'Viewer/training_viewer.dart';
import 'Viewer/week_details.dart';
import 'Viewer/workout_details.dart';
import 'Viewer/exercise_details.dart';
import 'Viewer/timer.dart';

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
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      primary: const Color(0xFF2196F3),
      secondary: const Color(0xFFFF9800),
      tertiary: const Color(0xFF4CAF50),
      error: const Color(0xFFF44336),
      background: const Color(0xFFF5F5F5),
      surface: const Color(0xFFFFFFFF),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onError: Colors.white,
      onBackground: Colors.black,
      onSurface: Colors.black,
      brightness: Brightness.light,
    );

    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      primary: const Color(0xFF90CAF9),
      secondary: const Color(0xFFFFCC80),
      tertiary: const Color(0xFF81C784),
      error: const Color(0xFFEF9A9A),
      background: const Color(0xFF121212),
      surface: const Color(0xFF1F1F1F),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onTertiary: Colors.black,
      onError: Colors.black,
      onBackground: Colors.white,
      onSurface: Colors.white,
      brightness: Brightness.dark,
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      textTheme: GoogleFonts.robotoTextTheme(),
      visualDensity: VisualDensity.adaptivePlatformDensity,
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
                                  exerciseName:
                                      extra?['exerciseName'] ?? '',
                                  exerciseVariant:
                                      extra?['exerciseVariant'],
                                  seriesList:
                                      List<Map<String, dynamic>>.from(
                                          extra?['seriesList'] ?? []),
                                  startIndex: extra?['startIndex'] ?? 0,
                                  userId: state.pathParameters['userId']!,
                                );
                              },
                              routes: [
                                GoRoute(
                                  path: 'timer',
                                  builder: (context, state) => TimerPage(
                                    programId: Uri.decodeComponent(
                                        state.pathParameters['programId']!),
                                    weekId: Uri.decodeComponent(
                                        state.pathParameters['weekId']!),
                                    workoutId: Uri.decodeComponent(
                                        state.pathParameters['workoutId']!),
                                    exerciseId: Uri.decodeComponent(state
                                        .pathParameters['exerciseId']!),
                                    currentSeriesIndex: int.parse(
                                        state.uri.queryParameters[
                                            'currentSeriesIndex']!),
                                    totalSeries: int.parse(state.uri
                                        .queryParameters['totalSeries']!),
                                    restTime: int.parse(state
                                        .uri.queryParameters['restTime']!),
                                    isEmomMode: state.uri.queryParameters[
                                            'isEmomMode'] ==
                                        'true',
                                    userId: state.pathParameters['userId']!,
                                  ),
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
                  path: 'training_program',
                  builder: (context, state) => TrainingProgramPage(
                    userId: state.pathParameters['userId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: ':programId',
                      builder: (context, state) => TrainingProgramPage(
                        programId: state.pathParameters['programId'],
                        userId: state.pathParameters['userId']!,
                        weekIndex: null,
                      ),
                    ),
                    GoRoute(
                      path: ':programId/week/:weekIndex',
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
                            weekIndex: int.parse(
                                state.pathParameters['weekIndex']!),
                            workoutIndex:
                                int.parse(state.pathParameters['workoutIndex']!),
                          ),
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
              path: 'user_profile/:userId',
              builder: (context, state) =>
                  UserProfile(userId: state.pathParameters['userId']!),
            ),
          ],
        ),
        GoRoute(
          path: '/user_profile/:userId',
          builder: (context, state) =>
              UserProfile(userId: state.pathParameters['userId']!),
        ),
        GoRoute(
          path: '/user_profile',
          builder: (context, state) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            return userId != null
                ? UserProfile(userId: userId)
                : const SizedBox();
          },
        ),
      ],
    )
  ],
);
    return MaterialApp.router(
      routerConfig: router,
      title: 'AlphanessOne',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
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
            return AuthScreen();
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await ref.read(usersServiceProvider).fetchUserRole();
              final userRole = ref.read(userRoleProvider);
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