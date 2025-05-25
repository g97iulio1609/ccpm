// Barrel export file for the refactored progressions module
// This follows the principle of open/closed and facilitates maintenance

// Controllers
export 'package:alphanessone/trainingBuilder/controllers/progression_controllers.dart';

// Models
export 'package:alphanessone/trainingBuilder/models/progression_view_model.dart';

// Services
export 'package:alphanessone/trainingBuilder/services/progression_business_service.dart';

// Pages
export 'package:alphanessone/trainingBuilder/presentation/pages/progressions_list_page.dart';

// Widgets
export 'package:alphanessone/trainingBuilder/presentation/widgets/progression_field_widgets.dart';
export 'package:alphanessone/trainingBuilder/presentation/widgets/progression_table_widget.dart';
export 'package:alphanessone/trainingBuilder/presentation/widgets/week_row_widget.dart';

// Backward compatibility
export 'package:alphanessone/trainingBuilder/List/progressions_list.dart'
    show ProgressionsList, formatNumber;
