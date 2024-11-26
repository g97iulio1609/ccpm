import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/models/measurement_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/user_autocomplete.dart';
import 'widgets/measurement_card.dart';
import 'widgets/measurement_chart.dart';
import 'widgets/measurement_form.dart';
import 'measurement_controller.dart';
import 'measurement_constants.dart';

class MeasurementsPage extends ConsumerStatefulWidget {
  const MeasurementsPage({super.key});

  @override
  ConsumerState<MeasurementsPage> createState() => _MeasurementsPageState();

  static void showAddMeasurementDialog(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => MeasurementForm(
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
    _initializeUser();
  }

  void _initializeUser() {
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
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (currentUserRole == 'admin' || currentUserRole == 'coach')
                _buildUserSearch(colorScheme),
              _buildAddButton(context, colorScheme, selectedUserId),
              Expanded(
                child: selectedUserId != null
                    ? _buildMeasurementsContent(selectedUserId)
                    : _buildUserSelectionPrompt(
                        theme, colorScheme, currentUserRole),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSearch(ColorScheme colorScheme) {
    return Container(
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
        onSelected: (user) {
          ref.read(selectedUserIdProvider.notifier).state = user.id;
        },
        onChanged: (value) {
          final allUsers = ref.read(userListProvider);
          final filteredUsers = allUsers
              .where((user) =>
                  user.name.toLowerCase().contains(value.toLowerCase()) ||
                  user.email.toLowerCase().contains(value.toLowerCase()))
              .toList();
          ref.read(filteredUserListProvider.notifier).state = filteredUsers;
        },
      ),
    );
  }

  Widget _buildUserSelectionPrompt(
      ThemeData theme, ColorScheme colorScheme, String currentUserRole) {
    if (currentUserRole == 'admin' || currentUserRole == 'coach') {
      return Center(
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
      );
    }
    return _buildMeasurementsContent(
        ref.read(usersServiceProvider).getCurrentUserId());
  }

  Widget _buildMeasurementsContent(String userId) {
    return Consumer(
      builder: (context, ref, _) {
        final measurementsAsync =
            ref.watch(measurementControllerProvider(userId));
        final userAsync = ref.watch(userProvider(userId));

        return userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Errore: $error')),
          data: (user) => measurementsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Errore: $error')),
            data: (measurements) => _MeasurementsContent(
              measurements: measurements,
              userId: userId,
              userGender: user!.gender,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton(
      BuildContext context, ColorScheme colorScheme, String? selectedUserId) {
    return Padding(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      child: Container(
        width: double.infinity,
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
              selectedUserId ??
                  ref.read(usersServiceProvider).getCurrentUserId(),
            ),
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                  SizedBox(width: AppTheme.spacing.sm),
                  Text(
                    'Aggiungi Misurazione',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
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
}

class _MeasurementsContent extends ConsumerWidget {
  final List<MeasurementModel> measurements;
  final String userId;
  final int userGender;

  const _MeasurementsContent({
    required this.measurements,
    required this.userId,
    required this.userGender,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedComparisons = ref.watch(selectedMeasurementsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMeasurementCards(theme, colorScheme, ref),
                SizedBox(height: AppTheme.spacing.lg),
                MeasurementChart(
                  measurements: measurements,
                  showWeight: true,
                  showBodyFat: true,
                  showWaist: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementCards(
      ThemeData theme, ColorScheme colorScheme, WidgetRef ref) {
    final referenceMeasurement =
        measurements.isNotEmpty ? measurements.first : null;
    if (referenceMeasurement == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        final width = constraints.maxWidth / crossAxisCount - 16;

        return Wrap(
          spacing: AppTheme.spacing.lg,
          runSpacing: AppTheme.spacing.lg,
          children: MeasurementConstants.measurementLabels.entries.map((entry) {
            final value = _getMeasurementValue(referenceMeasurement, entry.key);
            return SizedBox(
              width: width,
              child: MeasurementCard(
                title: entry.value,
                value: value,
                unit: MeasurementConstants.measurementUnits[entry.key]!,
                icon: MeasurementConstants.measurementIcons[entry.key]!,
                status: _getMeasurementStatus(ref, entry.key, value ?? 0),
                comparisonValues: const [], // TODO: Implement comparison values
              ),
            );
          }).toList(),
        );
      },
    );
  }

  double? _getMeasurementValue(MeasurementModel measurement, String key) {
    switch (key) {
      case 'weight':
        return measurement.weight;
      case 'height':
        return measurement.height;
      case 'bodyFat':
        return measurement.bodyFatPercentage;
      case 'waist':
        return measurement.waistCircumference;
      case 'hip':
        return measurement.hipCircumference;
      case 'chest':
        return measurement.chestCircumference;
      case 'biceps':
        return measurement.bicepsCircumference;
      default:
        return null;
    }
  }

  MeasurementStatus _getMeasurementStatus(
      WidgetRef ref, String key, double value) {
    final controller = ref.read(measurementControllerProvider(userId).notifier);
    switch (key) {
      case 'weight':
        return controller.getWeightStatus(value, userGender);
      case 'bodyFat':
        return controller.getBodyFatStatus(value);
      case 'waist':
        return controller.getWaistStatus(value);
      default:
        return MeasurementStatus.normal;
    }
  }
}
