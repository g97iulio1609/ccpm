import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserProfile extends ConsumerStatefulWidget {
  final String? userId;

  const UserProfile({super.key, this.userId});

  @override
  UserProfileState createState() => UserProfileState();
}

class UserProfileState extends ConsumerState<UserProfile> {
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _excludedFields = ['currentProgram', 'role', 'socialLinks', 'id', 'photoURL'];
  String? _snackBarMessage;
  Color? _snackBarColor;
  final _debouncer = Debouncer(milliseconds: 1000);
  String? _selectedGender;
  String? _password; // Campo per conservare la password
  DateTime? _birthdate;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    String uid = widget.userId ?? ref.read(usersServiceProvider).getCurrentUserId();
    DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userProfileData = userData.data() as Map<String, dynamic>?;
    userProfileData?.forEach((key, value) {
      if (!_excludedFields.contains(key)) {
        _controllers[key] = TextEditingController(text: value.toString());
      }
    });
    // Normalizza il valore di gender per gestire maiuscole/minuscole
    _selectedGender = userProfileData?['gender']?.toString().toLowerCase();
    
    // Imposta la data di nascita
    if (userProfileData?['birthdate'] != null) {
      _birthdate = (userProfileData!['birthdate'] as Timestamp).toDate();
    }

    if (mounted) {
      setState(() {});
    }
  }

  int _calculateAge(DateTime birthdate) {
    DateTime today = DateTime.now();
    int age = today.year - birthdate.year;
    if (today.month < birthdate.month || (today.month == birthdate.month && today.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  Future<void> saveProfile(String field, dynamic value) async {
    String uid = widget.userId ?? ref.read(usersServiceProvider).getCurrentUserId();
    try {
      await ref.read(usersServiceProvider).updateUser(uid, {field: value});
      updateSnackBar('Profilo salvato con successo!', Colors.green);
    } catch (e) {
      updateSnackBar('Errore durante il salvataggio del profilo!', Colors.red);
    }
  }

  void updateSnackBar(String message, Color color) {
    _snackBarMessage = message;
    _snackBarColor = color;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> requestGalleryPermission() async {
    PermissionStatus status = await Permission.photos.request();

    if (status.isGranted) {
      await uploadProfilePicture();
    } else if (status.isPermanentlyDenied) {
      updateSnackBar('Accesso alla galleria negato in modo permanente dall\'utente.', Colors.red);
    } else if (status.isDenied) {
      updateSnackBar('Accesso alla galleria negato dall\'utente.', Colors.red);
    } else {
      updateSnackBar('Accesso alla galleria negato a causa di altre restrizioni.', Colors.red);
    }
  }

  Future<void> uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileExtension = path.extension(file.path).toLowerCase();

      if (fileExtension == '.jpg' || fileExtension == '.png' || fileExtension == '.jpeg') {
        String uid = widget.userId ?? ref.read(usersServiceProvider).getCurrentUserId();
        final storageRef = FirebaseStorage.instance.ref().child('user_profile_pictures/$uid$fileExtension');
        await storageRef.putFile(file);
        final downloadURL = await storageRef.getDownloadURL();
        await ref.read(usersServiceProvider).updateUser(uid, {'photoURL': downloadURL});
        updateSnackBar('Immagine del profilo caricata con successo!', Colors.green);
      } else {
        updateSnackBar('Formato immagine non supportato. Scegli un file JPG, PNG o JPEG.', Colors.red);
      }
    } else {
      updateSnackBar('Nessuna immagine selezionata.', Colors.red);
    }
  }

  Future<void> deleteUser() async {
    String uid = widget.userId ?? ref.read(usersServiceProvider).getCurrentUserId();
    try {
      // Elimina l'utente dall'autenticazione Firebase
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await ref.read(usersServiceProvider).deleteUser(uid);
        updateSnackBar('Utente eliminato con successo!', Colors.green);
        // Naviga verso la schermata di login dopo aver eliminato l'utente
        context.go('/'); // Usa la rotta configurata per la schermata di login
      } else {
        throw Exception("User not authenticated.");
      }
    } catch (e) {
      updateSnackBar('Errore durante l\'eliminazione dell\'utente: $e', Colors.red);
    }
  }

  Future<void> reauthenticateWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // L'utente ha annullato l'accesso
        updateSnackBar('Accesso annullato.', Colors.red);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(credential);
      await deleteUser(); // Chiama deleteUser dopo la re-autenticazione
    } catch (e) {
      updateSnackBar('Errore durante la re-autenticazione: $e', Colors.red);
    }
  }

  Future<void> reauthenticateWithPassword() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && _password != null) {
        String email = user.email!;
        AuthCredential credential = EmailAuthProvider.credential(email: email, password: _password!);
        await user.reauthenticateWithCredential(credential);
        await deleteUser(); // Chiama deleteUser dopo la re-autenticazione
      } else {
        throw Exception("User not authenticated or password not provided.");
      }
    } catch (e) {
      updateSnackBar('Errore durante la re-autenticazione: $e', Colors.red);
    }
  }

  Future<void> _showPasswordDialog() async {
    String password = '';
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma la tua password'),
          content: TextField(
            obscureText: true,
            onChanged: (value) {
              password = value;
            },
            decoration: const InputDecoration(hintText: "Password"),
          ),
          actions: [
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Conferma'),
              onPressed: () {
                _password = password;
                Navigator.of(context).pop();
                reauthenticateWithPassword(); // Re-autenticazione con la password
              },
            ),
          ],
        );
      },
    );
  }

  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma eliminazione'),
          content: const Text('Sei sicuro di voler eliminare questo utente?'),
          actions: [
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Elimina'),
              onPressed: () {
                Navigator.of(context).pop();
                User? currentUser = FirebaseAuth.instance.currentUser;
                if (isGoogleUser(currentUser)) {
                  reauthenticateWithGoogle(); // Re-autenticazione con Google
                } else {
                  _showPasswordDialog(); // Richiedi password per email/password
                }
              },
            ),
          ],
        );
      },
    );
  }

  bool isGoogleUser(User? user) {
    return user?.providerData.any((userInfo) => userInfo.providerId == 'google.com') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_snackBarMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_snackBarMessage!),
          backgroundColor: _snackBarColor,
        ));
        _snackBarMessage = null;
      });
    }

    String? userPhotoURL = _controllers['photoURL']?.text;
    bool hasValidPhotoURL = userPhotoURL != null && userPhotoURL.isNotEmpty && Uri.parse(userPhotoURL).isAbsolute;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: GestureDetector(
                onTap: requestGalleryPermission,
                child: CircleAvatar(
                  backgroundImage: hasValidPhotoURL ? NetworkImage(userPhotoURL) : null,
                  radius: 80,
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  child: !hasValidPhotoURL
                      ? const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 40),
            buildBirthdayField(),
            ..._controllers.keys
                .where((field) => field != 'photoURL' && field != 'gender' && field != 'birthdate')
                .map((field) => buildEditableField(field, _controllers[field]!)),
            const SizedBox(height: 24),
            buildGenderDropdown(),
            const SizedBox(height: 40),
            if (ref.read(usersServiceProvider).getCurrentUserRole() == 'admin' || widget.userId != null)
              ElevatedButton.icon(
                onPressed: showDeleteConfirmationDialog,
                icon: const Icon(Icons.delete),
                label: const Text(
                  'Elimina Utente',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildEditableField(String field, TextEditingController controller) {
    String label = field[0].toUpperCase() + field.substring(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
        ),
        onChanged: (value) {
          _debouncer.run(() => saveProfile(field, value));
        },
      ),
    );
  }

  Widget buildBirthdayField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: _birthdate ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null && pickedDate != _birthdate) {
            setState(() {
              _birthdate = pickedDate;
              saveProfile('birthdate', Timestamp.fromDate(pickedDate));
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Età',
            labelStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.white),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
          ),
          child: Text(
            _birthdate != null ? '${_calculateAge(_birthdate!)} anni' : 'Seleziona la data di nascita',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      onChanged: (value) {
        setState(() {
          _selectedGender = value?.toLowerCase();
          saveProfile('gender', value!.toLowerCase());
        });
      },
      decoration: InputDecoration(
        labelText: 'Genere',
        labelStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      dropdownColor: Colors.grey[900],
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
      ),
      items: <String>['male', 'female', 'other']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value.toLowerCase(),
          child: Text(value),
        );
      }).toList(),
      hint: const Text(
        'Seleziona il genere',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 18,
        ),
      ),
      validator: (value) {
        if (value == null) {
          return 'Per favore seleziona un genere';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
