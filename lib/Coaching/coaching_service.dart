import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';


class Association {
  final String id;
  final String coachId;
  final String athleteId;
  final String status; // 'pending', 'accepted', 'rejected'

  Association({
    required this.id,
    required this.coachId,
    required this.athleteId,
    required this.status,
  });

  factory Association.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Association(
      id: doc.id,
      coachId: data['coachId'],
      athleteId: data['athleteId'],
      status: data['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coachId': coachId,
      'athleteId': athleteId,
      'status': status,
    };
  }
}

class CoachingService {
  final FirebaseFirestore _firestore;

  CoachingService(this._firestore);

  /// Ottiene le associazioni per un coach specifico
  Stream<List<Association>> getCoachAssociations(String coachId) {
    return _firestore
        .collection('associations')
        .where('coachId', isEqualTo: coachId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Association.fromFirestore(doc))
            .toList());
  }

  /// Ottiene le associazioni per un cliente specifico
  Stream<List<Association>> getUserAssociations(String userId) {
    return _firestore
        .collection('associations')
        .where('athleteId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Association.fromFirestore(doc))
            .toList());
  }

  /// Cerca i coach in base al nome o all'email
  Future<List<UserModel>> searchCoaches(String query) async {
    query = query.toLowerCase().trim();

    if (query.isEmpty) {
      return [];
    }

    final nameQuerySnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    final emailQuerySnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    final Set<String> uniqueIds = {};
    final List<UserModel> results = [];

    for (var doc in [...nameQuerySnapshot.docs, ...emailQuerySnapshot.docs]) {
      if (!uniqueIds.contains(doc.id)) {
        uniqueIds.add(doc.id);
        results.add(UserModel.fromFirestore(doc));
      }
    }

    results.sort((a, b) {
      if (a.name.toLowerCase().startsWith(query)) {
        return -1;
      } else if (b.name.toLowerCase().startsWith(query)) {
        return 1;
      } else {
        return a.name.compareTo(b.name);
      }
    });

    return results.take(10).toList();
  }

  /// Invia una richiesta di associazione
  Future<bool> requestAssociation(String coachId, String athleteId) async {
    try {
      // Verifica se esiste già una richiesta pendente
      final existing = await _firestore
          .collection('associations')
          .where('coachId', isEqualTo: coachId)
          .where('athleteId', isEqualTo: athleteId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existing.docs.isNotEmpty) {
        //debugPrint('Richiesta di associazione già esistente.');
        return false;
      }

      await _firestore.collection('associations').add({
        'coachId': coachId,
        'athleteId': athleteId,
        'status': 'pending',
      });
      return true;
    } catch (e) {
      //debugPrint('Error requesting association: $e');
      return false;
    }
  }

  /// Risponde a una richiesta di associazione (accetta o rifiuta)
  Future<bool> respondToAssociation(String associationId, bool accept) async {
    try {
      DocumentReference docRef =
          _firestore.collection('associations').doc(associationId);
      await docRef.update({
        'status': accept ? 'accepted' : 'rejected',
      });
      return true;
    } catch (e) {
      //debugPrint('Error responding to association: $e');
      return false;
    }
  }

  /// Rimuove un'associazione accettata
  Future<bool> removeAssociation(String associationId) async {
    try {
      await _firestore.collection('associations').doc(associationId).delete();
      return true;
    } catch (e) {
      //debugPrint('Error removing association: $e');
      return false;
    }
  }

  /// Verifica se un coach è disponibile per nuove associazioni
  Future<bool> isCoachAvailableForAssociation(String coachId) async {
    try {
      final coachDoc = await _firestore.collection('users').doc(coachId).get();
      final coachData = coachDoc.data();

      if (coachData == null) {
        return false; // Coach non trovato
      }

      final bool isBlocked = coachData['blockAssociations'] ?? false;
      if (isBlocked) {
        return false;
      }

      final associationsCount = await _firestore
          .collection('associations')
          .where('coachId', isEqualTo: coachId)
          .where('status', isEqualTo: 'accepted')
          .count()
          .get()
          .then((value) => value.count);

      final int maxAssociations = coachData['maxAssociations'] ?? 10;

      return associationsCount! < maxAssociations;
    } catch (e) {
      //debugPrint('Error checking coach availability: $e');
      return false;
    }
  }
}
