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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisci lo schema colori per il tema chiaro
    final ColorScheme lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3), // Blu come colore base
      primary: const Color(0xFF2196F3), // Blu
      secondary: const Color(0xFFFF9800), // Arancione
      error: const Color(0xFFF44336), // Rosso
      background: const Color(0xFFE0E0E0), // Grigio chiaro
      onPrimary: Colors.white, // Bianco su Blu
      onSecondary: Colors.white, // Bianco su Arancione
      onError: Colors.white, // Bianco su Rosso
      onBackground: Colors.black, // Nero su Grigio chiaro
      brightness: Brightness.light,
    );

    // Definisci lo schema colori per il tema scuro
    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3), // Blu come colore base
      primary: const Color(0xFF42A5F5), // Blu chiaro
      secondary: const Color(0xFFFFA726), // Arancione chiaro
      error: const Color(0xFFEF9A9A), // Rosso chiaro
      background: const Color(0xFF121212), // Quasi Nero
      onPrimary: Colors.white, // Bianco su Blu chiaro
      onSecondary: Colors.white, // Bianco su Arancione chiaro
      onError: Colors.white, // Bianco su Rosso chiaro
      onBackground: Colors.white, // Bianco su Quasi Nero
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
      textTheme: GoogleFonts.robotoTextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
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
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return AuthScreen();
        },
      ),
      routes: {
        '/auth': (context) => AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/exercises_list': (context) => ExercisesList(),
        '/maxrmdashboard': (context) => const MaxRMDashboard(),
        'trainingprogram':(context) => TrainingProgramPage()
      },
    );
  }
}
