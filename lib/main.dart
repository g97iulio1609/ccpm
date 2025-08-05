import 'package:alphanessone/Main/app_services.dart';
import 'package:alphanessone/services/ai/ai_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'Main/app_router.dart';
import 'Main/app_theme.dart';
import 'Main/app_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) =>
    throw UnimplementedError(
        'sharedPreferencesProvider needs to be overridden'));

Future<SharedPreferences> initializeServices() async {
  final List<Future> futures = [
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    SharedPreferences.getInstance(),
  ];

  if (!kIsWeb) {
    futures.add(Future(() async {
      await initializeNotifications();
      return;
    }));
  }

  final results = await Future.wait(futures);

  if (!kIsWeb) {
    await requestNotificationPermission();
  }

  if (kIsWeb) {
    // Temporaneamente commentato per compatibilità con Flutter 3.32
    // TODO: Riattivare quando flutter_stripe_web sarà compatibile con Flutter 3.32
    /*
    Stripe.publishableKey =
        'pk_live_51Lk8noGIoD20nGKnKB5igqB4Kpry8VQpYgWwm0t5dJWTCOX4pQXdg9N24dM1fSgZP3oVoYPTZj4SGYIp9aT05Mrr00a4XOvZg6';
    await Stripe.instance.applySettings();
    */
  }

  return results[1] as SharedPreferences;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await initializeServices();

  // Inizializza i servizi essenziali in modo asincrono
  appServices.initialize().then((_) {
    // Inizializzazione completata
  }).catchError((error) {
    debugPrint('Errore nell\'inizializzazione dei servizi: $error');
  });

  final bool isVersionSupported = await appServices.isAppVersionSupported();
  if (isVersionSupported) {
    // Sposta il controllo dell'abbonamento dopo il rendering iniziale
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          aiSettingsServiceProvider.overrideWithValue(AISettingsService(prefs)),
        ],
        child: const MyApp(),
      ),
    );

    // Controlla lo stato dell'abbonamento dopo che l'app è stata renderizzata
    appServices.checkSubscriptionStatus().then((_) {
      // Gestione dello stato dell'abbonamento completata
    }).catchError((error) {
      debugPrint('Errore nel controllo dell\'abbonamento: $error');
    });
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
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Aggiorna l'applicazione all'ultima versione per continuare ad usarla",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 24),
                if (!kIsWeb)
                  ElevatedButton(
                    onPressed: () async {
                      await appServices.checkForUpdate();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text(
                      'Aggiorna',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
