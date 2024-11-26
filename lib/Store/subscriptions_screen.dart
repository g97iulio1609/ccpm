// subscriptions_screen.dart

import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/UI/components/user_autocomplete.dart';
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
import 'package:alphanessone/Main/app_theme.dart';

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
    //debugPrint('SubscriptionsScreen initState with userId: ${widget.userId}');
  }

  Future<void> _initializeScreen() async {
    //debugPrint('Initializing SubscriptionsScreen');
    await _checkIfAdmin();
    await _fetchSubscriptionDetails(
        userId: widget.userId); // Passa userId se disponibile
    if (ref.read(isAdminProvider) && widget.userId == null) {
      await _loadAllUsers();
    }
  }

  // Checks if the current user is an admin
  Future<void> _checkIfAdmin() async {
    //debugPrint('Checking if user is admin');
    final firebaseAuth = ref.read(firebaseAuthProvider);
    final firebaseFirestore = ref.read(firebaseFirestoreProvider);

    final user = firebaseAuth.currentUser;
    if (user != null) {
      final userDoc =
          await firebaseFirestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
        ref.read(isAdminProvider.notifier).state = true;
        //debugPrint('User is admin');
      } else {
        ref.read(isAdminProvider.notifier).state = false;
        //debugPrint('User is not admin');
      }
    } else {
      ref.read(isAdminProvider.notifier).state = false;
      //debugPrint('No authenticated user');
    }
  }

  // Loads all users if the current user is an admin and userId is not provided
  Future<void> _loadAllUsers() async {
    final isAdmin = ref.read(isAdminProvider);
    //debugPrint('Loading all users: isAdmin=$isAdmin');
    if (isAdmin) {
      try {
        final usersStream = ref.read(usersServiceProvider).getUsers();
        _userSubscription = usersStream.listen((users) {
          ref.read(userListProvider.notifier).state = users;
          ref.read(filteredUserListProvider.notifier).state = users;
          //debugPrint('Loaded ${users.length} users');
        });
      } catch (e) {
        _showSnackBar('Errore nel caricamento degli utenti.');
        //debugPrint('Error loading users: $e');
      }
    }
  }

  // Fetches subscription details for the given userId
  Future<void> _fetchSubscriptionDetails({String? userId}) async {
    ref.read(subscriptionLoadingProvider.notifier).state = true;
    //debugPrint('Fetching subscription details for userId: $userId');

    try {
      final isAdmin = ref.read(isAdminProvider);
      final targetUserId = userId ??
          (isAdmin
              ? ref.read(selectedUserIdProvider)
              : FirebaseAuth.instance.currentUser!.uid);
      //debugPrint('isAdmin: $isAdmin, targetUserId: $targetUserId');

      // Nel metodo _fetchSubscriptionDetails
      if (isAdmin && userId != null) {
        // Admin viewing another user's subscription
        //debugPrint('Admin viewing subscription for userId: $targetUserId');
        final details = await _inAppPurchaseService.getSubscriptionDetails(
            userId: targetUserId);
        ref.read(selectedUserSubscriptionProvider.notifier).state = details;
        //debugPrint('Fetched subscription details for userId: $targetUserId');

        // Imposta selectedUserIdProvider
        ref.read(selectedUserIdProvider.notifier).state = targetUserId;
        //debugPrint('selectedUserIdProvider set to: $targetUserId');
      } else {
        // Regular user viewing their own subscription
        //debugPrint('Regular user viewing own subscription');
        final details = await _inAppPurchaseService.getSubscriptionDetails();
        ref.read(subscriptionDetailsProvider.notifier).state = details;
        //debugPrint('Fetched own subscription details');
      }
    } catch (e) {
      _showSnackBar('Errore nel recuperare i dettagli dell\'abbonamento: $e');
      //debugPrint('Error fetching subscription details: $e');
    } finally {
      ref.read(subscriptionLoadingProvider.notifier).state = false;
      //debugPrint('Finished fetching subscription details');
    }
  }

  // Shows a SnackBar with a message
  void _showSnackBar(String message) {
    //debugPrint('SnackBar message: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Shows options to manage the subscription
  void _showManageSubscriptionOptions() {
    final subscriptionDetails = ref.read(subscriptionDetailsProvider);
    if (subscriptionDetails == null) {
      _showSnackBar('Nessun abbonamento attivo.');
      //debugPrint('No active subscription to manage');
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.update,
                    color: Theme.of(context).colorScheme.primary),
                title: Text('Aggiorna Piano'),
                onTap: () {
                  Navigator.pop(context);
                  _showUpdateSubscriptionDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel,
                    color: Theme.of(context).colorScheme.error),
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
    //debugPrint('Manage subscription options shown');
  }

  // Shows the dialog to update the subscription
  void _showUpdateSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedPriceId;
        final availableProducts = _inAppPurchaseService
            .productDetailsByProductId.values
            .expand((e) => e)
            .toList();
        //debugPrint('Available products for update: ${availableProducts.map((p) => p.id).toList()}');

        return AlertDialog(
          title: Text('Aggiorna Abbonamento'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButtonFormField<String>(
                items: availableProducts.map((product) {
                  return DropdownMenuItem<String>(
                    value: product.id,
                    child: Text(
                        '${product.title} - ${product.price} ${product.currencyCode}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPriceId = value;
                  });
                  //debugPrint('Selected new priceId: $value');
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
                //debugPrint('Update subscription dialog cancelled');
              },
            ),
            ElevatedButton(
              onPressed: selectedPriceId == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      ref.read(managingSubscriptionProvider.notifier).state =
                          true;
                      //debugPrint('Updating subscription to priceId: $selectedPriceId');
                      try {
                        await _inAppPurchaseService
                            .updateSubscription(selectedPriceId!);
                        _showSnackBar('Abbonamento aggiornato con successo.');
                        await _fetchSubscriptionDetails(
                            userId: ref.read(selectedUserIdProvider));
                        //debugPrint('Subscription updated and details refetched');
                      } catch (e) {
                        _showSnackBar(
                            'Errore nell\'aggiornamento dell\'abbonamento: $e');
                        //debugPrint('Error updating subscription: $e');
                      } finally {
                        ref.read(managingSubscriptionProvider.notifier).state =
                            false;
                      }
                    },
              child: Text('Aggiorna'),
            ),
          ],
        );
      },
    );
    //debugPrint('Update subscription dialog shown');
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
              //debugPrint('Subscription cancellation cancelled');
            },
          ),
          ElevatedButton(
            child: Text('Sì'),
            onPressed: () {
              Navigator.pop(context, true);
              //debugPrint('Subscription cancellation confirmed');
            },
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(managingSubscriptionProvider.notifier).state = true;
      //debugPrint('Cancelling subscription');
      try {
        await _inAppPurchaseService.cancelSubscription();
        _showSnackBar('Abbonamento annullato con successo.');
        await _fetchSubscriptionDetails(
            userId: ref.read(selectedUserIdProvider));
        //debugPrint('Subscription cancelled and details refetched');
      } catch (e) {
        _showSnackBar('Errore nell\'annullamento dell\'abbonamento: $e');
        //debugPrint('Error cancelling subscription: $e');
      } finally {
        ref.read(managingSubscriptionProvider.notifier).state = false;
      }
    } else {
      //debugPrint('Subscription cancellation not confirmed');
      // Do nothing if the user cancels
    }
  }

  // Creates a new subscription (functionality not implemented)
  Future<void> _createNewSubscription() async {
    // Use context.push to navigate to the '/subscriptions' route
    await context.push('/subscriptions');
    //debugPrint('Navigated to /subscriptions to create a new subscription');

    // Refresh the subscription details after returning from the purchase page
    await _fetchSubscriptionDetails();
    //debugPrint('Subscription details refreshed after creating new subscription');
  }

  // Synchronizes the subscription with Stripe
  Future<void> _syncStripeSubscription() async {
    ref.read(syncingProvider.notifier).state = true;
    //debugPrint('Synchronizing subscription with Stripe');

    try {
      final firebaseFunctions = ref.read(firebaseFunctionsProvider);
      final HttpsCallable callable =
          firebaseFunctions.httpsCallable('syncStripeSubscription');
      final result = await callable.call(<String, dynamic>{
        'syncAll': ref.read(
            isAdminProvider), // Passa true se admin per sincronizzare tutte le sottoscrizioni
      });

      if (result.data['success']) {
        _showSnackBar(result.data['message']);
        //debugPrint('Stripe synchronization successful: ${result.data['message']}');
        if (ref.read(isAdminProvider) &&
            ref.read(selectedUserIdProvider) != null) {
          await _fetchSubscriptionDetails(
              userId: ref.read(selectedUserIdProvider));
        } else {
          await _fetchSubscriptionDetails();
        }
      } else {
        _showSnackBar(result.data['message']);
        //debugPrint('Stripe synchronization failed: ${result.data['message']}');
      }
    } catch (e) {
      _showSnackBar('Errore nella sincronizzazione dell\'abbonamento.');
      //debugPrint('Error synchronizing with Stripe: $e');
    } finally {
      ref.read(syncingProvider.notifier).state = false;
      //debugPrint('Stripe synchronization completed');
    }
  }

  Future<void> _showGiftSubscriptionDialog(
      String userId, String userName) async {
    final durationOptions = [
      {'days': 7, 'label': '1 Settimana', 'icon': Icons.calendar_today},
      {'days': 30, 'label': '1 Mese', 'icon': Icons.calendar_month},
      {'days': 90, 'label': '3 Mesi', 'icon': Icons.calendar_today},
      {'days': 180, 'label': '6 Mesi', 'icon': Icons.calendar_view_month},
      {'days': 365, 'label': '1 Anno', 'icon': Icons.calendar_today},
    ];

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Regalo Abbonamento',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Seleziona la durata dell\'abbonamento da regalare a $userName:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ...durationOptions.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        try {
                          await _inAppPurchaseService.giftSubscription(
                            userId,
                            option['days'] as int,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Abbonamento regalato con successo'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            await _fetchSubscriptionDetails(userId: userId);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Errore: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(option['icon'] as IconData),
                              const SizedBox(width: 12),
                              Text(option['label'] as String),
                            ],
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annulla'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isAdmin = ref.watch(isAdminProvider);
    final allUsers = ref.watch(userListProvider);
    ref.watch(filteredUserListProvider);
    final selectedUserId = ref.watch(selectedUserIdProvider);
    final subscriptionDetails = ref.watch(subscriptionDetailsProvider);
    final selectedUserSubscription =
        ref.watch(selectedUserSubscriptionProvider);
    final isLoading = ref.watch(subscriptionLoadingProvider);
    ref.watch(managingSubscriptionProvider);
    final isSyncing = ref.watch(syncingProvider);

    //debugPrint('Building SubscriptionsScreen: isAdmin=$isAdmin, selectedUserId=$selectedUserId, isLoading=$isLoading');

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
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar per Admin
              if (isAdmin && widget.userId == null)
                Padding(
                  padding: EdgeInsets.all(AppTheme.spacing.xl),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                      boxShadow: AppTheme.elevations.small,
                    ),
                    padding: EdgeInsets.all(AppTheme.spacing.md),
                    child: UserTypeAheadField(
                      controller: _userSearchController,
                      focusNode: _userSearchFocusNode,
                      onSelected: (UserModel user) {
                        _userSearchController.text = user.name;
                        ref.read(selectedUserIdProvider.notifier).state =
                            user.id;
                        _fetchSubscriptionDetails(userId: user.id);
                        FocusScope.of(context).unfocus();
                        //debugPrint('Selected user for subscription viewing: ${user.id}');
                      },
                      onChanged: (pattern) {
                        final filtered = allUsers
                            .where((user) =>
                                user.name
                                    .toLowerCase()
                                    .contains(pattern.toLowerCase()) ||
                                user.email
                                    .toLowerCase()
                                    .contains(pattern.toLowerCase()))
                            .toList();
                        ref.read(filteredUserListProvider.notifier).state =
                            filtered;
                        //debugPrint('Filtered users based on search pattern: $pattern');
                      },
                    ),
                  ),
                ),

              // Contenuto principale
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : isAdmin &&
                            (widget.userId != null || selectedUserId != null)
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
        ),
      ),
      floatingActionButton: isAdmin && widget.userId == null
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radii.full),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: isSyncing ? null : _syncStripeSubscription,
                label: Text(
                  isSyncing ? 'Sincronizzazione...' : 'Sincronizza Tutti',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: isSyncing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.sync, color: colorScheme.onPrimary),
              ),
            )
          : null,
    );
  }

  // Builds the admin view (with selectedUserId)
  Widget _buildAdminView({
    required String userId,
    required SubscriptionDetails? subscriptionDetails,
  }) {
    return Builder(builder: (context) {
      //debugPrint('Building admin view: userId=$userId');

      final usersService = ref.read(usersServiceProvider);
      final Future<UserModel?> userFuture = usersService.getUserById(userId);

      return FutureBuilder<UserModel?>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text('Utente non trovato.',
                  style: Theme.of(context).textTheme.titleLarge),
            );
          }

          final user = snapshot.data!;
          final bool isGiftSubscription =
              subscriptionDetails?.platform == 'gift';

          return SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.card_giftcard,
                        label: 'Regala Abbonamento',
                        onTap: () =>
                            _showGiftSubscriptionDialog(userId, user.name),
                        isPrimary: true,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.md),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.sync,
                        label: 'Sincronizza',
                        onTap: ref.watch(syncingProvider)
                            ? null
                            : _syncStripeSubscription,
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacing.xl),

                // Subscription Details
                if (subscriptionDetails != null) ...[
                  SubscriptionCard(
                    title: '${user.name}\'s Abbonamento',
                    status: subscriptionDetails.status.capitalize(),
                    expiry: DateFormat.yMMMd()
                        .add_jm()
                        .format(subscriptionDetails.currentPeriodEnd),
                    isGift: isGiftSubscription,
                    giftInfo: isGiftSubscription ? 'Abbonamento regalo' : null,
                  ),
                  SizedBox(height: AppTheme.spacing.xl),
                  Text(
                    'Dettagli Abbonamento',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Divider(),
                  ...subscriptionDetails.items.map((item) {
                    return SubscriptionItemTile(item: item);
                  }),
                ] else ...[
                  Center(
                    child: Text(
                      'L\'utente non ha un abbonamento attivo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isPrimary,
  }) {
    return Builder(builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPrimary
                ? [colorScheme.primary, colorScheme.primary.withOpacity(0.8)]
                : [
                    colorScheme.secondary,
                    colorScheme.secondary.withOpacity(0.8)
                  ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          boxShadow: AppTheme.elevations.small,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: AppTheme.spacing.lg,
                horizontal: AppTheme.spacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                  SizedBox(width: AppTheme.spacing.sm),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // Builds the user view (own subscription)
  Widget _buildUserView({
    required SubscriptionDetails? subscriptionDetails,
  }) {
    //debugPrint('Building user view: subscriptionDetails=${subscriptionDetails != null}');

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
            expiry: DateFormat.yMMMd()
                .add_jm()
                .format(subscriptionDetails.currentPeriodEnd),
            actionButton: ElevatedButton.icon(
              icon: Icon(Icons.manage_accounts),
              label: Text('Gestisci Abbonamento'),
              onPressed: ref.read(managingSubscriptionProvider)
                  ? null
                  : _showManageSubscriptionOptions,
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
            onPressed:
                ref.watch(syncingProvider) ? null : _syncStripeSubscription,
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
    //debugPrint('Disposed SubscriptionsScreenState');
    super.dispose();
  }
}

// Reusable widget to display a subscription card
class SubscriptionCard extends StatelessWidget {
  final String title;
  final String status;
  final String expiry;
  final Widget? actionButton;
  final bool isGift;
  final String? giftInfo;

  const SubscriptionCard({
    super.key,
    required this.title,
    required this.status,
    required this.expiry,
    this.actionButton,
    this.isGift = false,
    this.giftInfo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isGift)
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacing.sm),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radii.full),
                    ),
                    child: Icon(
                      Icons.card_giftcard,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                if (isGift) SizedBox(width: AppTheme.spacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing.md),
            _buildInfoRow(
              context,
              'Stato',
              status,
              Icons.info_outline,
            ),
            SizedBox(height: AppTheme.spacing.sm),
            _buildInfoRow(
              context,
              'Scadenza',
              expiry,
              Icons.event_outlined,
            ),
            if (giftInfo != null) ...[
              SizedBox(height: AppTheme.spacing.md),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing.md,
                  vertical: AppTheme.spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                ),
                child: Text(
                  giftInfo!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
            if (actionButton != null && !isGift) ...[
              SizedBox(height: AppTheme.spacing.lg),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: AppTheme.spacing.sm),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

// Reusable widget to display a subscription item
class SubscriptionItemTile extends StatelessWidget {
  final SubscriptionItem item;

  const SubscriptionItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    //debugPrint('Building SubscriptionItemTile for productId: ${item.productId}');
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
