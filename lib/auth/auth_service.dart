import 'package:alphanessone/providers/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:alphanessone/services/users_services.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref));

class AuthService {
  AuthService(this.ref);

  final Ref ref;

  FirebaseAuth get auth => FirebaseAuth.instance;
  GoogleSignIn get googleSignIn => GoogleSignIn.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  UsersService get usersService => ref.read(usersServiceProvider);

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final userCredential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await usersService.setUserRole(userCredential.user!.uid);
    return userCredential;
  }

  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
    String userName,
    String userGender,
  ) async {
    // Convertire il genere in valore numerico
    int genderValue;
    switch (userGender.toLowerCase()) {
      case 'male':
        genderValue = 1;
        break;
      case 'female':
        genderValue = 2;
        break;
      default:
        genderValue = 0;
    }

    final userCredential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user != null) {
      await firestore.collection('users').doc(user.uid).set({
        'address': '',
        'currentProgram': '',
        'displayName': userName,
        'email': email,
        'gender': genderValue, // Salvare il valore numerico per il genere
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
    try {
      // Initialize GoogleSignIn if not already done
      await googleSignIn.initialize();

      // Try lightweight authentication first
      GoogleSignInAccount? googleUser;
      try {
        final result = googleSignIn.attemptLightweightAuthentication();
        if (result is Future<GoogleSignInAccount?>) {
          googleUser = await result;
        } else {
          googleUser = result as GoogleSignInAccount?;
        }
      } catch (e) {
        // If lightweight auth fails, try full authentication
        googleUser = null;
      }

      // If lightweight auth didn't work, try full authentication
      googleUser ??= await googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      await updateUserDataIfNeeded(userCredential.user!);
      return userCredential;
    } catch (error) {
      debugPrint('CHECK ERROR: Failed to sign in with Google: $error');
      return null;
    }
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

  Widget renderGoogleSignInButton(BuildContext context, String userRole) {
    return ElevatedButton(
      onPressed: () async {
        try {
          final userCredential = await signInWithGoogle();
          if (userCredential != null) {
            final userId = userCredential.user?.uid;
            if (userId != null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Google Sign-In successful'),
                    backgroundColor: Colors.green,
                  ),
                );
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (userRole == 'admin') {
                    Navigator.pushNamed(context, '/programs_screen');
                  } else {
                    Navigator.pushNamed(
                      context,
                      '/programs_screen/user_programs/$userId',
                    );
                  }
                });
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to retrieve user ID'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Google Sign-In cancelled'),
                  backgroundColor: Colors.amber,
                ),
              );
            }
          }
        } catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to sign in with Google: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
      child: const Text('Sign in with Google'),
    );
  }
}
