import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:numberpicker/numberpicker.dart';
import 'timer_constants.dart';

class TimerControls extends StatelessWidget {
  final int timerMinutes;
  final int timerSeconds;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<int> onSecondsChanged;
  final VoidCallback onStartTimer;
  final List<Map<String, dynamic>> presets;
  final Function(Map<String, dynamic>) onPresetSelected;
  final VoidCallback onAddPresetPressed;
  final Function(Map<String, dynamic>) onEditPresetPressed;
  final Function(String) onDeletePresetPressed;
  final String Function(int) formatDuration;

  const TimerControls({
    super.key,
    required this.timerMinutes,
    required this.timerSeconds,
    required this.onMinutesChanged,
    required this.onSecondsChanged,
    required this.onStartTimer,
    required this.presets,
    required this.onPresetSelected,
    required this.onAddPresetPressed,
    required this.onEditPresetPressed,
    required this.onDeletePresetPressed,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPresetButtons(theme, colorScheme),
        SizedBox(height: AppTheme.spacing.md),
        _buildCustomTimePicker(theme, colorScheme),
        SizedBox(height: AppTheme.spacing.lg),
        _buildStartButton(theme, colorScheme),
      ],
    );
  }

  Widget _buildPresetButtons(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: presets.map((preset) {
                return Padding(
                  padding: EdgeInsets.only(right: AppTheme.spacing.xs),
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => onPresetSelected(preset),
                      onLongPress: () => onEditPresetPressed(preset),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.primary),
                        padding: EdgeInsets.only(
                          left: AppTheme.spacing.sm,
                          right: AppTheme.spacing.xl,
                          top: AppTheme.spacing.sm,
                          bottom: AppTheme.spacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radii.md),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatDuration(preset['seconds'] as int),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: AppTheme.spacing.xs),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            onPressed: () =>
                                onDeletePresetPressed(preset['id'] as String),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAddPresetPressed,
          icon: const Icon(Icons.add),
          label: const Text('Aggiungi preset'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colorScheme.primary.withAlpha(128)),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTimePicker(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNumberPicker(
            theme,
            colorScheme,
            'Minuti',
            timerMinutes,
            59,
            onMinutesChanged,
          ),
          VerticalDivider(
            color: colorScheme.outline.withAlpha(26),
            width: AppTheme.spacing.lg,
          ),
          _buildNumberPicker(
            theme,
            colorScheme,
            'Secondi',
            timerSeconds,
            59,
            onSecondsChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberPicker(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    int value,
    int maxValue,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppTheme.spacing.xs),
        NumberPicker(
          value: value,
          minValue: 0,
          maxValue: maxValue,
          onChanged: onChanged,
          itemHeight: TimerConstants.numberPickerItemHeight,
          textStyle: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          selectedTextStyle: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colorScheme.outline.withAlpha(26)),
              bottom: BorderSide(color: colorScheme.outline.withAlpha(26)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onStartTimer,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          ),
        ),
        child: Text(
          'AVVIA TIMER',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
