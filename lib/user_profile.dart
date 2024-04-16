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
import 'users_services.dart';

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

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    String uid = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userProfileData = userData.data() as Map<String, dynamic>?;
    userProfileData?.forEach((key, value) {
      if (!_excludedFields.contains(key)) {
        _controllers[key] = TextEditingController(text: value.toString());
      }
    });
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> saveProfile(String field, String value) async {
    String uid = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
    try {
      await ref.read(usersServiceProvider).updateUser(uid, {field: value});
      updateSnackBar('Salvataggio riuscito!', Colors.green);
    } catch (e) {
      updateSnackBar('Errore di salvataggio!', Colors.red);
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
      updateSnackBar('Accesso alla galleria negato per altre restrizioni.', Colors.red);
    }
  }

  Future<void> uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileExtension = path.extension(file.path).toLowerCase();

      if (fileExtension == '.jpg' || fileExtension == '.png' || fileExtension == '.jpeg') {
        String uid = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
        final storageRef = FirebaseStorage.instance.ref().child('user_profile_pictures/$uid$fileExtension');
        await storageRef.putFile(file);
        final downloadURL = await storageRef.getDownloadURL();
        await ref.read(usersServiceProvider).updateUser(uid, {'photoURL': downloadURL});
        updateSnackBar('Immagine del profilo caricata con successo!', Colors.green);
      } else {
        updateSnackBar('Formato di immagine non supportato. Scegli un file JPG, PNG o JPEG.', Colors.red);
      }
    } else {
      updateSnackBar('Nessuna immagine selezionata.', Colors.red);
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: GestureDetector(
                onTap: requestGalleryPermission,
                child: CircleAvatar(
                  backgroundImage: hasValidPhotoURL ? NetworkImage(userPhotoURL) : null,
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.grey[800],
                  child: !hasValidPhotoURL ? const Icon(Icons.person, size: 60) : null,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ..._controllers.keys.where((field) => field != 'photoURL').map((field) => buildEditableField(field, _controllers[field]!)).toList(),
          ],
        ),
      ),
    );
  }

  Widget buildEditableField(String field, TextEditingController controller) {
    String label = field[0].toUpperCase() + field.substring(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[100] : Colors.grey[800],
        ),
        onChanged: (value) {
          _debouncer.run(() => saveProfile(field, value));
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
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