import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  UserProfileState createState() => UserProfileState();
}

class UserProfileState extends State<UserProfile> {
  final User? user = FirebaseAuth.instance.currentUser;
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
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
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
  }

  Future<void> saveProfile(String field, String value) async {
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({field: value});
        updateSnackBar('Salvataggio riuscito!', Colors.green);
      } catch (e) {
        updateSnackBar('Errore di salvataggio!', Colors.red);
      }
    }
  }

  void updateSnackBar(String message, Color color) {
    // Update snackbar message and color
    _snackBarMessage = message;
    _snackBarColor = color;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check and display the snackbar if message is available
    if (_snackBarMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_snackBarMessage!),
          backgroundColor: _snackBarColor,
        ));
        // Reset the message to prevent it from appearing again.
        _snackBarMessage = null;
      });
    }

    String? userPhotoURL = _controllers['photoURL']?.text;
    bool hasValidPhotoURL = userPhotoURL != null && userPhotoURL.isNotEmpty && Uri.parse(userPhotoURL).isAbsolute;

    return Scaffold(
      body: _controllers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
