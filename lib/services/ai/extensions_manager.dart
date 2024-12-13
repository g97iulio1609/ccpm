// lib/services/ai/extensions_manager.dart
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/services/ai/extensions/ai_extension.dart';
import 'package:alphanessone/services/ai/extensions/maxrm_extension.dart';
import 'package:alphanessone/services/ai/extensions/profile_extension.dart';
import 'package:alphanessone/services/ai/extensions/training_extension.dart';
import 'package:logger/logger.dart';

class ExtensionsManager {
  final Logger _logger = Logger();
  final List<AIExtension> _extensions = [
    MaxRMExtension(),
    ProfileExtension(),
    TrainingExtension(),
  ];

  Future<String?> executeAction(
      Map<String, dynamic> interpretation, UserModel user) async {
    final featureType = interpretation['featureType'];
    _logger.d('Executing action for featureType: $featureType');

    if (featureType == null) return null;

    final userId = user.id;
    for (var ext in _extensions) {
      if (await ext.canHandle(interpretation)) {
        _logger.d(
            'Found handler for featureType: $featureType -> ${ext.runtimeType}');
        try {
          final result = await ext.handle(interpretation, userId, user);
          _logger.d('Extension (${ext.runtimeType}) result: $result');
          return result;
        } catch (e, stackTrace) {
          _logger.e('Error executing extension (${ext.runtimeType})',
              error: e, stackTrace: stackTrace);
          return null;
        }
      }
    }

    _logger.w('No handler found for featureType: $featureType');
    return null;
  }
}
