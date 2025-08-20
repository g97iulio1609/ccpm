# Cardiovascolari — SOTA Planning (KISS, SOLID, DRY, Clean Architecture)

Obiettivo: introdurre gli esercizi “Cardiovascolari” in ExerciseManager, TrainingBuilder e Viewer, con compatibilità retro, export/import aggiornati e UX coerente.

## Principi
- [x] KISS: design incrementale, feature-flag, UI adattiva per tipo esercizio
- [x] SOLID: separare dominio, servizi, presentazione; interfacce per calcoli cardio
- [x] DRY: riuso modelli/shared, ReorderDialog, componenti UI comuni
- [x] Clean Architecture: dominio indipendente, servizi e UI pluggabili

## Fasi & Ambito
- [ ] Phase 0 — Flagging e telemetria (abilitazione controllata)
- [ ] Phase 1 — Modello di dominio e repository (shared)
- [ ] Phase 2 — ExerciseManager (creazione/gestione esercizi cardio)
- [ ] Phase 3 — TrainingBuilder (form serie cardio, validazioni, progressioni)
- [ ] Phase 4 — Viewer (visualizzazione, input esecuzione, timer)
- [ ] Phase 5 — Export/Import (JSON/CSV) + compatibilità
- [ ] Phase 6 — QA, migrazione, rollout

---

## Phase 0 — Flagging e Telemetria
- [ ] Feature flag `feature_cardio_enabled` via Remote Config
- [ ] Tracking eventi chiave (crea cardio, aggiungi serie cardio, export) lato app-logger
- [ ] Gate UI/azioni cardio dietro il flag per rollout graduale

## Phase 1 — Dominio e Repository (shared)
- [ ] Aggiungere tipo esercizio `type = 'cardio'` nel modello `Exercise` (già string-based → backward compat)
- [ ] Estendere `Series` con campi opzionali cardio (tutti nullable, no breaking):
  - [ ] `durationSeconds` (int), `distanceMeters` (int), `paceSecPerKm` (int), `avgHr` (int?), `kcal` (int?)
  - [ ] Semantica: per `cardio` non usare `weight`/`reps`; validazione condizionale
- [ ] Alternativa (fase 2+): sealed union `Series` (StrengthSeries | CardioSeries). Rinviare per evitare refactor esteso ora (KISS)
- [ ] Nuovo servizio dominio `CardioMetricsService` (pace ↔ durata/distanza, formattazioni, validazioni)
- [ ] Aggiornare `ValidationUtils` per regole cardio (almeno uno tra durata/distanza, limiti campi, interdipendenze)
- [ ] Estendere `ModelUtils.copyExercise/copySeries` e riordino per includere campi cardio
- [ ] Aggiornare `ExerciseRepository` (se usato) e mapping Firestore (map <-> model) per nuovi campi

## Phase 2 — ExerciseManager
- [ ] Aggiungere `cardio` a collezione `ExerciseTypes` (seed Firestore o tool admin)
- [ ] UI creazione/modifica esercizio: selettore tipo (`weight`/`cardio`) e variant (`run`, `bike`, `row`, ecc.)
- [ ] Filtri/tag: mostra tipo `cardio` e gruppi (opzionale: “Cardio” come muscleGroup logico)
- [ ] Ricerca: nessun cambio logico (by name); mostra tipo/variant nelle righe risultato
- [ ] Validazioni: per cardio, campi strength non obbligatori

## Phase 3 — TrainingBuilder
- [ ] ExerciseDialog: form dinamico per serie
  - [ ] Strength: UI attuale invariata
  - [ ] Cardio: campi `durata`, `distanza`, opz. `pace`, `HR`, `kcal`; helper di calcolo pace
  - [ ] Placeholders e unità coerenti (min:sec, km/mi in futuro via settings)
- [ ] SeriesListWidget: renderizzazione cardio
  - [ ] Badge di gruppo basato su (durata/distanza/pace) invece di (reps/weight)
  - [ ] Azioni bulk compatibili (duplica/elimina/riordina) senza logica weight
- [ ] Progression editor: pattern cardio (progressione tempo o distanza)
- [ ] Validation & business services
  - [ ] `ExerciseBusinessService.validateWorkoutExercises` con regole cardio
  - [ ] Nessun uso di `WeightCalculationService` per cardio; introdurre `CardioMetricsService`
  - [ ] Evitare `getLatestMaxWeight` su cardio (return 0 o null; UI non mostra)
- [ ] TrainingVolumeDashboard: includere “Volume Cardio” (tempo totale, distanza totale)
- [ ] Share dialog: anteprima conteggi includa cardio (serie cardio nel totale)

## Phase 4 — Viewer
- [ ] Exercise card/details: layout condizionale
  - [ ] Mostrare durata/distanza/pace e nascondere peso/ripetizioni per cardio
  - [ ] Timer start/pausa/fine per esecuzione cardio (riuso bottom sheet timer esistente)
  - [ ] Input risultato: durata “effettiva”, distanza “effettiva” (scrittura su `Series.repsDone/weightDone` non usata per cardio; usare nuovi campi o mappare `repsDone`=durata sec e `weightDone`=distanza m solo se serve compatibilità temporanea)
- [ ] Stato completamento: determina “done” se durata o distanza inserita > 0
- [ ] Navigazione e superset: nessun cambio logico (cardio può esistere fuori superset)

## Phase 5 — Export / Import
- [ ] JSON export/import: includere campi cardio opzionali
- [ ] CSV export/import:
  - [ ] Aggiungere colonne: `durationSeconds`, `distanceMeters`, `paceSecPerKm`, `kcal`, `avgHr`
  - [ ] Per esercizi non-cardio: colonne vuote; per cardio: `reps/weight` vuoti
  - [ ] Parser tollerante: assenza colonne cardio non rompe import legacy
- [ ] Aggiornare `training_share_service_async.dart` builders e parser index

## Phase 6 — QA, Migrazione, Rollout
- [ ] Migrazione minima: nessun backfill richiesto; nuovi campi nullable
- [ ] Seed `ExerciseTypes.cardio` in Firestore (script/console) e opzioni variant comuni
- [ ] Unit test
  - [ ] Mapping model ↔ Firestore (nuovi campi)
  - [ ] Validation cardio (dominio)
  - [ ] CardioMetricsService (pace, formattazioni)
  - [ ] Export/Import JSON/CSV con/ senza colonne cardio
- [ ] UI test/golden
  - [ ] ExerciseDialog cardio (form), SeriesList cardio, Viewer card/details cardio
- [ ] E2E smoke: crea esercizio cardio → aggiungi a workout → aggiungi serie → visualizza in Viewer → export/import
- [ ] Rollout graduale: enable per beta → monitor → all users; fallback: disabilita flag

---

## Dettagli Implementativi (Semplificati)
- [ ] Modelli
  - [ ] `Exercise.type`: usare `'cardio'` come valore canonico
  - [ ] `Series` (aggiunte): `durationSeconds?`, `distanceMeters?`, `paceSecPerKm?`, `avgHr?`, `kcal?`
  - [ ] Helper display: `durationDisplay (mm:ss)`, `distanceDisplay (km con 2 decimali)`, `paceDisplay (mm:ss/km)`
- [ ] Servizi
  - [ ] `CardioMetricsService`: calcolo pace, normalizzazione input (mm:ss → sec)
  - [ ] `ValidationUtils`: strength vs cardio rules; messaggi chiari
- [ ] UI
  - [ ] Form dinamici a seconda del `Exercise.type` (evita duplicazioni; widget fields riusabili)
  - [ ] Componenti presentazionali separati: `CardioSeriesTile`, `StrengthSeriesTile`
  - [ ] Reuse `ReorderDialog` (nessun cambio)
- [ ] Compatibilità
  - [ ] Nessuna modifica a dati esistenti; nuovi campi opzionali
  - [ ] Weight-specific funzioni no-op per cardio (UI non le invoca)

## Deliverables per Modulo
- [ ] ExerciseManager: tipo/variant cardio, validazioni e filtri
- [ ] TrainingBuilder: dialog serie cardio, lista serie cardio, dashboard volume
- [ ] Viewer: card/detail cardio, timer, input risultati cardio
- [ ] Export/Import: JSON/CSV aggiornati e parser tolleranti
- [ ] Test suite e docs

## Roadmap (Indicativa)
- [ ] Settimana 1: Phase 1-2 (dominio + ExerciseManager)
- [ ] Settimana 2: Phase 3 (TrainingBuilder) + unit test
- [ ] Settimana 3: Phase 4 (Viewer) + golden test
- [ ] Settimana 4: Phase 5-6 (export/import, QA, rollout flag)

## Note di Rischio e Mitigazioni
- [ ] Estensione `Series` vs union sealed: iniziare con campi opzionali (KISS), monitorare complessità → possibile refactor a sealed in fase 2+
- [ ] UI condizionale: centralizzare logica in componenti dedicati per evitare if sparsi (SOLID)
- [ ] CSV retro-compatibilità: parser permissivo; test su file legacy

## Done Definition
- [ ] Creazione/edizione esercizi cardio da ExerciseManager
- [ ] Aggiunta/riordino serie cardio in TrainingBuilder
- [ ] Visualizzazione ed input esecuzione cardio in Viewer
- [ ] Export/Import con cardio senza regressioni
- [ ] Copertura test fondamentale (dominio, servizi, UI chiave)

