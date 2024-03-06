import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Definizione del modello User per rappresentare i dati degli utenti
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  // Metodo factory per creare un'istanza di UserModel da un documento Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
    );
  }
}

// Definizione del provider di servizi per gli utenti
final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService(FirebaseFirestore.instance);
});

// Definizione della classe di servizi per gli utenti
class UsersService {
  final FirebaseFirestore _firestore;

  UsersService(this._firestore);

  // Metodo per ottenere lo stream di tutti gli utenti
  Stream<List<UserModel>> getUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }
}
