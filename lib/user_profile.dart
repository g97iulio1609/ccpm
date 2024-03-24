import 'dart:async';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: CircleAvatar(
                backgroundImage: hasValidPhotoURL ? NetworkImage(userPhotoURL) : null,
                radius: 60,
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.grey[800],
                child: !hasValidPhotoURL ? const Icon(Icons.person, size: 60) : null,
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