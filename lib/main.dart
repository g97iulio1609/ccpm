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
import 'programs_screen.dart'; // Importa programs_screen.dart

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
          path: '/training_program',
          builder: (context, state) => const TrainingProgramPage(),
        ),
        GoRoute(
          path: '/user_profile',
          builder: (context, state) => const UserProfile(),
        ),
        GoRoute(
          path: '/users_dashboard',
          builder: (context, state) => const UsersDashboard(),
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
            Future.microtask(() => ref.read(usersServiceProvider).fetchUserRole());
            Future.microtask(() => context.go('/programs_screen'));
            return const HomeScreen(child: SizedBox());
          }
        }
        // Mostra un indicatore di caricamento mentre lo stato di autenticazione viene risolto
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}