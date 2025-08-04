import 'package:alphanessone/trainingBuilder/services/training_services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Main/app_theme.dart';
import '../../Main/routes.dart';
import '../../providers/providers.dart';
import '../../models/user_model.dart';
import '../../models/exercise_record.dart';
import '../../exerciseManager/exercise_model.dart';
import '../../trainingBuilder/models/training_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward();

    // Aggiorna i dati ogni 30 secondi
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    await _controller.reverse();
    await _controller.forward();

    setState(() => _isRefreshing = false);
  }

  Widget _buildTrainingTile(UserModel user) {
    final trainingService = ref.watch(trainingServiceProvider);

    return FutureBuilder<TrainingProgram?>(
      future: user.currentProgram != null
          ? trainingService.fetchTrainingProgram(user.currentProgram!)
          : Future.value(null),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorTile(
            icon: Icons.fitness_center,
            title: 'Allenamento',
            color: AppTheme.accentBlue,
            delay: 0.2,
          );
        }

        if (!snapshot.hasData) {
          return _buildLoadingTile(
            icon: Icons.fitness_center,
            title: 'Allenamento',
            color: AppTheme.accentBlue,
            delay: 0.2,
          );
        }

        final program = snapshot.data;
        if (program == null) {
          return _LiveTile(
            icon: Icons.fitness_center,
            title: 'Allenamento',
            primaryInfo: 'Nessun programma',
            secondaryInfo: 'Tocca per iniziare',
            color: AppTheme.accentBlue,
            onTap: () => context.push(Routes.trainingGallery),
            controller: _controller,
            delay: 0.2,
          );
        }

        return _LiveTile(
          icon: Icons.fitness_center,
          title: 'Allenamento',
          primaryInfo: program.name,
          secondaryInfo: 'Tocca per vedere',
          color: AppTheme.accentBlue,
          onTap: () => context.push(Routes.trainingGallery),
          controller: _controller,
          delay: 0.2,
        );
      },
    );
  }

  Widget _buildRecordsTile(UserModel user) {
    final exerciseRecordService = ref.watch(exerciseRecordServiceProvider);
    final exercisesService = ref.watch(exercisesServiceProvider);

    return FutureBuilder<List<ExerciseModel>>(
      future: exercisesService.getExercises().first,
      builder: (context, exercisesSnapshot) {
        if (exercisesSnapshot.hasError) {
          return _buildErrorTile(
            icon: Icons.timeline,
            title: 'Records',
            color: AppTheme.accentPurple,
            delay: 0.5,
          );
        }

        if (!exercisesSnapshot.hasData) {
          return _buildLoadingTile(
            icon: Icons.timeline,
            title: 'Records',
            color: AppTheme.accentPurple,
            delay: 0.5,
          );
        }

        final exercises = exercisesSnapshot.data!;
        if (exercises.isEmpty) {
          return _LiveTile(
            icon: Icons.timeline,
            title: 'Records',
            primaryInfo: 'Nessun esercizio',
            secondaryInfo: 'Tocca per aggiungere',
            color: AppTheme.accentPurple,
            onTap: () => context.push(Routes.maxRmDashboard),
            controller: _controller,
            delay: 0.5,
          );
        }

        return StreamBuilder<List<ExerciseRecord>>(
          stream: exerciseRecordService.getExerciseRecords(
            userId: user.id,
            exerciseId: exercises.first.id,
          ),
          builder: (context, recordsSnapshot) {
            if (recordsSnapshot.hasError) {
              return _buildErrorTile(
                icon: Icons.timeline,
                title: 'Records',
                color: AppTheme.accentPurple,
                delay: 0.5,
              );
            }

            if (!recordsSnapshot.hasData) {
              return _buildLoadingTile(
                icon: Icons.timeline,
                title: 'Records',
                color: AppTheme.accentPurple,
                delay: 0.5,
              );
            }

            final records = recordsSnapshot.data!;
            final latestRecord = records.isNotEmpty ? records.first : null;

            return _LiveTile(
              icon: Icons.timeline,
              title: 'Records',
              primaryInfo: latestRecord != null
                  ? latestRecord.exerciseId
                  : 'Nessun record',
              secondaryInfo: latestRecord != null
                  ? '${latestRecord.maxWeight} kg'
                  : 'Tocca per aggiungere',
              color: AppTheme.accentPurple,
              onTap: () => context.push(Routes.maxRmDashboard),
              controller: _controller,
              delay: 0.5,
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingTile({
    required IconData icon,
    required String title,
    required Color color,
    required double delay,
  }) {
    return _LiveTile(
      icon: icon,
      title: title,
      primaryInfo: 'Caricamento...',
      secondaryInfo: '',
      color: color,
      onTap: () {},
      controller: _controller,
      delay: delay,
    );
  }

  Widget _buildErrorTile({
    required IconData icon,
    required String title,
    required Color color,
    required double delay,
  }) {
    return _LiveTile(
      icon: icon,
      title: title,
      primaryInfo: 'Errore',
      secondaryInfo: 'Tocca per riprovare',
      color: color,
      onTap: () => setState(() {}),
      controller: _controller,
      delay: delay,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userAsyncValue = ref.watch(userProvider(currentUserId));

    return userAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Errore: $error')),
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Utente non trovato'));
        }

        return Scaffold(
          backgroundColor: AppTheme.surfaceDark,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              backgroundColor: AppTheme.surfaceMedium,
              color: AppTheme.primaryGold,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header con saluto e profilo
                  SliverToBoxAdapter(
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.5),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeOutCubic,
                      )),
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Benvenuto,',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  user.displayName,
                                  style:
                                      theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Hero(
                              tag: 'profile_avatar',
                              child: GestureDetector(
                                onTap: () => context.push(Routes.userProfile),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            AppTheme.primaryGold.withAlpha(77),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.primaryGold,
                                    backgroundImage: user.photoURL.isNotEmpty
                                        ? NetworkImage(user.photoURL)
                                        : null,
                                    child: user.photoURL.isEmpty
                                        ? const Icon(Icons.person,
                                            color: AppTheme.surfaceDark)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Statistiche principali
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacing.md),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: AppTheme.spacing.md,
                        crossAxisSpacing: AppTheme.spacing.md,
                        children: [
                          _buildTrainingTile(user),
                          _buildRecordsTile(user),
                        ],
                      ),
                    ),
                  ),

                  // Sezioni Principali
                  SliverToBoxAdapter(
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeOutCubic,
                      )),
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sezioni Principali',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: AppTheme.spacing.md),
                            Wrap(
                              spacing: AppTheme.spacing.sm,
                              runSpacing: AppTheme.spacing.sm,
                              children: [
                                _AnimatedActionButton(
                                  icon: Icons.fitness_center,
                                  label: 'Allenamenti',
                                  onTap: () =>
                                      context.push(Routes.trainingGallery),
                                  controller: _controller,
                                  delay: 0.6,
                                ),
                                _AnimatedActionButton(
                                  icon: Icons.restaurant_menu,
                                  label: 'Nutrizione',
                                  onTap: () => context.push(Routes.foodTracker),
                                  controller: _controller,
                                  delay: 0.7,
                                ),
                                _AnimatedActionButton(
                                  icon: Icons.calculate,
                                  label: 'Calcola TDEE',
                                  onTap: () => context.push(Routes.tdee),
                                  controller: _controller,
                                  delay: 0.8,
                                ),
                                _AnimatedActionButton(
                                  icon: Icons.monitor_weight,
                                  label: 'Misurazioni',
                                  onTap: () =>
                                      context.push(Routes.measurements),
                                  controller: _controller,
                                  delay: 0.9,
                                ),
                                _AnimatedActionButton(
                                  icon: Icons.timeline,
                                  label: 'Records',
                                  onTap: () =>
                                      context.push(Routes.maxRmDashboard),
                                  controller: _controller,
                                  delay: 1.0,
                                ),
                                _AnimatedActionButton(
                                  icon: Icons.list_alt,
                                  label: 'Esercizi',
                                  onTap: () =>
                                      context.push(Routes.exercisesList),
                                  controller: _controller,
                                  delay: 1.1,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Sezione Abbonamento
                  if (user.subscriptionExpiryDate != null) ...[
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _controller,
                          curve:
                              const Interval(0.8, 1.0, curve: Curves.easeOut),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _controller,
                            curve:
                                const Interval(0.8, 1.0, curve: Curves.easeOut),
                          )),
                          child: Padding(
                            padding: EdgeInsets.all(AppTheme.spacing.md),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.surfaceMedium,
                                    AppTheme.surfaceMedium.withAlpha(204),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radii.lg),
                                border: Border.all(
                                  color: AppTheme.primaryGold.withAlpha(77),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGold.withAlpha(26),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => context.push(Routes.status),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radii.lg),
                                  child: Padding(
                                    padding:
                                        EdgeInsets.all(AppTheme.spacing.md),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(
                                              AppTheme.spacing.sm),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGold
                                                .withAlpha(77),
                                            borderRadius: BorderRadius.circular(
                                                AppTheme.radii.sm),
                                          ),
                                          child: const Icon(
                                            Icons.star,
                                            color: AppTheme.primaryGold,
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: AppTheme.spacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Abbonamento Premium',
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                'Attivo fino al ${user.subscriptionExpiryDate?.day}/${user.subscriptionExpiryDate?.month}/${user.subscriptionExpiryDate?.year}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _controller,
                          curve:
                              const Interval(0.8, 1.0, curve: Curves.easeOut),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _controller,
                            curve:
                                const Interval(0.8, 1.0, curve: Curves.easeOut),
                          )),
                          child: Padding(
                            padding: EdgeInsets.all(AppTheme.spacing.md),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.surfaceMedium,
                                    AppTheme.surfaceMedium.withAlpha(204),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radii.lg),
                                border: Border.all(
                                  color: AppTheme.primaryGold.withAlpha(77),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGold.withAlpha(26),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () =>
                                      context.push(Routes.subscriptions),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radii.lg),
                                  child: Padding(
                                    padding:
                                        EdgeInsets.all(AppTheme.spacing.md),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(
                                              AppTheme.spacing.sm),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGold
                                                .withAlpha(77),
                                            borderRadius: BorderRadius.circular(
                                                AppTheme.radii.sm),
                                          ),
                                          child: const Icon(
                                            Icons.star_border,
                                            color: AppTheme.primaryGold,
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: AppTheme.spacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Passa a Premium',
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                'Sblocca tutte le funzionalità',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LiveTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String primaryInfo;
  final String secondaryInfo;
  final Color color;
  final VoidCallback onTap;
  final AnimationController controller;
  final double delay;

  const _LiveTile({
    required this.icon,
    required this.title,
    required this.primaryInfo,
    required this.secondaryInfo,
    required this.color,
    required this.onTap,
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: controller,
        curve: Interval(delay, delay + 0.2, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Interval(delay, delay + 0.2, curve: Curves.easeOut),
        )),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.surfaceMedium,
                AppTheme.surfaceMedium.withAlpha(204),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            border: Border.all(
              color: color.withAlpha(77),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(10),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacing.sm),
                      decoration: BoxDecoration(
                        color: color.withAlpha(77),
                        borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          primaryInfo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          secondaryInfo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AnimationController controller;
  final double delay;

  const _AnimatedActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: controller,
        curve: Interval(delay, delay + 0.2, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Interval(delay, delay + 0.2, curve: Curves.easeOut),
        )),
        child: SizedBox(
          width:
              (MediaQuery.of(context).size.width - AppTheme.spacing.md * 4) / 3,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.radii.md),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing.sm),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacing.sm),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.surfaceMedium,
                            AppTheme.surfaceMedium.withAlpha(204),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radii.md),
                        border: Border.all(
                          color: AppTheme.primaryGold.withAlpha(26),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withAlpha(26),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: AppTheme.primaryGold,
                        size: 24,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing.xs),
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final currentTrainingProgramProvider =
    StreamProvider.family<TrainingProgram?, String>((ref, userId) {
  final usersService = ref.watch(usersServiceProvider);
  final trainingService = TrainingProgramService(FirestoreService());

  return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
    final user = await usersService.getUserById(userId);
    if (user?.currentProgram == null) return null;
    return await trainingService.fetchTrainingProgram(user!.currentProgram!);
  });
});
