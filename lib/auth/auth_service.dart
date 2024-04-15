// auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../users_services.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref));

class AuthService {
  AuthService(this.ref);

  final Ref ref;

  FirebaseAuth get auth => FirebaseAuth.instance;
  GoogleSignIn get googleSignIn => GoogleSignIn();
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  UsersService get usersService => ref.read(usersServiceProvider);

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    final userCredential = await auth.signInWithEmailAndPassword(
        email: email, password: password);
    await usersService.setUserRole(userCredential.user!.uid);
    return userCredential;
  }

  Future<UserCredential> signUpWithEmailAndPassword(String email,
      String password, String userName, String userGender) async {
    final userCredential = await auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = userCredential.user;
    if (user != null) {
      await firestore.collection('users').doc(user.uid).set({
        'address': '',
        'currentProgram': '',
        'displayName': userName,
        'email': email,
        'gender': userGender,
        'id': user.uid,
        'name': userName,
        'phoneNumber': null,
        'photoURL': user.photoURL ?? '',
        'role': 'client',
        'socialLinks': {'facebook': '', 'twitter': ''},
      });
      await user.updateDisplayName(userName);
      await usersService.setUserRole(user.uid);
    }
    return userCredential;
  }

  Future<UserCredential?> signInWithGoogle() async {
    final user = await googleSignIn.signIn();
    if (user != null) {
      final googleAuth = await user.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await auth.signInWithCredential(credential);
      await updateUserDataIfNeeded(userCredential.user!);
      return userCredential;
    }
    return null;
  }

  Future<void> updateUserDataIfNeeded(User user) async {
    final userDocRef = firestore.collection('users').doc(user.uid);
    final userDocSnapshot = await userDocRef.get();
    if (!userDocSnapshot.exists) {
      await userDocRef.set({
        'address': '',
        'currentProgram': '',
        'displayName': user.displayName,
        'email': user.email,
        'gender': '',
        'id': user.uid,
        'name': user.displayName,
        'phoneNumber': null,
        'photoURL': user.photoURL ?? '',
        'role': 'client',
        'socialLinks': {'facebook': '', 'twitter': ''},
      });
    }
    await usersService.setUserRole(user.uid);
  }

  Future<void> updateUserName(User? user) async {
    if (user != null) {
      usersService.updateUserName(user.displayName);
    }
  }
}