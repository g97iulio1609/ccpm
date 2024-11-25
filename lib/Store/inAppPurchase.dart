// lib/Store/inAppPurchase.dart

import 'package:alphanessone/Store/inAppPurchase_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'inAppPurchase_model.dart';
import '../utils/debug_logger.dart';

class InAppSubscriptionsPage extends ConsumerStatefulWidget {
  const InAppSubscriptionsPage({super.key});

  @override
  InAppSubscriptionsPageState createState() => InAppSubscriptionsPageState();
}

class InAppSubscriptionsPageState extends ConsumerState<InAppSubscriptionsPage> {
  late final InAppPurchaseService _inAppPurchaseService;
  bool _loading = true;
  final TextEditingController _promoCodeController = TextEditingController();
  String? _promoCodeError;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    debugLog('InAppSubscriptionsPage: initState called');
    ref.read(usersServiceProvider);
    _inAppPurchaseService = InAppPurchaseService();
    _inAppPurchaseService.setContext(context);
    _initialize();
    _checkAdminStatus();
  }

  Future<void> _initialize() async {
    debugLog('Initializing store info...');
    try {
      await _inAppPurchaseService.initStoreInfo();
      debugLog('Store info initialized successfully');
    } catch (e) {
      debugLog("Error during initialization: $e");
      _showSnackBar('Errore durante l\'inizializzazione dello store: $e');
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
      debugLog('Loading state set to false');
    }
  }

  Future<void> _checkAdminStatus() async {
    debugLog('Checking admin status...');
    final userRole = ref.read(usersServiceProvider).getCurrentUserRole();
    setState(() {
      _isAdmin = userRole == 'admin';
    });
    debugLog('Admin status: $_isAdmin');
  }

  @override
  void dispose() {
    debugLog('Disposing InAppSubscriptionsPage');
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _redeemPromoCode() async {
    debugLog('Redeeming promo code: ${_promoCodeController.text}');
    setState(() {
      _promoCodeError = null;
    });
    try {
      await _inAppPurchaseService.redeemPromoCode(_promoCodeController.text);
      if (mounted) {
        _showSnackBar('Promo code redeemed successfully!');
      }
    } catch (e) {
      debugLog('Error redeeming promo code: $e');
      setState(() {
        _promoCodeError = e.toString();
      });
      _showSnackBar('Errore nel redeem del promo code: $e');
    }
  }

  void _showSnackBar(String message) {
    debugLog('Showing SnackBar: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showPromoCodeDialog() {
    debugLog('Showing promo code dialog');
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Redeem Promo Code', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _promoCodeController,
            decoration: InputDecoration(
              labelText: 'Enter Promo Code',
              errorText: _promoCodeError,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                debugLog('Cancel promo code dialog');
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Redeem'),
              onPressed: () {
                debugLog('Redeem button pressed in promo code dialog');
                Navigator.of(dialogContext).pop();
                _redeemPromoCode();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _syncProducts() async {
    debugLog('Syncing products...');
    try {
      await _inAppPurchaseService.manualSyncProducts();
      _showSnackBar('Products synced successfully');
      await _initialize();
    } catch (e) {
      debugLog('Error syncing products: $e');
      _showSnackBar('Error syncing products: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugLog('Building InAppSubscriptionsPage');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // Promo Code Button
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacing.xl),
                        child: _buildPromoCodeButton(theme, colorScheme),
                      ),
                    ),

                    // Subscription Plans
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.xl,
                        vertical: AppTheme.spacing.md,
                      ),
                      sliver: _buildSubscriptionPlans(theme, colorScheme),
                    ),

                    // Admin Sync Button
                    if (_isAdmin)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(AppTheme.spacing.xl),
                          child: _buildSyncButton(theme, colorScheme),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPromoCodeButton(ThemeData theme, ColorScheme colorScheme) {
    return Container(
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showPromoCodeDialog,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppTheme.spacing.lg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.redeem,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
                SizedBox(width: AppTheme.spacing.sm),
                Text(
                  'Redeem Promo Code',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionPlans(ThemeData theme, ColorScheme colorScheme) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final productDetailsList = _inAppPurchaseService.productDetailsByProductId.values.expand((e) => e).toList();
          if (index >= productDetailsList.length) return null;
          
          final productDetails = productDetailsList[index];
          return _buildSubscriptionCard(productDetails, theme, colorScheme);
        },
        childCount: _inAppPurchaseService.productDetailsByProductId.values
            .expand((e) => e)
            .length,
      ),
    );
  }

  Widget _buildSubscriptionCard(
    dynamic productDetails,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
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
        child: InkWell(
          onTap: () {
            debugLog('Subscribe button pressed for productId: ${productDetails.id}');
            _inAppPurchaseService.makePurchase(productDetails.id);
          },
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Plan Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing.sm,
                    vertical: AppTheme.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
                  ),
                  child: Text(
                    'Premium Plan',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: AppTheme.spacing.sm),

                // Plan Title
                Text(
                  productDetails.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: AppTheme.spacing.xs),

                // Description
                Text(
                  productDetails.description ?? 'No description available.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: AppTheme.spacing.sm),

                // Price
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing.sm,
                    vertical: AppTheme.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                  ),
                  child: Text(
                    '${productDetails.price} ${productDetails.currencyCode}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: AppTheme.spacing.sm),

                // Subscribe Button
                Container(
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppTheme.spacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: colorScheme.onPrimary,
                          size: 18,
                        ),
                        SizedBox(width: AppTheme.spacing.xs),
                        Text(
                          'Subscribe',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncButton(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.secondary,
            colorScheme.secondary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _syncProducts,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppTheme.spacing.lg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sync,
                  color: colorScheme.onSecondary,
                  size: 24,
                ),
                SizedBox(width: AppTheme.spacing.sm),
                Text(
                  'Sync Products',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
