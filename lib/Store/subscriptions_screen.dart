// lib/screens/subscriptions_screen.dart

import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/user_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Store/inAppPurchase_services.dart';
import 'package:alphanessone/Store/inAppPurchase_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  SubscriptionsScreenState createState() => SubscriptionsScreenState();
}

class SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  final InAppPurchaseService _inAppPurchaseService = InAppPurchaseService();
  SubscriptionDetails? _subscriptionDetails;
  bool _isLoading = true;
  bool _isManagingSubscription = false;
  bool _isSyncing = false;

  // Variables per admin
  bool _isAdmin = false;
  UserModel? _selectedUser;
  SubscriptionDetails? _selectedUserSubscription;
  final TextEditingController _userSearchController = TextEditingController();
  final FocusNode _userSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    debugPrint('initState: Initializing SubscriptionsScreen');
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _checkIfAdmin();
    await _fetchSubscriptionDetails();
  }

  // Controlla se l'utente corrente è admin
  Future<void> _checkIfAdmin() async {
    debugPrint('Checking if current user is admin');
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      debugPrint('User document exists: ${userDoc.exists}');
      if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
        setState(() {
          _isAdmin = true;
        });
        debugPrint('User is admin');
      } else {
        debugPrint('User is not admin');
      }
    } else {
      debugPrint('No authenticated user found');
    }
  }

  // Recupera i dettagli dell'abbonamento per l'utente corrente o per un utente selezionato (admin)
  Future<void> _fetchSubscriptionDetails({String? userId}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isAdmin && userId != null) {
        debugPrint('Fetching subscription details for user ID: $userId');
        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getUserSubscriptionDetails');
        final results = await callable.call(<String, dynamic>{
          'userId': userId,
        });

        if (results.data['hasSubscription']) {
          final sub = results.data['subscription'];
          setState(() {
            _selectedUserSubscription = SubscriptionDetails(
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
          });
          debugPrint('User subscription details retrieved successfully for user ID: $userId');
        } else {
          setState(() {
            _selectedUserSubscription = null;
          });
          _showSnackBar('L\'utente selezionato non ha abbonamenti attivi.');
          debugPrint('The selected user has no active subscriptions.');
        }
      } else {
        debugPrint('Fetching subscription details for current user');
        final details = await _inAppPurchaseService.getSubscriptionDetails();
        setState(() {
          _subscriptionDetails = details;
        });
        debugPrint('Subscription details retrieved successfully.');
      }
    } catch (e) {
      debugPrint('Error retrieving subscription details: $e');
      _showSnackBar('Errore nel recuperare i dettagli dell\'abbonamento.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Mostra un SnackBar con un messaggio
  void _showSnackBar(String message) {
    debugPrint('Showing SnackBar with message: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Mostra le opzioni per gestire l'abbonamento
  void _showManageSubscriptionOptions() {
    debugPrint('Showing manage subscription options');
    if (_subscriptionDetails == null) {
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
                  debugPrint('Update Plan tapped');
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
                  debugPrint('Cancel Subscription tapped');
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

  // Mostra la dialog per aggiornare l'abbonamento
  void _showUpdateSubscriptionDialog() {
    debugPrint('Showing update subscription dialog');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedPriceId;
        List<ProductDetails> availableProducts = _inAppPurchaseService.productDetailsByProductId.values.expand((e) => e).toList();

        return AlertDialog(
          title: Text('Aggiorna Abbonamento'),
          content: DropdownButtonFormField<String>(
            items: availableProducts.map((product) {
              return DropdownMenuItem<String>(
                value: product.id,
                child: Text('${product.title} - ${product.price} ${product.currencyCode}'),
              );
            }).toList(),
            onChanged: (value) {
              selectedPriceId = value;
              debugPrint('Selected Price ID: $selectedPriceId');
            },
            decoration: InputDecoration(
              labelText: 'Seleziona Nuovo Piano',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Annulla'),
              onPressed: () {
                debugPrint('Cancel update subscription dialog');
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              onPressed: selectedPriceId == null
                  ? null
                  : () async {
                      debugPrint('Update subscription button pressed with Price ID: $selectedPriceId');
                      Navigator.pop(context);
                      setState(() {
                        _isManagingSubscription = true;
                      });
                      try {
                        await _inAppPurchaseService.updateSubscription(selectedPriceId!);
                        _showSnackBar('Abbonamento aggiornato con successo.');
                        await _fetchSubscriptionDetails(userId: _selectedUser?.id);
                        debugPrint('Subscription updated successfully for user');
                      } catch (e) {
                        debugPrint('Error updating subscription: $e');
                        _showSnackBar('Errore nell\'aggiornamento dell\'abbonamento: $e');
                      } finally {
                        setState(() {
                          _isManagingSubscription = false;
                        });
                      }
                    },
              child: Text('Aggiorna'),
            ),
          ],
        );
      },
    );
  }

  // Conferma l'annullamento dell'abbonamento
  Future<void> _confirmCancelSubscription() async {
    debugPrint('Confirming subscription cancellation');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annulla Abbonamento'),
        content: Text('Sei sicuro di voler annullare il tuo abbonamento?'),
        actions: [
          TextButton(
            child: Text('No'),
            onPressed: () {
              debugPrint('User chose not to cancel subscription');
              Navigator.pop(context, false);
            },
          ),
          ElevatedButton(
            child: Text('Sì'),
            onPressed: () {
              debugPrint('User chose to cancel subscription');
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );

    if (confirm == true) {
      debugPrint('User confirmed subscription cancellation');
      setState(() {
        _isManagingSubscription = true;
      });
      try {
        await _inAppPurchaseService.cancelSubscription();
        _showSnackBar('Abbonamento annullato con successo.');
        debugPrint('Subscription cancelled successfully');
        await _fetchSubscriptionDetails(userId: _selectedUser?.id);
      } catch (e) {
        debugPrint('Error cancelling subscription: $e');
        _showSnackBar('Errore nell\'annullamento dell\'abbonamento: $e');
      } finally {
        setState(() {
          _isManagingSubscription = false;
        });
      }
    } else {
      debugPrint('Subscription cancellation aborted by user');
    }
  }

  // Crea un nuovo abbonamento (funzionalità non implementata)
  Future<void> _createNewSubscription() async {
    debugPrint('Creating new subscription');
    _showSnackBar('Funzionalità di creazione abbonamento non implementata.');
  }

  // Sincronizza l'abbonamento con Stripe
  Future<void> _syncStripeSubscription() async {
    debugPrint('Starting Stripe subscription synchronization');
    setState(() {
      _isSyncing = true;
    });

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('syncStripeSubscription');
      final result = await callable.call(<String, dynamic>{
        'syncAll': _isAdmin, // Passa true se è un admin per sincronizzare tutte le sottoscrizioni
      });

      if (result.data['success']) {
        debugPrint('Stripe subscription synchronization successful: ${result.data['message']}');
        _showSnackBar(result.data['message']);
        if (_isAdmin && _selectedUser != null) {
          await _fetchSubscriptionDetails(userId: _selectedUser!.id);
        } else {
          await _fetchSubscriptionDetails();
        }
      } else {
        debugPrint('Stripe subscription synchronization failed: ${result.data['message']}');
        _showSnackBar(result.data['message']);
      }
    } catch (e) {
      debugPrint('Error syncing Stripe subscription: $e');
      _showSnackBar('Errore nella sincronizzazione dell\'abbonamento.');
    } finally {
      setState(() {
        _isSyncing = false;
      });
      debugPrint('Finished Stripe subscription synchronization');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'Gestione Abbonamenti' : 'I Tuoi Abbonamenti'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isAdmin
                ? () {
                    debugPrint('Refresh button pressed (admin)');
                    if (_selectedUser != null) {
                      _fetchSubscriptionDetails(userId: _selectedUser!.id);
                    } else {
                      _fetchSubscriptionDetails();
                    }
                  }
                : () {
                    debugPrint('Refresh button pressed (user)');
                    _fetchSubscriptionDetails();
                  },
            tooltip: 'Ricarica',
          ),
        ],
      ),
      body: Column(
        children: [
          // Campo di ricerca per admin
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: UserTypeAheadField(
                controller: _userSearchController,
                focusNode: _userSearchFocusNode,
                onSelected: (UserModel user) {
                  debugPrint('Admin selected user: ${user.id}');
                  setState(() {
                    _selectedUser = user;
                  });
                  _fetchSubscriptionDetails(userId: user.id);
                },
                onChanged: (pattern) {
                  ref.read(userSearchQueryProvider.notifier).state = pattern;
                  debugPrint('Admin search query changed: $pattern');
                },
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _isAdmin
                    ? _buildAdminView()
                    : _buildUserView(),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _isSyncing ? null : _syncStripeSubscription,
              label: _isSyncing ? Text('Sincronizzazione...') : Text('Sincronizza Tutti'),
              icon: _isSyncing
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

  // Costruisce la vista per gli admin
  Widget _buildAdminView() {
    debugPrint('Building admin view');
    return _selectedUser == null
        ? Center(
            child: Text(
              'Seleziona un utente per visualizzare i suoi abbonamenti.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          )
        : _selectedUserSubscription == null
            ? Center(
                child: Text(
                  'L\'utente selezionato non ha abbonamenti attivi.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SubscriptionCard(
                      title: '${_selectedUser!.name}\'s Abbonamento',
                      status: _selectedUserSubscription!.status.capitalize(),
                      expiry: DateFormat.yMMMd().add_jm().format(_selectedUserSubscription!.currentPeriodEnd),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Dettagli Abbonamento',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Divider(),
                    ..._selectedUserSubscription!.items.map((item) {
                      return SubscriptionItemTile(item: item);
                    }),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSyncing ? null : _syncStripeSubscription,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: _isSyncing
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

  // Costruisce la vista per gli utenti normali
  Widget _buildUserView() {
    debugPrint('Building user view');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_subscriptionDetails == null)
            Center(
              child: Text(
                'Nessun abbonamento attivo.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            )
          else ...[
            SubscriptionCard(
              title: 'Il Tuo Abbonamento',
              status: _subscriptionDetails!.status.capitalize(),
              expiry: DateFormat.yMMMd().add_jm().format(_subscriptionDetails!.currentPeriodEnd),
              actionButton: ElevatedButton.icon(
                icon: Icon(Icons.manage_accounts),
                label: Text('Gestisci Abbonamento'),
                onPressed: _isManagingSubscription ? null : _showManageSubscriptionOptions,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Dettagli Abbonamento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Divider(),
            ..._subscriptionDetails!.items.map((item) {
              return SubscriptionItemTile(item: item);
            }),
          ],
          SizedBox(height: 24),
          if (_subscriptionDetails == null)
            ElevatedButton(
              onPressed: _createNewSubscription,
              child: Text('Abbonati Ora'),
            ),
          if (_subscriptionDetails != null) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSyncing ? null : _syncStripeSubscription,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isSyncing
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('Disposing SubscriptionsScreenState');
    _userSearchController.dispose();
    _userSearchFocusNode.dispose();
    super.dispose();
  }
}

// Widget riutilizzabile per visualizzare una card di abbonamento
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
