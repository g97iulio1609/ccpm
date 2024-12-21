// lib/Store/in_app_purchase.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Main/app_theme.dart';
import 'in_app_purchase_model.dart';
import 'in_app_purchase_services.dart';
import 'stripe_checkout_widget.dart';
import '../providers/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Classe per lo stato degli acquisti in-app
class InAppPurchaseState {
  final bool isLoading;
  final String? error;
  final SubscriptionDetails? subscription;
  final List<Product> products;
  final bool isSubscribed;

  const InAppPurchaseState({
    this.isLoading = false,
    this.error,
    this.subscription,
    this.products = const [],
    this.isSubscribed = false,
  });

  InAppPurchaseState copyWith({
    bool? isLoading,
    String? error,
    SubscriptionDetails? subscription,
    List<Product>? products,
    bool? isSubscribed,
  }) {
    return InAppPurchaseState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      subscription: subscription ?? this.subscription,
      products: products ?? this.products,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}

// Provider per il servizio degli acquisti in-app
final inAppPurchaseServiceProvider =
    Provider<InAppPurchaseService>((ref) => InAppPurchaseService());

// Provider per lo stato degli acquisti
final inAppPurchaseProvider =
    StateProvider<InAppPurchaseState>((ref) => const InAppPurchaseState());

class InAppPurchaseScreen extends ConsumerStatefulWidget {
  const InAppPurchaseScreen({super.key});

  @override
  ConsumerState<InAppPurchaseScreen> createState() =>
      _InAppPurchaseScreenState();
}

class _InAppPurchaseScreenState extends ConsumerState<InAppPurchaseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late final InAppPurchaseService _inAppPurchaseService;
  bool _isLoading = true;
  List<Product> _products = [];
  String? _error;

  // Cache per i prodotti
  static List<Product>? _cachedProducts;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // Ridotto da 800ms a 500ms
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

    _inAppPurchaseService = ref.read(inAppPurchaseServiceProvider);

    // Caricamento ottimizzato con cache
    _loadProductsOptimized();
  }

  Future<void> _loadProductsOptimized() async {
    try {
      // Verifica se abbiamo una cache valida
      if (_cachedProducts != null && _lastFetchTime != null) {
        final now = DateTime.now();
        if (now.difference(_lastFetchTime!) < _cacheDuration) {
          if (mounted) {
            setState(() {
              _products = _cachedProducts!;
              _isLoading = false;
              _error = null;
            });
            _controller.forward();
            return;
          }
        }
      }

      setState(() => _isLoading = true);

      // Caricamento asincrono dei prodotti
      final products = await _inAppPurchaseService.getProducts();

      // Aggiorna la cache
      _cachedProducts = products;
      _lastFetchTime = DateTime.now();

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
          _error = null;
        });
        _controller.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.error,
              ),
              SizedBox(height: AppTheme.spacing.md),
              Text(
                'Errore nel caricamento dei prodotti',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.error,
                ),
              ),
              SizedBox(height: AppTheme.spacing.sm),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.spacing.lg),
              ElevatedButton.icon(
                onPressed: _loadProductsOptimized,
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error.withAlpha(26),
                  foregroundColor: AppTheme.error,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Premium',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGold.withAlpha(38),
                      AppTheme.primaryGoldLight.withAlpha(13),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverFadeTransition(
            opacity: _fadeAnimation,
            sliver: SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFeatureSection(theme),
                      SizedBox(height: AppTheme.spacing.xl),
                      _buildProductList(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caratteristiche Premium',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppTheme.spacing.md),
        _buildFeatureItem(
          theme,
          icon: Icons.fitness_center,
          title: 'Programmi di Allenamento Illimitati',
          description: 'Crea e personalizza tutti i programmi che desideri',
        ),
        _buildFeatureItem(
          theme,
          icon: Icons.person_outline,
          title: 'Coaching Personalizzato',
          description: 'Accesso a consigli e supporto professionale',
        ),
        _buildFeatureItem(
          theme,
          icon: Icons.analytics_outlined,
          title: 'Analisi Dettagliate',
          description: 'Monitora i tuoi progressi con statistiche avanzate',
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.sm),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.spacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(AppTheme.radii.md),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          SizedBox(width: AppTheme.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppTheme.spacing.xxs),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Piani Disponibili',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: AppTheme.spacing.lg),
        ..._products.map((product) => Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacing.md),
              child: _buildProductCard(context, product),
            )),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPopular = product.id.contains('yearly');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color:
              isPopular ? theme.colorScheme.primary : theme.colorScheme.outline,
          width: isPopular ? 2 : 1,
        ),
        gradient: isPopular
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface.withAlpha(242),
                  colorScheme.surface.withAlpha(242).withOpacity(0.95),
                ],
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handlePurchase(context, product),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.sm,
                      vertical: AppTheme.spacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radii.full),
                    ),
                    child: Text(
                      'Più Popolare',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                ],
                Text(
                  product.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppTheme.spacing.xs),
                Text(
                  product.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: AppTheme.spacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.price,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPopular ? theme.colorScheme.primary : null,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _handlePurchase(context, product),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Acquista'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isPopular ? theme.colorScheme.primary : null,
                        foregroundColor:
                            isPopular ? theme.colorScheme.onPrimary : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePurchase(BuildContext context, Product product) async {
    try {
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;

      if (userId == null) {
        throw Exception('Utente non autenticato');
      }

      // Salva il BuildContext originale
      final originalContext = context;

      // Mostra loading indicator
      BuildContext? dialogContext;
      if (!mounted) return;
      showDialog(
        context: originalContext,
        barrierDismissible: false,
        builder: (BuildContext context) {
          dialogContext = context;
          return PopScope(
            canPop: false,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );

      try {
        final result =
            await _inAppPurchaseService.createPaymentIntent(product.id, userId);

        // Verifica se il widget è ancora montato
        if (!mounted) return;

        // Chiudi il loading indicator
        if (dialogContext != null) {
          Navigator.of(dialogContext!).pop();
        }

        final clientSecret = result['clientSecret'];
        final amount = result['amount'] / 100;
        final currency = result['currency'];

        // Verifica se il widget è ancora montato
        if (!mounted) return;

        await showModalBottomSheet(
          context: originalContext,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          enableDrag: false,
          builder: (BuildContext context) => StripeCheckoutWidget(
            clientSecret: clientSecret,
            amount: amount,
            currency: currency,
            onPaymentSuccess: (String paymentId) async {
              if (!mounted) return;

              Navigator.of(context).pop();

              if (!mounted) return;

              BuildContext? confirmContext;
              showDialog(
                context: originalContext,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  confirmContext = context;
                  return PopScope(
                    canPop: false,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              );

              try {
                final functions = ref.read(firebaseFunctionsProvider);
                await functions.httpsCallable('handleSuccessfulPayment').call({
                  'paymentId': paymentId,
                  'productId': product.id,
                });

                if (!mounted) return;

                if (confirmContext != null) {
                  Navigator.of(confirmContext!).pop();
                  ScaffoldMessenger.of(originalContext).showSnackBar(
                    SnackBar(
                      content: const Text('Abbonamento attivato con successo!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;

                if (confirmContext != null) {
                  Navigator.of(confirmContext!).pop();
                  ScaffoldMessenger.of(originalContext).showSnackBar(
                    SnackBar(
                      content: Text('Errore durante l\'attivazione: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            onPaymentError: (String error) {
              if (!mounted) return;

              Navigator.of(context).pop();
              ScaffoldMessenger.of(originalContext).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: AppTheme.error,
                ),
              );
            },
          ),
        );
      } catch (e) {
        if (!mounted) return;

        if (dialogContext != null) {
          Navigator.of(dialogContext!).pop();
        }
        rethrow;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'acquisto: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}
