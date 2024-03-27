import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'users_services.dart';

final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

class AuthScreen extends HookConsumerWidget {
  AuthScreen({super.key});

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
          ),
          ToggleAuthModeButton(isLogin: isLogin),
          GoogleSignInButton(
            googleSignIn: googleSignIn,
            firestore: firestore,
            usersService: usersService,
          ),
        ],
      ),
    );
  }
}

class SubmitButton extends ConsumerStatefulWidget {
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

  @override
  _SubmitButtonState createState() => _SubmitButtonState();
}

class _SubmitButtonState extends ConsumerState<SubmitButton> {
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _submit(context),
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
      child: Text(widget.isLogin.value ? 'Login' : 'Sign Up'),
    );
  }

 Future<void> _submit(BuildContext context) async {
  if (widget.formKey.currentState?.validate() ?? false) {
    widget.formKey.currentState?.save();
    final email = widget.userEmail.value.trim();
    final password = widget.userPassword.value.trim();
    try {
      UserCredential userCredential;
      if (widget.isLogin.value) {
        userCredential = await _signInWithEmailAndPassword(email, password);
      } else {
        userCredential = await _signUpWithEmailAndPassword(email, password);
      }
      await _updateUserData(userCredential.user);
      _showSnackBar('Authentication successful', Colors.green);
      if (mounted) {
        final userRole = ref.read(userRoleProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (userRole == 'admin') {
            context.go('/programs_screen');
          } else {
            context.go(
                '/programs_screen/user_programs/${userCredential.user!.uid}');
          }
        });
      }
    } on FirebaseAuthException catch (error) {
      _showSnackBar(
          error.message ?? 'An error occurred, please try again', Colors.red);
    }
  }
}

  Future<UserCredential> _signInWithEmailAndPassword(
      String email, String password) async {
    final userCredential = await widget.auth
        .signInWithEmailAndPassword(email: email, password: password);
    await widget.usersService.setUserRole(userCredential.user!.uid);
    return userCredential;
  }

  Future<UserCredential> _signUpWithEmailAndPassword(
      String email, String password) async {
    final userCredential = await widget.auth
        .createUserWithEmailAndPassword(email: email, password: password);
    final user = userCredential.user;
    if (user != null) {
      await widget.firestore.collection('users').doc(user.uid).set({
        'address': '',
        'currentProgram': '',
        'displayName': widget.userName.value,
        'email': email,
        'gender': widget.userGender.value,
        'id': user.uid,
        'name': widget.userName.value,
        'phoneNumber': null,
        'photoURL': user.photoURL ?? '',
        'role': 'client',
        'socialLinks': {'facebook': '', 'twitter': ''},
      });
      await user.updateDisplayName(widget.userName.value);
      await widget.usersService.setUserRole(user.uid);
    }
    return userCredential;
  }

  Future<void> _updateUserData(User? user) async {
    if (user != null) {
      widget.usersService.updateUserName(user.displayName);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    _scaffoldMessenger?.removeCurrentSnackBar();
    _scaffoldMessenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}

class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.googleSignIn,
    required this.firestore,
    required this.usersService,
  });

  final GoogleSignIn googleSignIn;
  final FirebaseFirestore firestore;
  final UsersService usersService;

  @override
  _GoogleSignInButtonState createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _signInWithGoogle(context),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
      child: const Text('Sign in with Google'),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final user = await widget.googleSignIn.signIn();
      if (user != null) {
        final googleAuth = await user.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        await _updateUserDataIfNeeded(userCredential.user);
        _showSnackBar('Google Sign-In successful', Colors.green);
        final userRole = ref.read(userRoleProvider);
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (userRole == 'admin') {
              context.go('/programs_screen');
            } else {
              context.go(
                  '/programs_screen/user_programs/${userCredential.user!.uid}');
            }
          });
        }
      }
    } catch (error) {
      _showSnackBar('Failed to sign in with Google: $error', Colors.red);
    }
  }

  Future<void> _updateUserDataIfNeeded(User? user) async {
    if (user != null) {
      final userDocRef = widget.firestore.collection('users').doc(user.uid);
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
      await widget.usersService.setUserRole(user.uid);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    _scaffoldMessenger?.removeCurrentSnackBar();
    _scaffoldMessenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}

class ToggleAuthModeButton extends StatelessWidget {
  const ToggleAuthModeButton({super.key, required this.isLogin});

  final ValueNotifier<bool> isLogin;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(
          isLogin.value ? 'Create new account' : 'I already have an account'),
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
      validator: (value) => (value == null || value.isEmpty || value.length < 4)
          ? 'Please enter at least 4 characters'
          : null,
      decoration: const InputDecoration(
          labelText: 'Username', border: OutlineInputBorder()),
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
      validator: (value) =>
          (value == null || value.isEmpty || !value.contains('@'))
              ? 'Please enter a valid email address'
              : null,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
          labelText: 'Email address', border: OutlineInputBorder()),
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
      decoration: const InputDecoration(
          labelText: 'Password', border: OutlineInputBorder()),
      obscureText: true,
      onSaved: (value) => userPassword.value = value ?? '',
    );
  }
}
