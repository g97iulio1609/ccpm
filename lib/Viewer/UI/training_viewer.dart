import 'package:alphanessone/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/training_program_provider.dart';
import '../../Store/inAppPurchase_services.dart';
import '../../utils/subscription_checker.dart';
import '../../UI/components/card.dart';

class TrainingViewer extends ConsumerStatefulWidget {
  final String programId;
  final String userId;

  const TrainingViewer({super.key, required this.programId, required this.userId});

  @override
  TrainingViewerState createState() => TrainingViewerState();
}

class TrainingViewerState extends ConsumerState<TrainingViewer> {
  @override
  void initState() {
    super.initState();
    _checkSubscriptionAndFetch();
  }

  Future<void> _checkSubscriptionAndFetch() async {
    final userRole = ref.read(userRoleProvider);

    if (userRole == 'admin') {
      Future.microtask(() => fetchTrainingWeeks());
      return;
    }

    final subscriptionChecker = SubscriptionChecker();
    final hasValidSubscription = await subscriptionChecker.checkSubscription(context);

    if (!hasValidSubscription) {
      if (mounted) {
        await showSubscriptionExpiredDialog(context);
        context.go('/subscriptions');
        return;
      }
    }

    Future.microtask(() => fetchTrainingWeeks());
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(trainingLoadingProvider);
    final weeks = ref.watch(trainingWeeksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.92),
              ],
            ),
          ),
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = () {
                      if (constraints.maxWidth > 1200) return 4; // Desktop large
                      if (constraints.maxWidth > 900) return 3;  // Desktop
                      if (constraints.maxWidth > 600) return 2;  // Tablet
                      return 1; // Mobile
                    }();

                    final horizontalPadding = crossAxisCount == 1 ? 16.0 : 24.0;
                    final spacing = 20.0;

                    if (crossAxisCount == 1) {
                      // Utilizza SliverList per una colonna con altezza adattiva
                      return CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              horizontalPadding,
                              horizontalPadding,
                              horizontalPadding + MediaQuery.of(context).padding.bottom,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  var week = weeks[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20.0),
                                    child: ActionCard(
                                      onTap: () => context.go(
                                        '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${week['id']}',
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            'Week ${week['number']}',
                                            style: theme.textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          if (week['description'] != null &&
                                              week['description'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              week['description'],
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: theme.colorScheme.secondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ],
                                      ),
                                      actions: [
                                        IconButtonWithBackground(
                                          icon: Icons.chevron_right,
                                          color: theme.colorScheme.primary,
                                          onPressed: () => context.go(
                                            '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${week['id']}',
                                          ),
                                        ),
                                      ],
                                      bottomContent: const [],
                                    ),
                                  );
                                },
                                childCount: weeks.length,
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Utilizza SliverGrid per più colonne con childAspectRatio adeguato
                      return CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              horizontalPadding,
                              horizontalPadding,
                              horizontalPadding + MediaQuery.of(context).padding.bottom,
                            ),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: spacing,
                                crossAxisSpacing: spacing,
                                childAspectRatio: 1.8, // Rapporto fisso per griglie
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  var week = weeks[index];
                                  return ActionCard(
                                    onTap: () => context.go(
                                      '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${week['id']}',
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Week ${week['number']}',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        if (week['description'] != null &&
                                            week['description'].toString().isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            week['description'],
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.secondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ],
                                    ),
                                    actions: [
                                      IconButtonWithBackground(
                                        icon: Icons.chevron_right,
                                        color: theme.colorScheme.primary,
                                        onPressed: () => context.go(
                                          '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${week['id']}',
                                        ),
                                      ),
                                    ],
                                    bottomContent: const [],
                                  );
                                },
                                childCount: weeks.length,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
        ),
      ),
    );
  }

  Future<void> showSubscriptionExpiredDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final inAppPurchaseService = InAppPurchaseService();
    final subscriptionDetails = await inAppPurchaseService.getSubscriptionDetails();
    final platform = subscriptionDetails?.platform ?? 'stripe';

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            'Abbonamento Scaduto',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Il tuo abbonamento è scaduto. Per continuare ad accedere ai contenuti, '
            'è necessario rinnovare l\'abbonamento.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (platform == 'stripe') {
                  context.go('/subscriptions');
                } else {
                  inAppPurchaseService.makePurchase('alphanessoneplussubscription');
                }
              },
              child: Text(
                'Rinnova Abbonamento',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/');
              },
              child: Text(
                'Torna Indietro',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchTrainingWeeks() async {
    ref.read(trainingLoadingProvider.notifier).state = true;
    try {
      final weeks = await ref.read(trainingProgramServicesProvider).fetchTrainingWeeks(widget.programId);
      if (mounted) {
        ref.read(trainingWeeksProvider.notifier).state = weeks;
      }
    } catch (e) {
      // Gestione degli errori
      // Potresti mostrare un messaggio di errore all'utente qui
    } finally {
      if (mounted) {
        ref.read(trainingLoadingProvider.notifier).state = false;
      }
    }
  }
}