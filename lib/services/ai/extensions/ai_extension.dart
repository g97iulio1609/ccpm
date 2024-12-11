import 'package:alphanessone/models/user_model.dart';

abstract class AIExtension {
  /// Determina se l'estensione può gestire l'interpretazione fornita.
  Future<bool> canHandle(Map<String, dynamic> interpretation);

  /// Gestisce la richiesta. Se non riesce a produrre una risposta, ritorna null
  /// in modo che il flusso principale possa ripiegare sull'AI.
  /// `interpretation` è il JSON interpretato dall'AI.
  /// `userId` è l'ID dell'utente corrente.
  /// `user` è il profilo dell'utente.
  Future<String?> handle(
      Map<String, dynamic> interpretation, String userId, UserModel user);
}
