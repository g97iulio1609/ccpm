// subscriptions_screen.dart

import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/user_autocomplete.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Store/inAppPurchase_services.dart';
import 'package:alphanessone/Store/inAppPurchase_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  final String? userId; // Optional userId parameter

  const SubscriptionsScreen({super.key, this.userId}); // Modified constructor

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
    debugPrint('SubscriptionsScreen initState with userId: ${widget.userId}');
  }

  Future<void> _initializeScreen() async {
    debugPrint('Initializing SubscriptionsScreen');
    await _checkIfAdmin();
    await _fetchSubscriptionDetails(userId: widget.userId); // Passa userId se disponibile
    if (ref.read(isAdminProvider) && widget.userId == null) {
      await _loadAllUsers();
    }
  }

  // Checks if the current user is an admin
  Future<void> _checkIfAdmin() async {
    debugPrint('Checking if user is admin');
    final firebaseAuth = ref.read(firebaseAuthProvider);
    final firebaseFirestore = ref.read(firebaseFirestoreProvider);

    final user = firebaseAuth.currentUser;
    if (user != null) {
      final userDoc = await firebaseFirestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
        ref.read(isAdminProvider.notifier).state = true;
        debugPrint('User is admin');
      } else {
        ref.read(isAdminProvider.notifier).state = false;
        debugPrint('User is not admin');
      }
    } else {
      ref.read(isAdminProvider.notifier).state = false;
      debugPrint('No authenticated user');
    }
  }

  // Loads all users if the current user is an admin and userId is not provided
  Future<void> _loadAllUsers() async {
    final isAdmin = ref.read(isAdminProvider);
    debugPrint('Loading all users: isAdmin=$isAdmin');
    if (isAdmin) {
      try {
        final usersStream = ref.read(usersServiceProvider).getUsers();
        _userSubscription = usersStream.listen((users) {
          ref.read(userListProvider.notifier).state = users;
          ref.read(filteredUserListProvider.notifier).state = users;
          debugPrint('Loaded ${users.length} users');
        });
      } catch (e) {
        _showSnackBar('Errore nel caricamento degli utenti.');
        debugPrint('Error loading users: $e');
      }
    }
  }

  // Fetches subscription details for the given userId
  Future<void> _fetchSubscriptionDetails({String? userId}) async {
    ref.read(subscriptionLoadingProvider.notifier).state = true;
    debugPrint('Fetching subscription details for userId: $userId');

    try {
      final isAdmin = ref.read(isAdminProvider);
      final targetUserId = userId ??
          (isAdmin ? ref.read(selectedUserIdProvider) : FirebaseAuth.instance.currentUser!.uid);
      debugPrint('isAdmin: $isAdmin, targetUserId: $targetUserId');

  // Nel metodo _fetchSubscriptionDetails
if (isAdmin && userId != null) {
  // Admin viewing another user's subscription
  debugPrint('Admin viewing subscription for userId: $targetUserId');
  final details = await _inAppPurchaseService.getSubscriptionDetails(userId: targetUserId);
  ref.read(selectedUserSubscriptionProvider.notifier).state = details;
  debugPrint('Fetched subscription details for userId: $targetUserId');
  
  // Imposta selectedUserIdProvider
  ref.read(selectedUserIdProvider.notifier).state = targetUserId;
  debugPrint('selectedUserIdProvider set to: $targetUserId');
}
 else {
        // Regular user viewing their own subscription
        debugPrint('Regular user viewing own subscription');
        final details = await _inAppPurchaseService.getSubscriptionDetails();
        ref.read(subscriptionDetailsProvider.notifier).state = details;
        debugPrint('Fetched own subscription details');
      }
    } catch (e) {
      _showSnackBar('Errore nel recuperare i dettagli dell\'abbonamento: $e');
      debugPrint('Error fetching subscription details: $e');
    } finally {
      ref.read(subscriptionLoadingProvider.notifier).state = false;
      debugPrint('Finished fetching subscription details');
    }
  }

  // Shows a SnackBar with a message
  void _showSnackBar(String message) {
    debugPrint('SnackBar message: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Shows options to manage the subscription
  void _showManageSubscriptionOptions() {
    final subscriptionDetails = ref.read(subscriptionDetailsProvider);
    if (subscriptionDetails == null) {
      _showSnackBar('Nessun abbonamento attivo.');
      debugPrint('No active subscription to manage');
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
    debugPrint('Manage subscription options shown');
  }

  // Shows the dialog to update the subscription
  void _showUpdateSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedPriceId;
        final availableProducts = _inAppPurchaseService.productDetailsByProductId.values.expand((e) => e).toList();
        debugPrint('Available products for update: ${availableProducts.map((p) => p.id).toList()}');

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
                  debugPrint('Selected new priceId: $value');
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
                debugPrint('Update subscription dialog cancelled');
              },
            ),
            ElevatedButton(
              onPressed: selectedPriceId == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      ref.read(managingSubscriptionProvider.notifier).state = true;
                      debugPrint('Updating subscription to priceId: $selectedPriceId');
                      try {
                        await _inAppPurchaseService.updateSubscription(selectedPriceId!);
                        _showSnackBar('Abbonamento aggiornato con successo.');
                        await _fetchSubscriptionDetails(userId: ref.read(selectedUserIdProvider));
                        debugPrint('Subscription updated and details refetched');
                      } catch (e) {
                        _showSnackBar('Errore nell\'aggiornamento dell\'abbonamento: $e');
                        debugPrint('Error updating subscription: $e');
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
    debugPrint('Update subscription dialog shown');
  }

  // Confirms the cancellation of the subscription
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
              debugPrint('Subscription cancellation cancelled');
            },
          ),
          ElevatedButton(
            child: Text('Sì'),
            onPressed: () {
              Navigator.pop(context, true);
              debugPrint('Subscription cancellation confirmed');
            },
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(managingSubscriptionProvider.notifier).state = true;
      debugPrint('Cancelling subscription');
      try {
        await _inAppPurchaseService.cancelSubscription();
        _showSnackBar('Abbonamento annullato con successo.');
        await _fetchSubscriptionDetails(userId: ref.read(selectedUserIdProvider));
        debugPrint('Subscription cancelled and details refetched');
      } catch (e) {
        _showSnackBar('Errore nell\'annullamento dell\'abbonamento: $e');
        debugPrint('Error cancelling subscription: $e');
      } finally {
        ref.read(managingSubscriptionProvider.notifier).state = false;
      }
    } else {
      debugPrint('Subscription cancellation not confirmed');
      // Do nothing if the user cancels
    }
  }

  // Creates a new subscription (functionality not implemented)
  Future<void> _createNewSubscription() async {
    // Use context.push to navigate to the '/subscriptions' route
    await context.push('/subscriptions');
    debugPrint('Navigated to /subscriptions to create a new subscription');

    // Refresh the subscription details after returning from the purchase page
    await _fetchSubscriptionDetails();
    debugPrint('Subscription details refreshed after creating new subscription');
  }

  // Synchronizes the subscription with Stripe
  Future<void> _syncStripeSubscription() async {
    ref.read(syncingProvider.notifier).state = true;
    debugPrint('Synchronizing subscription with Stripe');

    try {
      final firebaseFunctions = ref.read(firebaseFunctionsProvider);
      final HttpsCallable callable = firebaseFunctions.httpsCallable('syncStripeSubscription');
      final result = await callable.call(<String, dynamic>{
        'syncAll': ref.read(isAdminProvider), // Passa true se admin per sincronizzare tutte le sottoscrizioni
      });

      if (result.data['success']) {
        _showSnackBar(result.data['message']);
        debugPrint('Stripe synchronization successful: ${result.data['message']}');
        if (ref.read(isAdminProvider) && ref.read(selectedUserIdProvider) != null) {
          await _fetchSubscriptionDetails(userId: ref.read(selectedUserIdProvider));
        } else {
          await _fetchSubscriptionDetails();
        }
      } else {
        _showSnackBar(result.data['message']);
        debugPrint('Stripe synchronization failed: ${result.data['message']}');
      }
    } catch (e) {
      _showSnackBar('Errore nella sincronizzazione dell\'abbonamento.');
      debugPrint('Error synchronizing with Stripe: $e');
    } finally {
      ref.read(syncingProvider.notifier).state = false;
      debugPrint('Stripe synchronization completed');
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

  debugPrint('Building SubscriptionsScreen: isAdmin=$isAdmin, selectedUserId=$selectedUserId, isLoading=$isLoading');

  // Determina quale subscriptionDetails usare
  final SubscriptionDetails? targetSubscriptionDetails;
  if (isAdmin && widget.userId != null) {
    targetSubscriptionDetails = selectedUserSubscription;
  } else if (isAdmin && selectedUserId != null) {
    targetSubscriptionDetails = selectedUserSubscription;
  } else {
    targetSubscriptionDetails = subscriptionDetails;
  }

  return Scaffold(
    body: Column(
      children: [
        // User search field for admin only if userId is not provided
        if (isAdmin && widget.userId == null)
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
                debugPrint('Selected user for subscription viewing: ${user.id}');
              },
              onChanged: (pattern) {
                final filtered = allUsers.where((user) =>
                    user.name.toLowerCase().contains(pattern.toLowerCase()) ||
                    user.email.toLowerCase().contains(pattern.toLowerCase())).toList();
                ref.read(filteredUserListProvider.notifier).state = filtered;
                debugPrint('Filtered users based on search pattern: $pattern');
              },
            ),
          ),
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : isAdmin && (widget.userId != null || selectedUserId != null)
                  ? _buildAdminView(
                      userId: widget.userId ?? selectedUserId!,
                      subscriptionDetails: targetSubscriptionDetails,
                    )
                  : _buildUserView(
                      subscriptionDetails: targetSubscriptionDetails,
                    ),
        ),
      ],
    ),
    floatingActionButton: isAdmin && widget.userId == null
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


  // Builds the admin view (with selectedUserId)
Widget _buildAdminView({
  required String userId,
  required SubscriptionDetails? subscriptionDetails,
}) {
  debugPrint('Building admin view: userId=$userId');

  if (subscriptionDetails == null) {
    return Center(
      child: Text(
        'L\'utente selezionato non ha abbonamenti attivi.',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  final usersService = ref.read(usersServiceProvider);
  final Future<UserModel?> userFuture = usersService.getUserById(userId);

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
              status: subscriptionDetails.status.capitalize(),
              expiry: DateFormat.yMMMd().add_jm().format(subscriptionDetails.currentPeriodEnd),
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
    },
  );
}

  // Builds the user view (own subscription)
  Widget _buildUserView({
    required SubscriptionDetails? subscriptionDetails,
  }) {
    debugPrint('Building user view: subscriptionDetails=${subscriptionDetails != null}');

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
    _userSubscription?.cancel(); // Cancels the user stream subscription
    debugPrint('Disposed SubscriptionsScreenState');
    super.dispose();
  }
}

// Reusable widget to display a subscription card
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
    debugPrint('Building SubscriptionCard: $title, status: $status, expiry: $expiry');
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

// Reusable widget to display a subscription item
class SubscriptionItemTile extends StatelessWidget {
  final SubscriptionItem item;

  const SubscriptionItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building SubscriptionItemTile for productId: ${item.productId}');
    return ListTile(
      title: Text('Prodotto: ${item.productId}'),
      subtitle: Text('ID Prezzo: ${item.priceId}'),
      trailing: Text('Quantità: ${item.quantity}'),
    );
  }
}

// Extension to capitalize strings
extension StringCasingExtension on String {
  String capitalize() {
    if (length <= 1) return toUpperCase();
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
