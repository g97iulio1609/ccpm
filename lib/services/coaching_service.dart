import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final coachingServiceProvider = Provider<CoachingService>((ref) {
  return CoachingService(FirebaseFirestore.instance);
});

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

  Stream<List<Association>> getUserAssociations(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('coaching')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Association.fromFirestore(doc))
            .toList());
  }

  Future<bool> requestAssociation(String coachId, String athleteId) async {
    try {
      final associationRef = _firestore
          .collection('users')
          .doc(coachId)
          .collection('coaching')
          .doc();
      await associationRef.set(Association(
        id: associationRef.id,
        coachId: coachId,
        athleteId: athleteId,
        status: 'pending',
      ).toMap());
      return true;
    } catch (e) {
      debugPrint('Error requesting association: $e');
      return false;
    }
  }

  Future<bool> respondToAssociation(String coachId, String associationId, bool accept) async {
    WriteBatch batch = _firestore.batch();
    try {
      DocumentReference docRef = _firestore
          .collection('users')
          .doc(coachId)
          .collection('coaching')
          .doc(associationId);
      batch.update(docRef, {
        'status': accept ? 'accepted' : 'rejected',
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error responding to association: $e');
      return false;
    }
  }

  Future<bool> removeAssociation(String coachId, String associationId) async {
    WriteBatch batch = _firestore.batch();
    try {
      DocumentReference docRef = _firestore
          .collection('users')
          .doc(coachId)
          .collection('coaching')
          .doc(associationId);
      batch.delete(docRef);

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error removing association: $e');
      return false;
    }
  }

  Future<bool> toggleBlockAssociations(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentBlockStatus = userDoc.data()?['blockAssociations'] ?? false;
      await _firestore.collection('users').doc(userId).update({
        'blockAssociations': !currentBlockStatus,
      });
      return true;
    } catch (e) {
      debugPrint('Error toggling block associations: $e');
      return false;
    }
  }

  Future<bool> isAssociationBlocked(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['blockAssociations'] ?? false;
    } catch (e) {
      debugPrint('Error checking if association is blocked: $e');
      return false;
    }
  }

  Future<List<UserModel>> searchCoaches(String query) async {
    query = query.toLowerCase().trim();

    if (query.isEmpty) {
      return [];
    }

    final nameQuerySnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .limit(10)
        .get();

    final emailQuerySnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThan: query + 'z')
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

  Future<bool> isCoachAvailableForAssociation(String coachId) async {
    final coachDoc = await _firestore.collection('users').doc(coachId).get();
    final coachData = coachDoc.data() as Map<String, dynamic>?;

    if (coachData == null) {
      return false; // Coach non trovato
    }

    final bool isBlocked = coachData['blockAssociations'] ?? false;
    if (isBlocked) {
      return false;
    }

    final associationsQuery = await _firestore
        .collection('users')
        .doc(coachId)
        .collection('coaching')
        .where('status', isEqualTo: 'accepted')
        .get();

    final int currentAssociations = associationsQuery.docs.length;
    final int maxAssociations = coachData['maxAssociations'] ?? 10;

    return currentAssociations < maxAssociations;
  }

  Future<UserModel?> getCoachDetails(String coachId) async {
    final coachDoc = await _firestore.collection('users').doc(coachId).get();
    if (coachDoc.exists) {
      return UserModel.fromFirestore(coachDoc);
    }
    return null;
  }
}
