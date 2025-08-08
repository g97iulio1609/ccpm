## Obiettivi

- Correggere tutti gli errori e completare il refactoring di TrainingBuilder e Viewer (DRY, KISS, SOLID)
- Uniformare data layer, stato e componenti UI
- Migliorare UX (performance, accessibilità, coerenza visiva)
- Integrare test e strumenti di qualità

## Roadmap step-by-step

1) Stabilità e qualità di base
- Verifica build/lint su tutto il repo
- Uniformare definitivamente gli import `Viewer` (case-sensitive) ovunque
- Rafforzare `analysis_options.yaml` (lint più severi)
- Setup CI (lint + test) per evitare regressioni

2) Struttura del progetto e naming
- Consolidare modelli e mapper in `lib/shared/models` e `lib/shared/mappers`
- Spostare util comuni in `lib/shared/utils` (formatter, validator, logger)
- Allineare naming file/cartelle a lower_snake_case ovunque

3) Data layer unificato (Builder + Viewer)
- Definire repository condivisi in `lib/shared/repositories` (TrainingRepository, WorkoutRepository, TimerPresetRepository)
- Implementazioni Firestore in `infrastructure/...` per entrambi i moduli
- Ridurre N+1 (parallelizzazione con Future.wait) in tutte le fetch (già fatto per Viewer)
- Aggiornare/creare indici Firestore necessari

4) Stato e Dependency Injection
- Riverpod ovunque per lo stato e i provider
- Convergere i `ChangeNotifier` orientati UI e i `StateNotifier` per logiche più complesse
- Un contenitore DI per Builder (`TrainingBuilderDI`) e uno per Viewer (`viewer_providers.dart`) puntati ai repository condivisi

5) Refactor TrainingBuilder
- Rimuovere controller legacy duplicati, mantenendo le versioni refactor
- Consolidare dialog/forme (esercizi, serie, superset) usando `RangeControllers` condiviso
- Migliorare riordino e copia (week/workout/exercise) con validazioni chiare e messaggistica UX coerente

6) Refactor Viewer
- Caching coerente e prefetch ottimizzato (già migliorato)
- Subscriptions per exerciseId (già corretto) e gestione note fluida
- Timer con preset stabili, opzione EMOM e feedback chiari

7) UI/UX e Design System
- Uniformare componenti (card, badge, divider, chip, dialog, empty state)
- Stati di errore e loading coerenti (skeleton, pull-to-refresh)
- Accessibilità: contrasto, touch target, semantic label, focus order

8) Error handling e logging
- Handler centralizzato errori (Firestore, rete, permessi)
- Logging strutturato; eventuale integrazione crashlytics

9) Performance
- Prefetch settimanale selettivo (on-expand), pagination se necessario
- Cache locale mirata (SharedPreferences/Hive per preset e metadati)
- Debounce nelle query di ricerca/filtri

10) Test
- Unit test: repository e business services (TrainingBusinessService, WorkoutRepositoryImpl)
- Widget test: `TrainingViewerPage`, `WorkoutDetailsPage`, dialog chiave
- Golden test: card e componenti UI principali
- Integration test (emulatore Firestore) per CRUD completo

11) Rilascio e documentazione
- Aggiornare `MIGRATION_GUIDE.md` e `README.md` (architettura, convenzioni, come aggiungere feature)

## Prossime azioni (immediate)
- Scansione globale import `package:alphanessone/viewer/` e normalizzazione a `.../Viewer/...` (completata)
- Allineare i dialog di bulk series al `RangeControllers` condiviso (completata)
- Eseguire `flutter analyze` e correggere i warning residui (in corso)
- Sostituire `PopupMenuButton` con `MenuAnchor` dove opportuno (in corso)

## Criteri di accettazione
- Build verde, lint a zero per i file toccati
- Test esistenti e nuovi verdi
- Nessuna regressione funzionale (CRUD, timer, note, progressi)
- UI coerente, accessibilità base rispettata


