import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  UserProfileState createState() => UserProfileState();
}

class UserProfileState extends State<UserProfile> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _excludedFields = ['currentProgram', 'role', 'socialLinks', 'id'];

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (mounted) {
        setState(() {
          final userProfileData = userData.data() as Map<String, dynamic>?;
          userProfileData?.forEach((key, value) {
            if (!_excludedFields.contains(key)) {
              _controllers[key] = TextEditingController(text: value.toString());
            }
          });
        });
      }
    }
  }

  Future<void> saveProfile(String field, String value) async {
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({field: value});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salvataggio riuscito!'), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore di salvataggio!'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine whether a user photo URL is available
    String? userPhotoURL = _controllers['photoURL']?.text;
    bool hasValidPhotoURL = userPhotoURL != null && userPhotoURL.isNotEmpty && Uri.parse(userPhotoURL).isAbsolute;

    return Scaffold(
      body: _controllers.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  CircleAvatar(
                    backgroundImage: hasValidPhotoURL ? NetworkImage(userPhotoURL!) : null,
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.grey[800],
                    child: !hasValidPhotoURL ? Icon(Icons.person, size: 50) : null,
                  ),
                  SizedBox(height: 20),
                  ..._controllers.keys.where((field) => field != 'photoURL').map((field) => buildEditableField(field, _controllers[field]!)).toList(),
                ],
              ),
            ),
    );
  }

  Widget buildEditableField(String field, TextEditingController controller) {
    String label = field[0].toUpperCase() + field.substring(1);
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
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
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}
