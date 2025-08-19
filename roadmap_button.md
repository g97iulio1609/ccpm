# Roadmap — Pulsanti, Glass e Autocomplete

Questo documento riepiloga quanto completato e la roadmap per uniformare lo stile dei pulsanti (Glass “lite”), l’autocomplete basato su SearchAnchor/SearchBar e le rifiniture dei dialog in tutta l’app.

## Completato

- Autocomplete unificato con Material 3 SearchAnchor + SearchBar
  - Creato `lib/common/app_search_field.dart` (debounce, suggerimenti async, overlay Glass, controller condiviso, fix per overlay input).
  - Migrazione dei punti che usavano `GenericAutocompleteField`/`AppAutocompleteField`:
    - `lib/exerciseManager/exercises_manager.dart` (barra ricerca esercizi)
    - `lib/ExerciseRecords/exercise_autocomplete.dart`
    - `lib/trainingBuilder/dialog/add_exercise_dialog.dart`
    - `lib/trainingBuilder/dialog/athlete_selection_dialog.dart`
    - `lib/nutrition/tracker/food_autocomplete.dart`
    - `lib/UI/components/user_autocomplete.dart`
  - Rimozione file deprecati: `lib/common/generic_autocomplete.dart`, `lib/common/app_autocomplete.dart`.
  - Overlay Glass coerente per SearchView e righe suggerimenti (opacità aumentata per leggibilità).

- TrainingBuilder — estetica e funzionalità
  - Dialog import JSON/CSV:
    - Responsive (scroll interno, niente overflow) e editor adattivo con `expands`.
    - Anteprima on‑demand (non rallenta): conteggi settimane/workouts/esercizi/serie.
    - Parser JSON tollerante: accetta `{ "program": {...} }` o direttamente `{ name, weeks, ... }`.
    - Fix crash: guardie `_disposed` nel controller per import.
  - Pulsanti pagina programma:
    - Sostituiti i `FilledButton.*` con `AppButton` (Glass “lite”), varianti coerenti: `primary` su azioni principali, `subtle/outline` sulle secondarie.
    - Pulsante admin “Select Athlete” convertito a `AppButton`.
  - Dialog TrainingBuilder:
    - Azioni uniformate via `AppDialogHelpers` + `AppButton` in
      - `exercise_management_dialogs.dart`
      - `series_dialog.dart`
      - `athlete_selection_dialog.dart`
      - opzioni esercizio (aggiunta/crea superset) in `exercise_options_dialog.dart`.
  - Controller minori: pulsanti di chiusura/cancel nei piccoli `AlertDialog` convertiti a `AppDialogHelpers` (week/workout controller).

- Viewer — dialog note
  - `WorkoutDialogs.showNoteDialog` e `workout_details/note_dialog.dart` usano `AppDialogHelpers`/`AppButton` (incluso stato destructivo per “Elimina”).

- Glass overlay per Autocomplete
  - Stile coerente “Glass lite”: opacità alzata (SearchView ~184, righe ~196), bordo più marcato; stesso set nella versione generica `AppSearchField`.

- Verifica lint
  - `flutter analyze` verde sui file toccati.

## Dettagli implementativi (principali)

- `AppSearchField<T>`
  - Un unico `SearchController` condiviso tra `SearchAnchor` e `SearchBar`.
  - Listener per aggiornare i suggerimenti da overlay e da bar; debounce; guardia `lastReqId` per evitare race.
  - `SearchViewThemeData` e parametri del `SearchBar` con MaterialStateProperty, opacità Glass, bordo coerente.

- `AppDialog`
  - Wrapper Glass con gestione insets tastiera; altezza massima dinamica e scroll interno per evitare overflow.
  - `AppDialogHelpers` ora restituisce `AppButton` con varianti `primary/subtle/destructive` coerenti.

- `AppButton`
  - Widget centralizzato: varianti, dimensioni, glass on/off, icona + label, block.
  - Mantiene `MaterialButton` interno per piena compatibilità semantica/gestione tap.

## Da completare (Roadmap)

- Pulse “Glass Button” in tutta l’app (azioni di dialog e pulsanti pagina):
  - Store
    - [x] `lib/Store/payment_failure_screen.dart` (Elevated/Outlined)
    - [x] `lib/Store/payment_success_screen.dart` (Elevated)
    - [x] `lib/Store/stripe_checkout_widget.dart` (Elevated)
    - [x] `lib/Store/subscriptions_screen.dart` (Text/Filled/Elevated, dialog interni)
  - Nutrition
    - [x] `lib/nutrition/tracker/diet_plan_screen.dart` (Filled)
    - [x] `lib/nutrition/tracker/food_management.dart` (Elevated)
    - [x] `lib/nutrition/tracker/view_diet_plans_screen.dart` (Text/Elevated, dialog)
    - [x] `lib/nutrition/tracker/food_list.dart` (Text multipli in dialog)
  - Viewer
    - [x] `lib/Viewer/presentation/widgets/exercise_timer_bottom_sheet.dart` (Text/Filled/Outlined in bottom sheet)
    - [x] `lib/Viewer/presentation/widgets/workout_details/series_execution_dialog.dart` (Text/Filled)
    - [x] `lib/Viewer/presentation/pages/workout_details_page.dart` (Text/Filled — azioni locali)
    - [x] `lib/Viewer/UI/training_viewer.dart` (TextButton in toolbar/azioni)
  - ExerciseRecords
    - [x] `lib/ExerciseRecords/widgets/edit_record_dialog.dart` (Text/Filled)
    - [x] `lib/ExerciseRecords/exercise_stats.dart` (Text/Filled)
    - [x] `lib/ExerciseRecords/maxrmdashboard.dart` (Text/Filled)
  - Users / Auth / Profile
    - [x] `lib/users_dashboard.dart` (Text/Filled nelle azioni)
    - [x] `lib/user_profile.dart` (Elevated)
    - [x] `lib/auth/auth_buttons.dart` (MaterialButton → AppButton mantenendo varianti e dimensioni)
    - [x] `lib/auth/auth_form.dart` (TextButton)
    - [x] `lib/main.dart` (Elevated in percorsi on‑boarding)
  - Varie UI
    - [x] `lib/UI/app_bar_custom.dart` (Text/Elevated in menù contestuali → usare `AppButton.icon` o `MenuItemButton` con stile coerente)
    - [x] `lib/trainingBuilder/shared/widgets/progression_components.dart` (Elevated)
    - [x] `lib/trainingBuilder/presentation/forms/bulk_series_form.dart` (Elevated)
    - [x] `lib/measurements/widgets/measurement_form.dart` (TextButton su dialog)

- Regole di conversione (coerenti e non distruttive):
  - Azioni di dialog: usare `AppDialogHelpers.buildCancelButton/buildActionButton` (mantiene semanticità e consistenza visiva Glass); usare `isDestructive` quando serve.
  - Pulsanti “primari” (salvataggio/applicazione): `AppButton` con `variant: primary`.
  - Pulsanti “secondari”: `AppButton` con `variant: subtle` o `outline`.
  - Azioni app bar/toolbar: preferire `IconButton` per compattezza; per CTA prominenti usare `AppButton.icon` versione compatta.
  - Mantenere onPressed e flussi invariati (nessuna rimozione logica), solo sostituzione visuale.

- Autocomplete: verifiche extra
  - [ ] Validare overlay e suggerimenti in eventuali nuovi punti d’uso (es. se si estende `AppSearchField` a ricerche non esercizi).
  - [ ] Opzionale: soglia caratteri per dataset molto grandi (configurabile per singolo call‑site).

## Criteri di accettazione

- Nessuna regressione funzionale: callback/azioni invariati.
- `flutter analyze` pulito per ogni batch di conversione.
- Consistenza visiva: paddings, radius, hover/focus/pressed, contrasti AA.
- Touch target ≥ 44/48 px, overlay coerenti.

## Test rapidi (manuali)

- TrainingBuilder
  - Import JSON/CSV con testo lungo → dialog scrolla, nessun overflow, anteprima corretta.
  - Importa JSON con root `program` e oggetto diretto → nessun crash. Salvataggio programma ok.
  - Ricerca esercizi: suggerimenti visibili da 1 char, aggiornano con backspace.
- Viewer
  - Dialog note: Elimina/Annulla/Salva coerenti (destructive su Elimina).
- Regressioni zero su: navigazione, drawer, salvataggi.

## Appendice — File toccati (principali)

- Nuovi/Modificati chiave
  - `lib/common/app_search_field.dart` (nuovo)
  - `lib/trainingBuilder/dialog/exercise_dialog.dart` (stile overlay e bar)
  - `lib/UI/components/app_dialog.dart` (scroll + helpers → AppButton)
  - `lib/UI/components/button.dart` (usato come base coerente)
  - `lib/trainingBuilder/training_program.dart` (pulsanti + import)
  - `lib/trainingBuilder/services/training_share_service_async.dart` (parser JSON tollerante)
  - `lib/trainingBuilder/controller/training_program_controller.dart` (guardie `_disposed`)
  - Dialog TB vari: `exercise_management_dialogs.dart`, `series_dialog.dart`, `athlete_selection_dialog.dart`, `exercise_options_dialog.dart`
  - Dialog Viewer: `workout_dialogs.dart`, `workout_details/note_dialog.dart`

---

Nota: la classe `_GradientElevatedButton` è ancora presente ma non più referenziata; può essere rimossa in un cleanup finale dopo aver concluso la migrazione globale ai `AppButton`.
