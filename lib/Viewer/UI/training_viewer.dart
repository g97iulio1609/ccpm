import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/training_program_provider.dart';
import '../../Store/inAppPurchase_services.dart';
import '../../Store/inAppPurchase_model.dart';
import '../../utils/subscription_checker.dart';

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
    final subscriptionChecker = SubscriptionChecker();
    final hasValidSubscription = await subscriptionChecker.checkSubscription(context);
    
    if (!hasValidSubscription) {
      if (mounted) {
        await showSubscriptionExpiredDialog(context);
        context.go('/subscriptions'); // Navigate back to subscriptions page
        return;
      }
    }

    // Only fetch training weeks if subscription is valid
    Future.microtask(() => fetchTrainingWeeks());
  }

  Future<void> showSubscriptionExpiredDialog(BuildContext context) async {
    final inAppPurchaseService = InAppPurchaseService();
    final subscriptionDetails = await inAppPurchaseService.getSubscriptionDetails();
    final platform = subscriptionDetails?.platform ?? 'stripe'; // Default to stripe if unknown

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Abbonamento Scaduto'),
          content: const Text(
            'Il tuo abbonamento è scaduto. Per continuare ad accedere ai contenuti, '
            'è necessario rinnovare l\'abbonamento.'
          ),
          actions: [
            TextButton(
              child: const Text('Rinnova Abbonamento'),
              onPressed: () {
                Navigator.of(context).pop();
                if (platform == 'stripe') {
                  context.go('/subscriptions');
                } else {
                  // For Google Play, open the Play Store subscription page
                  inAppPurchaseService.makePurchase('alphanessoneplussubscription');
                }
              },
            ),
            TextButton(
              child: const Text('Torna Indietro'),
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/');
              },
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
      // Handle error
    } finally {
      if (mounted) {
        ref.read(trainingLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(trainingLoadingProvider);
    final weeks = ref.watch(trainingWeeksProvider);

    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: weeks.length,
              itemBuilder: (context, index) {
                var week = weeks[index];
                return WeekCard(
                  weekNumber: week['number'],
                  weekDescription: week['description'] ?? '',
                  onTap: () {
                    context.go(
                        '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${week['id']}');
                  },
                );
              },
            ),
    );
  }
}

class WeekCard extends StatelessWidget {
  final int weekNumber;
  final String weekDescription;
  final VoidCallback onTap;

  const WeekCard({
    super.key,
    required this.weekNumber,
    required this.weekDescription,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$weekNumber',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Settimana $weekNumber',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
