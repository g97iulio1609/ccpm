## Obiettivo

Unificare e rifattorizzare i moduli Viewer e TrainingBuilder secondo KISS, DRY, SOLID e Material 3, eliminando duplicazioni e stabilendo una UI/UX coerente e moderna.

## Principi guida

- **KISS**: widget e classi con responsabilità chiare, metodi brevi, minori parametri impliciti.
- **DRY**: rimozione duplicazioni (Viewer/TrainingBuilder), utility condivise.
- **SOLID**: separazione presentation/stato/business, dipendere da astrazioni (repository/use case), componenti estendibili e testabili.
- **UI/UX**: Material 3, componenti coerenti, micro‑interazioni e accessibilità.

## Milestones

### 1) Consolidamento Viewer (Workout Details)
- [x] Rendere canonica la pagina `presentation/pages/workout_details_page.dart` nel router (`Main/app_router.dart`).
- [x] Rimuovere duplicati: `Viewer/UI/workout_details.dart` e `Viewer/UI/workout_details_refactored.dart` (dopo aggiornamento call‑site).
- [x] Spostare/riutilizzare i widget sotto `Viewer/presentation/widgets/*` ove necessario (evitare duplicati in `UI/widgets`).
- [x] Verificare prefetch e controllo abbonamento restino funzionanti in `UnifiedTrainingViewer` → navigazione workout details.
- [x] Allineare naming/import a snake_case e percorsi definitivi.

### 2) Timer Presets nel dominio (repository/use case + provider)
- [x] Centralizzare i preset timer nel dominio (repository + use case: get/save/update/delete).
- [x] Creare un `StateNotifier`/provider per esporre lista e mutazioni ai widget.
- [x] Adattare `TimerControls` e componenti timer a leggere/scrivere tramite provider (UI thin).
- [x] Eliminare `Viewer/UI/preset_manager.dart` e migrare la logica (inclusa cache `SharedPreferences`) dentro il repository.
- [x] Mantenere comportamento EMOM e notifiche locali in `TimerManager` (senza logica di persistenza nella UI).

### 3) Pulizia TrainingBuilder e allineamento architetturale
- [x] Rimuovere definitivamente UI legacy sotto `lib/trainingBuilder/List/*` (già sostituite da `presentation/pages/*`).
 - [x] Migrare i `ChangeNotifier` "fat" a `StateNotifier`/`Notifier` con stato tipizzato; tenere nei controller solo orchestrazione UI.
- [x] Spostare business‑logic in `trainingBuilder/domain/services/*` e riusare nei controller (immutabilità con `copyWith`).
- [x] Unificare definitivamente l’uso di "Max Weight" su `ExerciseService.getLatestMaxWeight` in tutti i call‑site.
 - [x] Completare flusso Superset immutabile (add/remove, cleanup superset vuoti) e riassegnazioni sicure.
 - [x] Estrarre funzioni serie (range, reorder, recalc orders) in `SeriesBusinessService` e aggiornare i call‑site.
 - [x] Aggiornare import, naming e rimuovere file obsoleti residui.
 - [x] Migrare i `ChangeNotifier` "fat" a `StateNotifier`/`Notifier` con stato tipizzato; tenere nei controller solo orchestrazione UI.
  
Completati in questa fase:
- [x] Reorder/replace/recalculate immutabili per series tramite `SeriesBusinessService` e integrazione nei controller.

### 4) Pass UI/UX Material 3 e componenti moderni (Flutter 3.32.x)
- [x] Abilitare Material 3 (`useMaterial3: true`) e `ColorScheme.fromSeed`, integrando `dynamic_color` per palette adaptive.
- [x] Sostituire CTA principali con `FilledButton`; secondarie con `FilledButton.tonal` o `OutlinedButton` dove opportuno.
- [x] Introdurre `SegmentedButton` per switch layout (Lista/Griglia, Compatta/Dettaglio) nelle liste allenamenti/esercizi.
- [x] Integrare `SearchBar`/`SearchAnchor` nel dialog "Cambia esercizio" e nelle pagine con ricerca.
- [x] Uniformare i menu contestuali con `MenuAnchor`/`RawMenuAnchor` M3.
- [x] Rappresentare lo stato delle serie con `Chip`/`Badge` M3 (completata/fallita/non svolta) invece di sole icone.
- [x] Standardizzare `PageScaffold` e `EmptyState` condivisi su tutte le pagine (Viewer e TrainingBuilder) con gradient/padding coerenti. (in corso di completamento; principali pagine TB aggiornate)
- [x] iOS: adozione forme "squircle" dove rilevante e aggiornamenti Cupertino; mantenere `UI/app_bar_custom.dart` come app bar globale senza creare duplicati. (verificato)
- [x] Micro‑interazioni: usare `AnimatedSwitcher`, `SliverAnimatedList`/`AnimatedList`, transizioni coerenti tra stati (loading/empty/content). (applicate su weeks/workouts)

### 5) Qualità, lint e test
- [ ] Rafforzare lint (valutare riattivazione `use_build_context_synchronously` e rimozione eccezioni generiche nelle regole locali).
- [ ] Eseguire `flutter analyze --fatal-infos` e sistemare warning/import non usati.
- [ ] Aggiornare/aggiungere smoke test UI in `test/ui/*` per le pagine principali (weeks, workouts, exercises, workout details).
- [ ] Valutare setup CI locale per lint + test (facoltativo ma raccomandato).
- [ ] Uniformare naming a snake_case per file/cartelle e rimuovere refusi.

## Criteri di accettazione
- [x] Router aggiornato a pagina workout details modulare; nessun riferimento ai file duplicati rimossi.
- [x] Preset timer gestiti via repository/use case + provider; UI priva di persistenza diretta (niente `PresetManager` in UI).
- [x] Controller snelli (orchestrazione) e business‑logic in `domain/services/*`; superset e serie gestiti in modo immutabile.
- [x] UI coerente Material 3 con componenti moderni (FilledButton, SegmentedButton, SearchBar, Chip/Badge, MenuAnchor).
- [ ] `flutter analyze --fatal-infos` verde sull’intero workspace; test UI principali eseguiti con esito positivo.


