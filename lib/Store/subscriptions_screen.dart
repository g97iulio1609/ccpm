// lib/screens/subscriptions_screen.dart

import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/user_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Store/inAppPurchase_services.dart';
import 'package:alphanessone/Store/inAppPurchase_model.dart';
import 'package:alphanessone/utils/debug_logger.dart';
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

  // Variables for admin
  bool _isAdmin = false;
  UserModel? _selectedUser;
  SubscriptionDetails? _selectedUserSubscription;
  final TextEditingController _userSearchController = TextEditingController();
  final FocusNode _userSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    debugPrint('initState: Initializing SubscriptionsScreen');
    _checkIfAdmin();
    _fetchSubscriptionDetails(); // For normal users
  }

  // Function to check if the current user is admin
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

  Future<void> _fetchSubscriptionDetails() async {
    debugPrint('Fetching subscription details for current user');
    setState(() {
      _isLoading = true;
    });

    try {
      final details = await _inAppPurchaseService.getSubscriptionDetails();
      setState(() {
        _subscriptionDetails = details;
      });
      debugPrint('Subscription details retrieved successfully.');
    } catch (e) {
      debugPrint('Error retrieving subscription details: $e');
      _showSnackBar('Error retrieving subscription details.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to retrieve subscriptions for a specific user (admin)
  Future<void> _fetchUserSubscription(String userId) async {
    debugPrint('Fetching subscription details for user ID: $userId');
    setState(() {
      _isLoading = true;
      _selectedUserSubscription = null;
    });

    try {
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
        _showSnackBar('The selected user has no active subscriptions.');
        debugPrint('The selected user has no active subscriptions.');
      }
    } catch (e) {
      debugPrint('Error retrieving user subscription details: $e');
      _showSnackBar('Error retrieving user subscription details.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    debugPrint('Showing SnackBar with message: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showManageSubscriptionOptions() {
    debugPrint('Showing manage subscription options');
    if (_subscriptionDetails == null) {
      _showSnackBar('No active subscription.');
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Manage Subscription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ListTile(
                leading: Icon(Icons.update),
                title: Text('Update Plan'),
                onTap: () {
                  debugPrint('Update Plan tapped');
                  Navigator.pop(context);
                  _showUpdateSubscriptionDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel),
                title: Text('Cancel Subscription', style: TextStyle(color: Colors.red)),
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

  void _showUpdateSubscriptionDialog() {
    debugPrint('Showing update subscription dialog');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedPriceId;
        List<ProductDetails> availableProducts = _inAppPurchaseService.productDetailsByProductId.values.expand((e) => e).toList();

        return AlertDialog(
          title: Text('Update Subscription'),
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
              labelText: 'Select New Plan',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
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
                        _showSnackBar('Subscription updated successfully.');
                        await _fetchSubscriptionDetails();
                        debugPrint('Subscription updated successfully for user');
                      } catch (e) {
                        debugPrint('Error updating subscription: $e');
                        _showSnackBar('Error updating subscription: $e');
                      } finally {
                        setState(() {
                          _isManagingSubscription = false;
                        });
                      }
                    },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmCancelSubscription() async {
    debugPrint('Confirming subscription cancellation');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Subscription'),
        content: Text('Are you sure you want to cancel your subscription?'),
        actions: [
          TextButton(
            child: Text('No'),
            onPressed: () {
              debugPrint('User chose not to cancel subscription');
              Navigator.pop(context, false);
            },
          ),
          ElevatedButton(
            child: Text('Yes'),
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
        _showSnackBar('Subscription cancelled successfully.');
        debugPrint('Subscription cancelled successfully');
        await _fetchSubscriptionDetails();
      } catch (e) {
        debugPrint('Error cancelling subscription: $e');
        _showSnackBar('Error cancelling subscription: $e');
      } finally {
        setState(() {
          _isManagingSubscription = false;
        });
      }
    } else {
      debugPrint('Subscription cancellation aborted by user');
    }
  }

  Future<void> _createNewSubscription() async {
    debugPrint('Creating new subscription');
    // Implement the logic to create a new subscription
    _showSnackBar('Subscription creation functionality not implemented.');
  }

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
        if (_isAdmin) {
          if (_selectedUser != null) {
            await _fetchUserSubscription(_selectedUser!.id);
          } else {
            await _fetchSubscriptionDetails();
          }
        } else {
          await _fetchSubscriptionDetails();
        }
      } else {
        debugPrint('Stripe subscription synchronization failed: ${result.data['message']}');
        _showSnackBar(result.data['message']);
      }
    } catch (e) {
      debugPrint('Error syncing Stripe subscription: $e');
      _showSnackBar('Error syncing subscription.');
    } finally {
      setState(() {
        _isSyncing = false;
      });
      debugPrint('Finished Stripe subscription synchronization');
    }
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat.simpleCurrency();

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
                      _fetchUserSubscription(_selectedUser!.id);
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
          // Se l'utente è admin, mostra il campo di ricerca
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
                  _fetchUserSubscription(user.id);
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
              label: _isSyncing ? Text('Syncing...') : Text('Sync All'),
              icon: _isSyncing ? CircularProgressIndicator(color: Colors.white) : Icon(Icons.sync),
            )
          : null,
    );
  }

  Widget _buildAdminView() {
    debugPrint('Building admin view');
    return _selectedUser == null
        ? Center(
            child: Text(
              'Select a user to view their subscriptions.',
              style: TextStyle(fontSize: 18),
            ),
          )
        : _selectedUserSubscription == null
            ? Center(
                child: Text(
                  'The selected user has no active subscriptions.',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: Colors.green.shade50,
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_selectedUser!.name}\'s Subscription',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text('Status: ${_selectedUserSubscription!.status.capitalize()}'),
                            SizedBox(height: 4),
                            Text(
                              'Expiry: ${DateFormat.yMMMd().add_jm().format(_selectedUserSubscription!.currentPeriodEnd)}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Subscription Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Divider(),
                    ..._selectedUserSubscription!.items.map((item) {
                      return ListTile(
                        title: Text('Product: ${item.productId}'),
                        subtitle: Text('Price ID: ${item.priceId}'),
                        trailing: Text('Quantity: ${item.quantity}'),
                      );
                    }),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSyncing ? null : _syncStripeSubscription,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                      child: _isSyncing
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Sync Stripe Subscription'),
                    ),
                  ],
                ),
              );
  }

  Widget _buildUserView() {
    debugPrint('Building user view');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_subscriptionDetails == null)
            Text('No active subscription.', style: TextStyle(fontSize: 18))
          else ...[
            Card(
              color: Colors.blue.shade50,
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Subscription',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Status: ${_subscriptionDetails!.status.capitalize()}'),
                    SizedBox(height: 4),
                    Text(
                      'Expiry: ${DateFormat.yMMMd().add_jm().format(_subscriptionDetails!.currentPeriodEnd)}',
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.manage_accounts),
                      label: Text('Manage Subscription'),
                      onPressed: _isManagingSubscription ? null : _showManageSubscriptionOptions,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Subscription Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(),
            ..._subscriptionDetails!.items.map((item) {
              return ListTile(
                title: Text('Product: ${item.productId}'),
                subtitle: Text('Price ID: ${item.priceId}'),
                trailing: Text('Quantity: ${item.quantity}'),
              );
            }),
          ],
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _subscriptionDetails == null ? _createNewSubscription : null,
            child: Text('Subscribe Now'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSyncing ? null : _syncStripeSubscription,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: TextStyle(fontSize: 16),
            ),
            child: _isSyncing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Sync Stripe Subscription'),
          ),
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

extension StringCasingExtension on String {
  String capitalize() {
    if (length <= 1) return toUpperCase();
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
