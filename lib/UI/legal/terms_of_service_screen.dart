import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termini di Servizio'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: TermsOfServiceContent(),
      ),
    );
  }
}

class TermsOfServiceContent extends StatelessWidget {
  const TermsOfServiceContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TERMINI DI SERVIZIO',
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
          '1. ACCETTAZIONE DEI TERMINI',
          '''Utilizzando l'applicazione AlphanessOne, accetti di essere vincolato da questi Termini di Servizio. Se non accetti questi termini, non utilizzare l'applicazione.''',
        ),

        _buildSection(
          context,
          '2. DESCRIZIONE DEL SERVIZIO',
          '''AlphanessOne è un'applicazione per il fitness che fornisce:
- Programmi di allenamento personalizzati
- Tracciamento nutrizionale
- Monitoraggio dei progressi
- Coaching virtuale

Il servizio è fornito "così com'è" e può essere modificato o interrotto in qualsiasi momento.''',
        ),

        _buildSection(
          context,
          '3. ACCOUNT UTENTE',
          '''Per utilizzare l'applicazione devi:
- Fornire informazioni accurate e complete
- Mantenere la sicurezza del tuo account
- Notificarci immediatamente di qualsiasi uso non autorizzato
- Essere responsabile di tutte le attività sul tuo account''',
        ),

        _buildSection(context, '4. USO ACCETTABILE', '''Ti impegni a non:
- Utilizzare l'applicazione per scopi illegali
- Interferire con il funzionamento del servizio
- Tentare di accedere ad account di altri utenti
- Trasmettere contenuti dannosi o offensivi
- Violare i diritti di proprietà intellettuale'''),

        _buildSection(
          context,
          '5. CONTENUTI UTENTE',
          '''Sei responsabile dei contenuti che carichi nell'applicazione. Concedi a AlphanessOne una licenza per utilizzare, modificare e distribuire tali contenuti per fornire il servizio.''',
        ),

        _buildSection(
          context,
          '6. LIMITAZIONE DI RESPONSABILITÀ',
          '''AlphanessOne non è responsabile per:
- Danni diretti, indiretti o consequenziali
- Perdita di dati o interruzioni del servizio
- Risultati di fitness o salute
- Azioni di terze parti

L'uso dell'applicazione è a tuo rischio.''',
        ),

        _buildSection(
          context,
          '7. MODIFICHE AI TERMINI',
          '''Ci riserviamo il diritto di modificare questi termini in qualsiasi momento. Le modifiche saranno comunicate attraverso l'applicazione.''',
        ),

        const SizedBox(height: 32),

        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(
                  text: 'https://alphanessone.app/terms-of-service',
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
            label: const Text('Copia link Termini di Servizio'),
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