import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:numberpicker/numberpicker.dart';
import 'timer_constants.dart';
import 'package:flutter/services.dart';

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
        _buildPresetGrid(theme, colorScheme),
        SizedBox(height: AppTheme.spacing.lg),
        _buildCustomTimePicker(theme, colorScheme),
        SizedBox(height: AppTheme.spacing.lg),
        _buildStartButton(theme, colorScheme),
      ],
    );
  }

  Widget _buildPresetGrid(ThemeData theme, ColorScheme colorScheme) {
    // Organizziamo i preset in categorie basate sulla durata
    final shortPresets =
        presets.where((p) => (p['seconds'] as int) <= 60).toList();
    final mediumPresets = presets
        .where(
            (p) => (p['seconds'] as int) > 60 && (p['seconds'] as int) <= 180)
        .toList();
    final longPresets =
        presets.where((p) => (p['seconds'] as int) > 180).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Preset Timer',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Griglia di preset
        if (presets.isNotEmpty)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            ),
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.all(AppTheme.spacing.sm),
                children: [
                  if (shortPresets.isNotEmpty)
                    _buildPresetCategory(theme, colorScheme, shortPresets,
                        'Brevi', AppTheme.accentGreen),
                  if (mediumPresets.isNotEmpty)
                    _buildPresetCategory(theme, colorScheme, mediumPresets,
                        'Medi', AppTheme.primaryGold),
                  if (longPresets.isNotEmpty)
                    _buildPresetCategory(theme, colorScheme, longPresets,
                        'Lunghi', AppTheme.accentPurple),

                  // Pulsante per aggiungere un nuovo preset
                  GestureDetector(
                    onTap: onAddPresetPressed,
                    child: Container(
                      width: 80,
                      margin: EdgeInsets.only(left: AppTheme.spacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(AppTheme.radii.md),
                        border: Border.all(
                          color: colorScheme.primary.withAlpha(100),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                          SizedBox(height: AppTheme.spacing.xs),
                          Text(
                            'Nuovo',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // Se non ci sono preset, mostriamo un pulsante per crearne uno
          OutlinedButton.icon(
            onPressed: onAddPresetPressed,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi il tuo primo preset'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
              side: BorderSide(color: colorScheme.primary.withAlpha(128)),
            ),
          ),
      ],
    );
  }

  Widget _buildPresetCategory(
    ThemeData theme,
    ColorScheme colorScheme,
    List<Map<String, dynamic>> categoryPresets,
    String categoryName,
    Color categoryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: AppTheme.spacing.sm),
          child: Text(
            categoryName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: categoryColor.withAlpha(200),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: categoryPresets.map((preset) {
            // Calcola una dimensione proporzionale al tempo (minimo 70, massimo 110)
            final seconds = preset['seconds'] as int;
            double width = 70 + (seconds / 300 * 40);
            if (width > 110) width = 110;

            return GestureDetector(
              onTap: () => onPresetSelected(preset),
              onLongPress: () => onEditPresetPressed(preset),
              child: Container(
                width: width,
                height: 70,
                margin: EdgeInsets.only(left: AppTheme.spacing.sm),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      categoryColor.withAlpha(40),
                      categoryColor.withAlpha(70),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radii.md),
                  border: Border.all(
                    color: categoryColor.withAlpha(100),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            formatDuration(seconds),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (preset['label'] != null &&
                              preset['label'] != formatDuration(seconds))
                            Text(
                              preset['label'] as String,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withAlpha(180),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // Pulsante elimina
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onDeletePresetPressed(preset['id'] as String);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(100),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: AppTheme.error.withAlpha(220),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomTimePicker(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timer Personalizzato',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppTheme.spacing.md),
          Row(
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
                color: colorScheme.outline.withAlpha(50),
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
            color: Colors.white.withAlpha(150),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppTheme.spacing.xs),
        NumberPicker(
          value: value,
          minValue: 0,
          maxValue: maxValue,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            onChanged(value);
          },
          itemHeight: TimerConstants.numberPickerItemHeight,
          textStyle: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white.withAlpha(100),
          ),
          selectedTextStyle: theme.textTheme.headlineSmall?.copyWith(
            color: AppTheme.primaryGold,
            fontWeight: FontWeight.w600,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colorScheme.outline.withAlpha(40)),
              bottom: BorderSide(color: colorScheme.outline.withAlpha(40)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onStartTimer,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          ),
          elevation: 6,
          shadowColor: AppTheme.success.withAlpha(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, size: 24),
            SizedBox(width: AppTheme.spacing.xs),
            Text(
              'AVVIA TIMER',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
