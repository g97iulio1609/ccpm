import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile extends StatefulWidget {
  final String? userId;

  const UserProfile({super.key, this.userId});

  @override
  UserProfileState createState() => UserProfileState();
}

class UserProfileState extends State<UserProfile> {
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _excludedFields = ['currentProgram', 'role', 'socialLinks', 'id'];
  String? _snackBarMessage;
  Color? _snackBarColor;

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
      await FirebaseFirestore.instance.collection('users').doc(uid).update({field: value});
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
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            CircleAvatar(
              backgroundImage: hasValidPhotoURL ? NetworkImage(userPhotoURL) : null,
              radius: 50,
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.grey[800],
              child: !hasValidPhotoURL ? const Icon(Icons.person, size: 50) : null,
            ),
            const SizedBox(height: 20),
            ..._controllers.keys.where((field) => field != 'photoURL').map((field) => buildEditableField(field, _controllers[field]!)).toList(),
          ],
        ),
      ),
    );
  }

  Widget buildEditableField(String field, TextEditingController controller) {
    String label = field[0].toUpperCase() + field.substring(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        onChanged: (value) => saveProfile(field, value),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        enabled: widget.userId == null,
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