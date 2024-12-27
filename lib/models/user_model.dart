import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String displayName;
  final String email;
  final String role;
  final String photoURL;
  final int gender; // Added gender field
  final String? uniqueNumber;
  final DateTime? subscriptionExpiryDate;
  final String? productId;
  final String? purchaseToken;
  final String? phoneNumber; // Add phone number field
  final DateTime? _birthdate; // Private field for birthdate
  final double? _height; // Private field for height
  final String? currentProgram; // Aggiunto campo currentProgram
  final double? activityLevel; // Activity level stored as double

  UserModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.email,
    required this.role,
    required this.photoURL,
    required this.gender, // Added gender field
    this.uniqueNumber,
    this.subscriptionExpiryDate,
    this.productId,
    this.purchaseToken,
    this.currentProgram, // Aggiunto al costruttore
    this.phoneNumber, // Add to constructor
    this.activityLevel, // Add to constructor
    DateTime? birthdate, // Add birthdate to the constructor
    double? height, // Add height to the constructor
  })  : _birthdate = birthdate,
        _height = height;

  // Factory method for creating a UserModel from Firestore data
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'client',
      photoURL: data['photoURL'] ?? '',
      gender: data['gender'] ?? 0, // Assicurati che sia numerico
      uniqueNumber: data['uniqueNumber'],
      subscriptionExpiryDate:
          (data['subscriptionExpiryDate'] as Timestamp?)?.toDate(),
      productId: data['productId'],
      purchaseToken: data['purchaseToken'],
      currentProgram: data['currentProgram'], // Aggiunto al fromFirestore
      phoneNumber: data['phoneNumber'], // Add phoneNumber to fromFirestore
      activityLevel: (data['activityLevel'] as num?)
          ?.toDouble(), // Convert to double when reading from Firestore
      birthdate: (data['birthdate'] as Timestamp?)?.toDate(),
      height: (data['height'] as num?)?.toDouble(),
    );
  }

  // Map method for converting UserModel to Firestore format
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'displayName': displayName,
      'email': email,
      'role': role,
      'photoURL': photoURL,
      'gender': gender, // Added gender field
      'uniqueNumber': uniqueNumber,
      'subscriptionExpiryDate': subscriptionExpiryDate != null
          ? Timestamp.fromDate(subscriptionExpiryDate!)
          : null,
      'productId': productId,
      'purchaseToken': purchaseToken,
      'currentProgram': currentProgram, // Aggiunto al toMap
      'phoneNumber': phoneNumber, // Add phoneNumber to toMap
      'activityLevel': activityLevel, // Add activityLevel to toMap
      'birthdate': _birthdate != null
          ? Timestamp.fromDate(_birthdate)
          : null, // Add birthdate to Firestore map
      'height': _height, // Add height to Firestore map
    };
  }

  // Getter for birthdate
  DateTime? get birthdate => _birthdate;

  // Getter for height
  double? get height => _height;
}
