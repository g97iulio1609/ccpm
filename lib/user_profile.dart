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

const Map<int, String> genderMap = {
  0: 'Altro',
  1: 'Maschio',
  2: 'Femmina',
};

class UserProfile extends ConsumerStatefulWidget {
  final String? userId;

  const UserProfile({super.key, this.userId});

  @override
  UserProfileState createState() => UserProfileState();
}

class UserProfileState extends ConsumerState<UserProfile> with SingleTickerProviderStateMixin {
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _excludedFields = ['currentProgram', 'role', 'socialLinks', 'id', 'photoURL', 'gender'];
  String? _snackBarMessage;
  Color? _snackBarColor;
  final _debouncer = Debouncer(milliseconds: 1000);
  int? _selectedGender;
  String? _password;
  DateTime? _birthdate;
  late TabController _tabController;
  bool _isLoading = true;
  String? _photoURL;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String uid = widget.userId ?? ref.read(usersServiceProvider).getCurrentUserId();
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userProfileData = userData.data() as Map<String, dynamic>?;
      
      if (userProfileData != null) {
        userProfileData.forEach((key, value) {
          if (!_excludedFields.contains(key)) {
            _controllers[key] = TextEditingController(text: value?.toString() ?? '');
          }
        });
        
        _selectedGender = userProfileData['gender'] as int?;
        _photoURL = userProfileData['photoURL'] as String?;
        
        if (userProfileData['birthdate'] != null) {
          _birthdate = (userProfileData['birthdate'] as Timestamp).toDate();
        }
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        setState(() {
          _photoURL = downloadURL;
        });
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
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await ref.read(usersServiceProvider).deleteUser(uid);
        updateSnackBar('Utente eliminato con successo!', Colors.green);
        if (mounted) {
          context.go('/');
        }
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
        updateSnackBar('Accesso annullato.', Colors.red);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(credential);
      await deleteUser();
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
        await deleteUser();
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
                reauthenticateWithPassword();
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
                  reauthenticateWithGoogle();
                } else {
                  _showPasswordDialog();
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_snackBarMessage!),
            backgroundColor: _snackBarColor,
          ));
          _snackBarMessage = null;
        }
      });
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 60, bottom: 20),
                    child: Center(
                      child: GestureDetector(
                        onTap: requestGalleryPermission,
                        child: CircleAvatar(
                          backgroundImage: _photoURL != null ? NetworkImage(_photoURL!) : null,
                          radius: 60,
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          child: _photoURL == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.person), text: "Personale"),
                      Tab(icon: Icon(Icons.settings), text: "Account"),
                      Tab(icon: Icon(Icons.fitness_center), text: "Fitness"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPersonalInfoTab(),
                        _buildAccountSettingsTab(),
                        _buildFitnessDataTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildEditableField('name', _controllers['name']),
          buildEditableField('surname', _controllers['surname']),
          buildBirthdayField(),
          buildGenderDropdown(),
          buildEditableField('email', _controllers['email']),
          buildEditableField('phone', _controllers['phone']),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildEditableField('username', _controllers['username']),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Implementa la logica per cambiare la password
            },
            child: const Text('Cambia Password'),
          ),
          const SizedBox(height: 20),
          if (ref.read(usersServiceProvider).getCurrentUserRole() == 'admin' || widget.userId != null)
            ElevatedButton(
              onPressed: showDeleteConfirmationDialog,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Elimina Account'),
            ),
        ],
      ),
    );
  }

  Widget _buildFitnessDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildEditableField('height', _controllers['height']),
          buildEditableField('weight', _controllers['weight']),
          buildEditableField('bodyFat', _controllers['bodyFat']),
        ],
      ),
    );
  }

  Widget buildEditableField(String field, TextEditingController? controller) {
    if (controller == null) return const SizedBox.shrink();
    
    String label = field[0].toUpperCase() + field.substring(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
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
      padding: const EdgeInsets.only(bottom: 16),
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
            labelText: 'Data di nascita',
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
          ),
          child: Text(
            _birthdate != null ? '${_calculateAge(_birthdate!)} anni (${_birthdate!.day}/${_birthdate!.month}/${_birthdate!.year})' : 'Seleziona la data di nascita',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        value: _selectedGender,
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
            if (value != null) {
              saveProfile('gender', value);
            }
          });
        },
        decoration: InputDecoration(
          labelText: 'Genere',
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
        ),
        dropdownColor: Colors.grey[900],
        style: const TextStyle(color: Colors.white),
        items: genderMap.entries.map<DropdownMenuItem<int>>((entry) {
          return DropdownMenuItem<int>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        hint: Text(
          'Seleziona il genere',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _tabController.dispose();
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