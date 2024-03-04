import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Assicurati che questo sia il percorso corretto

final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());

class AuthScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLogin = useState(true);
    final userEmail = useState('');
    final userPassword = useState('');
    final userName = useState('');

    // Usa ref.watch per accedere al provider
    final FirebaseAuth auth = ref.watch(authProvider);
    final GoogleSignIn googleSignIn = ref.watch(googleSignInProvider);

    void showSnackBar(String message, bool isError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }

    Future<void> trySubmit() async {
      final isValid = formKey.currentState?.validate();
      FocusScope.of(context).unfocus();

      if (isValid ?? false) {
        formKey.currentState?.save();
        try {
          if (isLogin.value) {
            await auth.signInWithEmailAndPassword(
              email: userEmail.value.trim(),
              password: userPassword.value.trim(),
            );
          } else {
            await auth.createUserWithEmailAndPassword(
              email: userEmail.value.trim(),
              password: userPassword.value.trim(),
            );
          }
          // Non è più necessario navigare qui perché lo stato dell'utente cambia verrà rilevato dallo StreamBuilder in MyApp
          showSnackBar('Authentication successful', false);
        } on FirebaseAuthException catch (error) {
          showSnackBar(error.message ?? 'An error occurred, please try again', true);
        }
      }
    }

    Future<void> signInWithGoogle() async {
      try {
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await auth.signInWithCredential(credential);
          showSnackBar('Google Sign-In successful', false);
        }
      } catch (error) {
        showSnackBar('Failed to sign in with Google: $error', true);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin.value ? 'Login' : 'Sign Up'),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isLogin.value)
                      TextFormField(
                        key: const ValueKey('username'),
                        validator: (value) {
                          if (value!.isEmpty || value.length < 4) {
                            return 'Please enter at least 4 characters';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (value) {
                          userName.value = value!;
                        },
                      ),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const ValueKey('email'),
                      validator: (value) {
                        if (value!.isEmpty || !value.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) {
                        userEmail.value = value!;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const ValueKey('password'),
                      validator: (value) {
                        if (value!.isEmpty || value.length < 7) {
                          return 'Password must be at least 7 characters long';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      onSaved: (value) {
                        userPassword.value = value!;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: trySubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: Text(isLogin.value ? 'Login' : 'Sign Up'),
                    ),
                    TextButton(
                      child: Text(isLogin.value ? 'Create new account' : 'I already have an account'),
                      onPressed: () {
                        isLogin.value = !isLogin.value;
                      },
                    ),
                    ElevatedButton(
                      onPressed: signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text('Sign in with Google'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
