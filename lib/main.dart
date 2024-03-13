import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'authScreen.dart';
import 'homeScreen.dart';
import 'exerciseList.dart';
import 'maxRMDashboard.dart';
import 'trainingProgram.dart';
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
      error: const Color(0xFFF44336),
      background: const Color(0xFFE0E0E0),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      onBackground: Colors.black,
      brightness: Brightness.light,
    );

    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      primary: const Color(0xFF42A5F5),
      secondary: const Color(0xFFFFA726),
      error: const Color(0xFFEF9A9A),
      background: const Color(0xFF121212),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      onBackground: Colors.white,
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              // Remove the old way of updating user role in build method.
              // Instead, handle user role updating asynchronously after user has logged in.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(usersServiceProvider).setUserRole(snapshot.data!.uid);
              });
              // Return the home screen if the user is logged in.
              return const HomeScreen();
            } else {
              // Return the authentication screen if there is no user logged in.
              return AuthScreen();
            }
          }
          // Return a loading screen while Firebase is initializing.
          return const Center(child: CircularProgressIndicator());
        },
      ),
      routes: {
        '/auth': (context) => AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/exercises_list': (context) => ExercisesList(),
        '/maxrmdashboard': (context) => const MaxRMDashboard(),
        '/trainingprogram': (context) => TrainingProgramPage(),
      },
    );
  }
}
