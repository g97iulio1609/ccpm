import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:numberpicker/numberpicker.dart';
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
        _buildPresetSection(theme, colorScheme),
        SizedBox(height: AppTheme.spacing.xl),
        _buildEnhancedTimePicker(theme, colorScheme),
        SizedBox(height: AppTheme.spacing.xl),
        _buildEnhancedStartButton(theme, colorScheme),
      ],
    );
  }

  Widget _buildPresetSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.sm),
          child: Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 20,
                color: AppTheme.primaryGold,
              ),
              SizedBox(width: AppTheme.spacing.xs),
              Text(
                'Preset Rapidi',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppTheme.spacing.md),
        if (presets.isNotEmpty)
          _buildEnhancedPresetGrid(theme, colorScheme)
        else
          _buildEmptyPresetState(theme, colorScheme),
        SizedBox(height: AppTheme.spacing.md),
        _buildAddPresetButton(theme, colorScheme),
      ],
    );
  }

  Widget _buildEnhancedPresetGrid(ThemeData theme, ColorScheme colorScheme) {
    final sortedPresets = List<Map<String, dynamic>>.from(presets)
      ..sort((a, b) => (a['seconds'] as int).compareTo(b['seconds'] as int));

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.sm),
        itemCount: sortedPresets.length,
        separatorBuilder: (context, index) =>
            SizedBox(width: AppTheme.spacing.sm),
        itemBuilder: (context, index) {
          final preset = sortedPresets[index];
          return _buildModernPresetCard(preset, theme, colorScheme, index);
        },
      ),
    );
  }

  Widget _buildModernPresetCard(
    Map<String, dynamic> preset,
    ThemeData theme,
    ColorScheme colorScheme,
    int index,
  ) {
    final seconds = preset['seconds'] as int;
    final isQuick = seconds <= 60;
    final isMedium = seconds > 60 && seconds <= 180;
    final isLong = seconds > 180;

    Color categoryColor = AppTheme.primaryGold;
    IconData categoryIcon = Icons.timer_rounded;

    if (isQuick) {
      categoryColor = AppTheme.success;
      categoryIcon = Icons.flash_on_rounded;
    } else if (isMedium) {
      categoryColor = AppTheme.primaryGold;
      categoryIcon = Icons.timer_rounded;
    } else if (isLong) {
      categoryColor = AppTheme.accentPurple;
      categoryIcon = Icons.schedule_rounded;
    }

    return SizedBox(
      width: 100,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onPresetSelected(preset);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            onEditPresetPressed(preset);
          },
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  categoryColor.withAlpha(20),
                  categoryColor.withAlpha(5),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              border: Border.all(
                color: categoryColor.withAlpha(80),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(AppTheme.spacing.sm),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(categoryIcon, color: categoryColor, size: 24),
                      SizedBox(height: AppTheme.spacing.xs),
                      Text(
                        formatDuration(seconds),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: categoryColor,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onDeletePresetPressed(preset['id'] as String);
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.error.withAlpha(20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.error.withAlpha(80),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddPresetButton(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: AppTheme.primaryGold.withAlpha(60),
          width: 1.5,
        ),
      ),
      child: TextButton.icon(
        onPressed: onAddPresetPressed,
        icon: Icon(Icons.add_rounded, size: 20, color: AppTheme.primaryGold),
        label: Text(
          'Crea Nuovo Preset',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppTheme.primaryGold,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPresetState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 80,
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(20), width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_off_rounded,
              color: colorScheme.onSurfaceVariant.withAlpha(120),
              size: 24,
            ),
            SizedBox(height: AppTheme.spacing.xs),
            Text(
              'Nessun preset salvato',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTimePicker(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest.withAlpha(40),
            colorScheme.surfaceContainerHighest.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radii.xl),
        border: Border.all(color: colorScheme.outline.withAlpha(30), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: AppTheme.primaryGold, size: 20),
              SizedBox(width: AppTheme.spacing.xs),
              Text(
                'Timer Personalizzato',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing.lg),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.lg,
              vertical: AppTheme.spacing.md,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              border: Border.all(
                color: AppTheme.primaryGold.withAlpha(30),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildEnhancedNumberPicker(
                    theme,
                    colorScheme,
                    'Minuti',
                    timerMinutes,
                    59,
                    onMinutesChanged,
                  ),
                ),
                Container(
                  width: 3,
                  height: 80,
                  margin: EdgeInsets.symmetric(horizontal: AppTheme.spacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.primaryGold.withAlpha(50),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: _buildEnhancedNumberPicker(
                    theme,
                    colorScheme,
                    'Secondi',
                    timerSeconds,
                    59,
                    onSecondsChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedNumberPicker(
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
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppTheme.primaryGold,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: AppTheme.spacing.sm),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(30),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: NumberPicker(
            value: value,
            minValue: 0,
            maxValue: maxValue,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              onChanged(value);
            },
            itemHeight: 40,
            itemWidth: 80,
            textStyle: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant.withAlpha(120),
              fontWeight: FontWeight.w500,
            ),
            selectedTextStyle: theme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.primaryGold,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: AppTheme.primaryGold.withAlpha(30),
                  blurRadius: 4,
                ),
              ],
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.primaryGold.withAlpha(60),
                  width: 2,
                ),
                bottom: BorderSide(
                  color: AppTheme.primaryGold.withAlpha(60),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedStartButton(ThemeData theme, ColorScheme colorScheme) {
    final totalSeconds = (timerMinutes * 60) + timerSeconds;
    final isEnabled = totalSeconds > 0;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radii.xl),
        gradient: isEnabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryGold, AppTheme.primaryGoldDark],
              )
            : null,
        color: !isEnabled
            ? colorScheme.surfaceContainerHighest.withAlpha(60)
            : null,
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppTheme.primaryGold.withAlpha(30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isEnabled
            ? () {
                HapticFeedback.heavyImpact();
                onStartTimer();
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.xl),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radii.xl),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                size: 28,
                color: isEnabled
                    ? Colors.black
                    : colorScheme.onSurfaceVariant.withAlpha(80),
              ),
              SizedBox(width: AppTheme.spacing.sm),
              Text(
                'AVVIA TIMER',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: isEnabled
                      ? Colors.black
                      : colorScheme.onSurfaceVariant.withAlpha(80),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
