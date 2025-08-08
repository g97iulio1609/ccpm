## Obiettivo

Unificare e rifattorizzare i moduli TrainingBuilder e Viewer seguendo KISS, DRY, SOLID e una migliore modularità/UI. Eliminare codice duplicato/obsoleto, rinominare e riordinare file/cartelle per una struttura chiara e coerente.

## Ambito e principi

- **KISS**: classi e widget con responsabilità chiare, metodi brevi, meno parametri impliciti.
- **DRY**: rimuovere duplicazioni tra legacy (List/UI) e nuove versioni (presentation/*). Estrarre utility condivise.
- **SOLID**: separare presentazione, stato e business-logic; dipendere da astrazioni; componenti aperti all'estensione.
- **Modularità**: pagine, widget, dialog e form in cartelle dedicate; domain/services separati da presentation.
- **UI/UX**: componenti coerenti (card, dialog, empty state, FAB/menù), gradient/layout standardizzati.

## Stato attuale sintetico

- TrainingBuilder contiene due linee di UI:
  - Legacy: `lib/trainingBuilder/List/*.dart` e `lib/trainingBuilder/dialogs/*`.
  - Nuova: `lib/trainingBuilder/presentation/**/*` (pagine, widget, dialog, form).
- Dialog e servizi duplicati (es. gestione serie, bulk, max weight).
- `SuperSetController` con metodi non completati per immutabilità (nota di refactor pending).
- Viewer ha doppioni: `UI/workout_details*.dart` vs versione modulare e note di migrazione; esiste anche una pagina molto grande in `presentation/pages/workout_details_page.dart` da smontare in widget modulari.

Completato:
- Spostato `reorder_dialog.dart` in `trainingBuilder/shared/widgets/` e aggiornati i call‑site.
- Create e applicate UI condivise: `shared/widgets/page_scaffold.dart` e `shared/widgets/empty_state.dart`.
  - Applicato a: `trainingBuilder/presentation/pages/workouts_page.dart`, `weeks_page.dart`, `exercises_page.dart` e `Viewer/presentation/pages/workout_details_page.dart` (loading/error/empty).
- Migrazione pagine legacy → modulari:
  - `List/workout_list.dart` → `presentation/pages/workouts_page.dart` (legacy rimosso)
  - `List/week_list.dart` → `presentation/pages/weeks_page.dart`
  - `List/exercises_list.dart` → `presentation/pages/exercises_page.dart`
- Consolidamento dialog esercizi: introdotto `presentation/widgets/dialogs/exercise_management_dialogs.dart` e rimosse varianti duplicate legacy.
- SuperSet: aggiornato `super_set_controller.dart` per mutazioni immutabili con `copyWith` (add/remove esercizio, cleanup superset vuoti).
- DRY MaxWeight: unificato su `ExerciseService.getLatestMaxWeight`; `SeriesUtils.getLatestMaxWeight` ora delega a `ExerciseService`.
- Series: `SeriesUtils.updateSeriesWeights` ora ritorna nuove `Series` e riassegna immutabilmente l’`exercise` nel `program`.
- Pulizia duplicati controller/DI: rimossi `dependency_injection.dart` e i controller `*_refactored.dart` non referenziati; mantenuto un unico `controller/exercise_controller.dart`.

## Linee guida di consolidamento

- Tenere solo le versioni sotto `presentation/*` per UI (pagine, widget, dialog, form).
- Spostare la business-logic in `domain/services/*` e tenere i controller come orchestratori UI.
- Unificare i servizi “Max Weight” in un’unica API e aggiornare i call-site.
- Completare la gestione dei Superset con `copyWith` e riassegnazioni immutabili.
- Estrarre componenti UI condivisi: `PageScaffold`, `EmptyState`, pulsanti azione coerenti, `ReorderDialog` sotto `shared/widgets/`.

Stato: linee guida sopra implementate parzialmente (vedi sezione “Completato”).

## Nuova struttura cartelle (proposta)

- `lib/trainingBuilder/`
  - `presentation/`
    - `pages/` (ex `List/*` consolidati: `exercises_page.dart`, `workouts_page.dart`, `weeks_page.dart`, `progressions_list_page.dart`)
    - `widgets/`
      - `cards/` (`exercise_card.dart`, `series_card.dart`)
      - `lists/` (`series_list_widget.dart`)
      - `dialogs/` (`exercise_dialog.dart`, `series_dialog.dart`, `bulk_series_dialog.dart`, `exercise_options_dialog.dart`)
      - `forms/` (`series_form_fields.dart`, `bulk_series_form.dart`)
  - `domain/`
    - `entities/` (eventuali view models)
    - `services/` (`exercise_business_service.dart`, `training_business_service.dart`, `week_business_service.dart`, `workout_business_service.dart`)
  - `infrastructure/`
    - `repositories/` (Firestore impl)
  - `controller/` (solo orchestrazione UI; usare versioni refactor)
  - `services/` (solo servizi thin di presentazione; logica in domain/services)
  - `shared/` (mixin, utils, widgets riutilizzabili; es. `reorder_dialog.dart`)

- `lib/Viewer/`
  - `presentation/`
    - `pages/` (`workout_details_page.dart` - versione modulare)
    - `widgets/` (`exercise_card.dart`, `superset_card.dart`, `series_widgets.dart`, `workout_dialogs.dart`, `workout_formatters.dart`, `exercise_timer_bottom_sheet.dart`)
    - `notifiers/` (`workout_details_notifier.dart`, ecc.)
  - `domain/` (entities, repositories, usecases)
  - `data/` (repositories impl)

## Azioni di rinomina e rimozione (prima migrazione call-site)

- TrainingBuilder (UI)
  - Rinominare/spostare:
    - `List/exercises_list.dart` → `presentation/pages/exercises_page.dart`
    - `List/workout_list.dart` → `presentation/pages/workouts_page.dart`
    - `List/week_list.dart` → `presentation/pages/weeks_page.dart`
    - `List/series_list.dart` → sostituito da `presentation/widgets/lists/series_list_widget.dart`
    - `dialog/series_dialog.dart` → `presentation/widgets/dialogs/series_dialog.dart`
    - `dialog/reorder_dialog.dart` → `shared/widgets/reorder_dialog.dart`
  - Rimuovere duplicati/obsoleti (dopo update import):
    - `List/*.dart` legacy (dove esiste l’equivalente in `presentation/pages/`)
    - `dialogs/bulk_series_dialogs.dart` (duplicato di `presentation/widgets/dialogs/bulk_series_dialog.dart`)
    - `dialogs/exercise_dialogs.dart` (duplicato; mantenere unico `exercise_dialog.dart`)

- Viewer
  - Rendere canonico `workout_details_page.dart` modulare (spostare la versione da `UI/` a `presentation/pages/` se necessario).
  - Spostare `UI/widgets/*` → `presentation/widgets/*`.
  - Rimuovere `UI/workout_details*.dart` e l’eventuale pagina monolitica in `presentation/pages/` dopo migrazione dei call-site.

## Consolidamento servizi e logica

- Max Weight
  - Unificare `ExerciseService.getLatestMaxWeight` e `SeriesUtils.getLatestMaxWeight` in un’unica funzione (es. in `services/exercise_service.dart`) e aggiornare i call-site (`exercises_page`, `series_list_widget`, dialog serie).

- SuperSet
  - Completare `SuperSetController.addExerciseToSuperSet/removeExerciseFromSuperSet` usando `copyWith`:
    - Aggiornare `workout.superSets` con nuova lista (immutabilità) e riassegnare via `workout.copyWith(superSets: ...)`.
    - Aggiornare `exercise.superSetId` via `exercise.copyWith(superSetId: ...)` e rimpiazzare nella lista `workout.exercises`.

- Controller
  - Preferire i controller refactor (`exercise_controller_refactored.dart`) e ridurre duplicazioni (metodi `updateSeries` presenti in più classi). Demandare pesi/validazioni a `domain/services/*`.

## UI/UX coerenza

- Introdurre `PageScaffold` condiviso: `SafeArea + CustomScrollView + SliverPadding + gradient`.
- Uniformare `EmptyState` (icona, titolo, sottotitolo, azione primaria) in `shared/widgets/`.
- Allineare pulsanti “opzioni” (dimensioni, tooltip, tonalità). Riutilizzare `BottomMenu` con intestazione coerente.

## Sequenza operativa (fasi)

1) Struttura e spostamenti — Fatto (prima tranche)
- Cartelle/UI condivise create; refusi legacy sostituiti con `presentation/*` e `shared/*`.
- Import e referenze aggiornati nelle pagine principali.

2) Pulizia duplicati — Fatto (prima tranche)
- Rimossi `List/*` coperti da `presentation/pages/*`, dialog legacy duplicati, `dependency_injection.dart`, controller `*_refactored.dart` non usati.

3) Consolidamento logica — In corso
- MaxWeight unificato e call-site aggiornati.
- Superset immutabili implementati.
- `updateSeriesWeights` reso immutabile; prossima estrazione verso `domain/services/*` dove opportuno.

4) UI/UX — In corso
- `PageScaffold`/`EmptyState` applicati a settimane, allenamenti, esercizi e viewer workout details.
- Prossimo: applicazione a progressioni e altre schermate residue.

5) Qualità — In corso
- `flutter analyze` su file modificati: verde.
- Prossimo: passata globale + aggiornamento test UI.

## Criteri di accettazione

- Build e analyze verdi su tutto il repo.
- Nessun riferimento ai file legacy rimossi (`List/*`, `UI/*` duplicati, dialog duplicati).
- Superset funzionanti (aggiunta/rimozione) senza mutazioni in-place.
- Unico servizio per “Max Weight”, usato da tutti i call-site.
- Pagine e widget con layout coerente (gradient, padding, menù opzioni).

## Rischi e mitigazioni

- Rotture import durante i rename: mitigare con refactor assistito e analyzer continuo.
- Cambiamenti di logica Superset: copertura manuale dei casi comuni (aggiungi, rimuovi, superset vuoto → cleanup).
- Divergenza tra Builder e Viewer: standardizzare provider e naming per evitare collisioni.

## Prossimi step immediati

- Applicare `PageScaffold`/`EmptyState` a `presentation/pages/progressions_list_page.dart` e consolidare la UI.
- Consolidare Progression: sostituire gradualmente `ProgressionBusinessService` con `ProgressionBusinessServiceOptimized` e aggiornare call‑site.
- Estrarre ulteriormente la logica serie (range, reorder) in `domain/services/*` e snellire `SeriesController`.
- Passata `flutter analyze` globale e fix import non usati.

## Milestones (checklist)

- [x] Spostamenti/Struttura iniziale
  - [x] Spostare `reorder_dialog.dart` in `trainingBuilder/shared/widgets/` e aggiornare i call‑site
  - [x] Migrare `List/week_list.dart` → `presentation/pages/weeks_page.dart`
  - [x] Migrare `List/workout_list.dart` → `presentation/pages/workouts_page.dart`
  - [x] Migrare `List/exercises_list.dart` → `presentation/pages/exercises_page.dart`
  - [x] Consolidare dialog esercizi in `presentation/widgets/dialogs/exercise_management_dialogs.dart`

- [x] UI/UX condivisa
  - [x] Creare `shared/widgets/page_scaffold.dart`
  - [x] Creare `shared/widgets/empty_state.dart`
  - [x] Applicare a `workouts_page.dart`
  - [x] Applicare a `weeks_page.dart`
  - [x] Applicare a `exercises_page.dart`
  - [x] Applicare a `Viewer/presentation/pages/workout_details_page.dart` (loading/error/empty)
  - [ ] Applicare a `presentation/pages/progressions_list_page.dart`

- [x] DRY/Logica
  - [x] Unificare MaxWeight su `ExerciseService.getLatestMaxWeight`
  - [x] Delegare `SeriesUtils.getLatestMaxWeight` a `ExerciseService`
  - [x] Rendere `SeriesUtils.updateSeriesWeights` immutabile (nuove `Series` e riassegnazione `exercise`)
  - [x] Refactor Superset con `copyWith` (add/remove esercizio, cleanup vuoti)
  - [x] Estrarre range/reorder serie in `domain/services/*` per snellire `SeriesController` (aggiunto `domain/services/series_business_service.dart` e integrato in `SeriesController`)

- [x] Pulizia Duplicati/Obsoleti
  - [x] Rimuovere `List/*` sostituiti
  - [x] Rimuovere dialog duplicati legacy
  - [x] Rimuovere `dependency_injection.dart` non referenziato
  - [x] Rimuovere controller `*_refactored.dart` non usati
  - [x] Consolidare `controller/exercise_controller.dart` come unica fonte

- [ ] Progressioni
  - [x] Sostituire `ProgressionBusinessService` con `ProgressionBusinessServiceOptimized`
  - [x] Aggiornare call‑site in `progressions_list_page.dart`
  - [x] Applicare `PageScaffold`/`EmptyState` alla pagina progressioni

- [ ] Qualità/Regressioni
  - [x] Passata `flutter analyze` globale e fix warning/import
  - [ ] Aggiornare/aggiungere smoke test UI (test/ui/*)
  - [ ] Valutare CI locale (lint + test)

## Step rimanenti (dettaglio)

- [x] Progressioni – rimozione wrapper legacy
  - [x] Aggiornare import in `exercise_options_dialog.dart` da `List/progressions_list.dart` a `presentation/pages/progressions_list_page.dart`
  - [x] Rimuovere `lib/trainingBuilder/List/progressions_list.dart`

- [x] Serie – immutabilità e DRY
  - [x] Refactor `presentation/widgets/lists/series_list_widget.dart` per evitare `exercise.series.remove/add` diretti (usare `SeriesBusinessService` + `TrainingProgramController.updateSeries`)
  - [x] Refactor `domain/services/exercise_business_service.dart` per evitare `exercise.series.add` in place
  - [x] Sostituire `SeriesController._updateSeriesOrders` con `SeriesBusinessService.recalculateOrders` e riassegnazione immutabile

- [ ] Allineamento struttura dialog
  - [x] Spostare `trainingBuilder/dialog/series_dialog.dart` → `trainingBuilder/presentation/widgets/dialogs/series_dialog.dart`
  - [x] Aggiornare tutti gli import referenti al nuovo path (aggiunto re-export e aggiornati controller/call-site)

- [x] Rimozioni legacy
  - [x] Rimuovere `lib/trainingBuilder/List/exercises_list.dart`
  - [x] Rimuovere `lib/trainingBuilder/List/series_list.dart`
  - [x] Rimuovere `lib/trainingBuilder/List/week_list.dart`
  - [x] Rimuovere `services/progression_business_service.dart` se non più referenziato
  - [x] Rimuovere file `.DS_Store` sotto `trainingBuilder/`
