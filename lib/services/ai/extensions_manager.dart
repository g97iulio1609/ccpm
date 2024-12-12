// extensions_manager.dart
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/services/ai/extensions/ai_extension.dart';
import 'package:alphanessone/services/ai/extensions/maxrm_extension.dart';
import 'package:alphanessone/services/ai/extensions/profile_extension.dart';
import 'package:alphanessone/services/ai/extensions/training_extension.dart';


class ExtensionsManager {
  final List<AIExtension> _extensions = [
    MaxRMExtension(),
    ProfileExtension(),
    TrainingExtension(),
  ];

  Future<String?> executeAction(Map<String, dynamic> interpretation, UserModel user) async {
    final featureType = interpretation['featureType'];
    if (featureType == null) return null;

    final userId = user.id;
    for (var ext in _extensions) {
      if (await ext.canHandle(interpretation)) {
        final result = await ext.handle(interpretation, userId!, user);
        return result;
      }
    }

    return null;
  }
}
