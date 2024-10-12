// subscriptions_screen.dart

import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/user_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Store/inAppPurchase_services.dart';
import 'package:alphanessone/Store/inAppPurchase_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  SubscriptionsScreenState createState() => SubscriptionsScreenState();
}

class SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  final InAppPurchaseService _inAppPurchaseService = InAppPurchaseService();
  final TextEditingController _userSearchController = TextEditingController();
  final FocusNode _userSearchFocusNode = FocusNode();
  StreamSubscription<List<UserModel>>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _checkIfAdmin();
    await _fetchSubscriptionDetails();
    await _loadAllUsers(); // Carica la lista completa degli utenti
  }

  // Controlla se l'utente corrente è un amministratore
  Future<void> _checkIfAdmin() async {
    final firebaseAuth = ref.read(firebaseAuthProvider);
    final firebaseFirestore = ref.read(firebaseFirestoreProvider);

    final user = firebaseAuth.currentUser;
    if (user != null) {
      final userDoc = await firebaseFirestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
        ref.read(isAdminProvider.notifier).state = true;
      } else {
      }
    } else {
    }
  }

  // Carica la lista completa degli utenti e aggiorna il provider
  Future<void> _loadAllUsers() async {
    final isAdmin = ref.read(isAdminProvider);
    if (isAdmin) {
      try {
        final usersStream = ref.read(usersServiceProvider).getUsers();
        _userSubscription = usersStream.listen((users) {
          ref.read(userListProvider.notifier).state = users;
          ref.read(filteredUserListProvider.notifier).state = users;
        });
      } catch (e) {
        _showSnackBar('Errore nel caricamento degli utenti.');
      }
    }
  }

  // Recupera i dettagli dell'abbonamento per l'utente corrente o per un utente selezionato (admin)
  Future<void> _fetchSubscriptionDetails({String? userId}) async {
    ref.read(subscriptionLoadingProvider.notifier).state = true;

    try {
      final isAdmin = ref.read(isAdminProvider);
      if (isAdmin && userId != null) {
        final firebaseFunctions = ref.read(firebaseFunctionsProvider);
        final HttpsCallable callable = firebaseFunctions.httpsCallable('getUserSubscriptionDetails');
        final results = await callable.call(<String, dynamic>{
          'userId': userId,
        });

        if (results.data['hasSubscription']) {
          final sub = results.data['subscription'];
          final subscriptionDetails = SubscriptionDetails(
            id: sub['id'],
            status: sub['status'],
            currentPeriodEnd: DateTime.fromMillisecondsSinceEpoch(sub['current_period_end'] * 1000),
            items: List<SubscriptionItem>.from(
              sub['items'].map((item) => SubscriptionItem(
                    priceId: item['priceId'],
                    productId: item['productId'],
                    quantity: item['quantity'],
                  )),
            ),
          );
          ref.read(selectedUserSubscriptionProvider.notifier).state = subscriptionDetails;
        } else {
          ref.read(selectedUserSubscriptionProvider.notifier).state = null;
          _showSnackBar('L\'utente selezionato non ha abbonamenti attivi.');
        }
      } else {
        final details = await _inAppPurchaseService.getSubscriptionDetails();
        ref.read(subscriptionDetailsProvider.notifier).state = details;
      }
    } catch (e) {
      _showSnackBar('Errore nel recuperare i dettagli dell\'abbonamento.');
    } finally {
      ref.read(subscriptionLoadingProvider.notifier).state = false;
    }
  }

  // Mostra una SnackBar con un messaggio
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Mostra le opzioni per gestire l'abbonamento
  void _showManageSubscriptionOptions() {
    final subscriptionDetails = ref.read(subscriptionDetailsProvider);
    if (subscriptionDetails == null) {
      _showSnackBar('Nessun abbonamento attivo.');
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.update, color: Theme.of(context).colorScheme.primary),
                title: Text('Aggiorna Piano'),
                onTap: () {
                  Navigator.pop(context);
                  _showUpdateSubscriptionDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Annulla Abbonamento',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmCancelSubscription();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Mostra il dialog per aggiornare l'abbonamento
  void _showUpdateSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedPriceId;
        final availableProducts = _inAppPurchaseService.productDetailsByProductId.values.expand((e) => e).toList();

        return AlertDialog(
          title: Text('Aggiorna Abbonamento'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButtonFormField<String>(
                items: availableProducts.map((product) {
                  return DropdownMenuItem<String>(
                    value: product.id,
                    child: Text('${product.title} - ${product.price} ${product.currencyCode}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPriceId = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Seleziona Nuovo Piano',
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Annulla'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              onPressed: selectedPriceId == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      ref.read(managingSubscriptionProvider.notifier).state = true;
                      try {
                        await _inAppPurchaseService.updateSubscription(selectedPriceId!);
                        _showSnackBar('Abbonamento aggiornato con successo.');
                        await _fetchSubscriptionDetails(userId: ref.read(selectedUserIdProvider));
                      } catch (e) {
                        _showSnackBar('Errore nell\'aggiornamento dell\'abbonamento: $e');
                      } finally {
                        ref.read(managingSubscriptionProvider.notifier).state = false;
                      }
                    },
              child: Text('Aggiorna'),
            ),
          ],
        );
      },
    );
  }

  // Conferma la cancellazione dell'abbonamento
  Future<void> _confirmCancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annulla Abbonamento'),
        content: Text('Sei sicuro di voler annullare il tuo abbonamento?'),
        actions: [
          TextButton(
            child: Text('No'),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
          ElevatedButton(
            child: Text('Sì'),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(managingSubscriptionProvider.notifier).state = true;
      try {
        await _inAppPurchaseService.cancelSubscription();
        _showSnackBar('Abbonamento annullato con successo.');
        await _fetchSubscriptionDetails(userId: ref.read(selectedUserIdProvider));
      } catch (e) {
        _showSnackBar('Errore nell\'annullamento dell\'abbonamento: $e');
      } finally {
        ref.read(managingSubscriptionProvider.notifier).state = false;
      }
    } else {
    }
  }

  // Crea un nuovo abbonamento (funzionalità non implementata)
  Future<void> _createNewSubscription() async {
    _showSnackBar('Funzionalità di creazione abbonamento non implementata.');
  }

  // Sincronizza l'abbonamento con Stripe
  Future<void> _syncStripeSubscription() async {
    ref.read(syncingProvider.notifier).state = true;

    try {
      final firebaseFunctions = ref.read(firebaseFunctionsProvider);
      final HttpsCallable callable = firebaseFunctions.httpsCallable('syncStripeSubscription');
      final result = await callable.call(<String, dynamic>{
        'syncAll': ref.read(isAdminProvider), // Passa true se admin per sincronizzare tutti gli abbonamenti
      });

      if (result.data['success']) {
        _showSnackBar(result.data['message']);
        if (ref.read(isAdminProvider) && ref.read(selectedUserIdProvider) != null) {
          await _fetchSubscriptionDetails(userId: ref.read(selectedUserIdProvider));
        } else {
          await _fetchSubscriptionDetails();
        }
      } else {
        _showSnackBar(result.data['message']);
      }
    } catch (e) {
      _showSnackBar('Errore nella sincronizzazione dell\'abbonamento.');
    } finally {
      ref.read(syncingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final isAdmin = ref.watch(isAdminProvider);
    final allUsers = ref.watch(userListProvider);
    ref.watch(filteredUserListProvider);
    final selectedUserId = ref.watch(selectedUserIdProvider);
    final subscriptionDetails = ref.watch(subscriptionDetailsProvider);
    final selectedUserSubscription = ref.watch(selectedUserSubscriptionProvider);
    final isLoading = ref.watch(subscriptionLoadingProvider);
    ref.watch(managingSubscriptionProvider);
    final isSyncing = ref.watch(syncingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Gestione Abbonamenti' : 'I Tuoi Abbonamenti'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              if (isAdmin && selectedUserId != null) {
                _fetchSubscriptionDetails(userId: selectedUserId);
              } else {
                _fetchSubscriptionDetails();
              }
            },
            tooltip: 'Ricarica',
          ),
        ],
      ),
      body: Column(
        children: [
          // Campo di ricerca utenti per admin
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: UserTypeAheadField(
                controller: _userSearchController,
                focusNode: _userSearchFocusNode,
                onSelected: (UserModel user) {
                  _userSearchController.text = user.name;
                  ref.read(selectedUserIdProvider.notifier).state = user.id;
                  _fetchSubscriptionDetails(userId: user.id);
                  FocusScope.of(context).unfocus();
                },
                onChanged: (pattern) {
                  final filtered = allUsers.where((user) =>
                      user.name.toLowerCase().contains(pattern.toLowerCase()) ||
                      user.email.toLowerCase().contains(pattern.toLowerCase())).toList();
                  ref.read(filteredUserListProvider.notifier).state = filtered;
                },
              ),
            ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : isAdmin
                    ? _buildAdminView(
                        selectedUserId: selectedUserId,
                        selectedUserSubscription: selectedUserSubscription,
                      )
                    : _buildUserView(
                        subscriptionDetails: subscriptionDetails,
                      ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: isSyncing ? null : _syncStripeSubscription,
              label: isSyncing ? Text('Sincronizzazione...') : Text('Sincronizza Tutti'),
              icon: isSyncing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: colorScheme.onSecondary, strokeWidth: 2),
                    )
                  : Icon(Icons.sync),
            )
          : null,
    );
  }

  // Costruisce la vista per l'amministratore
  Widget _buildAdminView({
    required String? selectedUserId,
    required SubscriptionDetails? selectedUserSubscription,
  }) {
    if (selectedUserId == null) {
      return Center(
        child: Text(
          'Seleziona un utente per visualizzare i suoi abbonamenti.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }

    if (selectedUserSubscription == null) {
      return Center(
        child: Text(
          'L\'utente selezionato non ha abbonamenti attivi.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }

    final usersService = ref.read(usersServiceProvider);
    final Future<UserModel?> userFuture = usersService.getUserById(selectedUserId);

    return FutureBuilder<UserModel?>(
      future: userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(
            child: Text(
              'Utente non trovato.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
        }

        final user = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubscriptionCard(
                title: '${user.name}\'s Abbonamento',
                status: selectedUserSubscription.status.capitalize(),
                expiry: DateFormat.yMMMd().add_jm().format(selectedUserSubscription.currentPeriodEnd),
              ),
              SizedBox(height: 16),
              Text(
                'Dettagli Abbonamento',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Divider(),
              ...selectedUserSubscription.items.map((item) {
                return SubscriptionItemTile(item: item);
              }),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: ref.watch(syncingProvider) ? null : _syncStripeSubscription,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: ref.watch(syncingProvider)
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Text('Sincronizza Abbonamento con Stripe'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Costruisce la vista per l'utente
  Widget _buildUserView({
    required SubscriptionDetails? subscriptionDetails,
  }) {
    if (subscriptionDetails == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Nessun abbonamento attivo.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createNewSubscription,
              child: Text('Abbonati Ora'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubscriptionCard(
            title: 'Il Tuo Abbonamento',
            status: subscriptionDetails.status.capitalize(),
            expiry: DateFormat.yMMMd().add_jm().format(subscriptionDetails.currentPeriodEnd),
            actionButton: ElevatedButton.icon(
              icon: Icon(Icons.manage_accounts),
              label: Text('Gestisci Abbonamento'),
              onPressed: ref.read(managingSubscriptionProvider) ? null : _showManageSubscriptionOptions,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Dettagli Abbonamento',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Divider(),
          ...subscriptionDetails.items.map((item) {
            return SubscriptionItemTile(item: item);
          }),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: ref.watch(syncingProvider) ? null : _syncStripeSubscription,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: ref.watch(syncingProvider)
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Text('Sincronizza Abbonamento con Stripe'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _userSearchFocusNode.dispose();
    _userSubscription?.cancel(); // Annulla l'abbonamento allo stream degli utenti
    super.dispose();
  }
}

// Widget riutilizzabile per visualizzare una scheda di abbonamento
class SubscriptionCard extends StatelessWidget {
  final String title;
  final String status;
  final String expiry;
  final Widget? actionButton;

  const SubscriptionCard({
    super.key,
    required this.title,
    required this.status,
    required this.expiry,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text('Stato: $status', style: Theme.of(context).textTheme.bodyLarge),
            SizedBox(height: 4),
            Text('Scadenza: $expiry', style: Theme.of(context).textTheme.bodyLarge),
            if (actionButton != null) ...[
              SizedBox(height: 16),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}

// Widget riutilizzabile per visualizzare un elemento di abbonamento
class SubscriptionItemTile extends StatelessWidget {
  final SubscriptionItem item;

  const SubscriptionItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Prodotto: ${item.productId}'),
      subtitle: Text('ID Prezzo: ${item.priceId}'),
      trailing: Text('Quantità: ${item.quantity}'),
    );
  }
}

// Estensione per capitalizzare le stringhe
extension StringCasingExtension on String {
  String capitalize() {
    if (length <= 1) return toUpperCase();
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
