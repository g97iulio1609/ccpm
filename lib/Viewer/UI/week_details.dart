import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/training_program_provider.dart';
import '../../UI/components/card.dart';

class WeekDetails extends ConsumerStatefulWidget {
  final String programId;
  final String weekId;
  final String userId;

  const WeekDetails({
    super.key,
    required this.programId,
    required this.weekId,
    required this.userId,
  });

  @override
  ConsumerState<WeekDetails> createState() => _WeekDetailsState();
}

class _WeekDetailsState extends ConsumerState<WeekDetails> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeWeekName();
      _isInitialized = true;
    }
  }

  Future<void> _initializeWeekName() async {
    final weekService = ref.read(trainingProgramServicesProvider);
    final weekName = await weekService.fetchWeekName(widget.weekId);
    if (mounted) {
      ref.read(currentWeekNameProvider.notifier).state = weekName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekService = ref.watch(trainingProgramServicesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: weekService.getWorkouts(widget.weekId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Errore: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final workouts = snapshot.data!.docs
                  .map((doc) => {
                        'id': doc.id,
                        ...doc.data() as Map<String, dynamic>,
                      })
                  .toList();

              return LayoutBuilder(
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
                                final workout = workouts[index];
                                final workoutId = workout['id'];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20.0),
                                  child: ActionCard(
                                    onTap: () {
                                      if (workoutId != null) {
                                        context.go(
                                          '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/$workoutId',
                                        );
                                      }
                                    },
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Workout ${workout['order']}',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        if (workout['description'] != null &&
                                            workout['description'].toString().isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            workout['description'],
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
                                        onPressed: () {
                                          if (workoutId != null) {
                                            context.go(
                                              '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/$workoutId',
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                    bottomContent: const [],
                                  ),
                                );
                              },
                              childCount: workouts.length,
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
                              childAspectRatio: 1.4, // Rapporto fisso per griglie
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final workout = workouts[index];
                                final workoutId = workout['id'];
                                return ActionCard(
                                  onTap: () {
                                    if (workoutId != null) {
                                      context.go(
                                        '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/$workoutId',
                                      );
                                    }
                                  },
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  title: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Workout ${workout['order']}',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (workout['description'] != null &&
                                          workout['description'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          workout['description'],
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
                                      onPressed: () {
                                        if (workoutId != null) {
                                          context.go(
                                            '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/$workoutId',
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                  bottomContent: const [],
                                );
                              },
                              childCount: workouts.length,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}