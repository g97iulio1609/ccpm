# Analisi sostituzione `flutter_typeahead` (WASM‑safe)

## Obiettivo
- Rimuovere la dipendenza da `flutter_typeahead` (e in cascata `flutter_keyboard_visibility_web`), che introduce `dart:html` lato web e impedisce il build Wasm.
- Sostituire le funzionalità di “typeahead/autocomplete” con alternative WASM‑safe, preferibilmente native Flutter, mantenendo UX e API il più possibile stabili.

## Dove è usato oggi
- `lib/common/generic_autocomplete.dart` (wrapper generico usato in più punti)
- `lib/UI/components/user_autocomplete.dart` (usa GenericAutocompleteField)
- `lib/exerciseManager/exercises_manager.dart` (usa direttamente `TypeAheadField<ExerciseModel>`, con molte opzioni: builder personalizzato, suggestionsCallback async, itemBuilder, onSelected, debounce, constraints, decorationBuilder, ecc.)
- Altri punti indiretti: `Coaching/coaching_screen.dart`, `measurements/measurements.dart`, `nutrition/tracker/daily_food_tracker.dart`, `ExerciseRecords/widgets/max_rm_search_bar.dart` (tramite `UserTypeAheadField` → `GenericAutocompleteField`)

## Opzioni di sostituzione
1) Nativo Flutter: `RawAutocomplete<T>` / `Autocomplete<T>`
- Pro: 100% supportato, WASM‑safe, no dipendenze esterne; altissima longevità.
- Contro: `optionsBuilder` è sincrono; per usare sorgenti async va gestita una cache interna di “opzioni correnti” e il debounce manuale. Richiede codice di adattamento per emulare alcune feature.

2) Altro package (es. `searchfield`, `flutter_search_bar`, ecc.)
- Pro: potenzialmente simile a `flutter_typeahead` come API.
- Contro: rischio di nuove dipendenze non WASM‑safe; possibile lock-in; manutenzione futura incerta.

Scelta raccomandata: nativo Flutter (`RawAutocomplete`) con un “compat layer” che espone una API simile a `TypeAheadField` per minimizzare modifiche ai call‑site.

## Strategia di migrazione (compat layer)
- Creare un widget `TypeAheadFieldCompat<T>` (o esportarlo come `TypeAheadField` da un nostro file per evitare refactor invasivo) che:
  - Esponga i costruttori/parametri effettivamente usati oggi:
    - `builder: (context, controller, focusNode)`
    - `suggestionsCallback: Future<List<T>> Function(String)`
    - `itemBuilder: Widget Function(BuildContext, T)`
    - `onSelected: void Function(T)`
    - `debounceDuration`, `constraints`, `decorationBuilder`, `emptyBuilder`, `hideOnEmpty`/`hideOnLoading` (opzionali, emulate)
  - Internamente usi `RawAutocomplete<T>` con:
    - Uno stato locale che mantiene la lista opzioni correnti (aggiornata tramite `suggestionsCallback` su text change) + debounce (Timer / hooks / Rx se già presente).
    - `optionsViewBuilder` personalizzato per renderizzare i risultati con la stessa UI (riuso di `GlassLite`, `decorationBuilder`, `constraints`, ecc.).
    - `fieldViewBuilder` per rispettare il `builder` esistente.
    - `onSelected` inoltrato.
  - Gestione di `emptyBuilder`: se nessun risultato, mostra widget custom o SizedBox.
  - `hideWithKeyboard`: non necessario lato web (WASM). Possiamo ignorarlo o simularne l’effetto con `FocusScope`.

- Aggiornare `generic_autocomplete.dart` per usare `TypeAheadFieldCompat<T>` invece di `flutter_typeahead`.
- Nei punti che usano direttamente `flutter_typeahead` (es. `exercises_manager.dart`), importare il nostro compat e sostituire 1:1 (stesse signature usate in repo; se manca un parametro, si ignora o si emula).
- Rimuovere la dipendenza da `flutter_typeahead` in `pubspec.yaml`.

## Complessità e rischi
- Complessità: bassa‑media.
  - La parte “generica” è centralizzata in `GenericAutocompleteField`: facile.
  - `exercises_manager.dart` usa `TypeAheadField` direttamente con più opzioni: va trasposto nel compat layer (gestibile; ~100‑150 LOC). 
- Rischi:
  - Differenze minime di comportamento overlay (posizionamento, focus) — mitigabile con test UI manuale.
  - Debounce: da verificare tempi predefiniti e UX percepita.
  - Tastiere mobili: `flutter_typeahead` gestiva auto-hide con `keyboard_visibility`; su web WASM non serve; su mobile/desktop usiamo focus management standard.
- Benefici:
  - Rimozione totale della dipendenza “problematic” in ottica WASM; build leggero e sicuro.
  - Meno lock‑in su terze parti; solo Flutter SDK.

## Stima tempi
- Implementazione compat + migrazione wrapper: 2–3 ore.
- Migrazione casi diretti (`exercises_manager.dart`): 1–2 ore.
- Test manuale principali (web/mobile): 1–2 ore.
- Totale: 1 giornata scarsa (6–7 ore) con buffer.

## Piano (step‑by‑step)
1. Mappare i call‑site e i parametri effettivamente usati (DONE, lista sopra)
2. Creare `lib/common/typeahead_compat.dart` con `TypeAheadFieldCompat<T>` basato su `RawAutocomplete<T>`
3. Aggiornare `lib/common/generic_autocomplete.dart` per usare il compat
4. Migrare `lib/exerciseManager/exercises_manager.dart` a compat (sostituire import e costruttore)
5. Rimuovere `flutter_typeahead` da `pubspec.yaml` e `pubspec.lock` (pub get)
6. `dart analyze` + `flutter build web` con wasm dry run
7. QA rapido su overlay/UX (web+mobile); fine‑tuning debounce/margini
8. Documentare in `sub.md` le differenze comportamentali e fallback

## Fallback
- Se emergono regressioni, possiamo:
  - Ripristinare temporaneamente l’override locale già presente per `flutter_keyboard_visibility_web` (già predisposto) e pianificare il roll‑out del compat in una seconda release.
  - Introdurre un feature flag per usare compat vs. typeahead legacy in aree critiche (solo se necessario).

## Conclusione
- La sostituzione è tecnicamente fattibile con impatto contenuto, grazie ad un compat layer che preserva l’API usata. Rimuove l’ostacolo WASM a livello di dipendenze e semplifica lo stack. Consiglio di procedere con il piano sopra.

