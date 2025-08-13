## Milestones UI/UX Rewamp

### Milestone 1 — Fondamenta e tema
- [x] Verifica utilizzo `MaterialApp.router` e `AppTheme.darkTheme` attivo
- [x] Attivare `themeMode: system` e introdurre `AppTheme.lightTheme`
- [x] Aggiungere toggle tema in `Impostazioni` (nuova sezione `settings/ui` o esistente)
- [x] Integrare `dynamic_color` (Android 12+) con fallback palette brand

### Milestone 2 — Navigazione: Drawer semplificato e multilivello
- [x] Drawer persistente su large screen in `HomeScreen`
- [x] `CustomAppBar` centralizzato e riutilizzato
- [x] Semplificare voci Drawer: mantenere solo 5-7 destinazioni top‑level (Allenamenti, Nutrizione, Misure, Records, Profilo, Abbonamenti opz.)
- [x] Aggiungere gruppi/espansioni (multi‑livello) per sezioni secondarie (es. Diet Plans, Favorite Meals, Gestione Utenti)
- [x] Unificare metadati rotta (titolo, icona) in `route_metadata.dart` ed eliminare `switch` duplicati in `CustomAppBar`/`CustomDrawer`

### Milestone 3 — Design System e componenti
- [x] Token di design (`Spacing`, `Radii`, `Elevations`) presenti in `AppTheme`
- [x] Componenti core esistenti (`AppCard`, `SectionHeader`, `Badge`, `Snackbar`, `Spinner`)
- [x] Bonifica duplicati (preferire `app_card.dart` rispetto a `card.dart` se ridondante)
 - [x] Introdurre widget standard `AppLoading`, `AppEmptyState`, `AppErrorState` e linee guida d’uso
   - Loading: `AppSpinner`
   - Skeleton: `SkeletonBox/Card/List/Grid`
   - Empty/Error: pattern uniforme con `AppCard` + icone/testi coerenti (estrazione componenti dedicati opzionale)

### Milestone 4 — Tema Glass “lite”
- [x] Introdotte varianti Glass per `Drawer` e `AppCard` (blur moderato + opacità bassa) con toggle in Impostazioni
- [x] Bordi/inset subtili e fallback senza blur se preferenze riducono effetti
- [x] Verifica performance su liste lunghe (applicare glass solo a layer stabili)
- [x] Verifica contrasto AA su testi e icone sovrapposte
- [x] AppBar: glass opzionale per tutte le route (toggle attivo in Impostazioni)

### Milestone 5 — Schermate chiave
- [x] Dashboard: rimosso `Timer` periodico; mantenuto refresh esplicito/animato
- [x] Viewer/Allenamenti: breadcrumb nel `CustomAppBar`, azioni coerenti (salva, note, completamento)
- [x] Tracker Nutrizione: header con selettore data e menù azioni unificato presente in `CustomAppBar`
- [x] Misure: empty state chiaro con CTA; grafici `fl_chart` allineati al tema
- [x] Records (MaxRM): griglia card uniforme con skeleton e azioni evidenti e filtri

- [x] Programs screen (`lib/user_programs.dart`):
  - [x] Sostituire card custom con `AppCard` coerente (header/badge, body, actions)
  - [x] Integrare toggle Glass via `uiGlassEnabledProvider` su body (fallback gradient)
  - [x] Evitare `AppBar` locali, usare `CustomAppBar` globale

- [x] TrainingBuilder — Volume Dashboard (`lib/trainingBuilder/training_volume_dashboard.dart`):
  - [x] Convertire i contenitori card in `AppCard` (grafico e tabella)
  - [x] Integrare toggle Glass sul body
  - [x] Nessun `AppBar` locale; dipendere da `CustomAppBar`

- [x] Esercizi — Cards (`lib/exerciseManager/widgets/exercise_widgets.dart`):
  - [x] Unificare card esercizio da `Container` a `AppCard` per coerenza visiva e hover/tap

- [x] Nutrizione — FavouriteDays (`lib/nutrition/tracker/my_meals.dart`):
  - [x] Rimuovere `appBar` locale e usare `CustomAppBar`
  - [x] Verificare metadati rotta per titolo coerente in `RouteMetadata`

- [x] Metadati Rotte:
  - [x] Aggiungere eventuali route secondarie mancanti in `RouteMetadata` per garantire titoli/icone coerenti nel `CustomAppBar`

### Milestone 8 — Autenticazione
- [x] Login: UI coerente con stile Glass “lite” (GlassLite + AppTheme), testi localizzati IT, bottoni coerenti
- [x] Recupero password: flusso reset via email integrato, feedback SnackBar

### Milestone 6 — Accessibilità e motion
- [x] Controllo touch target ≥ 44px (IconButton/TextButton/FilledButton) e overlay coerenti
- [x] Riduzione animazioni rispettando preferenze OS (transizioni ridotte)
- [x] Stati hover/focus coerenti su desktop/web
- [x] Verifica puntuale contrasto AA su combinazioni critiche (badge, KPI badge; grafici con testo/linee leggibili)

### Milestone 7 — Qualità e test
- [x] Skeleton e placeholder unificati
 - [x] Golden/smoke test base per card/badge/empty-state
 - [x] Smoke test navigazione (GoRouter) e flussi principali

## Criteri di accettazione
- Build verde e lint puliti sui file toccati
- Coerenza visiva tra schermate (tipografia, spaziatura, colori, stati)
- Navigazione chiara e consistente mobile/desktop
- Nessuna regressione su deep‑link e rotte
- Riuso di `CustomAppBar` ovunque senza duplicati

## Note
-. Per preferenze di stile, mantenere UI moderna Google/Apple e non creare duplicati di `CustomAppBar`.