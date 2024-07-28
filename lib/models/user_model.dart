import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String displayName;
  final String email;
  final String role;
  final String photoURL;
  final String? uniqueNumber;
  final DateTime? subscriptionExpiryDate;
  final String? productId;
  final String? purchaseToken;

  UserModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.email,
    required this.role,
    required this.photoURL,
    this.uniqueNumber,
    this.subscriptionExpiryDate,
    this.productId,
    this.purchaseToken,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'client',
      photoURL: data['photoURL'] ?? '',
      uniqueNumber: data['uniqueNumber'],
      subscriptionExpiryDate: (data['subscriptionExpiryDate'] as Timestamp?)?.toDate(),
      productId: data['productId'],
      purchaseToken: data['purchaseToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'displayName': displayName,
      'email': email,
      'role': role,
      'photoURL': photoURL,
      'uniqueNumber': uniqueNumber,
      'subscriptionExpiryDate': subscriptionExpiryDate != null ? Timestamp.fromDate(subscriptionExpiryDate!) : null,
      'productId': productId,
      'purchaseToken': purchaseToken,
    };
  }
}
