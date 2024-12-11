import 'package:alphanessone/models/user_model.dart';

abstract class AIExtension {
  /// Determina se l'estensione può gestire l'interpretazione fornita.
  Future<bool> canHandle(Map<String, dynamic> interpretation);

  /// Gestisce la richiesta e restituisce una stringa di risposta da mostrare all'utente.
  /// `interpretation` è il JSON interpretato dall'AI.
  /// `userId` è l'ID dell'utente corrente.
  /// `user` è il profilo dell'utente.
  Future<String> handle(
      Map<String, dynamic> interpretation, String userId, UserModel user);
}// TODO Implement this library.