# Piano condivisione programmi (shareWorkout)

- [x] Mappare schema e punti di integrazione
- [x] Implementare servizi export/import (JSON e CSV)
- [x] Integrare in controller (API semplici)
- [x] Aggiungere UI pulsanti (Export JSON, Export CSV, Import)
- [x] Scrivere documentazione in `shareWorkoutIstruction.md`
- [x] Aggiungere import/export da file (web + mobile)
- [ ] Test manuale base e pulizia

Note:
- Principi: KISS, SOLID, DRY, Clean Architecture, modularità.
- Riutilizzo: modelli `Week/Workout/Exercise/Series` da `lib/shared/models/*` e dialoghi UI esistenti (`AppDialog`).
