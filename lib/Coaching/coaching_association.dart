import 'package:alphanessone/Coaching/coaching_service.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';

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
  const CoachAthleteAssociationScreen({super.key});

  @override
  CoachAthleteAssociationScreenState createState() => CoachAthleteAssociationScreenState();
}

class CoachAthleteAssociationScreenState extends ConsumerState<CoachAthleteAssociationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersService = ref.watch(usersServiceProvider);
    final String userRole = ref.watch(userRoleProvider);
    usersService.getCurrentUserId();
    final associationsAsyncValue = ref.watch(associationsStreamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.5),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: AppTheme.elevations.small,
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  indicatorColor: colorScheme.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                  unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                  ),
                  tabs: const [
                    Tab(text: 'Accettate'),
                    Tab(text: 'In Attesa'),
                  ],
                ),
              ),
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
        ),
      ),
      floatingActionButton: userRole == 'client'
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showCoachSearchDialog,
                  borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacing.md),
                    child: Icon(
                      Icons.add,
                      color: colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAssociationList(AsyncValue<List<Association>> associationsAsyncValue, String status, String userRole) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return associationsAsyncValue.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
      ),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            SizedBox(height: AppTheme.spacing.md),
            Text(
              'Errore: $err',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (associations) {
        final filteredAssociations = associations.where((a) => a.status == status).toList();
        if (filteredAssociations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'accepted' ? Icons.group_outlined : Icons.pending_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                SizedBox(height: AppTheme.spacing.md),
                Text(
                  'Nessuna associazione ${status == 'accepted' ? 'accettata' : 'in attesa'}.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(AppTheme.spacing.xl),
          itemCount: filteredAssociations.length,
          itemBuilder: (context, index) {
            final association = filteredAssociations[index];
            return Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacing.md),
              child: AssociationTile(
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
              ),
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

  const CoachSearchDialog({super.key, required this.userId});

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        child: InkWell(
          onTap: () => _showAssociationOptions(context, ref),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.md,
                        vertical: AppTheme.spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: association.status == 'accepted'
                            ? colorScheme.primaryContainer.withOpacity(0.3)
                            : colorScheme.secondaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppTheme.radii.full),
                      ),
                      child: Text(
                        association.status == 'accepted' ? 'Associazione Attiva' : 'Richiesta in Attesa',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: association.status == 'accepted'
                              ? colorScheme.primary
                              : colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => _showAssociationOptions(context, ref),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacing.md),
                FutureBuilder<UserModel?>(
                  future: _getUserDetails(ref),
                  builder: (context, snapshot) {
                    final userName = snapshot.data?.displayName ?? 'Utente';
                    return Text(
                      _getTitle(userName),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAssociationOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: association.status == 'accepted' ? 'Associazione Attiva' : 'Richiesta in Attesa',
        subtitle: _getTitle(association.athleteId),
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(
            association.status == 'accepted' ? Icons.group : Icons.pending,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        items: [
          if (onAccept != null)
            BottomMenuItem(
              title: 'Accetta Richiesta',
              icon: Icons.check_circle_outline,
              onTap: onAccept!,
            ),
          if (onReject != null)
            BottomMenuItem(
              title: 'Rifiuta Richiesta',
              icon: Icons.cancel_outlined,
              onTap: onReject!,
              isDestructive: true,
            ),
          if (onRemove != null)
            BottomMenuItem(
              title: 'Rimuovi Associazione',
              icon: Icons.delete_outline,
              onTap: onRemove!,
              isDestructive: true,
            ),
        ],
      ),
    );
  }

  /// Determina quale utente mostrare in base al ruolo corrente
  Future<UserModel?> _getUserDetails(WidgetRef ref) async {
    final usersService = ref.read(usersServiceProvider);
    if (userRole == 'client') {
      return usersService.getUserById(association.coachId);
    } else if (userRole == 'coach' || userRole == 'admin') {
      return usersService.getUserById(association.athleteId);
    }
    return null;
  }

  /// Genera il titolo della ListTile in base al ruolo dell'utente
  String _getTitle(String userName) {
    if (userRole == 'client') {
      return 'Coach: $userName';
    } else if (userRole == 'coach' || userRole == 'admin') {
      return 'Atleta: $userName';
    }
    return 'Utente: $userName';
  }
}
