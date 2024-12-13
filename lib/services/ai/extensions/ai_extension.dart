// lib/services/ai/extensions/ai_extension.dart
import 'package:alphanessone/models/user_model.dart';

abstract class AIExtension {
  Future<bool> canHandle(Map<String, dynamic> interpretation);
  Future<String?> handle(
      Map<String, dynamic> interpretation, String userId, UserModel user);
}
