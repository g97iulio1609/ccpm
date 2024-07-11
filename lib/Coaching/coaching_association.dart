import 'package:alphanessone/services/coaching_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/models/user_model.dart';

final associationsStreamProvider = StreamProvider.autoDispose<List<Association>>((ref) {
  final coachingService = ref.watch(coachingServiceProvider);
  final usersService = ref.watch(usersServiceProvider);
  final userId = usersService.getCurrentUserId();
  return coachingService.getUserAssociations(userId);
});

class CoachAthleteAssociationScreen extends ConsumerStatefulWidget {
  const CoachAthleteAssociationScreen({super.key});

  @override
  CoachAthleteAssociationScreenState createState() => CoachAthleteAssociationScreenState();
}

class CoachAthleteAssociationScreenState extends ConsumerState<CoachAthleteAssociationScreen> with SingleTickerProviderStateMixin {
  late String userRole;
  late String userId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final usersService = ref.read(usersServiceProvider);
    userRole = usersService.getCurrentUserRole();
    userId = usersService.getCurrentUserId();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final associationsAsyncValue = ref.watch(associationsStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Accettate'),
              Tab(text: 'In Attesa'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAssociationList(associationsAsyncValue, 'accepted'),
                _buildAssociationList(associationsAsyncValue, 'pending'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: userRole == 'client' ? FloatingActionButton(
        onPressed: _showCoachSearchDialog,
        tooltip: 'Cerca Coach',
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildAssociationList(AsyncValue<List<Association>> associationsAsyncValue, String status) {
    return associationsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Errore: $err')),
      data: (associations) {
        final filteredAssociations = associations.where((a) => a.status == status).toList();
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

  void _showCoachSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => CoachSearchDialog(userId: userId),
    );
  }

  Future<void> _respondToAssociation(String associationId, bool accept) async {
    final coachingService = ref.read(coachingServiceProvider);
    final result = await coachingService.respondToAssociation(associationId, accept);
    if (mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'Associazione accettata' : 'Associazione rifiutata')),
        );
        ref.refresh(associationsStreamProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nella risposta alla richiesta di associazione.')),
        );
      }
    }
  }

  Future<void> _removeAssociation(String associationId) async {
    final coachingService = ref.read(coachingServiceProvider);
    final result = await coachingService.removeAssociation(associationId);
    if (mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Associazione rimossa con successo.')),
        );
        ref.refresh(associationsStreamProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nella rimozione dell\'associazione.')),
        );
      }
    }
  }
}

class CoachSearchDialog extends ConsumerStatefulWidget {
  final String userId;

  const CoachSearchDialog({super.key, required this.userId});

  @override
  CoachSearchDialogState createState() => CoachSearchDialogState();
}

class CoachSearchDialogState extends ConsumerState<CoachSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cerca Coach'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Inserisci il nome o l'email del coach",
              ),
              onChanged: _performSearch,
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final coach = _searchResults[index];
                    return ListTile(
                      title: Text(coach.displayName ?? coach.name ?? 'Nome non disponibile'),
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
      ],
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final coachingService = ref.read(coachingServiceProvider);
    final results = await coachingService.searchCoaches(query);
    
    final availableCoaches = await Future.wait(results.map((coach) async {
      final isAvailable = await coachingService.isCoachAvailableForAssociation(coach.id);
      return isAvailable ? coach : null;
    }));

    setState(() => _searchResults = availableCoaches.whereType<UserModel>().toList());
  }

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

    final result = await coachingService.requestAssociation(coachId, widget.userId);
    if (mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Richiesta di associazione inviata con successo.')),
        );
        ref.refresh(associationsStreamProvider);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nell\'invio della richiesta di associazione.')),
        );
      }
    }
  }
}

class AssociationTile extends ConsumerWidget {
  final Association association;
  final String userRole;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onRemove;

  const AssociationTile({
    super.key,
    required this.association,
    required this.userRole,
    this.onAccept,
    this.onReject,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersService = ref.read(usersServiceProvider);
    final userFuture = userRole == 'admin' 
        ? usersService.getUserById(association.athleteId)
        : usersService.getUserById(association.coachId);

    return FutureBuilder<UserModel?>(
      future: userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(title: Text('Caricamento...'));
        }
        
        final associatedUser = snapshot.data;
        final userName = associatedUser?.displayName ?? associatedUser?.name ?? 'Utente sconosciuto';
        
        return ListTile(
          title: Text(userRole == 'admin' ? 'Atleta: $userName' : 'Coach: $userName'),
          subtitle: Text('Stato: ${association.status}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (association.status == 'pending' && 
                  (userRole == 'admin' || userRole == 'coach'))
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: onAccept,
                  tooltip: 'Accetta',
                ),
              if (association.status == 'pending' && 
                  (userRole == 'admin' || userRole == 'coach'))
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onReject,
                  tooltip: 'Rifiuta',
                ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onRemove,
                  tooltip: 'Rimuovi',
                ),
            ],
          ),
        );
      },
    );
  }
}

class AssociationDetailsScreen extends ConsumerStatefulWidget {
  final Association association;

  const AssociationDetailsScreen({super.key, required this.association});

  @override
  AssociationDetailsScreenState createState() => AssociationDetailsScreenState();
}

class AssociationDetailsScreenState extends ConsumerState<AssociationDetailsScreen> {
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    final usersService = ref.read(usersServiceProvider);
    _userFuture = usersService.getUserById(
      usersService.getCurrentUserRole() == 'admin' ? widget.association.athleteId : widget.association.coachId
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettagli Associazione'),
      ),
      body: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final associatedUser = snapshot.data;
          if (associatedUser == null) {
            return const Center(child: Text('Utente non trovato'));
          }

          final userName = associatedUser.displayName ?? associatedUser.name ?? 'Utente sconosciuto';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nome: $userName', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Email: ${associatedUser.email}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Stato: ${widget.association.status}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                if (widget.association.status == 'pending' && 
                    (ref.read(usersServiceProvider).getCurrentUserRole() == 'admin' || 
                     ref.read(usersServiceProvider).getCurrentUserRole() == 'coach'))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _respondToAssociation(true),
                        child: const Text('Accetta'),
                      ),
                      ElevatedButton(
                        onPressed: () => _respondToAssociation(false),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Rifiuta'),
                      ),
                    ],
                  ),
                if (widget.association.status == 'accepted')
                  Center(
                    child: ElevatedButton(
                      onPressed: _removeAssociation,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Termina Associazione'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _respondToAssociation(bool accept) async {
    final coachingService = ref.read(coachingServiceProvider);
    final result = await coachingService.respondToAssociation(widget.association.id, accept);
    if (mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(accept ? 'Associazione accettata' : 'Associazione rifiutata')),
        );
        ref.refresh(associationsStreamProvider);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nella risposta alla richiesta di associazione.')),
        );
      }
    }
  }

  Future<void> _removeAssociation() async {
    final coachingService = ref.read(coachingServiceProvider);
    final result = await coachingService.removeAssociation(widget.association.id);
    if (mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Associazione rimossa con successo.')),
        );
        ref.refresh(associationsStreamProvider);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nella rimozione dell\'associazione.')),
        );
      }
    }
  }
}