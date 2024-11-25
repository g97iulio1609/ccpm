import 'package:alphanessone/user_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:alphanessone/models/measurement_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';



class MeasurementsPage extends ConsumerStatefulWidget {
  const MeasurementsPage({super.key});

  @override
  ConsumerState<MeasurementsPage> createState() => _MeasurementsPageState();

  static void showAddMeasurementDialog(
      BuildContext context, WidgetRef ref, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => _MeasurementForm(
          scrollController: controller,
          measurement: null,
          userId: userId,
        ),
      ),
    );
  }
}

class _MeasurementsPageState extends ConsumerState<MeasurementsPage> {
  final TextEditingController _userSearchController = TextEditingController();
  final FocusNode _userSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = ref.read(usersServiceProvider).getCurrentUserId();
      final currentUserRole = ref.read(userRoleProvider);
      if (currentUserRole != 'admin' && currentUserRole != 'coach') {
        ref.read(selectedUserIdProvider.notifier).state = currentUserId;
      }
    });
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _userSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserRole = ref.watch(userRoleProvider);
    final selectedUserId = ref.watch(selectedUserIdProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // User Search Field (for admin/coach)
              if (currentUserRole == 'admin' || currentUserRole == 'coach')
                Container(
                  margin: EdgeInsets.all(AppTheme.spacing.xl),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                    boxShadow: AppTheme.elevations.small,
                  ),
                  child: UserTypeAheadField(
                    controller: _userSearchController,
                    focusNode: _userSearchFocusNode,
                    onSelected: (UserModel user) {
                      ref.read(selectedUserIdProvider.notifier).state = user.id;
                    },
                    onChanged: (String value) {
                      // Gestione del cambiamento del testo di ricerca
                      final allUsers = ref.read(userListProvider);
                      final filteredUsers = allUsers.where((user) =>
                        user.name.toLowerCase().contains(value.toLowerCase()) ||
                        user.email.toLowerCase().contains(value.toLowerCase())
                      ).toList();
                      ref.read(filteredUserListProvider.notifier).state = filteredUsers;
                    },
                  ),
                ),

              // Measurements Content
              Expanded(
                child: selectedUserId != null
                    ? _buildMeasurementsContent(selectedUserId)
                    : currentUserRole == 'admin' || currentUserRole == 'coach'
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                                ),
                                SizedBox(height: AppTheme.spacing.md),
                                Text(
                                  'Seleziona un utente',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildMeasurementsContent(
                            ref.read(usersServiceProvider).getCurrentUserId()),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => MeasurementsPage.showAddMeasurementDialog(
              context,
              ref,
              selectedUserId ?? ref.read(usersServiceProvider).getCurrentUserId(),
            ),
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              child: Icon(
                Icons.add,
                color: colorScheme.onPrimary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementsContent(String userId) {
    final measurementsAsyncValue = ref.watch(measurementsProvider(userId));
    final userAsyncValue = ref.watch(userProvider(userId));

    return userAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
      data: (user) => measurementsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (measurements) => _MeasurementsContent(
          measurements: measurements,
          userId: userId,
          userGender: user!.gender,
        ),
      ),
    );
  }
}

class _MeasurementsContent extends ConsumerWidget {
  final List<MeasurementModel> measurements;
  final String userId;
  final int userGender; // 1 for male, 2 for female

  const _MeasurementsContent({
    required this.measurements,
    required this.userId,
    required this.userGender,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedComparisons = ref.watch(selectedComparisonsProvider);
    Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildComparisonSelector(context, ref),
                const SizedBox(height: 16),
                _MeasurementCards(
                  measurements: measurements,
                  selectedComparisons: selectedComparisons,
                  userGender: userGender,
                ),
                const SizedBox(height: 16),
                _MeasurementsTrend(measurements: measurements),
                const SizedBox(height: 16),
                _MeasurementsList(measurements: measurements, userId: userId),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonSelector(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Compare measurements:',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface)),
        ElevatedButton(
          onPressed: () => _showComparisonSelectionDialog(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: const Text('Select'),
        ),
      ],
    );
  }

  void _showComparisonSelectionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) =>
          _ComparisonSelectionDialog(measurements: measurements),
    );
  }
}

class _MeasurementCards extends ConsumerWidget {
  final List<MeasurementModel> measurements;
  final List<MeasurementModel> selectedComparisons;
  final int userGender;

  const _MeasurementCards({
    required this.measurements,
    required this.selectedComparisons,
    required this.userGender,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referenceMeasurement = _getReferenceMeasurement();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        final width = constraints.maxWidth / crossAxisCount - 16;

        return Wrap(
          spacing: AppTheme.spacing.lg,
          runSpacing: AppTheme.spacing.lg,
          children: [
            _buildMeasurementCard(
              context,
              'Peso',
              width,
              referenceMeasurement?.weight,
              'kg',
              Icons.monitor_weight_outlined,
              (value) => _getWeightStatus(referenceMeasurement?.bodyFatPercentage ?? 0, userGender),
              _getComparisons(referenceMeasurement, (m) => m.weight),
              colorScheme,
              theme,
            ),
            _buildMeasurementCard(
              context,
              'Altezza',
              width,
              referenceMeasurement?.height,
              'cm',
              Icons.height,
              (_) => 'Normale',
              _getComparisons(referenceMeasurement, (m) => m.height),
              colorScheme,
              theme,
            ),
            _buildMeasurementCard(
              context,
              'BMI',
              width,
              referenceMeasurement?.bmi,
              '',
              Icons.calculate_outlined,
              _getBMIStatus,
              _getComparisons(referenceMeasurement, (m) => m.bmi),
              colorScheme,
              theme,
            ),
            _buildMeasurementCard(
              context,
              'Grasso Corporeo',
              width,
              referenceMeasurement?.bodyFatPercentage,
              '%',
              Icons.pie_chart_outline,
              _getBodyFatStatus,
              _getComparisons(referenceMeasurement, (m) => m.bodyFatPercentage),
              colorScheme,
              theme,
            ),
            _buildMeasurementCard(
              context,
              'Circonferenza Vita',
              width,
              referenceMeasurement?.waistCircumference,
              'cm',
              Icons.straighten,
              _getWaistStatus,
              _getComparisons(referenceMeasurement, (m) => m.waistCircumference),
              colorScheme,
              theme,
            ),
            _buildMeasurementCard(
              context,
              'Circonferenza Fianchi',
              width,
              referenceMeasurement?.hipCircumference,
              'cm',
              Icons.straighten,
              (_) => 'Normale',
              _getComparisons(referenceMeasurement, (m) => m.hipCircumference),
              colorScheme,
              theme,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMeasurementCard(
    BuildContext context,
    String title,
    double width,
    double? currentValue,
    String unit,
    IconData icon,
    String Function(double) getStatus,
    List<MapEntry<String, double?>> comparisonValues,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {}, // Gestire il tap se necessario
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con icona e titolo
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppTheme.spacing.sm),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(AppTheme.radii.md),
                        ),
                        child: Icon(
                          icon,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: AppTheme.spacing.sm),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppTheme.spacing.md),

                  // Valore corrente
                  if (currentValue != null) ...[
                    Text(
                      '${currentValue.toStringAsFixed(1)} $unit',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing.xs),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.sm,
                        vertical: AppTheme.spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(getStatus(currentValue), colorScheme).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radii.full),
                      ),
                      child: Text(
                        getStatus(currentValue),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _getStatusColor(getStatus(currentValue), colorScheme),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (comparisonValues.isNotEmpty) ...[
                      SizedBox(height: AppTheme.spacing.md),
                      Divider(
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                      SizedBox(height: AppTheme.spacing.sm),
                      ...comparisonValues.map((entry) => _buildComparisonRow(
                        context,
                        entry,
                        currentValue,
                        unit,
                        colorScheme,
                        theme,
                      )),
                    ],
                  ] else
                    Text(
                      'Nessun dato disponibile',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    BuildContext context,
    MapEntry<String, double?> entry,
    double currentValue,
    String unit,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final comparisonDate = entry.key;
    final comparisonValue = entry.value;
    if (comparisonValue != null) {
      final difference = currentValue - comparisonValue;
      final isPositive = difference >= 0;
      return Padding(
        padding: EdgeInsets.only(bottom: AppTheme.spacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              comparisonDate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: isPositive ? colorScheme.error : colorScheme.tertiary,
                ),
                Text(
                  '${difference.abs().toStringAsFixed(1)} $unit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isPositive ? colorScheme.error : colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  MeasurementModel? _getReferenceMeasurement() {
    return selectedComparisons.isNotEmpty
        ? selectedComparisons.reduce((a, b) => a.date.isAfter(b.date) ? a : b)
        : (measurements.isNotEmpty ? measurements.first : null);
  }

  List<MapEntry<String, double?>> _getComparisons(
      MeasurementModel? referenceMeasurement,
      double Function(MeasurementModel) getValue) {
    if (referenceMeasurement == null || selectedComparisons.isEmpty) {
      return [];
    }
    return selectedComparisons
        .where((m) => m.date != referenceMeasurement.date)
        .map((m) =>
            MapEntry(DateFormat('dd/MM/yyyy').format(m.date), getValue(m)))
        .toList();
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case 'underweight':
      case 'very low':
        return colorScheme.secondary;
      case 'normal':
      case 'optimal':
      case 'fitness':
        return colorScheme.tertiary;
      case 'overweight':
      case 'high':
        return colorScheme.secondary;
      case 'obese':
        return colorScheme.error;
      default:
        return colorScheme.onSurface;
    }
  }

  String _getWeightStatus(double bodyFatPercentage, int gender) {
    if (gender == 1) {
      // Male
      if (bodyFatPercentage < 6) return 'Essential Fat';
      if (bodyFatPercentage < 14) return 'Athletes';
      if (bodyFatPercentage < 18) return 'Fitness';
if (bodyFatPercentage < 25) return 'Normal';
      if (bodyFatPercentage < 32) return 'Overweight';
    } else if (gender == 2) {
      // Female
      if (bodyFatPercentage < 16) return 'Essential Fat';
      if (bodyFatPercentage < 20) return 'Athletes';
      if (bodyFatPercentage < 24) return 'Fitness';
      if (bodyFatPercentage < 31) return 'Normal';
      if (bodyFatPercentage < 39) return 'Overweight';
    }
    return 'Obese';
  }

  String _getBMIStatus(double value) {
    if (value < 18.5) return 'Underweight';
    if (value < 25) return 'Normal';
    if (value < 30) return 'Overweight';
    return 'Obese';
  }

  String _getBodyFatStatus(double value) {
    if (value < 10) return 'Very low';
    if (value < 20) return 'Fitness';
    if (value < 25) return 'Normal';
    if (value < 30) return 'Overweight';
    return 'Obese';
  }

  String _getWaistStatus(double value) {
    if (value < 80) return 'Optimal';
    if (value < 88) return 'Normal';
    return 'High';
  }
}

class _MeasurementsTrend extends StatelessWidget {
  final List<MeasurementModel> measurements;

  const _MeasurementsTrend({required this.measurements});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    bool hasMeasurements = measurements.isNotEmpty &&
        measurements.any((m) =>
            (m.weight) > 0 ||
            (m.bodyFatPercentage) > 0 ||
            (m.waistCircumference) > 0);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radii.lg),
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
                    Icons.trending_up,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppTheme.spacing.md),
                Text(
                  'Andamento Misurazioni',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Chart Content
          Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Column(
              children: [
                if (hasMeasurements) ...[
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: colorScheme.outlineVariant.withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: colorScheme.outlineVariant.withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: _buildTitlesData(theme, colorScheme),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        lineBarsData: [
                          _buildLineChartBarData(
                            measurements,
                            (m) => m.weight,
                            colorScheme.primary,
                            colorScheme,
                          ),
                          _buildLineChartBarData(
                            measurements,
                            (m) => m.bodyFatPercentage,
                            colorScheme.secondary,
                            colorScheme,
                          ),
                          _buildLineChartBarData(
                            measurements,
                            (m) => m.waistCircumference,
                            colorScheme.tertiary,
                            colorScheme,
                          ),
                        ],
                        minX: 0,
                        maxX: (measurements.length - 1).toDouble(),
                        minY: 0,
                        maxY: _calculateMaxY(),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipRoundedRadius: AppTheme.radii.md,
                            tooltipBorder: BorderSide(
                              color: colorScheme.outline.withOpacity(0.1),
                            ),
                            tooltipPadding: EdgeInsets.all(AppTheme.spacing.sm),
                            tooltipMargin: AppTheme.spacing.sm,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((LineBarSpot touchedSpot) {
                                final date = measurements[touchedSpot.x.toInt()].date;
                                final value = touchedSpot.y;
                                final measurementType = [
                                  'Peso',
                                  'Grasso Corporeo',
                                  'Circonferenza Vita'
                                ][touchedSpot.barIndex];
                                return LineTooltipItem(
                                  '${DateFormat('dd/MM/yyyy').format(date)}\n$measurementType: ${value.toStringAsFixed(1)}',
                                  TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList();
                            },
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                          ),
                          handleBuiltInTouches: true,
                          getTouchLineStart: (data, index) => 0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.lg),
                  // Legend
                  Wrap(
                    spacing: AppTheme.spacing.md,
                    runSpacing: AppTheme.spacing.sm,
                    children: [
                      _buildLegendItem('Peso', colorScheme.primary, theme, colorScheme),
                      _buildLegendItem('Grasso Corporeo', colorScheme.secondary, theme, colorScheme),
                      _buildLegendItem('Circonferenza Vita', colorScheme.tertiary, theme, colorScheme),
                    ],
                  ),
                ] else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        SizedBox(height: AppTheme.spacing.md),
                        Text(
                          'Nessuna misurazione disponibile',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacing.sm),
                        Text(
                          'Aggiungi nuove misurazioni per visualizzare il grafico',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppTheme.spacing.xs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData _buildTitlesData(ThemeData theme, ColorScheme colorScheme) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 10,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 10,
              ),
            );
          },
          reservedSize: 40,
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < measurements.length && index % 2 == 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('dd/MM').format(measurements[index].date),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 10,
                  ),
                ),
              );
            }
            return const Text('');
          },
          reservedSize: 30,
        ),
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(List<MeasurementModel> measurements,
      double? Function(MeasurementModel) getValue, Color color, ColorScheme colorScheme) {
    return LineChartBarData(
      spots: measurements.asMap().entries.map((entry) {
        final value = getValue(entry.value);
        return value != null && value > 0
            ? FlSpot(entry.key.toDouble(), value)
            : FlSpot.nullSpot;
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: color,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  double _calculateMaxY() {
    if (measurements.isEmpty) {
      return 100;
    }

    List<double> validValues = measurements
        .expand((m) => [m.weight, m.bodyFatPercentage, m.waistCircumference])
        .where((value) => value > 0)
        .toList();

    if (validValues.isEmpty) {
      return 100;
    }

    return validValues.reduce((a, b) => a > b ? a : b) + 10;
  }
}

class _MeasurementsList extends ConsumerWidget {
  final List<MeasurementModel> measurements;
  final String userId;

  const _MeasurementsList({required this.measurements, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radii.lg),
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
                    Icons.history,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppTheme.spacing.md),
                Text(
                  'Storico Misurazioni',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Lista misurazioni
          if (measurements.isEmpty)
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing.xl),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timeline_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    SizedBox(height: AppTheme.spacing.md),
                    Text(
                      'Nessuna misurazione disponibile',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing.sm),
                    Text(
                      'Aggiungi nuove misurazioni per visualizzare lo storico',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              itemCount: measurements.length,
              separatorBuilder: (context, index) => Divider(
                color: colorScheme.outline.withOpacity(0.1),
                height: AppTheme.spacing.md,
              ),
              itemBuilder: (context, index) {
                final measurement = measurements[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showMeasurementOptions(context, ref, measurement),
                    borderRadius: BorderRadius.circular(AppTheme.radii.md),
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacing.md),
                      child: Row(
                        children: [
                          // Data Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing.md,
                              vertical: AppTheme.spacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(AppTheme.radii.full),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(measurement.date),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: AppTheme.spacing.md),
                          // Dettagli misurazione
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Peso: ${measurement.weight.toStringAsFixed(1)} kg',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: AppTheme.spacing.xs),
                                Text(
                                  'Grasso: ${measurement.bodyFatPercentage.toStringAsFixed(1)}%',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Menu Icon
                          IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => _showMeasurementOptions(context, ref, measurement),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showMeasurementOptions(
    BuildContext context,
    WidgetRef ref,
    MeasurementModel measurement,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: DateFormat('dd/MM/yyyy').format(measurement.date),
        subtitle: 'Peso: ${measurement.weight.toStringAsFixed(1)} kg',
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(
            Icons.monitor_weight_outlined,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        items: [
          BottomMenuItem(
            title: 'Modifica Misurazione',
            icon: Icons.edit_outlined,
            onTap: () => _showEditMeasurementDialog(context, ref, measurement),
          ),
          BottomMenuItem(
            title: 'Elimina Misurazione',
            icon: Icons.delete_outline,
            onTap: () => _showDeleteConfirmationDialog(context, ref, measurement),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  void _showEditMeasurementDialog(
      BuildContext context, WidgetRef ref, MeasurementModel measurement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return _MeasurementForm(
          scrollController: ScrollController(),
          measurement: measurement,
          userId: userId,
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, MeasurementModel measurement) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text('Confirm Deletion',
              style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text('Are you sure you want to delete this measurement?',
              style: TextStyle(color: theme.colorScheme.onSurface)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: TextStyle(color: theme.colorScheme.primary)),
            ),
            TextButton(
              onPressed: () {
                ref.read(measurementsServiceProvider).deleteMeasurement(
                      userId: userId,
                      measurementId: measurement.id,
                    );
                Navigator.of(context).pop();
              },
              child: Text('Delete',
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        );
      },
    );
  }
}

class _ComparisonSelectionDialog extends ConsumerStatefulWidget {
  final List<MeasurementModel> measurements;

  const _ComparisonSelectionDialog({required this.measurements});

  @override
  _ComparisonSelectionDialogState createState() =>
      _ComparisonSelectionDialogState();
}

class _ComparisonSelectionDialogState extends ConsumerState<_ComparisonSelectionDialog> {
  late List<MeasurementModel> selectedTemp;

  @override
  void initState() {
    super.initState();
    selectedTemp = List<MeasurementModel>.from(ref.read(selectedComparisonsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      Icons.compare_arrows,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  Text(
                    'Misurazioni da Confrontare',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.spacing.lg),
                child: Column(
                  children: widget.measurements.map((measurement) {
                    final isSelected = selectedTemp.contains(measurement);
                    return Container(
                      margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: CheckboxListTile(
                          title: Text(
                            DateFormat('dd/MM/yyyy').format(measurement.date),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Peso: ${measurement.weight.toStringAsFixed(1)} kg',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          value: isSelected,
                          onChanged: (bool? selected) {
                            setState(() {
                              if (selected == true && !selectedTemp.contains(measurement)) {
                                selectedTemp.add(measurement);
                              } else if (selected == false) {
                                if (selectedTemp.length > 1 || measurement != selectedTemp.first) {
                                  selectedTemp.remove(measurement);
                                }
                              }
                            });
                          },
                          activeColor: colorScheme.primary,
                          checkColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
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
                  SizedBox(width: AppTheme.spacing.md),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ref.read(selectedComparisonsProvider.notifier).state = selectedTemp;
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.lg,
                            vertical: AppTheme.spacing.md,
                          ),
                          child: Text(
                            'Conferma',
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
      ),
    );
  }
}

class _MeasurementForm extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final MeasurementModel? measurement;
  final String userId;

  const _MeasurementForm({
    required this.scrollController,
    this.measurement,
    required this.userId,
  });

  @override
  _MeasurementFormState createState() => _MeasurementFormState();
}

class _MeasurementFormState extends ConsumerState<_MeasurementForm> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _bodyFatController;
  late final TextEditingController _waistController;
  late final TextEditingController _hipController;
  late final TextEditingController _chestController;
  late final TextEditingController _bicepsController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _weightController = TextEditingController(text: widget.measurement?.weight.toString() ?? '');
    _heightController = TextEditingController(text: widget.measurement?.height.toString() ?? '');
    _bodyFatController = TextEditingController(text: widget.measurement?.bodyFatPercentage.toString() ?? '');
    _waistController = TextEditingController(text: widget.measurement?.waistCircumference.toString() ?? '');
    _hipController = TextEditingController(text: widget.measurement?.hipCircumference.toString() ?? '');
    _chestController = TextEditingController(text: widget.measurement?.chestCircumference.toString() ?? '');
    _bicepsController = TextEditingController(text: widget.measurement?.bicepsCircumference.toString() ?? '');
    _selectedDate = widget.measurement?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _bodyFatController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _chestController.dispose();
    _bicepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radii.xl),
        ),
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      widget.measurement == null ? Icons.add_circle_outline : Icons.edit_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  Text(
                    widget.measurement == null ? 'Nuova Misurazione' : 'Modifica Misurazione',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDatePicker(context),
                    SizedBox(height: AppTheme.spacing.lg),
                    _buildMeasurementField(
                      controller: _weightController,
                      label: 'Peso',
                      hint: 'Inserisci il peso in kg',
                      icon: Icons.monitor_weight_outlined,
                      unit: 'kg',
                    ),
                    SizedBox(height: AppTheme.spacing.lg),
                    _buildMeasurementField(
                      controller: _heightController,
                      label: 'Altezza',
                      hint: 'Inserisci l\'altezza in cm',
                      icon: Icons.height,
                      unit: 'cm',
                    ),
                    SizedBox(height: AppTheme.spacing.lg),
                    _buildMeasurementField(
                      controller: _bodyFatController,
                      label: 'Grasso Corporeo',
                      hint: 'Inserisci la percentuale di grasso corporeo',
                      icon: Icons.pie_chart_outline,
                      unit: '%',
                    ),
                    SizedBox(height: AppTheme.spacing.lg),
                    _buildMeasurementField(
                      controller: _waistController,
                      label: 'Circonferenza Vita',
                      hint: 'Inserisci la circonferenza vita in cm',
                      icon: Icons.straighten,
                      unit: 'cm',
                    ),
                    SizedBox(height: AppTheme.spacing.lg),
                    _buildMeasurementField(
                      controller: _hipController,
                      label: 'Circonferenza Fianchi',
                      hint: 'Inserisci la circonferenza fianchi in cm',
                      icon: Icons.straighten,
                      unit: 'cm',
                    ),
                    SizedBox(height: AppTheme.spacing.lg),
                    _buildMeasurementField(
                      controller: _chestController,
                      label: 'Circonferenza Torace',
                      hint: 'Inserisci la circonferenza torace in cm',
                      icon: Icons.straighten,
                      unit: 'cm',
                    ),
                    SizedBox(height: AppTheme.spacing.lg),
                    _buildMeasurementField(
                      controller: _bicepsController,
                      label: 'Circonferenza Bicipiti',
                      hint: 'Inserisci la circonferenza bicipiti in cm',
                      icon: Icons.straighten,
                      unit: 'cm',
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                  SizedBox(width: AppTheme.spacing.md),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _submitMeasurement,
                        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.lg,
                            vertical: AppTheme.spacing.md,
                          ),
                          child: Text(
                            widget.measurement == null ? 'Aggiungi' : 'Aggiorna',
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
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppTheme.spacing.xs),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null && picked != _selectedDate) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
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
                Icon(
                  Icons.calendar_today,
                  color: colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: AppTheme.spacing.md),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String unit,
  }) {
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
        SizedBox(height: AppTheme.spacing.xs),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                icon,
                color: colorScheme.primary,
                size: 20,
              ),
              suffixText: unit,
              suffixStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(AppTheme.spacing.md),
            ),
          ),
        ),
      ],
    );
  }

  void _submitMeasurement() {
    if (_formKey.currentState!.validate()) {
      final measurementsService = ref.read(measurementsServiceProvider);
      final selectedUserId = ref.read(selectedUserIdProvider) ?? widget.userId;

      final weight = double.tryParse(_weightController.text) ?? 0.0;
      final height = double.tryParse(_heightController.text) ?? 0.0;
      final bodyFat = double.tryParse(_bodyFatController.text) ?? 0.0;
      final waist = double.tryParse(_waistController.text) ?? 0.0;
      final hip = double.tryParse(_hipController.text) ?? 0.0;
      final chest = double.tryParse(_chestController.text) ?? 0.0;
      final biceps = double.tryParse(_bicepsController.text) ?? 0.0;

      final bmi = height > 0 ? weight / ((height / 100) * (height / 100)) : 0.0;

      if (widget.measurement == null) {
        measurementsService.addMeasurement(
          userId: selectedUserId,
          date: _selectedDate,
          weight: weight,
          height: height,
          bmi: bmi,
          bodyFatPercentage: bodyFat,
          waistCircumference: waist,
          hipCircumference: hip,
          chestCircumference: chest,
          bicepsCircumference: biceps,
        );
      } else {
        measurementsService.updateMeasurement(
          userId: selectedUserId,
          measurementId: widget.measurement!.id,
          date: _selectedDate,
          weight: weight,
          height: height,
          bmi: bmi,
          bodyFatPercentage: bodyFat,
          waistCircumference: waist,
          hipCircumference: hip,
          chestCircumference: chest,
          bicepsCircumference: biceps,
        );
      }

      Navigator.pop(context);
    }
  }
}