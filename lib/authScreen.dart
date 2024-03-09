import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'usersServices.dart'; // Assicurati di avere il percorso corretto per questo import

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

    final auth = ref.watch(authProvider);
    final googleSignIn = ref.watch(googleSignInProvider);

    return Scaffold(
      appBar: AppBar(title: Text(isLogin.value ? 'Login' : 'Sign Up')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AuthForm(formKey: formKey, isLogin: isLogin, auth: auth, googleSignIn: googleSignIn, userEmail: userEmail, userPassword: userPassword, userName: userName),
          ),
        ),
      ),
    );
  }
}


class AuthForm extends HookConsumerWidget { // Modificato in HookConsumerWidget
  const AuthForm({
    super.key,
    required this.formKey,
    required this.isLogin,
    required this.auth,
    required this.googleSignIn,
    required this.userEmail,
    required this.userPassword,
    required this.userName,
  });

  final GlobalKey<FormState> formKey;
  final ValueNotifier<bool> isLogin;
  final FirebaseAuth auth;
  final GoogleSignIn googleSignIn;
  final ValueNotifier<String> userEmail;
  final ValueNotifier<String> userPassword;
  final ValueNotifier<String> userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Aggiunto WidgetRef
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLogin.value) UsernameField(userName: userName),
          const SizedBox(height: 10),
          EmailField(userEmail: userEmail),
          const SizedBox(height: 10),
          PasswordField(userPassword: userPassword),
          const SizedBox(height: 20),
          SubmitButton(formKey: formKey, isLogin: isLogin, auth: auth, userEmail: userEmail, userPassword: userPassword, userName: userName, ref: ref), // Passa ref
          ToggleAuthModeButton(isLogin: isLogin),
          GoogleSignInButton(googleSignIn: googleSignIn),
        ],
      ),
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
      validator: (value) => (value == null || value.isEmpty || value.length < 4) ? 'Please enter at least 4 characters' : null,
      decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
      onSaved: (value) => userName.value = value ?? '',
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
      validator: (value) => (value == null || value.isEmpty || !value.contains('@')) ? 'Please enter a valid email address' : null,
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
      validator: (value) => (value == null || value.isEmpty || value.length < 7) ? 'Password must be at least 7 characters long' : null,
      decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
      obscureText: true,
      onSaved: (value) => userPassword.value = value ?? '',
    );
  }
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.formKey,
    required this.isLogin,
    required this.auth,
    required this.userEmail,
    required this.userPassword,
    required this.userName,
    required this.ref, // Aggiunto
  });

  final GlobalKey<FormState> formKey;
  final ValueNotifier<bool> isLogin;
  final FirebaseAuth auth;
  final ValueNotifier<String> userEmail;
  final ValueNotifier<String> userPassword;
  final ValueNotifier<String> userName;
  final WidgetRef ref; // Aggiunto

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => submit(context),
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onPrimary, backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
      child: Text(isLogin.value ? 'Login' : 'Sign Up'),
    );
  }

 Future<void> submit(BuildContext context) async {
  if (formKey.currentState?.validate() ?? false) {
    formKey.currentState?.save();
    final email = userEmail.value.trim();
    final password = userPassword.value.trim();
    try {
      UserCredential userCredential;
      if (isLogin.value) {
        userCredential = await auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        userCredential = await auth.createUserWithEmailAndPassword(email: email, password: password);
        await userCredential.user!.updateDisplayName(userName.value); // Aggiorna il nome utente dopo la registrazione
        ref.read(userNameProvider.notifier).state = userName.value; // Aggiorna lo userName nel provider subito dopo l'aggiornamento dell'utente
      }
      final updatedUser = auth.currentUser; // Ricarica l'utente aggiornato
      if (updatedUser != null) {
        ref.read(userNameProvider.notifier).state = updatedUser.displayName ?? userName.value; // Aggiorna lo userName nel provider con il displayName dell'utente o il nome utente inserito
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication successful'), backgroundColor: Colors.green));
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'An error occurred, please try again'), backgroundColor: Colors.red));
    }
  }
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

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.googleSignIn});

  final GoogleSignIn googleSignIn;

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
            await FirebaseAuth.instance.signInWithCredential(credential);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign-In successful'), backgroundColor: Colors.green));
          }
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sign in with Google: $error'), backgroundColor: Colors.red));
        }
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black, backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
      child: const Text('Sign in with Google'),
    );
  }
}
