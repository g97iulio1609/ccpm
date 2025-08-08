import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/range_controllers.dart';

/// Component for displaying progression table header
class ProgressionTableHeader extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isSmallScreen;

  const ProgressionTableHeader({
    super.key,
    required this.colorScheme,
    required this.theme,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(76),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radii.lg),
        ),
      ),
      child: Row(
        children: [
          if (!isSmallScreen)
            Expanded(
              flex: 2,
              child: Text(
                'Week',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(128),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ...['Reps', 'Sets', 'Load'].map((header) {
            return Expanded(
              flex: 2,
              child: Text(
                header,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(128),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Component for progression field container
class ProgressionFieldContainer extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isLoadField;
  final bool isSmallScreen;

  const ProgressionFieldContainer({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    required this.colorScheme,
    required this.theme,
    required this.isLoadField,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radii.sm),
        child: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          constraints: isLoadField && isSmallScreen
              ? const BoxConstraints(minHeight: 80)
              : null,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radii.sm),
            border: Border.all(color: colorScheme.outline.withAlpha(26)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.spacing.sm),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: isSmallScreen && isLoadField ? 1.5 : 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: isSmallScreen && isLoadField ? 4 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Component for progression text field
class ProgressionTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType keyboardType;
  final Function(String) onChanged;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const ProgressionTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.keyboardType,
    required this.onChanged,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.sm),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            labelText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spacing.xs),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Component for progression range edit dialog
class ProgressionRangeEditDialog extends StatefulWidget {
  final String title;
  final String initialMin;
  final String initialMax;
  final Function(String?, String?) onSave;
  final Function(String?, String?) onChanged;

  const ProgressionRangeEditDialog({
    super.key,
    required this.title,
    required this.initialMin,
    required this.initialMax,
    required this.onSave,
    required this.onChanged,
  });

  @override
  State<ProgressionRangeEditDialog> createState() =>
      _ProgressionRangeEditDialogState();
}

class _ProgressionRangeEditDialogState
    extends State<ProgressionRangeEditDialog> {
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(text: widget.initialMin);
    _maxController = TextEditingController(text: widget.initialMax);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit ${widget.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _minController,
              decoration: InputDecoration(labelText: 'Minimum ${widget.title}'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                widget.onChanged(value, _maxController.text);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _maxController,
              decoration: InputDecoration(labelText: 'Maximum ${widget.title}'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                widget.onChanged(_minController.text, value);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final min = _minController.text.trim();
                  final max = _maxController.text.trim();
                  widget.onSave(
                    min.isNotEmpty ? min : null,
                    max.isNotEmpty ? max : null,
                  );
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }
}

/// Component for progression combined load dialog
class ProgressionCombinedLoadDialog extends StatefulWidget {
  final RangeControllers intensityControllers;
  final RangeControllers rpeControllers;
  final RangeControllers weightControllers;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final Function(String, String, String, String) onRealTimeUpdate;

  const ProgressionCombinedLoadDialog({
    super.key,
    required this.intensityControllers,
    required this.rpeControllers,
    required this.weightControllers,
    required this.colorScheme,
    required this.theme,
    required this.onRealTimeUpdate,
  });

  @override
  State<ProgressionCombinedLoadDialog> createState() =>
      _ProgressionCombinedLoadDialogState();
}

class _ProgressionCombinedLoadDialogState
    extends State<ProgressionCombinedLoadDialog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radii.xl),
        ),
      ),
      padding: EdgeInsets.all(AppTheme.spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: widget.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: AppTheme.spacing.md),
              Text(
                'Gestione Carico',
                style: widget.theme.textTheme.titleLarge?.copyWith(
                  color: widget.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing.lg),
          _buildIntensityFields(),
          SizedBox(height: AppTheme.spacing.lg),
          _buildWeightFields(),
          SizedBox(height: AppTheme.spacing.lg),
          _buildRpeFields(),
          SizedBox(height: AppTheme.spacing.xl),
          _buildConfirmButton(),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildIntensityFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed, color: widget.colorScheme.primary, size: 20),
            SizedBox(width: AppTheme.spacing.sm),
            Text(
              'Intensità (% 1RM)',
              style: widget.theme.textTheme.titleSmall?.copyWith(
                color: widget.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.intensityControllers.min,
                decoration: InputDecoration(
                  labelText: 'Min %',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.md),
                  ),
                  filled: true,
                  fillColor: widget.colorScheme.surfaceContainerHighest
                      .withAlpha(77),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) => _updateWithDelay('Intensity'),
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: TextField(
                controller: widget.intensityControllers.max,
                decoration: InputDecoration(
                  labelText: 'Max %',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.md),
                  ),
                  filled: true,
                  fillColor: widget.colorScheme.surfaceContainerHighest
                      .withAlpha(77),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) => _updateWithDelay('Intensity'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.fitness_center,
              color: widget.colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Text(
              'Peso (kg)',
              style: widget.theme.textTheme.titleSmall?.copyWith(
                color: widget.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.weightControllers.min,
                decoration: InputDecoration(
                  labelText: 'Min kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.md),
                  ),
                  filled: true,
                  fillColor: widget.colorScheme.surfaceContainerHighest
                      .withAlpha(77),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) => _updateWithDelay('Weight'),
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: TextField(
                controller: widget.weightControllers.max,
                decoration: InputDecoration(
                  labelText: 'Max kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.md),
                  ),
                  filled: true,
                  fillColor: widget.colorScheme.surfaceContainerHighest
                      .withAlpha(77),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) => _updateWithDelay('Weight'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRpeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              color: widget.colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Text(
              'RPE (Rate of Perceived Exertion)',
              style: widget.theme.textTheme.titleSmall?.copyWith(
                color: widget.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.rpeControllers.min,
                decoration: InputDecoration(
                  labelText: 'Min RPE',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.md),
                  ),
                  filled: true,
                  fillColor: widget.colorScheme.surfaceContainerHighest
                      .withAlpha(77),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) => _updateWithDelay('RPE'),
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: TextField(
                controller: widget.rpeControllers.max,
                decoration: InputDecoration(
                  labelText: 'Max RPE',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radii.md),
                  ),
                  filled: true,
                  fillColor: widget.colorScheme.surfaceContainerHighest
                      .withAlpha(77),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) => _updateWithDelay('RPE'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.colorScheme.primary,
          foregroundColor: widget.colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
        ),
        child: Text(
          'Conferma',
          style: widget.theme.textTheme.titleMedium?.copyWith(
            color: widget.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _updateWithDelay(String type) {
    // Aggiornamento immediato senza delay per una migliore esperienza utente
    final minValue = type == 'Intensity'
        ? widget.intensityControllers.min.text
        : type == 'RPE'
        ? widget.rpeControllers.min.text
        : widget.weightControllers.min.text;

    final maxValue = type == 'Intensity'
        ? widget.intensityControllers.max.text
        : type == 'RPE'
        ? widget.rpeControllers.max.text
        : widget.weightControllers.max.text;

    widget.onRealTimeUpdate(type, minValue, maxValue, type);
  }
}
