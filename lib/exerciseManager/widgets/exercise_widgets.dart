import 'package:flutter/material.dart';
import '../exercise_model.dart';
import '../../UI/components/card.dart';

class PendingApprovalBadge extends StatelessWidget {
  const PendingApprovalBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pending_outlined,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'Pending Approval',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseCardContent extends StatelessWidget {
  final ExerciseModel exercise;
  final List<Widget> actions;
  final VoidCallback onTap;

  const ExerciseCardContent({
    super.key,
    required this.exercise,
    required this.actions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionCard(
      onTap: onTap,
      title: Text(
        exercise.name,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${exercise.muscleGroup} - ${exercise.type}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: -0.3,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      actions: actions,
      bottomContent: exercise.status == 'pending' 
          ? [const PendingApprovalBadge()]
          : null,
    );
  }
} 