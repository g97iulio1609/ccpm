## Obiettivo

Rewamp UI/UX massivo e modulare dell’intera app (TrainingBuilder, Viewer, MaxRMDashboard, ExerciseDashboard, Nutrition, ecc.) ispirato alle top app Apple/Google e leader di settore. Preservare TUTTE le funzionalità, migliorare la qualità del codice (KISS, SOLID, DRY, modularità), adottare linee guida e novità Flutter 3.32 (e precedenti) e garantire una UI responsive, accessibile, con Light/Dark mode.

## Criteri di successo
- Build verde, zero regressioni funzionali, lint pulito per i file toccati
- UI coerente (Light/Dark), responsive (phone/tablet/desktop), accessibile (Semantics, contrasto, target, focus)
- Navigazione/transizioni Material 3 fluide e consistenti
- Nessun degrado prestazionale; caricamenti con skeleton/shimmer dove appropriato

## Fasi del piano (Step-by-step)

1) Fondamenta e Qualità
- Hardening `analysis_options.yaml` (lint severi, prefer_const, public_member_api_docs dove necessario) [done]
- Pulizia import e normalizzazione casing (Viewer vs viewer) [done]
- CI locale: `flutter analyze` + test minimi su moduli critici [done]

2) Tema, Design Tokens e Transizioni
- Consolidare tokens (spacing, radii, elevations, typography) in `AppTheme` [done]
- Aggiornare `pageTransitionsTheme` a builder sicuri Material/Cupertino [done]
- Verificare component theme per ProgressIndicator/Slider/Chip/Dialog/BottomSheet [done]
- Dinamica Light/Dark completa, contrasto e outlineVariant consistenti [done]

3) Componenti e Pattern M3
- `AppCard`/`SectionHeader` introdotti e adottati in Viewer/TrainingBuilder/MaxRMDashboard [done]
- `SeriesHeader` e `KpiBadge` creati e integrati (Viewer, TrainingBuilder, MaxRM) [done]
- Sostituire `PopupMenuButton` con `MenuAnchor` e `MenuItemButton` [done]
- Introdurre skeleton/shimmer per liste e card (loading) [done]
- Uniformare Card/Badge/Divider/Empty states [done]
- Aggiungere Semantics in liste principali e action row [done]

4) Responsività e Layout
- Breakpoints e adattività per griglie/liste (phone/tablet/desktop) [done]
- Migliorare padding/spacing in base allo schermo [done]

5) TrainingBuilder (UI/UX)
- Consolidare dialog, form e serie su widget condivisi (`SeriesHeader`, `KpiBadge`, form fields) [done]
- Ottimizzare bulk operations UX (etichette, help, conferme) [done]
- Aggiungere skeleton nei contenuti pesanti [done]

6) Viewer (UI/UX)
- Pull-to-refresh coerente, Semantics su liste workout/esercizi [done]
- `MenuAnchor` su action contestuali e cleanup navigazione [done]
- Grid/list responsive per esercizi/superset [done]

7) MaxRMDashboard & ExerciseDashboard
- Unificare card e KPI con `AppCard`/`KpiBadge`, introdurre skeleton/shimmer [done]
- Migliorare azioni contestuali (MenuAnchor) e Semantics [done]

8) Nutrition
- Migrazione menu → `MenuAnchor` (view_diet_plans_screen, food_list) [done]
- Migliorare bottom sheet e controlli (iOS/Android) [done]
 - AppCard tonali e hover/animazioni leggere: daily_food_tracker, food_list [done]
 - DietPlanScreen: sezioni giorno in AppCard tonali, pulsanti → FilledButton, skeleton loading [done]

9) Accessibilità (A11y)
- Label Semantics, ruoli e focus order per liste e controlli critici [done]
- Verifica contrasto testo/icones, target 48dp [done]

10) Performance
- Prefetch e cache coerenti (già migliorate su Viewer) [done]
- Evitare N+1 (Future.wait) e ottimizzare builder/list grid [done]

11) Test di regressione
- Widget test su pagine chiave (Viewer/Builder/Nutrition) [todo]
- Golden test per card/tiles [todo]
 - Integration test (emulatore Firestore) per CRUD completo [todo]

12) Auth (Registrazione/Login)
- Rewamp completo UI/UX schermate `auth_screen.dart` e `auth_form.dart` [done]
- Adozione Material 3: FilledButton, TextField con helper/validation live, toggle visibilità password [done]
- AutofillHints, password manager, validazioni accessibili (Semantics, errorText, focus) [done]
- SSO coerente con `auth_buttons.dart` (Apple/Google) usando `MenuAnchor`/sheet, stato di loading/errori unificati [done]
- Link legali e consensi (privacy/terms) allineati al tema e a11y [done]
- Layout responsive (phone/tablet/desktop) con spaziatura dinamica e illustrazioni leggere [done]
- Telemetria minima su errori (no PII) [done]

## Stato rapido
- Tema M3/transizioni: done
- MenuAnchor: exercise_card, app_bar_custom, food_list, view_diet_plans migrati
 - MenuAnchor: exercise_card, app_bar_custom, food_list, view_diet_plans migrati
 - AppBar → CustomAppBar: AI Chat, AI Settings, Workout Details migrati
- Semantics principali: inserite in Viewer/TrainingBuilder dialog [ongoing]
- Performance Viewer: ottimizzazioni repository e subscription: done
 - Skeletons: introdotti per Diet Plans, Food List, Workout Details loading [done]
 - Superset layout (serie in colonne per esercizio) in Workout Details: done

## Prossime azioni (immediate)
- `flutter analyze` globale e smoke test flussi principali [ricorrente]
- Test: widget/golden/integration (vedi Fase 11) [next]
 - Pass A11y finale: Semantics e focus order completivi nelle ultime liste Nutrition [next]

## Definition of Done (per modulo)
- TrainingBuilder: dialog/bulk serie uniformati, nessuna sovrapposizione UI, validazioni live, skeleton su carichi pesanti
- Viewer: superset layout stabile, refresh consistente, note/timer integri, skeleton su liste principali
- Nutrition: MenuAnchor ovunque, skeleton su liste, bottom sheet rifiniti
- Auth: login/registrazione M3, autofill e validazioni accessibili, SSO stabile
- MaxRMDashboard/ExerciseDashboard: card/grafici uniformi, filtri chiari, skeleton durante fetch

## Timeline suggerita (indicativa)
- Set A: Fix superset e skeleton principali [done]
- Set B: Migrazioni MenuAnchor residue + A11y pass [ongoing]
- Set C: Auth (UI/UX), bottom sheet iOS/Android [ongoing]
- Set D: Dashboard (MaxRM/Exercise), rifiniture e test [ongoing]


