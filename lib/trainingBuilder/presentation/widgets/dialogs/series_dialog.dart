import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import 'package:alphanessone/shared/services/cardio_metrics_service.dart';

class SeriesDialog extends StatefulWidget {
  final ExerciseRecordService exerciseRecordService;
  final String athleteId;
  final String exerciseId; // This is the original exercise ID
  final int weekIndex;
  final Exercise exercise;
  final String exerciseType;
  final List<Series>? currentSeriesGroup;
  final num latestMaxWeight;
  final ValueNotifier<double> weightNotifier;
  final bool isIndividualEdit;

  const SeriesDialog({
    super.key,
    required this.exerciseRecordService,
    required this.athleteId,
    required this.exerciseId,
    required this.exerciseType,
    required this.weekIndex,
    required this.exercise,
    this.currentSeriesGroup,
    required this.latestMaxWeight,
    required this.weightNotifier,
    this.isIndividualEdit = false,
  });

  @override
  State<SeriesDialog> createState() => _SeriesDialogState();
}

class _SeriesDialogState extends State<SeriesDialog> {
  late final SeriesFormController _formController;
  final GlobalKey<_CardioFormState> _cardioKey = GlobalKey<_CardioFormState>();
  String _seriesType = 'standard';

  @override
  void initState() {
    super.initState();
    _formController = SeriesFormController(
      currentSeriesGroup: widget.currentSeriesGroup,
      isIndividualEdit: widget.isIndividualEdit,
      latestMaxWeight: widget.latestMaxWeight,
      originalExerciseId: widget.exercise.exerciseId, // Pass the original exercise ID
    );
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCardio = (widget.exerciseType.toLowerCase() == 'cardio');
    final isBodyweight = widget.exercise.isBodyweight == true;

    return AppDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_getDialogTitle(), style: theme.textTheme.titleMedium),
          IconButton(
            icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      actions: [
        AppDialogHelpers.buildCancelButton(context: context),
        AppDialogHelpers.buildActionButton(
          context: context,
          label: 'Conferma',
          onPressed: _handleSubmit,
        ),
      ],
      child: SingleChildScrollView(
        child: isCardio
            ? _CardioForm(
                key: _cardioKey,
                isIndividualEdit: _formController.isIndividualEdit,
                currentSeriesGroup: widget.currentSeriesGroup,
                originalExerciseId: _formController.originalExerciseId,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormField(
                    controller: _formController.repsController,
                    maxController: _formController.maxRepsController,
                    label: 'Ripetizioni',
                    hint: 'Ripetizioni',
                    maxHint: 'Max Ripetizioni',
                    icon: Icons.repeat,
                    theme: theme,
                    colorScheme: colorScheme,
                    focusNode: _formController.repsNode,
                    maxFocusNode: _formController.maxRepsNode,
                  ),
                  SizedBox(height: AppTheme.spacing.lg),
                  if (!_formController.isIndividualEdit) ...[
                    _buildFormField(
                      controller: _formController.setsController,
                      label: 'Serie',
                      hint: 'Numero di serie',
                      icon: Icons.format_list_numbered,
                      theme: theme,
                      colorScheme: colorScheme,
                      focusNode: _formController.setsNode,
                    ),
                    SizedBox(height: AppTheme.spacing.lg),
                  ],
                  _buildFormField(
                    controller: _formController.intensityController,
                    maxController: _formController.maxIntensityController,
                    label: 'Intensità (%)',
                    hint: 'Intensità',
                    maxHint: 'Max Intensità',
                    icon: Icons.speed,
                    theme: theme,
                    colorScheme: colorScheme,
                    focusNode: _formController.intensityNode,
                    maxFocusNode: _formController.maxIntensityNode,
                  ),
                  SizedBox(height: AppTheme.spacing.lg),
                  _buildFormField(
                    controller: _formController.rpeController,
                    maxController: _formController.maxRpeController,
                    label: 'RPE',
                    hint: 'RPE',
                    maxHint: 'Max RPE',
                    icon: Icons.trending_up,
                    theme: theme,
                    colorScheme: colorScheme,
                    focusNode: _formController.rpeNode,
                    maxFocusNode: _formController.maxRpeNode,
                  ),
                  if (isBodyweight) ...[
                    SizedBox(height: AppTheme.spacing.lg),
                    _buildSeriesTypeSelector(theme, colorScheme),
                  ],
                  if (!isBodyweight) ...[
                    SizedBox(height: AppTheme.spacing.lg),
                    _buildFormField(
                      controller: _formController.weightController,
                      maxController: _formController.maxWeightController,
                      label: 'Peso (kg)',
                      hint: 'Peso',
                      maxHint: 'Max Peso',
                      icon: Icons.fitness_center,
                      theme: theme,
                      colorScheme: colorScheme,
                      focusNode: _formController.weightNode,
                      maxFocusNode: _formController.maxWeightNode,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildSeriesTypeSelector(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(26),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
      ),
      child: DropdownButtonFormField<String>(
        value: _seriesType,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(AppTheme.spacing.md),
          labelText: 'Tipo Serie',
          labelStyle: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(Icons.format_list_bulleted, color: colorScheme.onSurfaceVariant),
        ),
        style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
        dropdownColor: colorScheme.surfaceContainer,
        items: [
          DropdownMenuItem(
            value: 'standard',
            child: Text('Serie Standard', style: TextStyle(color: colorScheme.onSurface)),
          ),
          DropdownMenuItem(
            value: 'min_reps',
            child: Text('Minimo Reps', style: TextStyle(color: colorScheme.onSurface)),
          ),
          DropdownMenuItem(
            value: 'amrap',
            child: Text('AMRAP (Max Reps)', style: TextStyle(color: colorScheme.onSurface)),
          ),
        ],
        onChanged: (value) => setState(() => _seriesType = value ?? 'standard'),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required FocusNode focusNode,
    TextEditingController? maxController,
    String? maxHint,
    FocusNode? maxFocusNode,
  }) {
    bool isWeightRelatedField() {
      return label == 'Intensità (%)' || label == 'Peso (kg)';
    }

    void handleFieldChange() {
      if (isWeightRelatedField()) {
        // Se questo campo ha il focus, diventa il master
        if (focusNode.hasFocus) {
          if (label == 'Intensità (%)') {
            _formController.updateWeightFromIntensity();
          } else if (label == 'Peso (kg)') {
            _formController.updateIntensityFromWeight();
          }
          return;
        }

        if (maxFocusNode?.hasFocus == true) {
          if (label == 'Intensità (%)') {
            _formController.updateMaxWeightFromMaxIntensity();
          } else if (label == 'Peso (kg)') {
            _formController.updateMaxIntensityFromMaxWeight();
          }
          return;
        }

        // Se nessun campo peso ha il focus, non fare nulla
        if (_formController.intensityNode.hasFocus ||
            _formController.maxIntensityNode.hasFocus ||
            _formController.weightNode.hasFocus ||
            _formController.maxWeightNode.hasFocus) {
          return;
        }
      }

      // Per tutti gli altri campi, aggiorna normalmente
      _formController.updateRelatedFields();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withAlpha(179),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppTheme.spacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(26),
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            border: Border.all(color: colorScheme.outline.withAlpha(26)),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: colorScheme.primary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(AppTheme.spacing.md),
            ),
            onChanged: (_) => handleFieldChange(),
          ),
        ),
        if (maxController != null && maxFocusNode != null && maxHint != null) ...[
          SizedBox(height: AppTheme.spacing.sm),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(26),
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              border: Border.all(color: colorScheme.outline.withAlpha(26)),
            ),
            child: TextField(
              controller: maxController,
              focusNode: maxFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                hintText: maxHint,
                prefixIcon: Icon(icon, color: colorScheme.primary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(AppTheme.spacing.md),
              ),
              onChanged: (_) => handleFieldChange(),
            ),
          ),
        ],
      ],
    );
  }

  String _getDialogTitle() {
    if (widget.currentSeriesGroup != null) {
      return widget.isIndividualEdit ? 'Modifica Serie' : 'Modifica Gruppo Serie';
    }
    return 'Aggiungi Serie';
  }

  void _handleSubmit() {
    final isCardio = (widget.exerciseType.toLowerCase() == 'cardio');
    final count = widget.currentSeriesGroup?.length ?? widget.exercise.series.length;
    final updatedSeries = isCardio
        ? (_cardioKey.currentState?.createSeries(count) ?? const <Series>[])
        : _formController.createSeries(count);

    // Se stiamo modificando serie esistenti, manteniamo gli ID e l'ordine
    if (widget.currentSeriesGroup != null) {
      for (var i = 0; i < updatedSeries.length; i++) {
        updatedSeries[i] = updatedSeries[i].copyWith(
          id: i < widget.currentSeriesGroup!.length ? widget.currentSeriesGroup![i].id : null,
          originalExerciseId: i < widget.currentSeriesGroup!.length
              ? widget.currentSeriesGroup![i].originalExerciseId
              : widget.exercise.id,
          order: i < widget.currentSeriesGroup!.length ? widget.currentSeriesGroup![i].order : i,
        );
      }
    }

    // Ritorna direttamente la lista attesa dal chiamante
    Navigator.pop(context, updatedSeries);
  }
}

class _CardioForm extends StatefulWidget {
  final bool isIndividualEdit;
  final List<Series>? currentSeriesGroup;
  final String? originalExerciseId;

  const _CardioForm({
    super.key,
    required this.isIndividualEdit,
    required this.currentSeriesGroup,
    required this.originalExerciseId,
  });

  @override
  State<_CardioForm> createState() => _CardioFormState();
}

class _CardioFormState extends State<_CardioForm> {
  final _svc = const CardioMetricsService();

  final TextEditingController _sets = TextEditingController(text: '1');
  // Duration as hours and minutes (user-friendly); converted to seconds when saving
  final TextEditingController _hours = TextEditingController();
  final TextEditingController _minutes = TextEditingController();
  final TextEditingController _distance = TextEditingController(); // meters
  final TextEditingController _speed = TextEditingController(); // km/h
  final TextEditingController _pace = TextEditingController(); // sec/km
  final TextEditingController _incline = TextEditingController(); // %
  final TextEditingController _hrPct = TextEditingController(); // %
  final TextEditingController _hrBpm = TextEditingController(); // bpm
  final TextEditingController _kcal = TextEditingController();
  final TextEditingController _age = TextEditingController(); // years for HRmax

  // HIIT specific controllers
  final TextEditingController _workMinutes = TextEditingController();
  final TextEditingController _workSeconds = TextEditingController();
  final TextEditingController _restMinutes = TextEditingController();
  final TextEditingController _restSeconds = TextEditingController();
  final TextEditingController _rounds = TextEditingController();
  
  String _cardioType = 'steady';

  @override
  void initState() {
    super.initState();
    if (widget.currentSeriesGroup != null && widget.currentSeriesGroup!.isNotEmpty) {
      final s = widget.currentSeriesGroup!.first;
      _sets.text = widget.currentSeriesGroup!.length.toString();
      final dur = s.durationSeconds ?? 0;
      if (dur > 0) {
        _hours.text = (dur ~/ 3600).toString();
        _minutes.text = ((dur % 3600) ~/ 60).toString();
      }
      _distance.text = (s.distanceMeters ?? '').toString();
      _speed.text = (s.speedKmh ?? '').toString();
      _pace.text = (s.paceSecPerKm ?? '').toString();
      _incline.text = (s.inclinePercent ?? '').toString();
      _hrPct.text = (s.hrPercent ?? '').toString();
      _hrBpm.text = (s.hrBpm ?? '').toString();
      _kcal.text = (s.kcal ?? '').toString();
      
      // HIIT fields
      _cardioType = s.cardioType ?? 'steady';
      final workInterval = s.workIntervalSeconds ?? 0;
      if (workInterval > 0) {
        _workMinutes.text = (workInterval ~/ 60).toString();
        _workSeconds.text = (workInterval % 60).toString();
      }
      final restInterval = s.restIntervalSeconds ?? 0;
      if (restInterval > 0) {
        _restMinutes.text = (restInterval ~/ 60).toString();
        _restSeconds.text = (restInterval % 60).toString();
      }
      _rounds.text = (s.rounds ?? '').toString();
    }
  }

  @override
  void dispose() {
    _sets.dispose();
    _hours.dispose();
    _minutes.dispose();
    _distance.dispose();
    _speed.dispose();
    _pace.dispose();
    _incline.dispose();
    _hrPct.dispose();
    _hrBpm.dispose();
    _kcal.dispose();
    _age.dispose();
    _workMinutes.dispose();
    _workSeconds.dispose();
    _restMinutes.dispose();
    _restSeconds.dispose();
    _rounds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isIndividualEdit) _numField('Serie', _sets, Icons.format_list_numbered),
        _buildCardioTypeSelector(),
        if (_cardioType == 'steady') ...[
          _durationFields(),
          _numField('Distanza (m)', _distance, Icons.route, onChanged: _syncFromDistance),
        ] else ...[
          _buildHIITFields(),
        ],
        Row(
          children: [
            Expanded(
              child: _numField('Velocità (km/h)', _speed, Icons.speed, onChanged: _syncFromSpeed),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: _numField(
                'Pace (sec/km)',
                _pace,
                Icons.directions_run,
                onChanged: _syncFromPace,
              ),
            ),
          ],
        ),
        _numField('Pendenza (%)', _incline, Icons.trending_up),
        Row(
          children: [
            Expanded(
              child: _numField('FC %', _hrPct, Icons.favorite, onChanged: _syncHrFromPercent),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: _numField('FC (bpm)', _hrBpm, Icons.monitor_heart, onChanged: _syncHrFromBpm),
            ),
          ],
        ),
        _numField('Età (anni)', _age, Icons.cake),
        _numField('Kcal', _kcal, Icons.local_fire_department),
      ],
    );
  }

  Widget _buildCardioTypeSelector() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(26),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          border: Border.all(color: cs.outline.withAlpha(26)),
        ),
        child: DropdownButtonFormField<String>(
          value: _cardioType,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(AppTheme.spacing.md),
            labelText: 'Tipo Cardio',
            labelStyle: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            prefixIcon: Icon(Icons.directions_run, color: cs.primary),
          ),
          style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurface),
          dropdownColor: cs.surfaceContainer,
          items: const [
            DropdownMenuItem(value: 'steady', child: Text('Steady State')),
            DropdownMenuItem(value: 'hiit', child: Text('HIIT')),
          ],
          onChanged: (value) => setState(() => _cardioType = value ?? 'steady'),
        ),
      ),
    );
  }

  Widget _buildHIITFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _numField('Lavoro (min)', _workMinutes, Icons.fitness_center),
            ),
            SizedBox(width: AppTheme.spacing.xs),
            Expanded(
              child: _numField('Lavoro (sec)', _workSeconds, Icons.timer),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _numField('Riposo (min)', _restMinutes, Icons.pause),
            ),
            SizedBox(width: AppTheme.spacing.xs),
            Expanded(
              child: _numField('Riposo (sec)', _restSeconds, Icons.timer),
            ),
          ],
        ),
        _numField('Round', _rounds, Icons.repeat),
      ],
    );
  }

  Widget _numField(
    String label,
    TextEditingController c,
    IconData icon, {
    VoidCallback? onChanged,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: cs.onSurfaceVariant.withAlpha(179),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppTheme.spacing.sm),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withAlpha(26),
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              border: Border.all(color: cs.outline.withAlpha(26)),
            ),
            child: TextField(
              controller: c,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: cs.primary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(AppTheme.spacing.md),
              ),
              onChanged: (_) => onChanged?.call(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _durationFields() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Durata (hh:mm)',
            style: theme.textTheme.titleSmall?.copyWith(
              color: cs.onSurfaceVariant.withAlpha(179),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppTheme.spacing.sm),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withAlpha(26),
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                    border: Border.all(color: cs.outline.withAlpha(26)),
                  ),
                  child: TextField(
                    controller: _hours,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ore',
                      prefixIcon: Icon(Icons.timer, color: cs.primary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(AppTheme.spacing.md),
                    ),
                    onChanged: (_) => _syncFromDuration(),
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacing.md),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withAlpha(26),
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                    border: Border.all(color: cs.outline.withAlpha(26)),
                  ),
                  child: TextField(
                    controller: _minutes,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Minuti',
                      prefixIcon: Icon(Icons.timer_outlined, color: cs.primary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(AppTheme.spacing.md),
                    ),
                    onChanged: (_) => _syncFromDuration(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _syncFromDuration() {
    final h = int.tryParse(_hours.text) ?? 0;
    final m = int.tryParse(_minutes.text) ?? 0;
    final dur = (h * 3600) + (m * 60);
    final pace = int.tryParse(_pace.text);
    final speed = double.tryParse(_speed.text);
    final dist = _svc.deriveDistanceMeters(
      durationSeconds: dur,
      paceSecPerKm: pace,
      speedKmh: speed,
    );
    if (dist != null) _distance.text = dist.toString();
  }

  void _syncFromDistance() {
    final dist = int.tryParse(_distance.text);
    final pace = int.tryParse(_pace.text);
    final speed = double.tryParse(_speed.text);
    if (dist != null) {
      final dur = _svc.deriveDurationSeconds(
        distanceMeters: dist,
        paceSecPerKm: pace,
        speedKmh: speed,
      );
      if (dur != null) {
        _hours.text = (dur ~/ 3600).toString();
        _minutes.text = ((dur % 3600) ~/ 60).toString();
      }
    }
  }

  void _syncFromSpeed() {
    final speed = double.tryParse(_speed.text);
    if (speed != null && speed > 0) {
      _pace.text = _svc.paceSecPerKmFromSpeed(speed).toString();
      _syncFromDistance();
    }
  }

  void _syncFromPace() {
    final pace = int.tryParse(_pace.text);
    if (pace != null && pace > 0) {
      _speed.text = _svc.speedFromPaceSecPerKm(pace).toStringAsFixed(2);
      _syncFromDistance();
    }
  }

  void _syncHrFromPercent() {
    final pct = double.tryParse(_hrPct.text) ?? 0;
    final age = int.tryParse(_age.text) ?? 0;
    if (pct > 0 && age > 0) {
      final hrmax = _svc.hrMaxTanaka(age);
      _hrBpm.text = _svc.bpmFromPercent(hrPercent: pct, hrMax: hrmax).toString();
    }
  }

  void _syncHrFromBpm() {
    final bpm = int.tryParse(_hrBpm.text) ?? 0;
    final age = int.tryParse(_age.text) ?? 0;
    if (bpm > 0 && age > 0) {
      final hrmax = _svc.hrMaxTanaka(age);
      _hrPct.text = _svc.percentFromBpm(hrBpm: bpm, hrMax: hrmax).toStringAsFixed(1);
    }
  }

  List<Series> createSeries(int currentSeriesCount) {
    final sets = int.tryParse(_sets.text) ?? 1;
    final h = int.tryParse(_hours.text) ?? 0;
    final m = int.tryParse(_minutes.text) ?? 0;
    final duration = (h == 0 && m == 0) ? null : (h * 3600 + m * 60);
    final distance = int.tryParse(_distance.text);
    final speed = double.tryParse(_speed.text);
    final pace = int.tryParse(_pace.text);
    final incline = double.tryParse(_incline.text);
    final hrPct = double.tryParse(_hrPct.text);
    final hrBpm = int.tryParse(_hrBpm.text);
    final kcal = int.tryParse(_kcal.text);
    
    // HIIT fields
    final workMin = int.tryParse(_workMinutes.text) ?? 0;
    final workSec = int.tryParse(_workSeconds.text) ?? 0;
    final workInterval = (workMin * 60) + workSec;
    final restMin = int.tryParse(_restMinutes.text) ?? 0;
    final restSec = int.tryParse(_restSeconds.text) ?? 0;
    final restInterval = (restMin * 60) + restSec;
    final rounds = int.tryParse(_rounds.text);

    final list = <Series>[];
    final exist = widget.currentSeriesGroup ?? const <Series>[];
    for (int i = 0; i < sets; i++) {
      if (i < exist.length) {
        final e = exist[i];
        list.add(
          e.copyWith(
            reps: 0,
            sets: 1,
            weight: 0,
            durationSeconds: duration ?? e.durationSeconds,
            distanceMeters: distance ?? e.distanceMeters,
            speedKmh: speed ?? e.speedKmh,
            paceSecPerKm: pace ?? e.paceSecPerKm,
            inclinePercent: incline ?? e.inclinePercent,
            hrPercent: hrPct ?? e.hrPercent,
            hrBpm: hrBpm ?? e.hrBpm,
            kcal: kcal ?? e.kcal,
            workIntervalSeconds: workInterval > 0 ? workInterval : e.workIntervalSeconds,
            restIntervalSeconds: restInterval > 0 ? restInterval : e.restIntervalSeconds,
            rounds: rounds ?? e.rounds,
            cardioType: _cardioType,
          ),
        );
      } else {
        list.add(
          Series(
            serieId: generateRandomId(16),
            exerciseId: widget.originalExerciseId ?? '',
            order: i,
            reps: 0,
            sets: 1,
            weight: 0,
            durationSeconds: duration,
            distanceMeters: distance,
            speedKmh: speed,
            paceSecPerKm: pace,
            inclinePercent: incline,
            hrPercent: hrPct,
            hrBpm: hrBpm,
            kcal: kcal,
            workIntervalSeconds: workInterval > 0 ? workInterval : null,
            restIntervalSeconds: restInterval > 0 ? restInterval : null,
            rounds: rounds,
            cardioType: _cardioType,
          ),
        );
      }
    }
    return list;
  }
}

class SeriesFormController {
  final TextEditingController repsController = TextEditingController();
  final TextEditingController maxRepsController = TextEditingController();
  final TextEditingController setsController = TextEditingController();
  final TextEditingController intensityController = TextEditingController();
  final TextEditingController maxIntensityController = TextEditingController();
  final TextEditingController rpeController = TextEditingController();
  final TextEditingController maxRpeController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController maxWeightController = TextEditingController();

  final FocusNode repsNode = FocusNode();
  final FocusNode maxRepsNode = FocusNode();
  final FocusNode setsNode = FocusNode();
  final FocusNode intensityNode = FocusNode();
  final FocusNode maxIntensityNode = FocusNode();
  final FocusNode rpeNode = FocusNode();
  final FocusNode maxRpeNode = FocusNode();
  final FocusNode weightNode = FocusNode();
  final FocusNode maxWeightNode = FocusNode();

  final List<Series>? currentSeriesGroup;
  final bool isIndividualEdit;
  final num latestMaxWeight;
  final String? originalExerciseId;

  SeriesFormController({
    this.currentSeriesGroup,
    required this.isIndividualEdit,
    required this.latestMaxWeight,
    this.originalExerciseId,
  }) {
    if (currentSeriesGroup != null && currentSeriesGroup!.isNotEmpty) {
      final firstSeries = currentSeriesGroup!.first;
      repsController.text = firstSeries.reps.toString();
      setsController.text = currentSeriesGroup!.length.toString();
      intensityController.text = firstSeries.intensity ?? '';
      rpeController.text = firstSeries.rpe ?? '';
      weightController.text = firstSeries.weight.toString();

      if (firstSeries.maxReps != null) {
        maxRepsController.text = firstSeries.maxReps.toString();
      }
      if (firstSeries.maxIntensity != null) {
        maxIntensityController.text = firstSeries.maxIntensity!;
      }
      if (firstSeries.maxRpe != null) {
        maxRpeController.text = firstSeries.maxRpe!;
      }
      if (firstSeries.maxWeight != null) {
        maxWeightController.text = firstSeries.maxWeight.toString();
      }
    }
  }

  void dispose() {
    repsController.dispose();
    maxRepsController.dispose();
    setsController.dispose();
    intensityController.dispose();
    maxIntensityController.dispose();
    rpeController.dispose();
    maxRpeController.dispose();
    weightController.dispose();
    maxWeightController.dispose();

    repsNode.dispose();
    maxRepsNode.dispose();
    setsNode.dispose();
    intensityNode.dispose();
    maxIntensityNode.dispose();
    rpeNode.dispose();
    maxRpeNode.dispose();
    weightNode.dispose();
    maxWeightNode.dispose();
  }

  void updateWeightFromIntensity() {
    final intensity = double.tryParse(intensityController.text) ?? 0.0;
    if (intensity > 0) {
      final weight = (latestMaxWeight * intensity / 100).toStringAsFixed(1);
      weightController.text = weight;
    }
  }

  void updateIntensityFromWeight() {
    final weight = double.tryParse(weightController.text) ?? 0.0;
    if (weight > 0 && latestMaxWeight > 0) {
      final intensity = ((weight / latestMaxWeight) * 100).toStringAsFixed(1);
      intensityController.text = intensity;
    }
  }

  void updateMaxWeightFromMaxIntensity() {
    final maxIntensity = double.tryParse(maxIntensityController.text) ?? 0.0;
    if (maxIntensity > 0) {
      final maxWeight = (latestMaxWeight * maxIntensity / 100).toStringAsFixed(1);
      maxWeightController.text = maxWeight;
    }
  }

  void updateMaxIntensityFromMaxWeight() {
    final maxWeight = double.tryParse(maxWeightController.text) ?? 0.0;
    if (maxWeight > 0 && latestMaxWeight > 0) {
      final maxIntensity = ((maxWeight / latestMaxWeight) * 100).toStringAsFixed(1);
      maxIntensityController.text = maxIntensity;
    }
  }

  void updateRelatedFields() {
    // Questo metodo rimane per compatibilità ma non fa nulla
    // poiché ora gestiamo gli aggiornamenti in modo più specifico
  }

  List<Series> createSeries(int currentSeriesCount) {
    final reps = int.tryParse(repsController.text) ?? 0;
    final maxReps = int.tryParse(maxRepsController.text);
    final sets = int.tryParse(setsController.text) ?? 1;
    final intensity = intensityController.text;
    final maxIntensity = maxIntensityController.text;
    final rpe = rpeController.text;
    final maxRpe = maxRpeController.text;
    final weight = double.tryParse(weightController.text) ?? 0.0;
    final maxWeight = double.tryParse(maxWeightController.text);

    List<Series> newSeries = [];

    // Prima aggiungiamo le serie esistenti mantenendo i loro valori
    if (currentSeriesGroup != null) {
      for (int i = 0; i < currentSeriesGroup!.length && i < sets; i++) {
        var existingSeries = currentSeriesGroup![i];
        newSeries.add(
          Series(
            id: existingSeries.id,
            serieId: existingSeries.serieId,
            originalExerciseId: existingSeries.originalExerciseId,
            exerciseId: existingSeries.exerciseId,
            reps: reps,
            maxReps: maxReps,
            sets: 1,
            intensity: intensity,
            maxIntensity: maxIntensity.isNotEmpty ? maxIntensity : null,
            rpe: rpe,
            maxRpe: maxRpe.isNotEmpty ? maxRpe : null,
            weight: weight,
            maxWeight: maxWeight,
            order: i,
            done: existingSeries.done,
            repsDone: existingSeries.repsDone,
            weightDone: existingSeries.weightDone,
          ),
        );
      }
    }

    // Poi aggiungiamo le nuove serie se necessario
    for (int i = (currentSeriesGroup?.length ?? 0); i < sets; i++) {
      newSeries.add(
        Series(
          serieId: generateRandomId(16),
          exerciseId: originalExerciseId ?? '',
          originalExerciseId: originalExerciseId,
          reps: reps,
          maxReps: maxReps,
          sets: 1,
          intensity: intensity,
          maxIntensity: maxIntensity.isNotEmpty ? maxIntensity : null,
          rpe: rpe,
          maxRpe: maxRpe.isNotEmpty ? maxRpe : null,
          weight: weight,
          maxWeight: maxWeight,
          order: i,
          done: false,
          repsDone: 0,
          weightDone: 0.0,
        ),
      );
    }

    return newSeries;
  }
}
