import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'firebase_options.dart';
import 'Main/app_router.dart';
import 'Main/app_theme.dart';
import 'Main/app_notifications.dart';
import 'Main/app_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  await initializeNotifications();
  await requestNotificationPermission();
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
                const Icon(Icons.update, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  "L'App Deve Essere Aggiornata",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Aggiorna l'applicazione all'ultima versione per continuare ad usarla",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await AppServices().checkForUpdate();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text(
                    'Aggiorna',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    final ThemeData darkTheme = AppTheme.darkTheme;

    return MaterialApp.router(
      routerConfig: AppRouter.router(ref),
      title: 'AlphanessOne',
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
    );
  }
}
