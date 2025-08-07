## Obiettivo

Rewamp UI/UX massivo e modulare dell’intera app (TrainingBuilder, Viewer, MaxRMDashboard, ExerciseDashboard, Nutrition, ecc.) ispirato alle top app Apple/Google e leader di settore. Preservare TUTTE le funzionalità, migliorare la qualità del codice (KISS, SOLID, DRY, modularità), adottare linee guida e novità Flutter 3.32 (e precedenti) e garantire una UI responsive, accessibile, con Light/Dark mode.

## Criteri di successo
- Build verde, zero regressioni funzionali, lint pulito per i file toccati
- UI coerente (Light/Dark), responsive (phone/tablet/desktop), accessibile (Semantics, contrasto, target, focus)
- Navigazione/transizioni Material 3 fluide e consistenti
- Nessun degrado prestazionale; caricamenti con skeleton/shimmer dove appropriato

## Fasi del piano (Step-by-step)

1) Fondamenta e Qualità
- Hardening `analysis_options.yaml` (lint severi, prefer_const, public_member_api_docs dove necessario) [todo]
- Pulizia import e normalizzazione casing (Viewer vs viewer) [done]
- CI locale: `flutter analyze` + test minimi su moduli critici [todo]

2) Tema, Design Tokens e Transizioni
- Consolidare tokens (spacing, radii, elevations, typography) in `AppTheme` [done]
- Aggiornare `pageTransitionsTheme` a builder sicuri Material/Cupertino [done]
- Verificare component theme per ProgressIndicator/Slider/Chip/Dialog/BottomSheet [done]
- Dinamica Light/Dark completa, contrasto e outlineVariant consistenti [ongoing]

3) Componenti e Pattern M3
- Sostituire `PopupMenuButton` con `MenuAnchor` e `MenuItemButton` [ongoing]
- Introdurre skeleton/shimmer per liste e card (loading) [todo]
- Uniformare Card/Badge/Divider/Empty states [ongoing]
- Aggiungere Semantics in liste principali e action row [ongoing]

4) Responsività e Layout
- Breakpoints e adattività per griglie/liste (phone/tablet/desktop) [ongoing]
- Migliorare padding/spacing in base allo schermo [ongoing]

5) TrainingBuilder (UI/UX)
- Consolidare dialog, form e serie su widget condivisi (`RangeControllers`, form fields) [done]
- Ottimizzare bulk operations UX (etichette, help, conferme) [ongoing]
- Aggiungere skeleton nei contenuti pesanti [todo]

6) Viewer (UI/UX)
- Pull-to-refresh coerente, Semantics su liste workout/esercizi [done]
- `MenuAnchor` su action contestuali e cleanup navigazione [ongoing]
- Grid/list responsive per esercizi/superset [done]

7) MaxRMDashboard & ExerciseDashboard
- Unificare card, grafici e filtri, introdurre skeleton/shimmer [todo]
- Migliorare azioni contestuali (MenuAnchor) e Semantics [todo]

8) Nutrition
- Migrazione menu → `MenuAnchor` (view_diet_plans_screen, food_list) [done]
- Migliorare bottom sheet e controlli (iOS/Android) [todo]

9) Accessibilità (A11y)
- Label Semantics, ruoli e focus order per liste e controlli critici [ongoing]
- Verifica contrasto testo/icones, target 48dp [ongoing]

10) Performance
- Prefetch e cache coerenti (già migliorate su Viewer) [done]
- Evitare N+1 (Future.wait) e ottimizzare builder/list grid [ongoing]

11) Test di regressione
- Widget test su pagine chiave (Viewer/Builder/Nutrition) [todo]
- Golden test per card/tiles [todo]
 - Integration test (emulatore Firestore) per CRUD completo [todo]

12) Auth (Registrazione/Login)
- Rewamp completo UI/UX schermate `auth_screen.dart` e `auth_form.dart` [todo]
- Adozione Material 3: FilledButton, TextField con helper/validation live, toggle visibilità password [todo]
- AutofillHints, password manager, validazioni accessibili (Semantics, errorText, focus) [todo]
- SSO coerente con `auth_buttons.dart` (Apple/Google) usando `MenuAnchor`/sheet, stato di loading/errori unificati [todo]
- Link legali e consensi (privacy/terms) allineati al tema e a11y [todo]
- Layout responsive (phone/tablet/desktop) con spaziatura dinamica e illustrazioni leggere [todo]
- Telemetria minima su errori (no PII) [todo]

## Stato rapido
- Tema M3/transizioni: done
- MenuAnchor: exercise_card, app_bar_custom, food_list, view_diet_plans migrati
 - MenuAnchor: exercise_card, app_bar_custom, food_list, view_diet_plans migrati
 - AppBar → CustomAppBar: AI Chat, AI Settings, Workout Details migrati
- Semantics principali: inserite in Viewer/TrainingBuilder dialog [ongoing]
- Performance Viewer: ottimizzazioni repository e subscription: done
- Skeletons: introdotti per Diet Plans, Food List, Workout Details loading [ongoing]
 - Superset layout (serie in colonne per esercizio) in Workout Details: done

## Prossime azioni (immediate)
- Ricerca e migrazione ulteriori `PopupMenuButton` [repo]
- Introdurre skeleton generici condivisi per liste/workout/esercizi [scaffold]
- `flutter analyze` globale e smoke test flussi principali
 - Audit UI/UX Auth e bozza componenti M3 (login/registrazione)
 - Verifica che tutte le schermate usino il `CustomAppBar` globale (niente duplicati)
 - Verifica che tutte le schermate usino il `CustomAppBar` globale (niente duplicati) [ongoing]
 - Estendere il nuovo layout superset alle viste simili (se presenti) in Viewer/Builder

## Definition of Done (per modulo)
- TrainingBuilder: dialog/bulk serie uniformati, nessuna sovrapposizione UI, validazioni live, skeleton su carichi pesanti
- Viewer: superset layout stabile, refresh consistente, note/timer integri, skeleton su liste principali
- Nutrition: MenuAnchor ovunque, skeleton su liste, bottom sheet rifiniti
- Auth: login/registrazione M3, autofill e validazioni accessibili, SSO stabile
- MaxRMDashboard/ExerciseDashboard: card/grafici uniformi, filtri chiari, skeleton durante fetch

## Timeline suggerita (indicativa)
- Set A: Fix superset e skeleton principali [done]
- Set B: Migrazioni MenuAnchor residue + A11y pass [ongoing]
- Set C: Auth (UI/UX), bottom sheet iOS/Android [next]
- Set D: Dashboard (MaxRM/Exercise), rifiniture e test [next]


