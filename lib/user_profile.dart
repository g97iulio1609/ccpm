import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/services/users_services.dart';

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
    _selectedGender = userProfileData?['gender'];
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> saveProfile(String field, String value) async {
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
      await ref.read(usersServiceProvider).deleteUser(uid);
      updateSnackBar('Utente eliminato con successo!', Colors.green);
      // Naviga verso un'altra schermata o esegui le azioni necessarie dopo aver eliminato l'utente
    } catch (e) {
      updateSnackBar('Errore durante l\'eliminazione dell\'utente!', Colors.red);
    }
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
                deleteUser();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
            ..._controllers.keys
                .where((field) => field != 'photoURL' && field != 'gender')
                .map((field) => buildEditableField(field, _controllers[field]!))
                ,
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
                  foregroundColor: Colors.white, backgroundColor: Colors.red,
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

Widget buildGenderDropdown() {
  return DropdownButtonFormField<String>(
    value: _selectedGender,
    onChanged: (value) {
      setState(() {
        _selectedGender = value;
        saveProfile('gender', value!);
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
        value: value,
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