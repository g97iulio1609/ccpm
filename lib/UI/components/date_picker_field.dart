import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:alphanessone/Main/app_theme.dart';

class DatePickerField extends StatelessWidget {
  final DateTime? value;
  final String label;
  final String? helperText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime) onDateSelected;
  final String? Function(DateTime?)? validator;
  final String dateFormat;
  final IconData? icon;

  const DatePickerField({
    super.key,
    required this.value,
    required this.label,
    required this.onDateSelected,
    this.helperText,
    this.firstDate,
    this.lastDate,
    this.validator,
    this.dateFormat = 'dd/MM/yyyy',
    this.icon = Icons.calendar_today,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (helperText != null) ...[
          SizedBox(height: AppTheme.spacing.xs),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
        SizedBox(height: AppTheme.spacing.xs),
        InkWell(
          onTap: () => _showDatePicker(context),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Container(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                ],
                Expanded(
                  child: Text(
                    value != null 
                        ? DateFormat(dateFormat).format(value!)
                        : 'Seleziona data',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: value != null 
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (validator != null) ...[
          Builder(
            builder: (context) {
              final errorText = validator!(value);
              if (errorText != null) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: AppTheme.spacing.xs,
                    left: AppTheme.spacing.sm,
                  ),
                  child: Text(
                    errorText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ],
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radii.xl),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
              ),
              boxShadow: AppTheme.elevations.large,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(AppTheme.spacing.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(AppTheme.radii.full),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: AppTheme.spacing.md),
                      Text(
                        'Seleziona Data',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Calendar
                Theme(
                  data: theme.copyWith(
                    colorScheme: colorScheme.copyWith(
                      primary: colorScheme.primary,
                      onPrimary: colorScheme.onPrimary,
                      surface: colorScheme.surface,
                      onSurface: colorScheme.onSurface,
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: value ?? DateTime.now(),
                    firstDate: firstDate ?? DateTime(1900),
                    lastDate: lastDate ?? DateTime.now(),
                    onDateChanged: (date) {
                      Navigator.pop(context, date);
                    },
                  ),
                ),

                // Actions
                Container(
                  padding: EdgeInsets.all(AppTheme.spacing.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(AppTheme.radii.xl),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.lg,
                            vertical: AppTheme.spacing.md,
                          ),
                        ),
                        child: Text(
                          'Annulla',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }
} 