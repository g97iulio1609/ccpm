import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alphanessone/providers/providers.dart' as app_providers;
import 'package:alphanessone/Viewer/UI/workout_provider.dart' as workout_provider;
import 'package:alphanessone/Viewer/UI/widgets/workout_dialogs.dart';
import 'package:alphanessone/Viewer/UI/widgets/workout_formatters.dart';

class SeriesHeaderRow extends StatelessWidget {
  const SeriesHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildHeaderText('Serie', context, 1),
        _buildHeaderText('Reps', context, 2),
        _buildHeaderText('Kg', context, 2),
        _buildHeaderText('✓', context, 1),
      ],
    );
  }

  Widget _buildHeaderText(String text, BuildContext context, int flex) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class SeriesWidgets {
  static List<Widget> buildSeriesContainers(
    List<Map<String, dynamic>> series,
    BuildContext context,
    WidgetRef ref,
    Function(BuildContext, WidgetRef, Map<String, dynamic>, List<Map<String, dynamic>>)
    onEditSeries,
  ) {
    return series.asMap().entries.map((entry) {
      final seriesIndex = entry.key;
      final seriesData = entry.value;
      final userRole = ref.watch(app_providers.userRoleProvider);
      final isAdminOrCoach = userRole == 'admin' || userRole == 'coach';

      return GestureDetector(
        onTap: () {
          WorkoutDialogs.showUserSeriesInputDialog(context, ref, seriesData, 'reps');
        },
        onLongPress: isAdminOrCoach
            ? () {
                final exercise = {
                  'id': seriesData['exerciseId'],
                  'type': seriesData['type'] ?? 'weight',
                };
                onEditSeries(context, ref, exercise, [seriesData]);
              }
            : null,
        child: Column(
          children: [
            Row(
              children: [
                _buildSeriesIndexText(seriesIndex, context, 1),
                _buildSeriesDataText('reps', seriesData, context, ref, 2),
                _buildSeriesDataText('weight', seriesData, context, ref, 2),
                _buildSeriesDoneIcon(seriesData, context, ref, 1),
              ],
            ),
            if (seriesIndex < series.length - 1) const Divider(height: 16, thickness: 1),
          ],
        ),
      );
    }).toList();
  }

  static Widget _buildSeriesIndexText(int seriesIndex, BuildContext context, int flex) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Text(
        '${seriesIndex + 1}',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
        textAlign: TextAlign.center,
      ),
    );
  }

  static Widget _buildSeriesDataText(
    String field,
    Map<String, dynamic> seriesData,
    BuildContext context,
    WidgetRef ref,
    int flex,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final userRole = ref.watch(app_providers.userRoleProvider);
    final isAdminOrCoach = userRole == 'admin' || userRole == 'coach';

    // Ottieni il valore formattato
    final formattedValue = WorkoutFormatters.formatSeriesValue(seriesData, field, ref);

    // Se è una stringa semplice, mostrala direttamente
    if (formattedValue is String) {
      return Expanded(
        flex: flex,
        child: GestureDetector(
          onTap: () {
            WorkoutDialogs.showUserSeriesInputDialog(context, ref, seriesData, field);
          },
          onLongPress: isAdminOrCoach
              ? () {
                  // Questo callback dovrebbe essere gestito dal parent
                  // Per ora lo lascio vuoto per evitare dipendenze circolari
                }
              : null,
          child: Text(
            formattedValue,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Mostra sempre il formato esteso quando possibile
    return Expanded(
      flex: flex,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calcola la larghezza disponibile e decide quale formato usare
          final textStyle = Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface);
          final textSpan = TextSpan(
            text: (formattedValue as Map<String, String>)['extended'],
            style: textStyle,
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
            maxLines: 1,
          );
          textPainter.layout(maxWidth: double.infinity);

          // Se c'è spazio sufficiente per il formato esteso, usalo
          final hasEnoughSpace = textPainter.width <= constraints.maxWidth;

          return GestureDetector(
            onTap: () {
              WorkoutDialogs.showUserSeriesInputDialog(context, ref, seriesData, field);
            },
            onLongPress: isAdminOrCoach
                ? () {
                    // Questo callback dovrebbe essere gestito dal parent
                    // Per ora lo lascio vuoto per evitare dipendenze circolari
                  }
                : null,
            child: Text(
              hasEnoughSpace ? formattedValue['extended']! : formattedValue['compact']!,
              style: textStyle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }

  static Widget _buildSeriesDoneIcon(
    Map<String, dynamic> seriesData,
    BuildContext context,
    WidgetRef ref,
    int flex,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determina lo stato della serie
    bool isDone = WorkoutFormatters.determineSeriesStatus(seriesData, ref);
    bool isFailed = WorkoutFormatters.isSeriesFailed(seriesData);
    bool hasAttempted = WorkoutFormatters.hasAttemptedSeries(seriesData);

    IconData iconData;
    Color iconColor;

    if (isDone) {
      // Serie completata
      iconData = Icons.check_circle;
      iconColor = colorScheme.primary;
    } else if (isFailed && hasAttempted) {
      // Serie fallita (tentata ma non completata)
      iconData = Icons.error_outline;
      iconColor = colorScheme.error;
    } else {
      // Serie non svolta
      iconData = Icons.cancel;
      iconColor = colorScheme.onSurfaceVariant;
    }

    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () =>
              ref.read(workout_provider.workoutServiceProvider).toggleSeriesDone(seriesData),
          child: Icon(iconData, color: iconColor),
        ),
      ),
    );
  }
}
