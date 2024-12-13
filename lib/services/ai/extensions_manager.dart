// extensions_manager.dart
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/services/ai/extensions/ai_extension.dart';
import 'package:alphanessone/services/ai/extensions/maxrm_extension.dart';
import 'package:alphanessone/services/ai/extensions/profile_extension.dart';
import 'package:alphanessone/services/ai/extensions/training_extension.dart';
import 'package:logger/logger.dart';

class ExtensionsManager {
  final _logger = Logger();
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
        _logger.d('Found handler for featureType: $featureType');
        try {
          final result = await ext.handle(interpretation, userId!, user);
          _logger.d('Extension result: $result');
          return result;
        } catch (e) {
          _logger.e('Error executing extension', error: e);
          return null;
        }
      }
    }

    _logger.w('No handler found for featureType: $featureType');
    return null;
  }
}
