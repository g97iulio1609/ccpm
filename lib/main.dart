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
import 'user_profile.dart';
import 'users_dashboard.dart';
import 'users_services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'programs_screen.dart';
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
              builder: (context, state) => const ProgramsScreen(),
              routes: [
                GoRoute(
                  path: 'training_viewer/:programId',
                  builder: (context, state) => TrainingViewer(
                      programId: state.pathParameters['programId']!),
                  routes: [
                    GoRoute(
                      path: 'week_details/:weekId',
                      builder: (context, state) => WeekDetails(
                        programId: state.pathParameters['programId']!,
                        weekId: state.pathParameters['weekId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'workout_details/:workoutId',
                          builder: (context, state) => WorkoutDetails(
                            programId: state.pathParameters['programId']!,
                            weekId: state.pathParameters['weekId']!,
                            workoutId: state.pathParameters['workoutId']!,
                          ),
                          routes: [
                            GoRoute(
                              path: 'exercise_details/:exerciseId',
                              builder: (context, state) => ExerciseDetails(
                                programId: state.pathParameters['programId']!,
                                weekId: state.pathParameters['weekId']!,
                                workoutId: state.pathParameters['workoutId']!,
                                exerciseId: state.pathParameters['exerciseId']!,
                                exerciseName: (state.extra
                                    as Map<String, dynamic>)['exerciseName'],
                                exerciseVariant: (state.extra
                                    as Map<String, dynamic>)['exerciseVariant'],
                                seriesList: List<Map<String, dynamic>>.from(
                                    (state.extra
                                        as Map<String, dynamic>)['seriesList']),
                                startIndex: (state.extra
                                    as Map<String, dynamic>)['startIndex'],
                              ),
                              routes: [
                                GoRoute(
                                  path: 'timer',
                                  builder: (context, state) => TimerPage(
                                    programId:
                                        state.pathParameters['programId']!,
                                    weekId: state.pathParameters['weekId']!,
                                    workoutId:
                                        state.pathParameters['workoutId']!,
                                    exerciseId:
                                        state.pathParameters['exerciseId']!,
                                    currentSeriesIndex: int.parse(
                                        state.uri.queryParameters[
                                            'currentSeriesIndex']!),
                                    totalSeries: int.parse(state
                                        .uri.queryParameters['totalSeries']!),
                                    restTime: int.parse(
                                        state.uri.queryParameters['restTime']!),
                                    isEmomMode: state.uri
                                            .queryParameters['isEmomMode'] ==
                                        'true',
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
              ],
            ),
            GoRoute(
              path: '/training_program/:programId',
              builder: (context, state) => TrainingProgramPage(
                  programId: state.pathParameters['programId']),
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
              path: '/user_profile/:userId',
              builder: (context, state) =>
                  UserProfile(userId: state.pathParameters['userId']!),
            ),
            GoRoute(
              path: '/users_dashboard',
              builder: (context, state) => const UsersDashboard(),
            ),
            GoRoute(
                path: '/user_profile',
                builder: (context, state) {
                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  return userId != null
                      ? UserProfile(userId: userId)
                      : const SizedBox();
                }),
            GoRoute(
              path: '/training_program',
              builder: (context, state) =>
                  const TrainingProgramPage(), // Aggiungi questa rotta
            ),
          ],
        ),
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
            // Assicurati che l'utente sia caricato prima di passare a ProgramsScreen
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await ref.read(usersServiceProvider).fetchUserRole();
              if (context.mounted) {
                context.go('/programs_screen');
              }
            });
            return const HomeScreen(child: SizedBox());
          }
        }
        // Mostra un indicatore di caricamento mentre lo stato di autenticazione viene risolto
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
