// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'exercises_list.dart'; // Assicurati di includere il tuo ExercisesList.dart qui
import 'maxrmdashboard.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Importa hooks_riverpod per il ProviderScope

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp())); // Avvolgi MyApp con ProviderScope
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF005AC8),
        brightness: Brightness.light,
      ),
      shadowColor: Colors.grey.withOpacity(0.5),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF005AC8),
        brightness: Brightness.dark,
      ),
      shadowColor: Colors.black.withOpacity(0.5),
    );

    return MaterialApp(
      title: 'FlutterFire Auth Demo',
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
        '/exercises_list': (context) => ExercisesList(), // Aggiungi la route per ExercisesList
                '/maxrmdashboard': (context) => const MaxRMDashboard(), // Aggiungi la route per ExercisesList

      },
    );
  }
}
