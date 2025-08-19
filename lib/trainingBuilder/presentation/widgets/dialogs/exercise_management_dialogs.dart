import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import 'package:alphanessone/UI/components/button.dart';
import 'package:alphanessone/trainingBuilder/services/exercise_service.dart';

// Include anche i dialog bulk già consolidati
export 'package:alphanessone/trainingBuilder/presentation/widgets/dialogs/bulk_series_dialog.dart'
    show BulkSeriesSelectionDialog, BulkSeriesConfigurationDialog;

/// Dialog per aggiornare il Max RM di un esercizio
class UpdateMaxRMDialog extends StatefulWidget {
  final Exercise exercise;
  final ColorScheme colorScheme;
  final Function(double maxWeight, int repetitions) onSave;

  const UpdateMaxRMDialog({
    required this.exercise,
    required this.colorScheme,
    required this.onSave,
    super.key,
  });

  @override
  State<UpdateMaxRMDialog> createState() => _UpdateMaxRMDialogState();
}

class _UpdateMaxRMDialogState extends State<UpdateMaxRMDialog> {
  late final TextEditingController maxWeightController;
  late final TextEditingController repetitionsController;

  @override
  void initState() {
    super.initState();
    maxWeightController = TextEditingController();
    repetitionsController = TextEditingController(text: '1');

    // Auto-calcolo del Max RM quando cambiano le ripetizioni
    repetitionsController.addListener(_handleRepetitionsChange);
  }

  @override
  void dispose() {
    maxWeightController.dispose();
    repetitionsController.dispose();
    super.dispose();
  }

  void _handleRepetitionsChange() {
    final repetitions = int.tryParse(repetitionsController.text) ?? 1;
    if (repetitions > 1) {
      final weight = double.tryParse(maxWeightController.text) ?? 0;
      if (weight > 0) {
        final calculatedMaxWeight = ExerciseService.calculateMaxRM(
          weight,
          repetitions,
        );
        maxWeightController.text = calculatedMaxWeight.toStringAsFixed(1);
        repetitionsController.text = '1';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: const Text('Aggiorna Max RM'),
      actions: [
        AppDialogHelpers.buildCancelButton(context: context),
        AppDialogHelpers.buildActionButton(
          context: context,
          label: 'Salva',
          onPressed: _handleSave,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMaxWeightField(),
          SizedBox(height: AppTheme.spacing.md),
          _buildRepetitionsField(),
          SizedBox(height: AppTheme.spacing.sm),
          _buildCalculationHint(),
        ],
      ),
    );
  }

  Widget _buildMaxWeightField() {
    return Container(
      decoration: BoxDecoration(
        color: widget.colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: widget.colorScheme.outline.withAlpha(128)),
      ),
      child: TextField(
        controller: maxWeightController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d*')),
          TextInputFormatter.withFunction((oldValue, newValue) {
            final text = newValue.text.replaceAll(',', '.');
            return newValue.copyWith(
              text: text,
              selection: TextSelection.collapsed(offset: text.length),
            );
          }),
        ],
        style: TextStyle(color: widget.colorScheme.onSurface, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(AppTheme.spacing.md),
          labelText: 'Peso Massimo (kg)',
          labelStyle: TextStyle(color: widget.colorScheme.onSurfaceVariant),
          prefixIcon: Icon(
            Icons.fitness_center,
            color: widget.colorScheme.primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildRepetitionsField() {
    return Container(
      decoration: BoxDecoration(
        color: widget.colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: widget.colorScheme.outline.withAlpha(128)),
      ),
      child: TextField(
        controller: repetitionsController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(color: widget.colorScheme.onSurface, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(AppTheme.spacing.md),
          labelText: 'Ripetizioni',
          labelStyle: TextStyle(color: widget.colorScheme.onSurfaceVariant),
          prefixIcon: Icon(
            Icons.repeat,
            color: widget.colorScheme.primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildCalculationHint() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.sm),
      decoration: BoxDecoration(
        color: widget.colorScheme.primaryContainer.withAlpha(51),
        borderRadius: BorderRadius.circular(AppTheme.radii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: widget.colorScheme.primary),
          SizedBox(width: AppTheme.spacing.xs),
          Expanded(
            child: Text(
              'Se inserisci più di 1 ripetizione, il peso massimo verrà calcolato automaticamente',
              style: TextStyle(
                color: widget.colorScheme.onPrimaryContainer,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSave() {
    final maxWeight = double.tryParse(maxWeightController.text) ?? 0;
    final repetitions = int.tryParse(repetitionsController.text) ?? 1;

    if (maxWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Inserisci un peso valido'),
          backgroundColor: widget.colorScheme.error,
        ),
      );
      return;
    }

    widget.onSave(maxWeight, repetitions);
    Navigator.pop(context, true);
  }
}

/// Dialog per selezionare il SuperSet di destinazione
class SuperSetSelectionDialog extends StatefulWidget {
  final Exercise exercise;
  final List<SuperSet> superSets;
  final ColorScheme colorScheme;
  final Function(String superSetId) onSuperSetSelected;
  final VoidCallback onCreateNewSuperSet;

  const SuperSetSelectionDialog({
    required this.exercise,
    required this.superSets,
    required this.colorScheme,
    required this.onSuperSetSelected,
    required this.onCreateNewSuperSet,
    super.key,
  });

  @override
  State<SuperSetSelectionDialog> createState() =>
      _SuperSetSelectionDialogState();
}

class _SuperSetSelectionDialogState extends State<SuperSetSelectionDialog> {
  String? selectedSuperSetId;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: const Text('Aggiungi al Superset'),
      actions: [
        AppDialogHelpers.buildCancelButton(context: context),
        if (widget.superSets.isNotEmpty)
          AppDialogHelpers.buildActionButton(
            context: context,
            label: 'Aggiungi',
            onPressed: selectedSuperSetId != null ? _handleAddToSuperSet : () {},
            isPrimary: true,
          ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.superSets.isNotEmpty) ...[
            _buildSuperSetDropdown(),
            SizedBox(height: AppTheme.spacing.md),
          ],
          _buildCreateNewButton(),
        ],
      ),
    );
  }

  Widget _buildSuperSetDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: widget.colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: widget.colorScheme.outline.withAlpha(128)),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedSuperSetId,
        decoration: const InputDecoration(
          border: InputBorder.none,
          labelText: 'Seleziona Superset',
        ),
        dropdownColor: widget.colorScheme.surface,
        style: TextStyle(color: widget.colorScheme.onSurface),
        items: widget.superSets
            .map(
              (superSet) => DropdownMenuItem<String>(
                value: superSet.id,
                child: Text(
                  superSet.name ?? 'Superset ${superSet.id}',
                  style: TextStyle(color: widget.colorScheme.onSurface),
                ),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => selectedSuperSetId = value),
        icon: Icon(
          Icons.arrow_drop_down,
          color: widget.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildCreateNewButton() {
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        icon: Icons.add,
        label: 'Crea Nuovo Superset',
        variant: AppButtonVariant.outline,
        onPressed: _handleCreateNewSuperSet,
        block: true,
      ),
    );
  }

  void _handleAddToSuperSet() {
    if (selectedSuperSetId != null) {
      widget.onSuperSetSelected(selectedSuperSetId!);
      Navigator.pop(context);
    }
  }

  void _handleCreateNewSuperSet() {
    widget.onCreateNewSuperSet();
    Navigator.pop(context);
  }
}

/// Dialog per spostare un esercizio in un altro allenamento
class MoveExerciseDialog extends StatefulWidget {
  final List<dynamic> workouts;
  final int currentWorkoutIndex;
  final ColorScheme colorScheme;
  final Function(int destinationWorkoutIndex) onWorkoutSelected;

  const MoveExerciseDialog({
    required this.workouts,
    required this.currentWorkoutIndex,
    required this.colorScheme,
    required this.onWorkoutSelected,
    super.key,
  });

  @override
  State<MoveExerciseDialog> createState() => _MoveExerciseDialogState();
}

class _MoveExerciseDialogState extends State<MoveExerciseDialog> {
  int? selectedWorkoutIndex;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: const Text('Sposta Esercizio'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: selectedWorkoutIndex != null ? _handleMoveExercise : null,
          child: const Text('Sposta'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Seleziona l\'allenamento di destinazione:',
            style: TextStyle(color: widget.colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: AppTheme.spacing.md),
          _buildWorkoutDropdown(),
        ],
      ),
    );
  }

  Widget _buildWorkoutDropdown() {
    final availableWorkouts = widget.workouts
        .asMap()
        .entries
        .where((entry) => entry.key != widget.currentWorkoutIndex)
        .toList();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: widget.colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: widget.colorScheme.outline.withAlpha(128)),
      ),
      child: DropdownButtonFormField<int>(
        value: selectedWorkoutIndex,
        decoration: const InputDecoration(
          border: InputBorder.none,
          labelText: 'Allenamento di Destinazione',
        ),
        dropdownColor: widget.colorScheme.surface,
        style: TextStyle(color: widget.colorScheme.onSurface),
        items: availableWorkouts
            .map(
              (entry) => DropdownMenuItem<int>(
                value: entry.key,
                child: Text(
                  'Allenamento ${entry.value.order}',
                  style: TextStyle(color: widget.colorScheme.onSurface),
                ),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => selectedWorkoutIndex = value),
        icon: Icon(
          Icons.arrow_drop_down,
          color: widget.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  void _handleMoveExercise() {
    if (selectedWorkoutIndex != null) {
      widget.onWorkoutSelected(selectedWorkoutIndex!);
      Navigator.pop(context);
    }
  }
}
