import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: PrivacyPolicyContent(),
      ),
    );
  }
}

class PrivacyPolicyContent extends StatelessWidget {
  const PrivacyPolicyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INFORMATIVA SULLA PRIVACY',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Ultimo aggiornamento: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        _buildSection(
          context,
          '1. TITOLARE DEL TRATTAMENTO',
          '''AlphanessOne è un'applicazione sviluppata da Giulio Leone.

Titolare del trattamento:
- Nome: Giulio Leone
- Email: giulio97.leone@gmail.com''',
        ),

        _buildSection(
          context,
          '2. DATI PERSONALI RACCOLTI',
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
- Log di sistema per il debugging''',
        ),

        _buildSection(
          context,
          '3. FINALITÀ E BASE GIURIDICA DEL TRATTAMENTO',
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
- Miglioramento delle prestazioni dell'app''',
        ),

        _buildSection(
          context,
          '4. MODALITÀ DI TRATTAMENTO',
          '''Il trattamento dei dati personali avviene mediante strumenti informatici e telematici, con modalità organizzative e logiche strettamente correlate alle finalità indicate.

I dati sono:
- Archiviati su server sicuri con crittografia
- Accessibili solo al personale autorizzato
- Protetti da misure di sicurezza tecniche e organizzative
- Sottoposti a backup regolari per garantire la continuità del servizio''',
        ),

        _buildSection(
          context,
          '5. CONSERVAZIONE DEI DATI',
          '''I dati personali sono conservati per il tempo strettamente necessario al conseguimento delle finalità per cui sono stati raccolti:

- Dati dell'account: fino alla cancellazione dell'account
- Dati di allenamento: fino alla cancellazione dell'account
- Dati di log: massimo 12 mesi
- Dati per finalità di marketing: fino alla revoca del consenso''',
        ),

        _buildSection(
          context,
          '6. COMUNICAZIONE E DIFFUSIONE',
          '''I dati personali non sono oggetto di diffusione.

I dati possono essere comunicati a:
- Fornitori di servizi cloud (Firebase/Google Cloud)
- Fornitori di servizi di analisi
- Autorità competenti, se richiesto dalla legge

Tutti i fornitori sono selezionati in base a garanzie di conformità al GDPR.''',
        ),

        _buildSection(
          context,
          '7. TRASFERIMENTO DATI EXTRA-UE',
          '''Alcuni dati potrebbero essere trasferiti verso paesi extra-UE attraverso i servizi di Google Cloud Platform e Firebase.

Tali trasferimenti avvengono sulla base di:
- Decisioni di adeguatezza della Commissione Europea
- Clausole contrattuali standard approvate dalla Commissione
- Altre garanzie appropriate previste dal GDPR''',
        ),

        _buildSection(
          context,
          '8. DIRITTI DELL\'INTERESSATO',
          '''In qualità di interessato, hai diritto a:

a) Accesso (Art. 15 GDPR): ottenere conferma del trattamento e copia dei dati
b) Rettifica (Art. 16 GDPR): correggere dati inesatti o incompleti
c) Cancellazione (Art. 17 GDPR): ottenere la cancellazione dei dati
d) Limitazione (Art. 18 GDPR): limitare il trattamento in specifici casi
e) Portabilità (Art. 20 GDPR): ricevere i dati in formato strutturato
f) Opposizione (Art. 21 GDPR): opporsi al trattamento per motivi legittimi
g) Revoca del consenso: revocare il consenso in qualsiasi momento

Per esercitare i tuoi diritti, contattaci all'indirizzo: giulio.leone.dev@gmail.com''',
        ),

        _buildSection(
          context,
          '9. SICUREZZA DEI DATI',
          '''Implementiamo misure di sicurezza tecniche e organizzative appropriate per proteggere i dati personali:

- Crittografia dei dati in transito e a riposo
- Autenticazione a due fattori
- Controlli di accesso basati sui ruoli
- Monitoraggio continuo della sicurezza
- Formazione del personale sulla protezione dei dati
- Procedure di incident response''',
        ),

        _buildSection(
          context,
          '10. COOKIES E TECNOLOGIE SIMILI',
          '''L'applicazione utilizza tecnologie simili ai cookies per:
- Mantenere la sessione utente
- Memorizzare le preferenze
- Analizzare l'utilizzo dell'app

Puoi gestire queste preferenze nelle impostazioni dell'app.''',
        ),

        _buildSection(
          context,
          '11. MINORI',
          '''L'applicazione non è destinata a minori di 16 anni. Non raccogliamo consapevolmente dati personali di minori di 16 anni senza il consenso dei genitori o tutori legali.''',
        ),

        _buildSection(
          context,
          '12. MODIFICHE ALLA PRIVACY POLICY',
          '''Ci riserviamo il diritto di modificare questa informativa sulla privacy. Le modifiche saranno comunicate attraverso l'applicazione e/o via email.

Ti invitiamo a consultare periodicamente questa pagina per rimanere aggiornato.''',
        ),

        _buildSection(
          context,
          '13. CONTATTI E RECLAMI',
          '''Per qualsiasi domanda relativa a questa informativa sulla privacy o per esercitare i tuoi diritti, puoi contattarci:

Email: giulio97.leone.@gmail.com

Hai inoltre il diritto di presentare reclamo all'Autorità Garante per la protezione dei dati personali:
- Sito web: www.gpdp.it
- Email: garante@gpdp.it
- Telefono: 06.69677.1''',
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
}