import 'package:alphanessone/Coaching/coaching_service.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/models/user_model.dart';

/// Provider per ottenere lo stream delle associazioni in base al ruolo dell'utente
final associationsStreamProvider = StreamProvider.autoDispose<List<Association>>((ref) {
  final coachingService = ref.watch(coachingServiceProvider);
  final usersService = ref.watch(usersServiceProvider);
  final userId = usersService.getCurrentUserId();
  final userRole = ref.watch(userRoleProvider);

  if (userRole == 'coach' || userRole == 'admin') {
    // Per coach e admin, mostra tutte le associazioni dove sono coach
    return coachingService.getCoachAssociations(userId);
  } else if (userRole == 'client') {
    // Per client, mostra le proprie associazioni
    return coachingService.getUserAssociations(userId);
  } else {
    // Altri ruoli non gestiti
    return Stream.value([]);
  }
});

/// Schermata principale per la gestione delle associazioni coach-athlete
class CoachAthleteAssociationScreen extends ConsumerStatefulWidget {
  const CoachAthleteAssociationScreen({Key? key}) : super(key: key);

  @override
  CoachAthleteAssociationScreenState createState() => CoachAthleteAssociationScreenState();
}

class CoachAthleteAssociationScreenState extends ConsumerState<CoachAthleteAssociationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inizializza il TabController con 2 schede
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    // Dispone del TabController quando il widget viene distrutto
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ottiene il ruolo e l'ID dell'utente corrente in modo reattivo
    final usersService = ref.watch(usersServiceProvider);
    final String userRole = ref.watch(userRoleProvider);
    final String userId = usersService.getCurrentUserId();
    final associationsAsyncValue = ref.watch(associationsStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          // Container per la TabBar con sfondo colorato
          Container(
            color: Theme.of(context).primaryColor, // Imposta lo sfondo della TabBar
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white, // Colore dei titoli delle Tab selezionate
              unselectedLabelColor: Colors.white70, // Colore dei titoli delle Tab non selezionate
              indicatorColor: Colors.white, // Colore dell'indicatore della Tab selezionata
              tabs: const [
                Tab(text: 'Accettate'),
                Tab(text: 'In Attesa'),
              ],
            ),
          ),
          // TabBarView per mostrare le associazioni filtrate
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAssociationList(associationsAsyncValue, 'accepted', userRole),
                _buildAssociationList(associationsAsyncValue, 'pending', userRole),
              ],
            ),
          ),
        ],
      ),
      // FloatingActionButton visibile solo ai client per inviare richieste di associazione
      floatingActionButton: userRole == 'client'
          ? FloatingActionButton(
              onPressed: _showCoachSearchDialog,
              tooltip: 'Cerca Coach',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  /// Costruisce la lista delle associazioni filtrate per stato
  Widget _buildAssociationList(AsyncValue<List<Association>> associationsAsyncValue, String status, String userRole) {
    return associationsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Errore: $err')),
      data: (associations) {
        // Filtra le associazioni in base allo stato ('accepted' o 'pending')
        final filteredAssociations = associations.where((a) => a.status == status).toList();
        if (filteredAssociations.isEmpty) {
          return Center(child: Text('Nessuna associazione $status.'));
        }
        return ListView.builder(
          itemCount: filteredAssociations.length,
          itemBuilder: (context, index) {
            final association = filteredAssociations[index];
            return AssociationTile(
              association: association,
              userRole: userRole,
              onAccept: status == 'pending' && (userRole == 'admin' || userRole == 'coach')
                  ? () => _respondToAssociation(association.id, true)
                  : null,
              onReject: status == 'pending' && (userRole == 'admin' || userRole == 'coach')
                  ? () => _respondToAssociation(association.id, false)
                  : null,
              onRemove: status == 'accepted'
                  ? () => _removeAssociation(association.id)
                  : null,
            );
          },
        );
      },
    );
  }

  /// Mostra il dialogo di ricerca dei coach
  void _showCoachSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => CoachSearchDialog(userId: ref.read(usersServiceProvider).getCurrentUserId()),
    );
  }

  /// Risponde a una richiesta di associazione (accetta o rifiuta)
  Future<void> _respondToAssociation(String associationId, bool accept) async {
    final coachingService = ref.read(coachingServiceProvider);
    final result = await coachingService.respondToAssociation(associationId, accept);
    if (mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'Associazione accettata' : 'Associazione rifiutata')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nella risposta alla richiesta di associazione.')),
        );
      }
    }
  }

  /// Rimuove un'associazione accettata
  Future<void> _removeAssociation(String associationId) async {
    final coachingService = ref.read(coachingServiceProvider);
    final result = await coachingService.removeAssociation(associationId);
    if (mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Associazione rimossa con successo.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nella rimozione dell\'associazione.')),
        );
      }
    }
  }
}

/// Dialogo di ricerca dei coach per i clienti
class CoachSearchDialog extends ConsumerStatefulWidget {
  final String userId;

  const CoachSearchDialog({Key? key, required this.userId}) : super(key: key);

  @override
  CoachSearchDialogState createState() => CoachSearchDialogState();
}

class CoachSearchDialogState extends ConsumerState<CoachSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cerca Coach'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Campo di testo per inserire il nome o l'email del coach
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Inserisci il nome o l'email del coach",
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: _performSearch,
            ),
            const SizedBox(height: 10),
            // Mostra un indicatore di caricamento durante la ricerca
            _isLoading
                ? const CircularProgressIndicator()
                : Flexible(
                    child: SizedBox(
                      height: 200, // Altezza fissa per il ListView
                      child: _searchResults.isEmpty
                          ? const Center(child: Text('Nessun coach trovato.'))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final coach = _searchResults[index];
                                return ListTile(
                                  title: Text(coach.displayName),
                                  subtitle: Text(coach.email),
                                  onTap: () => _requestAssociation(coach.id),
                                );
                              },
                            ),
                    ),
                  ),
          ],
        ),
      ),
      actions: [
        // Bottone per annullare e chiudere il dialogo
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
      ],
    );
  }

  /// Esegue la ricerca dei coach in base al testo inserito
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    final coachingService = ref.read(coachingServiceProvider);
    final results = await coachingService.searchCoaches(query);

    // Filtra i coach disponibili per nuove associazioni
    final availableCoaches = await Future.wait(results.map((coach) async {
      final isAvailable = await coachingService.isCoachAvailableForAssociation(coach.id);
      return isAvailable ? coach : null;
    }));

    setState(() {
      _searchResults = availableCoaches.whereType<UserModel>().toList();
      _isLoading = false;
    });
  }

  /// Invia una richiesta di associazione al coach selezionato
  Future<void> _requestAssociation(String coachId) async {
    final coachingService = ref.read(coachingServiceProvider);

    final isAvailable = await coachingService.isCoachAvailableForAssociation(coachId);
    if (!isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Questo coach non è al momento disponibile per nuove associazioni.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final result = await coachingService.requestAssociation(coachId, widget.userId);
    setState(() => _isLoading = false);

    if (mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Richiesta di associazione inviata con successo.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nell\'invio della richiesta di associazione.')),
        );
      }
    }
  }
}

/// Widget per visualizzare una singola associazione nella lista
class AssociationTile extends ConsumerStatefulWidget {
  final Association association;
  final String userRole;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onRemove;

  const AssociationTile({
    Key? key,
    required this.association,
    required this.userRole,
    this.onAccept,
    this.onReject,
    this.onRemove,
  }) : super(key: key);

  @override
  AssociationTileState createState() => AssociationTileState();
}

class AssociationTileState extends ConsumerState<AssociationTile> {
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    final usersService = ref.read(usersServiceProvider);
    _userFuture = _determineAssociatedUser(usersService);
  }

  /// Determina quale utente mostrare in base al ruolo corrente
  Future<UserModel?> _determineAssociatedUser(UsersService usersService) async {
    if (widget.userRole == 'client') {
      return usersService.getUserById(widget.association.coachId);
    } else if (widget.userRole == 'coach' || widget.userRole == 'admin') {
      return usersService.getUserById(widget.association.athleteId);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(title: Text('Caricamento...'));
        }

        final associatedUser = snapshot.data;
        final userName = associatedUser?.displayName ?? associatedUser?.name ?? 'Utente sconosciuto';

        return ListTile(
          title: Text(_getTitle(userName)),
          subtitle: Text('Stato: ${widget.association.status}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // IconButton per accettare la richiesta (visibile solo a coach/admin)
              if (widget.association.status == 'pending' && 
                  (widget.userRole == 'admin' || widget.userRole == 'coach'))
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: widget.onAccept,
                  tooltip: 'Accetta',
                ),
              // IconButton per rifiutare la richiesta (visibile solo a coach/admin)
              if (widget.association.status == 'pending' && 
                  (widget.userRole == 'admin' || widget.userRole == 'coach'))
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: widget.onReject,
                  tooltip: 'Rifiuta',
                ),
              // IconButton per rimuovere l'associazione (visibile solo se accettata)
              if (widget.onRemove != null)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: widget.onRemove,
                  tooltip: 'Rimuovi',
                ),
            ],
          ),
        );
      },
    );
  }

  /// Genera il titolo della ListTile in base al ruolo dell'utente
  String _getTitle(String userName) {
    if (widget.userRole == 'client') {
      return 'Coach: $userName';
    } else if (widget.userRole == 'coach' || widget.userRole == 'admin') {
      return 'Atleta: $userName';
    }
    return 'Utente: $userName';
  }
}
