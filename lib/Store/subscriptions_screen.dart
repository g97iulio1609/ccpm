// subscriptions_screen.dart

import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/UI/components/user_autocomplete.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Store/in_app_purchase_services.dart';
import 'package:alphanessone/Store/in_app_purchase_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Extension to capitalize strings
extension StringCasingExtension on String {
  String capitalize() {
    if (length <= 1) return toUpperCase();
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

// Reusable widget to display a subscription card
class SubscriptionCard extends StatelessWidget {
  final String title;
  final String status;
  final String expiry;
  final bool isGift;
  final String? giftInfo;

  const SubscriptionCard({
    super.key,
    required this.title,
    required this.status,
    required this.expiry,
    this.isGift = false,
    this.giftInfo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withAlpha(26),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isGift)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(76),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.card_giftcard,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                if (isGift) const SizedBox(width: 8),
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
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              'Stato',
              status,
              Icons.info_outline,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'Scadenza',
              expiry,
              Icons.event_outlined,
            ),
            if (giftInfo != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(76),
                  borderRadius: BorderRadius.circular(8),
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
        const SizedBox(width: 8),
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
    return ListTile(
      title: Text('Prodotto: ${item.productId}'),
      subtitle: Text('ID Prezzo: ${item.priceId}'),
      trailing: Text('Quantità: ${item.quantity}'),
    );
  }
}

class SubscriptionsScreen extends ConsumerStatefulWidget {
  final String userId;

  const SubscriptionsScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  final InAppPurchaseService _inAppPurchaseService = InAppPurchaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSubscriptionDetails();
      ref.listenManual(selectedUserSubscriptionProvider, (previous, next) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void didUpdateWidget(SubscriptionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _fetchSubscriptionDetails();
    }
  }

  Future<void> _fetchSubscriptionDetails({String? userId}) async {
    setState(() => _isLoading = true);
    try {
      final targetUserId = userId ?? widget.userId;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .get();

      if (!userDoc.exists) {
        throw Exception('Utente non trovato');
      }

      final userData = userDoc.data()!;
      final subscriptionStatus = userData['subscriptionStatus'];
      final subscriptionEndDate = userData['subscriptionExpiryDate'];
      final subscriptionType = userData['subscriptionProductId'];
      final subscriptionId = userData['subscriptionId'];
      final subscriptionPlatform = userData['subscriptionPlatform'];

      if (subscriptionStatus == 'active' && subscriptionEndDate != null) {
        final subscriptionData = {
          'id': subscriptionId ?? '',
          'status': subscriptionStatus,
          'currentPeriodEnd': (subscriptionEndDate as Timestamp).toDate(),
          'platform': subscriptionPlatform ?? 'stripe',
          'items': [
            {
              'productId': subscriptionType ?? 'standard',
              'priceId': subscriptionId ?? '',
              'quantity': 1
            }
          ]
        };

        final subscriptionDetails =
            SubscriptionDetails.fromJson(subscriptionData);
        ref.read(selectedUserSubscriptionProvider.notifier).state =
            subscriptionDetails;
        return;
      }

      final details = await _inAppPurchaseService.getSubscriptionDetails(
        userId: targetUserId,
      );

      ref.read(selectedUserSubscriptionProvider.notifier).state = details;
    } catch (e) {
      ref.read(selectedUserSubscriptionProvider.notifier).state = null;
      _showSnackBar('Impossibile recuperare i dettagli dell\'abbonamento');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Sincronizza la sottoscrizione con Stripe
  Future<void> _syncStripeSubscription() async {
    ref.read(syncingProvider.notifier).state = true;

    try {
      final result = await _inAppPurchaseService.syncStripeSubscription(
        widget.userId,
        syncAll: ref.read(isAdminProvider),
      );

      if (result['success']) {
        _showSnackBar(result['message']);
        await _fetchSubscriptionDetails();
      } else {
        _showSnackBar(result['message']);
      }
    } catch (e) {
      _showSnackBar('Errore nella sincronizzazione dell\'abbonamento.');
    } finally {
      ref.read(syncingProvider.notifier).state = false;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = ref.watch(isAdminProvider);

    if (isAdmin) {
      return const Center(
        child: Text('Gli amministratori non necessitano di un abbonamento'),
      );
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
      );
    }

    final subscription = ref.watch(selectedUserSubscriptionProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subscription == null) ...[
            Center(
              child: Text(
                'Nessun abbonamento attivo.',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ] else ...[
            SubscriptionCard(
              title: 'Abbonamento',
              status: subscription.status.capitalize(),
              expiry: DateFormat.yMMMd()
                  .add_jm()
                  .format(subscription.currentPeriodEnd),
              isGift: subscription.platform == 'gift',
              giftInfo:
                  subscription.platform == 'gift' ? 'Abbonamento regalo' : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Dettagli Abbonamento',
              style: theme.textTheme.titleLarge,
            ),
            const Divider(),
            ...subscription.items.map((item) {
              return SubscriptionItemTile(item: item);
            }),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed:
                ref.watch(syncingProvider) ? null : _syncStripeSubscription,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: ref.watch(syncingProvider)
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Text('Sincronizza Abbonamento'),
          ),
        ],
      ),
    );
  }
}
