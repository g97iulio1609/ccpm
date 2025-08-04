// Shared models, services, and utilities for training modules
// This file provides a unified export for all shared components
// used by both trainingBuilder and Viewer modules

// Models
export 'models/exercise.dart';
export 'models/series.dart';
export 'models/workout.dart';
export 'models/week.dart';
// TrainingBuilder specific models (for compatibility)
export '../trainingBuilder/models/training_model.dart';
export '../trainingBuilder/models/superseries_model.dart';
export '../trainingBuilder/models/progressions_model.dart';

// Services
export 'services/base_repository.dart';
export 'services/exercise_repository.dart';
// export 'services/workout_repository.dart'; // Commented to avoid conflict with Viewer
export 'services/week_repository.dart';

// Utils
export 'utils/validation_utils.dart';
export 'utils/format_utils.dart';
export 'utils/model_utils.dart';