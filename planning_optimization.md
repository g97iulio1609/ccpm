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

## Linee guida di consolidamento

- Tenere solo le versioni sotto `presentation/*` per UI (pagine, widget, dialog, form).
- Spostare la business-logic in `domain/services/*` e tenere i controller come orchestratori UI.
- Unificare i servizi “Max Weight” in un’unica API e aggiornare i call-site.
- Completare la gestione dei Superset con `copyWith` e riassegnazioni immutabili.
- Estrarre componenti UI condivisi: `PageScaffold`, `EmptyState`, pulsanti azione coerenti, `ReorderDialog` sotto `shared/widgets/`.

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

1) Struttura e spostamenti
- Creare cartelle target; spostare versioni refactor in `presentation/*` e `shared/*`;
- Aggiornare import e referenze (Builder e Viewer).

2) Pulizia duplicati
- Eliminare legacy (`List/*`, `UI/*`, `dialogs/*` duplicati) dopo che tutti i call-site puntano ai nuovi percorsi.

3) Consolidamento logica
- Unificare servizio “Max Weight” e aggiornare utilizzi;
- Completare Superset con `copyWith` immutabile;
- Centralizzare `updateSeries` in un unico punto logico.

4) UI/UX
- Introdurre `PageScaffold` ed `EmptyState` condivisi; allineare pulsanti e FAB; rifinire spacing/gradient.

5) Qualità
- Eseguire `flutter analyze` e fixare import non usati;
- Verificare test UI esistenti (es. `test/ui/*`) e aggiungere smoke test minimi per nuove pagine;
- Valutare CI locale (lint + test) per regressioni.

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

- Spostare `reorder_dialog.dart` in `shared/widgets` e aggiornare tutti i call-site.
- Migrare `List/exercises_list.dart` verso `presentation/pages/exercises_page.dart` e rimuovere duplicati.
- Unificare API “Max Weight” ed aggiornare `series_list_widget` e i dialog.
- Completare metodi Superset con `copyWith`.
- Passata di `flutter analyze` e correzione warning.
