import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
color: theme.colorScheme.surfaceContainerHighest.withAlpha(
  (theme.colorScheme.surfaceContainerHighest.alpha * 0.8).toInt(),
),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Privacy Policy',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withValues(
                        alpha: theme.colorScheme.primary.opacity * 0.1,
                      ),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: PrivacyPolicyContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyContent extends StatefulWidget {
  const PrivacyPolicyContent({super.key});

  @override
  State<PrivacyPolicyContent> createState() => _PrivacyPolicyContentState();
}

class _PrivacyPolicyContentState extends State<PrivacyPolicyContent> {
  final Map<String, bool> _expandedSections = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header informativo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
theme.colorScheme.primaryContainer.withAlpha(
  (theme.colorScheme.primaryContainer.alpha * 0.3).toInt(),
),
theme.colorScheme.secondaryContainer.withAlpha(
  (theme.colorScheme.secondaryContainer.alpha * 0.2).toInt(),
),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(
                alpha: theme.colorScheme.outline.opacity * 0.2,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.security_rounded,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'La tua privacy è importante',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Questa policy spiega come raccogliamo, utilizziamo e proteggiamo i tuoi dati personali in conformità al GDPR.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
color: theme.colorScheme.primary.withAlpha(
  (theme.colorScheme.primary.alpha * 0.1).toInt(),
),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ultimo aggiornamento: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        _buildExpandableSection(
          context,
          '1. TITOLARE DEL TRATTAMENTO',
          Icons.business_rounded,
          '''AlphanessOne è un'applicazione sviluppata da Giulio Leone.

Titolare del trattamento:
- Nome: Giulio Leone
- Email: giulio97.leone@gmail.com''',
          'titolare',
        ),

        _buildExpandableSection(
          context,
          '2. DATI PERSONALI RACCOLTI',
          Icons.data_usage_rounded,
          '''L'applicazione raccoglie e tratta le seguenti categorie di dati personali:

a) Dati di registrazione:
- Nome e cognome
- Indirizzo email
- Password (crittografata)

b) Dati relativi all'allenamento:
- Programmi di allenamento personalizzati
- Progressi e statistiche degli esercizi
- Record personali e misurazioni

c) Dati nutrizionali:
- Piani alimentari
- Tracciamento dei pasti
- Calcoli metabolici (TDEE, macro)

d) Dati tecnici:
- Identificatori del dispositivo
- Dati di utilizzo dell'app
- Log di sistema per il debugging
- Dati di consenso GDPR: timestamp del consenso, indirizzo IP, versione della policy accettata, metodo di consenso''',
          'dati_raccolti',
        ),

        _buildExpandableSection(
          context,
          '3. FINALITÀ E BASE GIURIDICA DEL TRATTAMENTO',
          Icons.gps_fixed,
          '''I dati personali sono trattati per le seguenti finalità:

a) Fornitura del servizio (Art. 6, par. 1, lett. b GDPR):
- Gestione dell'account utente
- Erogazione delle funzionalità dell'app
- Personalizzazione dei contenuti

b) Consenso dell'interessato (Art. 6, par. 1, lett. a GDPR):
- Invio di comunicazioni promozionali
- Analisi statistiche per migliorare il servizio

c) Interesse legittimo (Art. 6, par. 1, lett. f GDPR):
- Sicurezza e prevenzione frodi
- Miglioramento delle prestazioni dell'app
- Tracciare e documentare il consenso GDPR per conformità normativa
- Gestire richieste di accesso, rettifica e cancellazione dati''',
          'finalita',
        ),

        _buildExpandableSection(
          context,
          '4. MODALITÀ DI TRATTAMENTO',
          Icons.settings_rounded,
          '''Il trattamento dei dati personali avviene mediante strumenti informatici e telematici, con modalità organizzative e logiche strettamente correlate alle finalità indicate.

I dati sono:
- Archiviati su server sicuri con crittografia
- Accessibili solo al personale autorizzato
- Protetti da misure di sicurezza tecniche e organizzative
- Sottoposti a backup regolari per garantire la continuità del servizio
- Processati con sistemi conformi GDPR
- Monitorati con audit trail per tracciabilità''',
          'modalita',
        ),

        _buildExpandableSection(
          context,
          '5. CONSERVAZIONE DEI DATI',
          Icons.schedule_rounded,
          '''I dati personali sono conservati per il tempo strettamente necessario al conseguimento delle finalità per cui sono stati raccolti:

- Dati dell'account: fino alla cancellazione dell'account
- Dati di allenamento: fino alla cancellazione dell'account
- Dati di log: massimo 12 mesi
- Dati per finalità di marketing: fino alla revoca del consenso
- Registri di consenso GDPR: 7 anni per conformità normativa
- Dati di audit: 3 anni per verifiche di conformità''',
          'conservazione',
        ),

        _buildExpandableSection(
          context,
          '6. COMUNICAZIONE E DIFFUSIONE',
          Icons.share_rounded,
          '''I dati personali non sono oggetto di diffusione.

I dati possono essere comunicati a:
- Fornitori di servizi cloud (Firebase/Google Cloud)
- Fornitori di servizi di analisi
- Autorità competenti, se richiesto dalla legge
- Processori di dati certificati GDPR
- Servizi di analytics anonimi per miglioramenti

Tutti i fornitori sono selezionati in base a garanzie di conformità al GDPR e vincolati da accordi di riservatezza.''',
          'comunicazione',
        ),

        _buildExpandableSection(
          context,
          '7. TRASFERIMENTO DATI EXTRA-UE',
          Icons.public_rounded,
          '''Alcuni dati potrebbero essere trasferiti verso paesi extra-UE attraverso i servizi di Google Cloud Platform e Firebase.

Tali trasferimenti avvengono sulla base di:
- Decisioni di adeguatezza della Commissione Europea
- Clausole contrattuali standard approvate dalla Commissione
- Altre garanzie appropriate previste dal GDPR
- Certificazioni di adequacy decisions per paesi terzi
- Monitoraggio continuo della conformità dei fornitori''',
          'trasferimenti',
        ),

        _buildExpandableSection(
          context,
          '8. DIRITTI DELL\'INTERESSATO',
          Icons.account_balance_rounded,
          '''In qualità di interessato, hai diritto a:

a) Accesso (Art. 15 GDPR): ottenere conferma del trattamento e copia dei dati
b) Rettifica (Art. 16 GDPR): correggere dati inesatti o incompleti
c) Cancellazione (Art. 17 GDPR): ottenere la cancellazione dei dati
d) Limitazione (Art. 18 GDPR): limitare il trattamento in specifici casi
e) Portabilità (Art. 20 GDPR): ricevere i dati in formato strutturato
f) Opposizione (Art. 21 GDPR): opporsi al trattamento per motivi legittimi
g) Revoca del consenso: revocare il consenso in qualsiasi momento
h) Reclamo: presentare reclamo all'autorità di controllo
i) Non essere sottoposto a decisioni automatizzate

Per esercitare i tuoi diritti, contattaci all'indirizzo: giulio97.leone@gmail.com
Risponderemo entro 30 giorni dalla richiesta.''',
          'diritti',
        ),

        _buildExpandableSection(
          context,
          '9. SICUREZZA DEI DATI',
          Icons.security_rounded,
          '''Implementiamo misure di sicurezza tecniche e organizzative appropriate per proteggere i dati personali:

- Crittografia dei dati in transito e a riposo
- Autenticazione a due fattori
- Controlli di accesso basati sui ruoli
- Monitoraggio continuo della sicurezza
- Formazione del personale sulla protezione dei dati
- Procedure di incident response
- Audit di sicurezza periodici
- Sistemi di rilevamento intrusioni
- Backup sicuri e disaster recovery''',
          'sicurezza',
        ),

        _buildExpandableSection(
          context,
          '10. COOKIES E TECNOLOGIE SIMILI',
          Icons.cookie_rounded,
          '''L'applicazione utilizza tecnologie simili ai cookies per:
- Mantenere la sessione utente
- Memorizzare le preferenze
- Analizzare l'utilizzo dell'app
- Migliorare le prestazioni
- Personalizzare l'esperienza utente
- Raccogliere statistiche anonime

Puoi gestire queste preferenze nelle impostazioni dell'app o del dispositivo.''',
          'cookies',
        ),

        _buildExpandableSection(
          context,
          '11. MINORI',
          Icons.child_care_rounded,
          '''L'applicazione non è destinata a minori di 16 anni. Non raccogliamo consapevolmente dati personali di minori di 16 anni senza il consenso dei genitori o tutori legali.

Se veniamo a conoscenza di aver raccolto dati di minori senza consenso appropriato, procederemo immediatamente alla cancellazione.

I genitori o tutori possono contattarci per:
- Verificare se abbiamo dati del minore
- Richiedere la cancellazione dei dati
- Esercitare i diritti per conto del minore''',
          'minori',
        ),

        _buildExpandableSection(
          context,
          '12. MODIFICHE ALLA PRIVACY POLICY',
          Icons.update_rounded,
          '''Ci riserviamo il diritto di modificare questa informativa sulla privacy. Le modifiche saranno comunicate attraverso l'applicazione e/o via email.

Modalità di comunicazione:
- Notifica push nell'app
- Email agli utenti registrati
- Banner informativo al primo accesso
- Richiesta di nuovo consenso se necessario

Ti invitiamo a consultare periodicamente questa pagina per rimanere aggiornato.
Versione corrente: 2.0 - Ultimo aggiornamento: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}''',
          'modifiche',
        ),

        _buildExpandableSection(
          context,
          '13. CONTATTI E RECLAMI',
          Icons.contact_support_rounded,
          '''Per qualsiasi domanda relativa a questa informativa sulla privacy o per esercitare i tuoi diritti, puoi contattarci:

Titolare del trattamento:
📧 Email: giulio97.leone@gmail.com
📱 Supporto in-app: sezione "Aiuto"
⏱️ Tempo di risposta: entro 30 giorni

Autorità Garante per la protezione dei dati personali:
🌐 Sito web: www.gpdp.it
📧 Email: garante@gpdp.it
📞 Telefono: 06.69677.1
📍 Indirizzo: Piazza Venezia, 11 - 00187 Roma

Hai il diritto di presentare reclamo se ritieni che il trattamento dei tuoi dati violi il GDPR.''',
          'contatti',
        ),

        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONSENSO AL TRATTAMENTO',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Utilizzando questa applicazione, dichiari di aver letto e compreso questa informativa sulla privacy e di acconsentire al trattamento dei tuoi dati personali per le finalità e con le modalità qui descritte.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.blue.shade700),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(
                  text: 'https://alphanessone.web.app/privacy-policy',
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copiato negli appunti'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copia link Privacy Policy'),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildExpandableSection(
    BuildContext context,
    String title,
    IconData icon,
    String content,
    String sectionKey,
  ) {
    final theme = Theme.of(context);
    final isExpanded = _expandedSections[sectionKey] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
color: theme.colorScheme.surfaceContainerHighest.withAlpha(
  (theme.colorScheme.surfaceContainerHighest.alpha * 0.3).toInt(),
),
borderRadius: BorderRadius.circular(16),
border: Border.all(
  color: theme.colorScheme.outline.withAlpha(
    (theme.colorScheme.outline.alpha * 0.2).toInt(),
  ),
),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _expandedSections[sectionKey] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: theme.colorScheme.primary.opacity * 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: isExpanded
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
