# Piano Implementazione: Esercizi a Corpo Libero + AMRAP

## 🎯 **OBIETTIVI**
1. **Supporto esercizi senza peso** (bodyweight): checkbox in TrainingBuilder, UI adattata in Viewer
2. **Supporto Max Reps (AMRAP)**: validazione per qualunque numero ≥ minimo
3. **Supporto Min Reps**: validazione per qualunque numero ≥ minimo
4. **Adeguamento UI**: cards e dialogs adattati per nuove tipologie

## 📋 **ANALISI SITUAZIONE ATTUALE**

### **Modelli Esistenti**
- ✅ **Series Model** già supporta `maxReps` 
- ✅ **Exercise Model** ha campo `type` per differenziare tipologie
- ✅ **Validation Logic** in `_isStrictlyDone()` considera già range min-max per reps/weight

### **Problemi da Risolvere**
- ❌ **Cardio Display**: esercizi cardio non mostrati correttamente in workout_details
- ❌ **Bodyweight Support**: manca supporto per esercizi senza peso
- ❌ **AMRAP Support**: manca supporto per serie "a esaurimento"

## 🔧 **IMPLEMENTAZIONE**

### **FASE 1: Database Schema Changes**

#### **Exercise Model Extensions** (`lib/shared/models/exercise.dart`)
```dart
class Exercise {
  final bool isBodyweight;        // TRUE per esercizi a corpo libero
  final String? repType;          // 'fixed', 'range', 'min_reps', 'amrap'
  
  // Costruttore aggiornato con nuovi campi
  const Exercise({
    // ... campi esistenti
    this.isBodyweight = false,
    this.repType = 'fixed',
  });
}
```

#### **Series Model Extensions** (`lib/shared/models/series.dart`)
```dart
class Series {
  // Campi già esistenti da sfruttare:
  final int reps;           // Reps minime (per min_reps e amrap)
  final int? maxReps;       // Reps massime (per range e amrap unlimited)
  final double weight;      // 0.0 per bodyweight
  final double? maxWeight;  // null per bodyweight
  
  // Nuovo campo per gestire logiche speciali
  final String? seriesType; // 'standard', 'amrap', 'min_reps'
  
  // Costruttore aggiornato
  const Series({
    // ... campi esistenti
    this.seriesType = 'standard',
  });
}
```

### **FASE 2: TrainingBuilder UI Changes**

#### **Exercise Creation Dialog** (`lib/trainingBuilder/dialog/add_exercise_dialog.dart`)
```dart
// Aggiungere checkbox per bodyweight
Widget _buildBodyweightCheckbox() {
  return CheckboxListTile(
    title: Text('Esercizio a corpo libero'),
    subtitle: Text('Senza peso aggiuntivo'),
    value: _isBodyweight,
    onChanged: (value) => setState(() => _isBodyweight = value ?? false),
  );
}
```

#### **Series Dialog** (`lib/trainingBuilder/presentation/widgets/dialogs/series_dialog.dart`)
```dart
// Aggiungere selector per tipo serie
Widget _buildSeriesTypeSelector() {
  return DropdownButtonFormField<String>(
    value: _seriesType,
    items: [
      DropdownMenuItem(value: 'standard', child: Text('Serie Standard')),
      DropdownMenuItem(value: 'min_reps', child: Text('Minimo Reps')),
      DropdownMenuItem(value: 'amrap', child: Text('AMRAP (Max Reps)')),
    ],
    onChanged: (value) => setState(() => _seriesType = value ?? 'standard'),
  );
}

// Logica condizionale per campi peso
Widget _buildWeightFields() {
  if (widget.isBodyweight) return SizedBox.shrink();
  return Column(/* campi peso esistenti */);
}
```

### **FASE 3: Viewer UI Changes**

#### **Series List** (`lib/Viewer/presentation/widgets/workout_details/series_list.dart`)
```dart
// Aggiornare header colonne
SeriesHeader(
  labels: _getExerciseType(exercise) == 'bodyweight'
    ? const ['#', 'Reps', 'Tipo', 'Fatti']     // Senza peso
    : _getExerciseType(exercise) == 'cardio'
    ? const ['#', 'Durata', 'Distanza', 'Effettivo']  // Cardio
    : const ['#', 'Reps', 'Peso', 'Fatti'],    // Con peso
),

// Aggiornare display serie per bodyweight
Widget _buildRepsColumn(Series series) {
  if (series.seriesType == 'amrap') {
    return _pill(context, 
      label: '${series.reps}+', 
      icon: Icons.trending_up
    );
  } else if (series.seriesType == 'min_reps') {
    return _pill(context,
      label: '${series.reps}+',
      icon: Icons.add_circle_outline
    );
  }
  return _pill(context,
    label: _formatRepsRange(context, series.reps, series.maxReps),
    icon: Icons.repeat
  );
}
```

#### **Series Execution Dialog** (`lib/Viewer/presentation/widgets/workout_details/series_execution_dialog.dart`)
```dart
// Aggiungere dialog specializzato per bodyweight
Future<void> showBodyweightSeriesExecutionDialog({
  required BuildContext context,
  required int initialReps,
  required String seriesType,
  required Future<void> Function(int repsDone) onSave,
}) async {
  final repsController = TextEditingController(text: initialReps.toString());
  
  return showAppDialog(
    context: context,
    title: Text(seriesType == 'amrap' ? 'AMRAP - Max Reps' : 'Reps Fatte'),
    child: TextField(
      controller: repsController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Reps effettuate',
        helperText: seriesType == 'amrap' ? 'Fai il massimo!' : null,
      ),
    ),
    actions: [/* standard actions */],
  );
}
```

### **FASE 4: Validation Logic**

#### **Updated Validation** (`lib/Viewer/presentation/widgets/workout_details/series_list.dart`)
```dart
String _getExerciseType(Exercise exercise) {
  if (exercise.type.toLowerCase() == 'cardio') return 'cardio';
  if (exercise.isBodyweight == true) return 'bodyweight';
  return 'weight';
}

bool _isStrictlyDone(Series s, String exerciseType) {
  switch (exerciseType) {
    case 'cardio':
      return _isCardioDone(s);
    case 'bodyweight':
      return _isBodyweightDone(s);
    case 'weight':
    default:
      return _isWeightDone(s);
  }
}

bool _isBodyweightDone(Series s) {
  switch (s.seriesType) {
    case 'amrap':
    case 'min_reps':
      return s.repsDone >= s.reps; // Qualsiasi numero >= minimo
    case 'standard':
    default:
      return s.maxReps != null
        ? (s.repsDone >= s.reps && s.repsDone <= s.maxReps)
        : (s.repsDone >= s.reps);
  }
}

bool _isWeightDone(Series s) {
  final bool repsOk = s.maxReps != null
    ? (s.repsDone >= s.reps && s.repsDone <= s.maxReps)
    : (s.repsDone >= s.reps);
  final bool weightOk = s.weightDone >= s.weight;
  return repsOk && weightOk;
}
```

### **FASE 5: Notifier Updates**

#### **Workout Details Notifier** (`lib/Viewer/presentation/notifiers/workout_details_notifier.dart`)
```dart
// Aggiungere metodo per completare serie bodyweight
Future<void> completeBodyweightSeries(
  Series series, {
  required int repsDone,
}) async {
  final updated = series.copyWith(
    done: true,
    isCompleted: true,
    repsDone: repsDone,
    weightDone: 0.0, // Bodyweight = 0 peso
  );
  
  await _workoutRepository.updateSeries(updated);
  await refreshWorkout();
}
```

## 📁 **FILES TO MODIFY**

### **Core Models**
- ✅ `lib/shared/models/exercise.dart` - Add `isBodyweight`, `repType`
- ✅ `lib/shared/models/series.dart` - Add `seriesType`

### **TrainingBuilder**
- ✅ `lib/trainingBuilder/dialog/add_exercise_dialog.dart` - Bodyweight checkbox
- ✅ `lib/trainingBuilder/presentation/widgets/dialogs/series_dialog.dart` - Series type selector

### **Viewer**
- ✅ `lib/Viewer/presentation/widgets/workout_details/series_list.dart` - Validation + UI
- ✅ `lib/Viewer/presentation/widgets/workout_details/series_execution_dialog.dart` - Bodyweight dialog
- ✅ `lib/Viewer/presentation/notifiers/workout_details_notifier.dart` - Completion methods

## 🔄 **MIGRATION STRATEGY**

### **Backward Compatibility**
- Tutti i campi nuovi hanno valori di default
- `isBodyweight = false` per esercizi esistenti
- `seriesType = 'standard'` per serie esistenti
- `repType = 'fixed'` per esercizi esistenti

### **Database Migration**
```dart
// Migration automatica via default values
Exercise.fromMap(map) {
  return Exercise(
    // ... campi esistenti
    isBodyweight: map['isBodyweight'] ?? false,
    repType: map['repType'] ?? 'fixed',
  );
}

Series.fromFirestore(doc) {
  return Series(
    // ... campi esistenti
    seriesType: data['seriesType'] ?? 'standard',
  );
}
```

## 🎯 **UX FLOW**

### **TrainingBuilder Flow**
1. **Creazione Esercizio** → Check "Bodyweight" → Nasconde campi peso
2. **Serie Standard** → Input reps minime-massime + peso
3. **Serie AMRAP** → Input reps minime + "+" indicator
4. **Serie Min Reps** → Input reps minime con validazione ≥ valore

### **Viewer Flow**  
1. **Visualizzazione** → Colonne adattate per tipo esercizio
2. **Cardio** → Durata/Distanza/Effettivo
3. **Bodyweight** → Reps/Tipo/Fatti (no peso)
4. **Weight** → Reps/Peso/Fatti
5. **Esecuzione** → Dialog specializzati per tipo
6. **Validazione** → Logica specifica per ogni tipo

## ✅ **TESTING CHECKLIST**

- [ ] Exercise creation con bodyweight checkbox
- [ ] Series creation con type selector
- [ ] Cardio exercises display correttamente
- [ ] Bodyweight exercises nascondono campi peso
- [ ] AMRAP validation accetta qualsiasi numero ≥ minimo
- [ ] Min Reps validation accetta qualsiasi numero ≥ minimo
- [ ] Standard validation funziona come prima
- [ ] Backward compatibility con dati esistenti
- [ ] Flutter analyze senza errori
- [ ] Build e deploy funzionanti

## 🚀 **DEPLOYMENT STEPS**

1. **Implement Changes** → Seguire ordine fasi 1-5
2. **Test Implementation** → Verificare tutti i casi d'uso
3. **Flutter Analyze** → Risolvere tutti lint/warnings
4. **Git Commit** → Commit con messaggio descrittivo
5. **Git Push** → Push al repository
6. **Firebase Deploy** → Deploy in produzione

---

**Priority**: 🔴 **HIGH** - Richiesto per supporto completo esercizi bodyweight e AMRAP
**Estimated Time**: 6-8 ore sviluppo + test + deploy
**Breaking Changes**: ❌ **NONE** - Completamente backward compatible