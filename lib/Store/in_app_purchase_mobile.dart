import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InAppPurchaseScreenMobile extends StatefulWidget {
  const InAppPurchaseScreenMobile({super.key});

  @override
  State<InAppPurchaseScreenMobile> createState() =>
      _InAppPurchaseScreenMobileState();
}

class _InAppPurchaseScreenMobileState extends State<InAppPurchaseScreenMobile>
    with SingleTickerProviderStateMixin {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _initializeStore();
  }

  Future<void> _initializeStore() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        setState(() {
          _error = 'Store non disponibile';
          _isLoading = false;
        });
        return;
      }

      // Configura lo stream degli acquisti
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (error) {
          setState(() {
            _error = error.toString();
            _isLoading = false;
          });
        },
      );

      // Recupera i prodotti
      const Set<String> kIds = {
        'alphanessoneplussubscription',
        'coachingalphaness'
      };
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(kIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Prodotti non trovati: ${response.notFoundIDs}');
      }

      setState(() {
        _products = response.productDetails;
        _isLoading = false;
      });
      _controller.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        setState(() => _isLoading = true);
      } else {
        setState(() => _isLoading = false);
        if (purchaseDetails.status == PurchaseStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore: ${purchaseDetails.error}'),
              backgroundColor: AppTheme.error,
            ),
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _verifyPurchase(purchaseDetails);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Utente non autenticato');

      // Verifica l'acquisto con il backend
      await _inAppPurchase.completePurchase(purchaseDetails);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Abbonamento attivato con successo!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nel completare l\'acquisto: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _handlePurchase(ProductDetails product) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Utente non autenticato');

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: userId,
      );
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ripristino acquisti in corso...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nel ripristino: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Caricamento prodotti...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(26),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              'Errore: $_error',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initializeStore,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error.withAlpha(26),
                foregroundColor: AppTheme.error,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun prodotto disponibile',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest.withAlpha(128),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGold.withAlpha(39),
                      AppTheme.primaryGoldLight.withAlpha(13),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 40, 24, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Premium',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Sblocca Tutte le Funzionalità',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Accedi a funzionalità esclusive e migliora la tua esperienza di allenamento',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureSection(),
                    const SizedBox(height: 48),
                    _buildProductList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Caratteristiche Premium',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildFeatureItem(
                    icon: Icons.fitness_center,
                    title: 'Programmi Illimitati',
                    description:
                        'Crea e personalizza tutti i programmi che desideri',
                    isFirst: true,
                  ),
                  _buildFeatureItem(
                    icon: Icons.person_outline,
                    title: 'Coaching Personalizzato',
                    description: 'Accesso a consigli e supporto professionale',
                  ),
                  _buildFeatureItem(
                    icon: Icons.analytics_outlined,
                    title: 'Analisi Dettagliate',
                    description:
                        'Monitora i tuoi progressi con statistiche avanzate',
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              )
            : null,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(24) : Radius.zero,
          bottom: isLast ? const Radius.circular(24) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scegli il Tuo Piano',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seleziona il piano più adatto alle tue esigenze',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ..._products.map((product) => _buildProductCard(product)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductDetails product) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isYearly = product.id.contains('yearly');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isYearly ? colorScheme.primary : colorScheme.outlineVariant,
          width: isYearly ? 2 : 1,
        ),
        boxShadow: isYearly
            ? [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: () => _handlePurchase(product),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isYearly)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: colorScheme.onPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Più Popolare',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isYearly) const SizedBox(height: 16),
                        Text(
                          product.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isYearly
                          ? colorScheme.primary.withAlpha(26)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      product.price,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isYearly
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handlePurchase(product),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Sblocca Ora'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isYearly ? colorScheme.primary : null,
                    foregroundColor: isYearly ? colorScheme.onPrimary : null,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
