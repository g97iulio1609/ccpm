// main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'authScreen.dart';
import 'homeScreen.dart';
import '../exerciseManager/exerciseList.dart';
import 'maxRMDashboard.dart';
import 'trainingBuilder/trainingProgram.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'usersServices.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

    return MaterialApp(
      title: 'AlphanessOne',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      routes: {
        '/auth': (context) => AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/exercises_list': (context) => ExercisesList(),
        '/maxrmdashboard': (context) => const MaxRMDashboard(),
        '/trainingprogram': (context) => const TrainingProgramPage(),
      },
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
            Future.microtask(() => ref.read(usersServiceProvider).setUserRole(user.uid));
            return const HomeScreen();
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}