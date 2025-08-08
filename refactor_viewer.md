# Piano di Refactoring del Modulo Viewer - AlphanessOne

## Obiettivi
- Riorganizzare il codice seguendo le best practice di Flutter
- Migliorare l'architettura applicando i principi SOLID
- Ottimizzare le prestazioni e la manutenibilità
- Migliorare UI/UX mantenendo la coerenza con il design system
- Preservare tutte le funzionalità esistenti

## Fasi del Refactoring

### Fase 1: Analisi e Pianificazione
- [X] 1.1 Analisi dell'architettura attuale
- [X] 1.2 Identificazione dei problemi e delle aree di miglioramento
- [X] 1.3 Definizione della nuova architettura (Proposta iniziale approvata)

### Fase 2: Riorganizzazione della Struttura e Servizi Core
- [X] 2.1 Definizione chiara dei layer: Data (Repositories), Domain (Use Cases/Services), Presentation (State Notifiers + UI).
- [X] 2.2 Suddivisione dei servizi `WorkoutService` e `TrainingProgramServices` in classi più piccole e focalizzate. (Implementazione di `WorkoutRepositoryImpl` e `TimerPresetRepositoryImpl` completata)
- [X] 2.3 Astrazione delle interazioni con Firestore dietro i Repository. (Metodi CRUD e di lettura per tutte le entità principali implementati)
- [X] 2.4 Centralizzazione e consolidamento dei provider Riverpod. (`viewer_providers.dart` aggiornato con provider per repository e use case)
- [X] 2.5 Riorganizzazione delle cartelle del modulo `Viewer`.

### Fase 3: Refactoring dei Modelli di Dati e Logica di Business
- [X] 3.1 Revisione e standardizzazione dei modelli. Entità di dominio con metodi helper (`copyWith`, `toMap`/`fromMap`) completate.
- [X] 3.2 Implementazione di classi immutabili.
- [X] 3.3 Spostamento della logica di business ai nuovi Use Cases. (Creati Use Case per Serie, Note Esercizio, Timer Presets. Provider aggiunti).
- [X] 3.4 Miglioramento della gestione della cache a livello di Repository. (Caching base in `TimerPresetRepositoryImpl`. Da rivedere/estendere se necessario).

### Fase 4: Refactoring dell'UI e State Management
- [In Corso] 4.1 Semplificazione dei widget (`WorkoutDetails`, `ExerciseTimerBottomSheet`) spostando la logica negli State Notifiers. (Creati `ExerciseTimerNotifier` e `WorkoutDetailsNotifier`. Inizio refactoring `ExerciseTimerBottomSheet`).
- [  ] 4.2 Creazione di componenti UI più piccoli, riutilizzabili e "dumb".
- [  ] 4.3 Refactoring della gestione dei dialoghi, estraendo la logica e possibilmente creando widget di dialogo dedicati.
- [  ] 4.4 Miglioramento della gestione dello stato per il timer e interazioni con gli esercizi usando State Notifiers.
- [  ] 4.5 Aggiornamento del design UI per coerenza con Material 3 e miglioramento UX (feedback visivi, transizioni), utilizzando `app_theme.dart`.
- [  ] 4.6 Gestione della logica di "controllo abbonamento" in modo più disaccoppiato, possibilmente tramite un service apposito o a un livello superiore dell'app.

### Fase 5: Test e Validazione
- [  ] 5.1 Scrittura di unit test per Repositories e Use Cases/Services.
- [  ] 5.2 Scrittura di widget test per i componenti UI critici.
- [  ] 5.3 Test funzionali end-to-end.
- [  ] 5.4 Test di prestazioni e profilazione.
- [  ] 5.5 Verifica della compatibilità cross-device.

## Problemi Identificati (Aggiornato dopo analisi)
1.  **Mescolanza di logica di business, UI e accesso ai dati nei widget:**
    *   `ExerciseTimerBottomSheet`: Logica Firestore per preset, gestione timer.
    *   `WorkoutDetails`: Logica complessa nei dialoghi, gestione diretta dello stato delle serie.
    *   `TrainingViewer`: Logica di controllo abbonamento.
2.  **Servizi con troppe responsabilità (Violazione SRP):**
    *   `WorkoutService`: Gestisce note, prefetching, cache, sottoscrizioni, aggiornamenti dati, calcoli, ecc.
    *   `TrainingProgramServices`: CRUD per multiple entità Firestore, notifiche.
3.  **Duplicazione di codice e logica:**
    *   Logica `isSeriesDone` simile in `WorkoutService` e `TrainingProgramServices`.
    *   Nomi di provider duplicati (`exercisesProvider`, `loadingProvider`) in `workout_provider.dart` e `training_program_provider.dart`.
4.  **Gestione dello stato (Riverpod) migliorabile:**
    *   Provider sparsi e con nomi duplicati.
    *   Accesso diretto a `ref.read` dai servizi attuali.
5.  **Interazioni dirette e diffuse con Firestore:**
    *   Mancanza di un layer di astrazione per l'accesso ai dati.
    *   Difficoltà nel gestire caching e ottimizzazioni delle query in modo centralizzato.
6.  **Widget Complessi e Monolitici:**
    *   `WorkoutDetails` è molto esteso e difficile da manutenere.
7.  **Gestione Manuale della Cache:**
    *   Logica di caching custom in `WorkoutService`.
8.  **Gestione Sottoscrizioni Firestore:**
    *   Necessità di gestione attenta per evitare memory leak (`_subscriptions` in `WorkoutService`).

## Miglioramenti Pianificati (Aggiornato dopo analisi)
1.  **Architettura Pulita a Layer:**
    *   **Data Layer:** Repositories per Firestore (es. `WorkoutRepository`, `WeekRepository`). Gestione centralizzata della cache.
    *   **Domain Layer:** Use Cases/Servizi specializzati (es. `CalculateMaxWeightUseCase`, `CompleteSeriesService`).
    *   **Presentation Layer:** State Notifiers (Riverpod) per la logica UI, Widget "dumb".
2.  **Servizi Focalizzati:** Suddividere `WorkoutService` e `TrainingProgramServices`.
3.  **Provider Riverpod Consolidati:** Unica fonte di verità per i provider, organizzati per feature/layer.
4.  **Modelli Dati Robusti:** Immutabilità, `copyWith`, `fromJson/toJson`.
5.  **UI Modulare:** Scomporre widget complessi. Creare componenti riutilizzabili.
6.  **Dialoghi Semplificati:** Estrarre logica dai dialoghi.
7.  **Logica di Business Centralizzata:** Spostare la logica dai widget ai nuovi servizi del domain layer o State Notifiers.
8.  **Testabilità:** Migliorare la testabilità attraverso l'iniezione di dipendenze e la separazione dei concern.

## Proposta Iniziale Nuova Architettura (Punto 1.3)
*   **Data Layer:**
    *   Contiene i Repositories (es. `FirestoreWorkoutRepository`, `FirestoreWeekRepository`, `SharedPreferencesPresetRepository`).
    *   Responsabili dell'interazione con le fonti dati (Firestore, SharedPreferences).
    *   Implementano la logica di caching dei dati.
    *   Espongono metodi per CRUD e query (es. `Stream<List<Workout>> getWorkouts(String weekId)`).
*   **Domain Layer:**
    *   Contiene Use Cases (o Servizi di Dominio) che incapsulano specifiche logiche di business.
    *   Esempi: `LoadWorkoutDetailsUseCase`, `CompleteSetUseCase`, `SaveTimerPresetUseCase`, `CalculateOneRepMaxUseCase`.
    *   Orchestrano le chiamate a uno o più Repositories.
    *   Sono classi Dart pure, facilmente testabili.
*   **Presentation Layer:**
    *   **State Management (Riverpod):**
        *   `StateNotifier` per gestire lo stato della UI e le interazioni dell'utente.
        *   Ogni `StateNotifier` dipende da Use Cases o Repositories (iniettati).
        *   Esempi: `WorkoutDetailsNotifier`, `ExerciseTimerNotifier`, `TrainingProgramNotifier`.
    *   **UI (Flutter Widgets):**
        *   Widget il più possibile "dumb", ricevono dati e callback dagli State Notifiers.
        *   Strutturati in componenti riutilizzabili.
        *   La navigazione e la visualizzazione dei dialoghi sono gestite o coordinate dagli State Notifiers o tramite specifici servizi di navigazione/dialogo.
*   **Struttura Cartelle (Proposta Iniziale per il modulo `Viewer`):**
    ```
    lib/viewer/
    ├── data/
    │   ├── datasources/      # Interfacce per Firestore, SharedPreferences, ecc.
    │   │   └── firestore_service.dart
    │   ├── models/           # Modelli dati usati dai repository (potrebbero essere comuni)
    │   ├── repositories/     # Implementazioni dei repository
    │   │   └── workout_repository_impl.dart
    ├── domain/
    │   ├── entities/         # Entità di dominio (se diverse dai modelli data)
    │   ├── repositories/     # Interfacce dei repository (contratti)
    │   │   └── workout_repository.dart
    │   ├── usecases/         # Casi d'uso
    │   │   └── load_workout_details.dart
    ├── presentation/
    │   ├── notifiers/        # StateNotifiers di Riverpod
    │   │   └── workout_details_notifier.dart
    │   ├── pages/            # Schermate principali del modulo Viewer
    │   │   └── workout_details_page.dart
    │   ├── widgets/          # Widget riutilizzabili specifici del Viewer
    │   │   └── exercise_card.dart
    │   └── view_models/      # Modelli specifici per la vista (se necessario)
    └── viewer_providers.dart # File centrale per i provider del modulo Viewer
    ```

## Registro dei Progressi

| Data       | Fase completata                                       | Note                                                                                                   |
|------------|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| <data_odierna> | 1.1 Analisi dell'architettura attuale             | Completata                                                                                             |
| <data_odierna> | 1.2 Identificazione dei problemi                  | Completata, problemi dettagliati sopra                                                                |
| <data_odierna> | 1.3 Definizione della nuova architettura            | Proposta iniziale approvata                                                                            |
| <data_odierna> | 2.1, 2.5 Struttura Layer e Cartelle               | Definite e create                                                                                      |
| <data_odierna> | 2.4 Provider Repository e Use Case                | Definiti in `viewer_providers.dart`                                                                    |
| <data_odierna> | 2.2, 2.3 Implementazione Repository          | `TimerPresetRepositoryImpl` e `WorkoutRepositoryImpl` (CRUD e lettura) completati.                     |
| <data_odierna> | 3.1, 3.2 Standardizzazione Entità e Metodi Helper   | Entità di dominio con `copyWith`, `toMap`/`fromMap` completate.                                         |
| <data_odierna> | 3.3 Creazione Use Cases                         | Creati Use Case per Serie, Note Esercizio, Timer Presets. Provider aggiunti.                         |
| <data_odierna> | 4.1 (Inizio) Creazione State Notifiers            | Creati `ExerciseTimerNotifier` e `WorkoutDetailsNotifier`.                         |
| <data_odierna> | 3.4 Gestione cache a livello Repository | Implementata cache base in `TimerPresetRepositoryImpl` |
| <data_odierna> | 2.X Risoluzione TODO rimanenti | Implementato metodo `updateExercisesInWorkout` in `WorkoutRepositoryImpl` e gestione note nell'eliminazione esercizi |
| <data_odierna> | 4.1 (Continuo) Refactoring Widget | Creato nuovo widget `ExerciseTimerBottomSheet` che utilizza `ExerciseTimerNotifier` |
| <data_odierna> | 4.1 (Continuo) Refactoring Widget | Creato nuovo widget `WorkoutDetailsPage` che utilizza `WorkoutDetailsNotifier` |
| <data_odierna> | 4.1 (Continuo) Refactoring Widget | Creato nuovo widget `TrainingViewerPage` come punto di ingresso principale del modulo |
|            |                                                       |                                                                                                        |

## Note e Considerazioni
- Priorità alla stabilità: ogni modifica deve essere testata attentamente.
- Mantenere la retrocompatibilità con il resto dell'applicazione o pianificare migrazioni.
- Documentare i cambiamenti significativi per facilitare la manutenzione futura.
- Procedere in modo incrementale, testando dopo ogni modifica significativa. 