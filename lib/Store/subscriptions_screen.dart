// subscriptions_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:alphanessone/providers/auth_providers.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/providers/ui_settings_provider.dart';
import 'package:alphanessone/UI/components/app_card.dart';
import 'package:alphanessone/Store/in_app_purchase_model.dart';
import 'package:alphanessone/Store/in_app_purchase_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';

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
  final VoidCallback? onCancelSubscription;
  final bool showCancelButton;
  final bool glass;

  const SubscriptionCard({
    super.key,
    required this.title,
    required this.status,
    required this.expiry,
    this.isGift = false,
    this.giftInfo,
    this.onCancelSubscription,
    this.showCancelButton = false,
    this.glass = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      glass: glass,
      title: title,
      leadingIcon: isGift ? Icons.card_giftcard : Icons.subscriptions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Stato', status, Icons.info_outline),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Scadenza', expiry, Icons.event_outlined),
          if (giftInfo != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          if (showCancelButton &&
              onCancelSubscription != null &&
              !isGift &&
              status.toLowerCase() == 'active') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCancelConfirmationDialog(context),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Disdici Abbonamento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
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
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
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

  void _showCancelConfirmationDialog(BuildContext context) {
    showAppDialog(
      context: context,
      title: const Text('Conferma Disdetta'),
      child: const Text(
        'Sei sicuro di voler disdire l\'abbonamento? '
        'Potrai continuare ad utilizzare il servizio fino alla fine del periodo corrente.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancelSubscription?.call();
          },
          child: const Text('Disdici'),
        ),
      ],
    );
  }
}

// Reusable widget to display a subscription item
class SubscriptionItemTile extends StatelessWidget {
  final SubscriptionItem item;
  final bool glass;

  const SubscriptionItemTile({
    super.key,
    required this.item,
    this.glass = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      glass: glass,
      title: 'Prodotto: ${item.productId}',
      subtitle: 'ID Prezzo: ${item.priceId}',
      leadingIcon: Icons.shopping_bag_outlined,
      child: Align(
        alignment: Alignment.centerRight,
        child: Text('Quantità: ${item.quantity}'),
      ),
    );
  }
}

class SubscriptionsScreen extends ConsumerStatefulWidget {
  final String userId;

  const SubscriptionsScreen({super.key, required this.userId});

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
              'quantity': 1,
            },
          ],
        };

        final subscriptionDetails = SubscriptionDetails.fromJson(
          subscriptionData,
        );
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cancelSubscription() async {
    setState(() => _isLoading = true);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('cancelSubscription');

      final result = await callable.call({'userId': widget.userId});

      if (result.data['success'] == true) {
        _showSnackBar(result.data['message']);
        await _fetchSubscriptionDetails();
      } else {
        throw Exception(result.data['error'] ?? 'Errore sconosciuto');
      }
    } catch (e) {
      _showSnackBar('Errore nella disdetta dell\'abbonamento: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAdmin = ref.watch(isAdminProvider);
    final isOwnProfile =
        widget.userId == FirebaseAuth.instance.currentUser?.uid;
    final glassEnabled = ref.watch(uiGlassEnabledProvider);

    if (isAdmin && isOwnProfile) {
      return const Center(
        child: Text('Gli amministratori non necessitano di un abbonamento'),
      );
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    final subscription = ref.watch(selectedUserSubscriptionProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sezione pulsanti
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 500;
                final buttons = [
                  if (isAdmin && !isOwnProfile)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showGiftSubscriptionDialog(context),
                        icon: const Icon(Icons.card_giftcard),
                        label: const Text('Regala Abbonamento'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  if (isAdmin && !isOwnProfile && isWideScreen)
                    const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ref.watch(syncingProvider)
                          ? null
                          : _syncStripeSubscription,
                      icon: ref.watch(syncingProvider)
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.sync),
                      label: const Text('Sincronizza Abbonamento'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ];

                return isWideScreen
                    ? Row(children: buttons)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...buttons,
                          if (buttons.length > 1) const SizedBox(height: 12),
                        ],
                      );
              },
            ),
          ),

          // Contenuto abbonamento
          if (subscription == null) ...[
            AppCard(
              glass: glassEnabled,
              title: 'Abbonamento',
              leadingIcon: Icons.subscriptions_outlined,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nessun abbonamento attivo.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ),
          ] else ...[
            SubscriptionCard(
              title: 'Abbonamento',
              status: subscription.status.capitalize(),
              expiry: DateFormat.yMMMd().add_jm().format(
                subscription.currentPeriodEnd,
              ),
              isGift: subscription.platform == 'gift',
              giftInfo: subscription.platform == 'gift'
                  ? 'Abbonamento regalo'
                  : null,
              showCancelButton:
                  (isAdmin || isOwnProfile) &&
                  subscription.platform == 'stripe',
              onCancelSubscription: _cancelSubscription,
              glass: glassEnabled,
            ),
            const SizedBox(height: 16),
            AppCard(
              glass: glassEnabled,
              title: 'Dettagli Abbonamento',
              leadingIcon: Icons.receipt_long_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...subscription.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SubscriptionItemTile(
                        item: item,
                        glass: glassEnabled,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showGiftSubscriptionDialog(BuildContext context) {
    int selectedDays = 30;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AppDialog(
              title: const Text('Regala Abbonamento'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annulla'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _createGiftSubscription(selectedDays);
                  },
                  child: Text('Regala'),
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Seleziona la durata dell\'abbonamento:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedDays,
                    decoration: InputDecoration(
                      labelText: 'Durata',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 7, child: Text('7 giorni')),
                      DropdownMenuItem(value: 30, child: Text('30 giorni')),
                      DropdownMenuItem(value: 90, child: Text('90 giorni')),
                      DropdownMenuItem(value: 180, child: Text('180 giorni')),
                      DropdownMenuItem(value: 365, child: Text('365 giorni')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedDays = value);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createGiftSubscription(int durationInDays) async {
    setState(() => _isLoading = true);
    try {
      await _inAppPurchaseService.createGiftSubscription(
        widget.userId,
        durationInDays,
      );
      _showSnackBar('Abbonamento regalo creato con successo!');
      await _fetchSubscriptionDetails();
    } catch (e) {
      _showSnackBar('Errore nella creazione dell\'abbonamento regalo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
