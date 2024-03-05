import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userProfileData;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  fetchUserProfile() async {
  if (user != null) {
    DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (mounted) { // Aggiungi questo controllo prima di chiamare setState()
      setState(() {
        userProfileData = userData.data() as Map<String, dynamic>?;
        userProfileData!.forEach((key, value) {
          _controllers[key] = TextEditingController(text: value.toString());
        });
      });
    }
  }
}

  void saveProfile(String field, String value) async {
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({field: value});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvataggio riuscito!'), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore di salvataggio!'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: userProfileData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  CircleAvatar(
                    backgroundImage: NetworkImage(userProfileData?['photoURL'] ?? 'https://via.placeholder.com/150'),
                    radius: 50,
                  ),
                  const SizedBox(height: 20),
                  ...userProfileData!.keys.map((field) => buildEditableField(field, _controllers[field]!)),
                ],
              ),
            ),
    );
  }

  Widget buildEditableField(String field, TextEditingController controller) {
    String label = field[0].toUpperCase() + field.substring(1); // Capitalize the first letter for the label
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          label: Text(label),
          border: const OutlineInputBorder(),
          fillColor: Theme.of(context).colorScheme.surfaceVariant,
          filled: true,
        ),
        onChanged: (value) {
          // Delayed auto-save
          Future.delayed(const Duration(seconds: 1), () {
            if (value == controller.text) { // Check if the value is still the same (user stopped typing)
              saveProfile(field, value);
            }
          });
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed.
    _controllers.forEach((_, controller) {
      controller.dispose();
    });
    super.dispose();
  }
}
