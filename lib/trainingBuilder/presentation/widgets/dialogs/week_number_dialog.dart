import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alphanessone/Main/app_theme.dart';

class WeekNumberDialog extends StatefulWidget {
  final int currentWeekNumber;
  final int maxWeekNumber;
  final Function(int) onWeekNumberChanged;

  const WeekNumberDialog({
    required this.currentWeekNumber,
    required this.maxWeekNumber,
    required this.onWeekNumberChanged,
    super.key,
  });

  @override
  State<WeekNumberDialog> createState() => _WeekNumberDialogState();
}

class _WeekNumberDialogState extends State<WeekNumberDialog> {
  late TextEditingController _weekNumberController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _weekNumberController = TextEditingController(
      text: widget.currentWeekNumber.toString(),
    );
  }

  @override
  void dispose() {
    _weekNumberController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final text = _weekNumberController.text.trim();
    
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Il numero della settimana è richiesto';
      });
      return;
    }

    final weekNumber = int.tryParse(text);
    if (weekNumber == null) {
      setState(() {
        _errorMessage = 'Inserisci un numero valido';
      });
      return;
    }

    if (weekNumber < 1) {
      setState(() {
        _errorMessage = 'Il numero deve essere maggiore di 0';
      });
      return;
    }

    if (weekNumber > widget.maxWeekNumber) {
      setState(() {
        _errorMessage = 'Il numero non può essere maggiore di ${widget.maxWeekNumber}';
      });
      return;
    }

    // Check if the week number is already in use (except for current week)
    // This validation will be handled by the business logic
    setState(() {
      _errorMessage = null;
    });

    widget.onWeekNumberChanged(weekNumber);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final viewInsets = MediaQuery.of(context).viewInsets;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.only(
        left: AppTheme.spacing.xl + viewInsets.left,
        right: AppTheme.spacing.xl + viewInsets.right,
        top: AppTheme.spacing.lg + viewInsets.top,
        bottom: AppTheme.spacing.lg + viewInsets.bottom,
      ),
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radii.xl),
          border: Border.all(color: colorScheme.outline.withAlpha(26)),
          boxShadow: AppTheme.elevations.large,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxDialogHeight = constraints.maxHeight;
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxDialogHeight),
              child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(77),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radii.xl),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.sm,
                      vertical: AppTheme.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(76),
                      borderRadius: BorderRadius.circular(AppTheme.radii.full),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  Text(
                    'Modifica Numero Settimana',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    'Numero Settimana',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(76),
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      border: Border.all(
                        color: _errorMessage != null
                            ? colorScheme.error
                            : colorScheme.outline.withAlpha(26),
                      ),
                    ),
                    child: TextField(
                      controller: _weekNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Es. 1, 2, 3...',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(AppTheme.spacing.lg),
                        prefixIcon: Icon(
                          Icons.numbers,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onChanged: (value) {
                        if (_errorMessage != null) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                      onSubmitted: (_) => _validateAndSubmit(),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    SizedBox(height: AppTheme.spacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.error,
                          size: 16,
                        ),
                        SizedBox(width: AppTheme.spacing.xs),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: AppTheme.spacing.md),
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(51),
                      borderRadius: BorderRadius.circular(AppTheme.radii.md),
                      border: Border.all(
                        color: colorScheme.primary.withAlpha(51),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 16,
                        ),
                        SizedBox(width: AppTheme.spacing.sm),
                        Expanded(
                          child: Text(
                            'Il numero deve essere compreso tra 1 e ${widget.maxWeekNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(77),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radii.xl),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel button
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline.withAlpha(51)),
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.lg,
                            vertical: AppTheme.spacing.md,
                          ),
                          child: Text(
                            'Annulla',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  // Save button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withAlpha(204),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(51),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _validateAndSubmit,
                        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.lg,
                            vertical: AppTheme.spacing.md,
                          ),
                          child: Text(
                            'Salva',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
              ),
            );
          },
        ),
      ),
    );
  }
}
