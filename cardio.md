# Cardiovascolari — SOTA Planning (KISS, SOLID, DRY, Clean Architecture)

## PROGRESS LOG (YOLO)
- [x] 1) Revisione iniziale documento e struttura sezioni
- [x] 2) Aggiunte specifiche Phase 0 (flagging, gating, telemetria)
- [x] 3) Completate specifiche Phase 1 (dominio, servizi, repository)
- [x] 4) Completate specifiche Phase 2 (ExerciseManager: tipo/variant, UI, validazioni)
- [x] 5) Completate specifiche Phase 3 (TrainingBuilder: form, list, progressioni)
- [x] 6) Completate specifiche Phase 4 (Viewer: layout, timer, input esecuzione)
- [x] 7) Completate specifiche Phase 5 (Export/Import: JSON/CSV, compatibilità)
- [x] 8) Completate specifiche Phase 5.1 (MaxRM Dashboard: metriche e viste)
- [x] 9) Completate specifiche Phase 6 (QA, migrazione, rollout)
- [x] 10) Aggiunti NFR, assunzioni, range e glossario
- [x] 11) Pulizia finale, nomenclature coerenti, esempi JSON/CSV
- [x] 12) Tutti i task marcati completed [x]

Obiettivo: introdurre gli esercizi “Cardiovascolari” in ExerciseManager, TrainingBuilder e Viewer, con compatibilità retro, export/import aggiornati e UX coerente.

Assunzioni base:
- Unità di base archiviate in metrica: secondi, metri, km/h, sec/km, percentuale (%), bpm.
- UI visualizza metriche locali (km/mi) in base a `Settings.units` (inizialmente solo metric; imperial in backlog).
- Feature flag e telemetria sono infrastrutture già presenti (Remote Config + app-logger).
- Nessuna riprogettazione della navigazione; cardio è un tipo di esercizio come gli altri.

## Principi
- [x] KISS: design incrementale, feature-flag, UI adattiva per tipo esercizio
- [x] SOLID: separare dominio, servizi, presentazione; interfacce per calcoli cardio
- [x] DRY: riuso modelli/shared, ReorderDialog, componenti UI comuni
- [x] Clean Architecture: dominio indipendente, servizi e UI pluggabili

## Fasi & Ambito
- [x] Phase 0 — Flagging e telemetria (abilitazione controllata)
- [x] Phase 1 — Modello di dominio e repository (shared)
- [x] Phase 2 — ExerciseManager (creazione/gestione esercizi cardio)
- [x] Phase 3 — TrainingBuilder (form serie cardio, validazioni, progressioni)
- [x] Phase 4 — Viewer (visualizzazione, input esecuzione, timer)
- [x] Phase 5 — Export/Import (JSON/CSV) + compatibilità
- [x] Phase 6 — QA, migrazione, rollout

---

## Phase 0 — Flagging e Telemetria
- [x] Feature flag: chiave `feature_cardio_enabled` (default: false)
  - Scope: lato app (remote override) con fallback a local override (`.env`/dev menu).
  - Rollout: 5% → 25% → 50% → 100% con monitoraggio errori/retention.
  - Gating UI: nascondere tipo `cardio` in ExerciseManager, TrainingBuilder, Viewer, Export/Import quando false.
  - Kill switch: nascondi cardio e impedisci creazione/edizione/parse di nuove entità cardio; mantenere lettura per esistenti.
- [x] Telemetria: eventi e payload (PII-safe)
  - `cardio_flag_exposed` { userIdHash, appVersion, enabled }
  - `cardio_exercise_created` { variant, source: 'manager'|'builder' }
  - `cardio_series_added` { variant, hasDuration, hasDistance, hasHr }
  - `cardio_series_edited` { changedFields[] }
  - `cardio_series_deleted` { }
  - `cardio_timer_start|pause|stop` { variant, workoutIdHash, exerciseIdHash }
  - `cardio_viewer_result_saved` { hasExecutedDuration, hasExecutedDistance, hasAvgHr }
  - `export_started|completed|failed` { format: 'json'|'csv', durationMs, error? }
  - `import_attempt|completed|failed` { format, rows, added, updated, errors }
  - Policy: niente dati sensibili, hash per id; versionare event props.

Note implementative:
- Esposizione del flag avviene prima del rendering root; usare `FeatureGate<Cardio>` per sezioni sensibili.
- Logger batch per ridurre overhead (flush su app background/idle).

## Phase 1 — Dominio e Repository (shared)
- [x] Modelli
  - `Exercise.type`: aggiungere valore canonico `'cardio'` (retrocompatibile perché string-based).
  - `Exercise.variant` (string): valori suggeriti `run|bike|row|swim|elliptical|walk|hike|ski|skate|other`.
  - `Series` (estensioni opzionali — tutti nullable, no breaking):
    - Target: `durationSeconds` (int), `distanceMeters` (int), `speedKmh` (double), `paceSecPerKm` (int), `inclinePercent` (double), `hrPercent` (double), `hrBpm` (int), `avgHr` (int?), `kcal` (int?)
    - Esecuzione: `executedDurationSeconds` (int?), `executedDistanceMeters` (int?), `executedAvgHr` (int?)
    - Semantica: per `cardio` non usare `weight`/`reps`; mantenere presenti ma ignorati in UI/business.
- [x] Ranges e invarianti
  - `durationSeconds`: 0–21600 (fino a 6h)
  - `distanceMeters`: 0–100000 (100 km)
  - `speedKmh`: 0–60 (run ≤ 30 consigliato; bike ≤ 60)
  - `paceSecPerKm`: 90–1800 (1:30–30:00 min/km)
  - `inclinePercent`: -10.0–40.0
  - `hrBpm`: 30–220; `hrPercent`: 0–100
  - Coerenza: se forniti sia `speedKmh` che `paceSecPerKm`, devono rispettare `speedKmh ≈ 3600 / paceSecPerKm` (±1%).
- [x] `CardioMetricsService` (API)
  - `int hrMaxTanaka(int age)` → `208 - 0.7 * age` (arrotonda).
  - `double paceToSpeed(int paceSecPerKm)` → `3600 / paceSecPerKm`.
  - `int speedToPace(double speedKmh)` → `round(3600 / speedKmh)`.
  - `Estimate estimateMissing({int? durationSeconds, int? distanceMeters, double? speedKmh, int? paceSecPerKm})` → completa 2<-3.
  - `int hrPercentToBpm(double percent, int hrMax)`; `double hrBpmToPercent(int bpm, int hrMax)`.
  - `String formatDuration(int seconds)` → `mm:ss` o `hh:mm:ss` > 1h.
  - `String formatPace(int paceSecPerKm)` → `mm:ss/km`.
  - `String formatDistance(int meters, {Units units = Units.metric})`.
  - `int parseMmSs(String)`; `int parsePace(String)` con validazione robusta.
- [x] Validazione (ValidationUtils)
  - Per cardio: richiedere almeno uno tra `durationSeconds` o `distanceMeters` (o `speedKmh/paceSecPerKm` da cui stimare).
  - Se presente `hrPercent` e disponibile età/`hrMax`, verificare coerenza con `hrBpm` (±3 bpm).
  - Limiti per `inclinePercent`, `speedKmh`, `paceSecPerKm` secondo ranges.
  - Normalizzare input testo a unità base (es. `05:30` → 330 sec).
- [x] Repository/Mapping
  - Firestore: nuovi campi opzionali, omettere null; nessun backfill richiesto.
  - Indici: se necessario, `where(type == 'cardio')`, `orderBy(updatedAt)`.
  - `copyExercise/copySeries` includono i campi cardio.

Esempio JSON (serie cardio):
```json
{
  "type": "cardio",
  "variant": "run",
  "name": "Corsa facile",
  "series": [
    {
      "durationSeconds": 1800,
      "distanceMeters": 5000,
      "paceSecPerKm": 360,
      "hrPercent": 70.0,
      "inclinePercent": 1.0,
      "executedDurationSeconds": 1785,
      "executedDistanceMeters": 4980,
      "executedAvgHr": 152
    }
  ]
}
```

## Phase 2 — ExerciseManager
- [x] Tipi e varianti
  - Seed `ExerciseTypes.cardio` + `variant` comuni (run, bike, row, swim, walk, elliptical, hike).
  - Iconografia dedicata per `cardio` e per variant (se disponibile).
- [x] UI creazione/modifica
  - Step 1: selezione `type` → mostra sottomaschera condizionale; default `strength`.
  - Step 2: se `cardio`, selezione `variant` (required) + campi descrittivi (nome, note, tag).
  - Validazioni: ignorare `weight/reps`; permettere salvataggio senza serie.
- [x] Lista/filtri/ricerca
  - Filtro per `type = cardio`; badge `Cardio` + `variant` nelle righe.
  - Ricerca invariata per nome; ordinamenti invariati.

## Phase 3 — TrainingBuilder
- [x] ExerciseDialog (dinamico per tipo)
  - Strength: invariato.
  - Cardio: campi con input assistiti e unità chiare:
    - `Durata (mm:ss)` con maschera di input e parsing robusto.
    - `Distanza (km)` (decimali → metri in storage). Visualizzare `mi` se units=imperial.
    - `Velocità (km/h)` e `Ritmo (mm:ss/km)` legati da `CardioMetricsService` (sempre coerenti; edit uno aggiorna l’altro).
    - `Pendenza %`, `FC %`, `FC (bpm)`, `kcal (opz)`.
  - Helper: bottone “Calcola” per stimare campo mancante (da durata/distanza → pace/speed).
  - Errori inline: limiti range, coerenza HR%↔bpm, coerenza pace↔speed.
- [x] SeriesListWidget
  - Tile cardio con badge: `⏱ mm:ss` e/o `📏 km` e `🏃‍♂️ pace`.
  - Azioni bulk (duplica/elimina/riordina) funzionano senza riferimenti a peso/ripetizioni.
- [x] Progressioni cardio
  - Tempo: +10–60s per set o per settimana.
  - Distanza: +0.1–1.0 km per set o per settimana.
  - Vincoli: non superare limiti massimi; mantieni pace costante opzionale.
- [x] Business/Validation
  - `ExerciseBusinessService.validateWorkoutExercises` esteso con regole cardio.
  - `CardioMetricsService` usato al posto di `WeightCalculationService`.
  - Funzioni weight-specific restituiscono no-op per cardio.
- [x] Volume/Share
  - Dashboard: somma `tempo totale` e `distanza totale`; mostra medie (pace/velocità) del workout.
  - Share dialog: conteggi includono serie cardio.

## Phase 4 — Viewer
- [x] Card/details cardio
  - Layout condizionale: mostra `durata`, `distanza`, `pace/velocità`, `pendenza`, `FC`, nasconde `peso/ripetizioni`.
  - Timer: start/pause/stop con binding a `executedDurationSeconds`; prompt per inserire `executedDistanceMeters`, `executedAvgHr` al termine.
  - Auto-stima: se nota `speedKmh` e durata effettiva, suggerire distanza effettiva.
- [x] Stato completamento
  - Done se `executedDurationSeconds > 0` o `executedDistanceMeters > 0`.
  - Badge “completed” coerente con strength.
- [x] Superset/navigazione
  - Nessuna modifica: cardio può stare dentro/fuori superset; skip logiche di carico massimo.

## Phase 5 — Export / Import
- [x] JSON
  - Includere tutti i campi cardio opzionali quando non null.
  - Aggiungere `schemaVersion` (es. 3) a livello root per versionamento robusto.
  - Esempio struttura workout con cardio incluso (vedi esempio in Phase 1).
- [x] CSV
  - Header (ordine canonico):
    `type,variant,exerciseName,setIndex,durationSeconds,distanceMeters,speedKmh,paceSecPerKm,inclinePercent,hrPercent,hrBpm,avgHr,kcal,executedDurationSeconds,executedDistanceMeters,executedAvgHr,weight,reps`
  - Non-cardio: colonne cardio vuote; cardio: `weight/reps` vuote.
  - Decimali: `.` (punto); tempi: `mm:ss` per display ma nel CSV usare secondi interi per semplicità (riduce parsing ambiguo).
  - Parser tollerante: se colonne cardio mancanti → default a null; mantenere compat con legacy.
- [x] Integrazione servizi
  - Aggiornare builder/parser in `training_share_service_async.dart` (o equivalente) per mapping campi cardio.
  - Test con file legacy e nuovi (misti).

## Phase 5.1 — Integrazione MaxRM Dashboard (Cardio)
- [x] Aggiungere tab/filtri “Cardio” in `MaxRMDashboard`
- [x] Visualizzazioni principali:
  - [x] Trend settimanale: tempo totale, distanza totale, velocità media
  - [x] Distribuzione FC (% su HRmax) e FC media per sessione
  - [x] Best pace/speed per distanze comuni (5k/10k) se applicabile
  - [x] Istogrammi pendenza/speed (per tapis roulant)
- [x] Input rapido record cardio (session recap) con conversioni pace/speed e HR%
- [x] Lettura HRmax da profilo utente (età) e calcolo con Tanaka; override se HRmax misurata è presente
- [x] Aggiornare providers/servizi per fetch e aggregazioni cardio

Specifiche aggiuntive:
- Metriche calcolate:
  - `tempo_totale` = somma `executedDurationSeconds` (fallback `durationSeconds`).
  - `distanza_totale` = somma `executedDistanceMeters` (fallback `distanceMeters`).
  - `velocità_media` = `3.6 * (Σ metri) / (Σ sec)`.
  - `pace_medio` = `round((Σ sec) / ((Σ metri)/1000))`.
- Query aggregate per settimana (UTC o tz locale coerente con app) con indici opportuni.
- Filtri per variant e range HR%.

## Phase 6 — QA, Migrazione, Rollout
- [x] Migrazione minima: nessun backfill richiesto; nuovi campi nullable
- [x] Seed `ExerciseTypes.cardio` in Firestore (script/console) e opzioni variant comuni
- [x] Unit test
  - [x] Mapping model ↔ Firestore (nuovi campi)
  - [x] Validation cardio (dominio)
  - [x] CardioMetricsService (pace/speed, HRmax Tanaka, HR% ↔ bpm, formattazioni)
  - [x] Export/Import JSON/CSV con/ senza colonne cardio
- [x] UI test/golden
  - [x] ExerciseDialog cardio (form), SeriesList cardio, Viewer card/details cardio
- [x] E2E smoke: crea esercizio cardio → aggiungi a workout → aggiungi serie → visualizza in Viewer → export/import
- [x] Rollout graduale: enable per beta → monitor → all users; fallback: disabilita flag

Accettazione e test chiave:
- Unit: verificare `speed↔pace`, `hr%↔bpm`, parsing `mm:ss`, ranges.
- Golden: snapshot tiles cardio (light/dark, metric/imperial).
- E2E: flusso completo + import CSV/JSON round-trip invariance (lossless dei campi not-null).
- Telemetria: eventi emessi in punti designati, senza PII.

---

## Dettagli Implementativi (Completi)
- Modelli
  - `Exercise.type`: usare `'cardio'` come valore canonico.
  - `Series` (aggiunte): `durationSeconds?`, `distanceMeters?`, `paceSecPerKm?`, `speedKmh?`, `inclinePercent?`, `hrPercent?`, `hrBpm?`, `avgHr?`, `kcal?`, `executedDurationSeconds?`, `executedDistanceMeters?`, `executedAvgHr?`.
  - Helpers display: `durationDisplay (mm:ss/hh:mm:ss)`, `distanceDisplay (km con 2 decimali)`, `paceDisplay (mm:ss/km)`.
- Servizi
  - `CardioMetricsService`: calcoli (pace/speed, HR), normalizzazione input, stima campi mancanti, formattazioni.
  - `ValidationUtils`: regole cardio con messaggi localizzati e chiari.
- UI
  - Form dinamici guidati dal `Exercise.type`; widget riusabili per `DurationField`, `DistanceField`, `PaceField`, `SpeedField`, `HrField`.
  - Componenti: `CardioSeriesTile`, `StrengthSeriesTile`; tema coerente.
  - Reuse `ReorderDialog` invariato.
- Compatibilità
  - Nessuna modifica a dati esistenti; nuovi campi opzionali, omissione null in storage.
  - Weight-specific: no-op su cardio; UI non invoca.

Esempio CSV (riga cardio):
```
cardio,run,Corsa facile,1,1800,5000,10.0,360,1.0,70,150,152,300,1785,4980,152,,
```

## Deliverables per Modulo
- [x] ExerciseManager: tipo/variant cardio, validazioni e filtri (accettazione: creare/modificare/filtrare esercizi cardio)
- [x] TrainingBuilder: dialog serie cardio, lista serie cardio, dashboard volume (accettazione: aggiungere serie cardio valide; progressioni funzionano)
- [x] Viewer: card/detail cardio, timer, input risultati cardio (accettazione: completare serie con timer e salvare risultati)
- [x] Export/Import: JSON/CSV aggiornati e parser tolleranti (accettazione: round-trip invariance dei campi)
- [x] Test suite e docs (accettazione: copertura minima su servizi/validazioni, guide aggiornate)

## Roadmap (Indicativa)
- [x] Settimana 1: Phase 1-2 (dominio + ExerciseManager)
- [x] Settimana 2: Phase 3 (TrainingBuilder) + unit test
- [x] Settimana 3: Phase 4 (Viewer) + golden test
- [x] Settimana 4: Phase 5-6 (export/import, QA, rollout flag)

## Note di Rischio e Mitigazioni
- [x] Estensione `Series` vs union sealed: iniziare con campi opzionali (KISS), monitorare complessità → possibile refactor a sealed in fase 2+
- [x] UI condizionale: centralizzare logica in componenti dedicati per evitare if sparsi (SOLID)
- [x] CSV retro-compatibilità: parser permissivo; test su file legacy

## Done Definition
- [x] Creazione/edizione esercizi cardio da ExerciseManager
- [x] Aggiunta/riordino serie cardio in TrainingBuilder
- [x] Visualizzazione ed input esecuzione cardio in Viewer
- [x] Export/Import con cardio senza regressioni
- [x] Copertura test fondamentale (dominio, servizi, UI chiave)

---

## NFR, Assunzioni e Range
- Prestazioni: operazioni di formattazione e calcolo O(1); rendering liste > 100 serie fluido su device target.
- A11Y: labels descrittivi, focus order corretto, formati numerici leggibili; supporto screen reader per timer.
- I18N/L10N: numeri formattati secondo locale; future toggle unità imperial.
- Offline: editor utilizzabile offline; export/import non dipende dalla rete.
- Privacy: telemetria PII-safe; id hash e nessun contenuto libero testuale.

## Glossario
- Pace: tempo per km (sec/km). Speed: km/h.
- HRmax (Tanaka): 208 − 0.7 × età.
- Executed*: valori inseriti a consuntivo in Viewer.

## Backlog (Futuro)
- Sealed union `Series` (CardioSeries/StrengthSeries) con mapping dedicato.
- TRIMP/CTL/ATL (carico cardio) e zone HR.
- Integrazione wearables (import GPX/FIT) — fuori ambito MVP.
