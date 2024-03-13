// authScreen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'usersServices.dart';

final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

class AuthScreen extends HookConsumerWidget {
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLogin = useState(true);
    final userEmail = useState('');
    final userPassword = useState('');
    final userName = useState('');
    final userGender = useState('');

    final auth = ref.watch(authProvider);
    final googleSignIn = ref.watch(googleSignInProvider);
    final firestore = ref.watch(firestoreProvider);
    final usersService = ref.read(usersServiceProvider);

    return Scaffold(
      key: scaffoldMessengerKey,
      appBar: AppBar(title: Text(isLogin.value ? 'Login' : 'Sign Up')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AuthForm(
              formKey: formKey,
              isLogin: isLogin,
              auth: auth,
              googleSignIn: googleSignIn,
              firestore: firestore,
              usersService: usersService,
              userEmail: userEmail,
              userPassword: userPassword,
              userName: userName,
              userGender: userGender,
              scaffoldMessengerKey: scaffoldMessengerKey,
            ),
          ),
        ),
      ),
    );
  }
}

class AuthForm extends HookConsumerWidget {
  const AuthForm({
    super.key,
    required this.formKey,
    required this.isLogin,
    required this.auth,
    required this.googleSignIn,
    required this.firestore,
    required this.usersService,
    required this.userEmail,
    required this.userPassword,
    required this.userName,
    required this.userGender,
    required this.scaffoldMessengerKey,
  });

  final GlobalKey<FormState> formKey;
  final ValueNotifier<bool> isLogin;
  final FirebaseAuth auth;
  final GoogleSignIn googleSignIn;
  final FirebaseFirestore firestore;
  final UsersService usersService;
  final ValueNotifier<String> userEmail;
  final ValueNotifier<String> userPassword;
  final ValueNotifier<String> userName;
  final ValueNotifier<String> userGender;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLogin.value) UsernameField(userName: userName),
          const SizedBox(height: 10),
          if (!isLogin.value) GenderField(userGender: userGender),
          const SizedBox(height: 10),
          EmailField(userEmail: userEmail),
          const SizedBox(height: 10),
          PasswordField(userPassword: userPassword),
          const SizedBox(height: 20),
          SubmitButton(
            formKey: formKey,
            isLogin: isLogin,
            auth: auth,
            firestore: firestore,
            usersService: usersService,
            userEmail: userEmail,
            userPassword: userPassword,
            userName: userName,
            userGender: userGender,
            ref: ref,
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
          ToggleAuthModeButton(isLogin: isLogin),
          GoogleSignInButton(
            googleSignIn: googleSignIn,
            firestore: firestore,
            usersService: usersService,
            scaffoldMessengerKey: scaffoldMessengerKey, // Passa la chiave del messaggero di Scaffold
          ),
        ],
      ),
    );
  }
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.formKey,
    required this.isLogin,
    required this.auth,
    required this.firestore,
    required this.usersService,
    required this.userEmail,
    required this.userPassword,
    required this.userName,
    required this.userGender,
    required this.ref,
    required this.scaffoldMessengerKey,
  });

  final GlobalKey<FormState> formKey;
  final ValueNotifier<bool> isLogin;
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final UsersService usersService;
  final ValueNotifier<String> userEmail;
  final ValueNotifier<String> userPassword;
  final ValueNotifier<String> userName;
  final ValueNotifier<String> userGender;
  final WidgetRef ref;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => submit(context),
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
      child: Text(isLogin.value ? 'Login' : 'Sign Up'),
    );
  }

  Future<void> submit(BuildContext context) async {
    bool widgetMounted = true; // Flag to track if the widget is still mounted

    void showSnackBar(SnackBar snackBar) {
      if (widgetMounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
      }
    }

    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      final email = userEmail.value.trim();
      final password = userPassword.value.trim();
      try {
        UserCredential userCredential;
        if (isLogin.value) {
          userCredential = await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          await usersService.setUserRole(userCredential.user!.uid);
        } else {
          userCredential = await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          final user = userCredential.user;
          if (user != null) {
            await firestore.collection('users').doc(user.uid).set({
              'address': '',
              'currentProgram': '',
              'displayName': userName.value,
              'email': email,
              'gender': userGender.value,
              'id': user.uid,
              'name': userName.value,
              'phoneNumber': null,
              'photoURL': user.photoURL ?? '',
              'role': 'client',
              'socialLinks': {'facebook': '', 'twitter': ''},
            });
            await user.updateDisplayName(userName.value);
            await usersService.setUserRole(user.uid);
          }
        }

        final updatedUser = auth.currentUser;
        if (updatedUser != null) {
          usersService.updateUserName(updatedUser.displayName);
        }

        showSnackBar(
          const SnackBar(
            content: Text('Authentication successful'),
            backgroundColor: Colors.green,
          ),
        );
      } on FirebaseAuthException catch (error) {
        showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'An error occurred, please try again'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        widgetMounted = false;
      }
    }
  }
}

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.googleSignIn,
    required this.firestore,
    required this.usersService,
    required this.scaffoldMessengerKey, // Aggiungi il parametro scaffoldMessengerKey
  });

  final GoogleSignIn googleSignIn;
  final FirebaseFirestore firestore;
  final UsersService usersService;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey; // Variabile per il messaggero di Scaffold

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          final user = await googleSignIn.signIn();
          if (user != null) {
            final googleAuth = await user.authentication;
            final credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );
            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

            // Crea un documento nella collezione "users" di Firestore
            await firestore.collection('users').doc(userCredential.user!.uid).set({
              'address': '',
              'currentProgram': '',
              'displayName': userCredential.user!.displayName,
              'email': userCredential.user!.email,
              'gender': '',
              'id': userCredential.user!.uid,
              'name': userCredential.user!.displayName,
              'phoneNumber': null,
              'photoURL': userCredential.user!.photoURL ?? '',
              'role': 'client', // Imposta il ruolo di default a "client"
              'socialLinks': {'facebook': '', 'twitter': ''},
            });

            // Aggiorna il ruolo dell'utente dopo il login con Google
            await usersService.setUserRole(userCredential.user!.uid);

            // Mostra lo SnackBar utilizzando il messaggero di Scaffold
            scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(
                content: Text('Google Sign-In successful'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (error) {
          // Mostra lo SnackBar utilizzando il messaggero di Scaffold
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Failed to sign in with Google: $error'),
              backgroundColor: Colors.red,
            ),
          );
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

class ToggleAuthModeButton extends StatelessWidget {
  const ToggleAuthModeButton({super.key, required this.isLogin});

  final ValueNotifier<bool> isLogin;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(isLogin.value ? 'Create new account' : 'I already have an account'),
      onPressed: () => isLogin.value = !isLogin.value,
    );
  }
}

class UsernameField extends StatelessWidget {
  const UsernameField({super.key, required this.userName});

  final ValueNotifier<String> userName;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const ValueKey('username'),
      validator: (value) =>
          (value == null || value.isEmpty || value.length < 4) ? 'Please enter at least 4 characters' : null,
      decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
      onSaved: (value) => userName.value = value ?? '',
    );
  }
}

class GenderField extends StatelessWidget {
  const GenderField({super.key, required this.userGender});

  final ValueNotifier<String> userGender;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: const ValueKey('gender'),
      value: userGender.value,
      onChanged: (value) => userGender.value = value ?? '',
      decoration: const InputDecoration(
        labelText: 'Gender',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: '',
          child: Text('Select Gender'),
        ),
        DropdownMenuItem(
          value: 'Male',
          child: Text('Male'),
        ),
        DropdownMenuItem(
          value: 'Female',
          child: Text('Female'),
        ),
        DropdownMenuItem(
          value: 'Other',
          child: Text('Other'),
        ),
      ],
    );
  }
}

class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.userEmail});

  final ValueNotifier<String> userEmail;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const ValueKey('email'),
      validator: (value) => (value == null || value.isEmpty || !value.contains('@'))
          ? 'Please enter a valid email address'
          : null,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(labelText: 'Email address', border: OutlineInputBorder()),
      onSaved: (value) => userEmail.value = value ?? '',
    );
  }
}

class PasswordField extends StatelessWidget {
  const PasswordField({super.key, required this.userPassword});

  final ValueNotifier<String> userPassword;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const ValueKey('password'),
      validator: (value) => (value == null || value.isEmpty || value.length < 7)
          ? 'Password must be at least 7 characters long'
          : null,
      decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
      obscureText: true,
      onSaved: (value) => userPassword.value = value ?? '',
    );
  }
}