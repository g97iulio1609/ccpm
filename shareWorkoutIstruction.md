# Istruzioni condivisione Programmi (JSON/CSV)

Questo documento descrive come strutturare i dati dei programmi di allenamento per poterli esportare e importare in AlphanessOne (trainingBuilder) in formato JSON e CSV. Il modello segue gli schemi in uso nell’app (`TrainingProgram` → `Week` → `Workout` → `Exercise` → `Series`).

## JSON

- Formato: oggetto con chiave `program` e `formatVersion`.
- Encoding: UTF-8, newline `\n`.
- Campi richiesti minimi: `program.name`, `program.mesocycleNumber`, `program.weeks` (array, anche vuoto). Gli altri campi sono opzionali ma consigliati.

Struttura:
```
{
  "formatVersion": 1,
  "program": {
    "id": "",                    // opzionale, se vuoto verrà generato
    "name": "Forza 4 settimane", // richiesto
    "description": "...",         // opzionale
    "athleteId": "user_123",      // opzionale
    "mesocycleNumber": 1,          // richiesto
    "hide": false,                 // opzionale (default false)
    "status": "private",          // opzionale (private|public)
    "weeks": [
      {
        "id": "",                // opzionale
        "number": 1,              // richiesto (>=1)
        "name": "Settimana 1",   // opzionale
        "description": "...",     // opzionale
        "isCompleted": false,      // opzionale
        "workouts": [
          {
            "id": "",            // opzionale
            "order": 1,           // richiesto (>=1)
            "name": "Full Body A",// opzionale
            "description": "...", // opzionale
            "isCompleted": false,  // opzionale
            "superSets": [         // opzionale, compatibilità trainingBuilder
              { "id": "ss1", "name": "", "exerciseIds": ["e1","e2"] }
            ],
            "exercises": [
              {
                "id": "",                    // opzionale
                "exerciseId": "sq_back",     // consigliato (ID esercizio libreria)
                "name": "Back Squat",        // consigliato (fallback se manca exerciseId)
                "type": "weight",             // richiesto (weight|time|...)
                "variant": "highbar",         // opzionale
                "order": 1,                    // richiesto (>=1)
                "superSetId": "ss1",          // opzionale
                "series": [                    // richiesto (anche vuoto)
                  {
                    "serieId": "",            // opzionale
                    "exerciseId": "",         // verrà sovrascritto in DB
                    "order": 1,                // richiesto (>=1)
                    "sets": 1,                 // richiesto (>=1)
                    "reps": 5,                 // richiesto (>=0)
                    "maxReps": 6,              // opzionale
                    "weight": 80.0,            // richiesto (>=0)
                    "maxWeight": 85.0,         // opzionale
                    "intensity": "70%",       // opzionale
                    "maxIntensity": "75%",    // opzionale
                    "rpe": "7",               // opzionale
                    "maxRpe": "8",            // opzionale
                    "restTimeSeconds": 120     // opzionale
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}
```

Note:
- Gli ID (`id`, `serieId`) possono essere vuoti: in fase di salvataggio verranno generati in modo consistente.
- `exerciseId` è l’ID dell’esercizio nel catalogo dell’app. Se manca, l’import userà `name`+`type` come fallback; alcuni automatismi (es. aggiornamento auto pesi) potrebbero non funzionare.
- `superSets` è un elenco di gruppi con `exerciseIds` che si riferiscono agli `id` degli esercizi nel workout. In import JSON viene mantenuto; nel CSV si usa la colonna `superSetId` per associare.

## CSV

- Una riga rappresenta una serie di un esercizio (o un placeholder esercizio se senza serie).
- Delimitatore: virgola `,` (RFC4180). Tutti i campi sono racchiusi tra doppi apici, con escaping `""`.
- Intestazione (obbligatoria):

```
formatVersion,programId,programName,programDescription,athleteId,mesocycleNumber,hide,status,weekNumber,workoutOrder,workoutName,exerciseOrder,exerciseName,exerciseId,type,variant,superSetId,seriesOrder,sets,reps,maxReps,weight,maxWeight,intensity,maxIntensity,rpe,maxRpe,restTimeSeconds
```

Campo per campo (principali):
- programName: nome programma (richiesto)
- mesocycleNumber: numero mesociclo (richiesto)
- weekNumber: numero settimana (>=1)
- workoutOrder: ordine allenamento nella settimana (>=1)
- workoutName: nome allenamento (opzionale)
- exerciseOrder: ordine esercizio nell’allenamento (>=1)
- exerciseName: nome esercizio (consigliato)
- exerciseId: ID esercizio libreria (consigliato)
- type: tipo esercizio, es. `weight` (richiesto)
- superSetId: identificatore gruppo superset (stessa stringa sulle righe degli esercizi del gruppo)
- seriesOrder: ordine della serie (>=1). Se vuoto e presenti valori, viene ordinato automaticamente.
- sets, reps, weight: valori target per la serie; i campi `max*` consentono range.

Esempio di 2 serie per “Back Squat” nella Settimana 1 / Workout 1 / Esercizio 1:
```
"1","","Forza 4 settimane","","user_123","1","false","private","1","1","Full Body A","1","Back Squat","sq_back","weight","highbar","ss1","1","1","5","6","80.0","85.0","70%","75%","7","8","120"
"1","","Forza 4 settimane","","user_123","1","false","private","1","1","Full Body A","1","Back Squat","sq_back","weight","highbar","ss1","2","1","5","6","80.0","85.0","70%","75%","7","8","120"
```

Note:
- Per un esercizio senza serie inserire una riga placeholder con `sets=0` e campi serie vuoti; l’esercizio verrà creato senza serie.
- Il CSV non contiene `weekProgressions` (progressioni multi‑settimana): quelle restano una feature dell’editor e possono essere rigenerate in app.
- I valori testo possono contenere virgole e virgolette: il writer fa escaping con `""`, l’importer le ripristina.

## Validazione e compatibilità

- In import JSON/CSV vengono ignorati i campi sconosciuti; i campi mancanti sono valorizzati con default sicuri.
- In import CSV l’ordinamento (week/workout/exercise/series) è determinato da `weekNumber`, `workoutOrder`, `exerciseOrder`, `seriesOrder`.
- In export/import non sono inclusi metadati e campi di tracking (es. `done`, `repsDone`), che l’app gestisce internamente. Se presenti in JSON vengono mantenuti in `series`.

## Suggerimenti pratici

- Preferisci l’export/import JSON per avere la massima fedeltà dei dati.
- Usa il CSV quando devi manipolare velocemente il programma in fogli di calcolo.
- Mantieni coerenti `exerciseId` (catalogo esercizi) e `type`; se mancano, l’app userà `name` come fallback ma alcune funzioni potrebbero essere limitate.

---
Per dubbi o casi particolari, vedere `lib/shared/models/*.dart` e `lib/trainingBuilder/services/training_share_service.dart`.

## Uso in App

- Dove: pagina Program (editor). Sono presenti due gruppi di azioni:
  - Copia/Incolla: “Export JSON”, “Export CSV”, “Import”.
  - File: “Export .json”, “Export .csv”, “Import da file”.

- Flussi supportati:
  - Export (copia): mostra un dialog con il contenuto pronto da copiare.
  - Export (file):
    - Web: download diretto del file.
    - Mobile/Desktop: condivisione del file generato (share sheet).
  - Import (incolla/file): incolla il contenuto o seleziona un `.json/.csv` dal file picker.

- Performance: costruzione/parsing JSON e CSV avvengono off‑thread (isolate via `compute`) per evitare blocchi UI. Export file JSON è minificato.

- Implementazione:
  - Costruzione/parsing dati: `lib/trainingBuilder/services/training_share_service.dart`
  - Versioni asincrone (no-blocking): `lib/trainingBuilder/services/training_share_service_async.dart`
  - I/O file: `lib/trainingBuilder/services/io/training_share_io_*.dart`

