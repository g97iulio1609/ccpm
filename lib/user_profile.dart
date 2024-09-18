import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:alphanessone/providers/providers.dart';

const Map<int, String> genderMap = {0: 'Altro', 1: 'Maschio', 2: 'Femmina'};

class UserProfile extends ConsumerStatefulWidget {
  final String? userId;

  const UserProfile({super.key, this.userId});

  @override
  UserProfileState createState() => UserProfileState();
}

class UserProfileState extends ConsumerState<UserProfile> with SingleTickerProviderStateMixin {
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _excludedFields = ['currentProgram', 'role', 'socialLinks', 'id', 'photoURL', 'gender'];
  final _debouncer = Debouncer(milliseconds: 1000);
  late TabController _tabController;
  String? _photoURL;
  int? _selectedGender;
  DateTime? _birthdate;
  bool _isLoading = true;
  String? _lastMeasurementId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    try {
      String uid = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userProfileData = userData.data() as Map<String, dynamic>?;
      
      if (userProfileData != null) {
        _updateControllers(userProfileData);
        _selectedGender = userProfileData['gender'] as int?;
        _photoURL = userProfileData['photoURL'] as String?;
        _birthdate = userProfileData['birthdate'] != null ? (userProfileData['birthdate'] as Timestamp).toDate() : null;

        // Fetch the most recent weight measurement
        final measurementsService = ref.read(measurementsServiceProvider);
        final measurements = await measurementsService.getMeasurements(userId: uid).first;
        if (measurements.isNotEmpty) {
          final mostRecentMeasurement = measurements.first;
          _lastMeasurementId = mostRecentMeasurement.id;
          _controllers['weight']?.text = mostRecentMeasurement.weight.toString();
        }
      }
    } catch (e) {
      _showSnackBar('Error fetching user profile: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateControllers(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (!_excludedFields.contains(key)) {
        _controllers[key] = TextEditingController(text: value?.toString() ?? '');
      }
    });
  }

  Future<void> _saveProfile(String field, dynamic value) async {
    try {
      String uid = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
      if (field == 'weight') {
        await _updateWeight(uid, value);
      } else {
        await ref.read(usersServiceProvider).updateUser(uid, {field: value});
      }
      _showSnackBar('Profile saved successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error saving profile: $e', Colors.red);
    }
  }

  Future<void> _updateWeight(String uid, String weightValue) async {
    final measurementsService = ref.read(measurementsServiceProvider);
    final weight = double.parse(weightValue);
    
    if (_lastMeasurementId != null) {
      // Update the last measurement
      final lastMeasurement = (await measurementsService.getMeasurements(userId: uid).first).first;
      await measurementsService.updateMeasurement(
        userId: uid,
        measurementId: _lastMeasurementId!,
        date: DateTime.now(),
        weight: weight,
        height: lastMeasurement.height,
        bmi: lastMeasurement.bmi,
        bodyFatPercentage: lastMeasurement.bodyFatPercentage,
        waistCircumference: lastMeasurement.waistCircumference,
        hipCircumference: lastMeasurement.hipCircumference,
        chestCircumference: lastMeasurement.chestCircumference,
        bicepsCircumference: lastMeasurement.bicepsCircumference,
      );
    } else {
      // Add a new measurement if there's no previous one
      _lastMeasurementId = await measurementsService.addMeasurement(
        userId: uid,
        date: DateTime.now(),
        weight: weight,
        height: 0,
        bmi: 0,
        bodyFatPercentage: 0,
        waistCircumference: 0,
        hipCircumference: 0,
        chestCircumference: 0,
        bicepsCircumference: 0,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    XFile? pickedFile;
    
    if (Platform.isAndroid) {
      // Usa il Photo Picker su Android
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    } else {
      // Su iOS, richiedi il permesso come prima
      final status = await Permission.photos.request();
      if (status.isGranted) {
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
      } else {
        _showSnackBar('Gallery access denied', Colors.red);
        return;
      }
    }

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String uid = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
      String fileExtension = file.path.split('.').last.toLowerCase();

      if (['jpg', 'png', 'jpeg'].contains(fileExtension)) {
        try {
          final storageRef = FirebaseStorage.instance.ref().child('user_profile_pictures/$uid.$fileExtension');
          await storageRef.putFile(file);
          final downloadURL = await storageRef.getDownloadURL();
          await ref.read(usersServiceProvider).updateUser(uid, {'photoURL': downloadURL});
          setState(() => _photoURL = downloadURL);
          _showSnackBar('Profile picture uploaded successfully!', Colors.green);
        } catch (e) {
          _showSnackBar('Error uploading profile picture: $e', Colors.red);
        }
      } else {
        _showSnackBar('Unsupported image format. Please choose a JPG, PNG, or JPEG file.', Colors.red);
      }
    } else {
      _showSnackBar('No image selected.', Colors.red);
    }
  }
  
  Future<void> _deleteUser() async {
    try {
      String uid = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        bool isSelfDelete = uid == user.uid;
        await ref.read(usersServiceProvider).deleteUser(uid);
        
        if (isSelfDelete) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            _showSnackBar('Your account has been deleted successfully.', Colors.green);
            context.go('/');
          }
        } else {
          if (mounted) {
            _showSnackBar('User deleted successfully!', Colors.green);
            context.pop();
          }
        }
      } else {
        throw Exception("User not authenticated.");
      }
    } catch (e) {
      _showSnackBar('Error deleting user: $e', Colors.red);
    }
  }

  Future<void> _reauthenticateAndDelete(bool isGoogleUser) async {
    try {
      if (isGoogleUser) {
        await _reauthenticateWithGoogle();
      } else {
        await _showPasswordDialog();
      }
      await _deleteUser();
    } catch (e) {
      _showSnackBar('Error during re-authentication: $e', Colors.red);
    }
  }

  Future<void> _reauthenticateWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      _showSnackBar('Sign-in cancelled.', Colors.red);
      return;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(credential);
  }

  Future<void> _showPasswordDialog() async {
    String password = '';
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm your password'),
          content: TextField(
            obscureText: true,
            onChanged: (value) => password = value,
            decoration: const InputDecoration(hintText: "Password"),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _reauthenticateWithPassword(password);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _reauthenticateWithPassword(String password) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);
    } else {
      throw Exception("User not authenticated or password not provided.");
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm deletion'),
          content: const Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                User? currentUser = FirebaseAuth.instance.currentUser;
                _reauthenticateAndDelete(_isGoogleUser(currentUser));
              },
            ),
          ],
        );
      },
    );
  }

  bool _isGoogleUser(User? user) {
    return user?.providerData.any((userInfo) => userInfo.providerId == 'google.com') ?? false;
  }

  Widget _buildEditableField(String field, TextEditingController? controller) {
    if (controller == null) return const SizedBox.shrink();
    
    String label = field[0].toUpperCase() + field.substring(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: _getInputDecoration(label),
        onChanged: (value) => _debouncer.run(() => _saveProfile(field, value)),
      ),
    );
  }

  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
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
    );
  }

  Widget _buildBirthdayField() {
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
              _saveProfile('birthdate', Timestamp.fromDate(pickedDate));
            });
          }
        },
        child: InputDecorator(
          decoration: _getInputDecoration('Birth date'),
          child: Text(
            _birthdate != null ? '${_calculateAge(_birthdate!)} years old (${_birthdate!.day}/${_birthdate!.month}/${_birthdate!.year})' : 'Select birth date',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  int _calculateAge(DateTime birthdate) {
    DateTime today = DateTime.now();
    int age = today.year - birthdate.year;
    if (today.month < birthdate.month || (today.month == birthdate.month && today.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        value: _selectedGender,
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
            if (value != null) _saveProfile('gender', value);
          });
        },
        decoration: _getInputDecoration('Gender'),
        dropdownColor: Colors.grey[900],
        style: const TextStyle(color: Colors.white),
        items: genderMap.entries.map((entry) {
          return DropdownMenuItem<int>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        hint: Text('Select gender', style: TextStyle(color: Colors.white.withOpacity(0.7))),
      ),
    );}

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditableField('name', _controllers['name']),
          _buildEditableField('surname', _controllers['surname']),
          _buildBirthdayField(),
          _buildGenderDropdown(),
          _buildEditableField('email', _controllers['email']),
          _buildEditableField('phone', _controllers['phone']),
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
          _buildEditableField('username', _controllers['username']),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Implement password change logic
            },
            child: const Text('Change Password'),
          ),
          const SizedBox(height: 20),
          if (ref.read(usersServiceProvider).getCurrentUserRole() == 'admin' || widget.userId != null)
            ElevatedButton(
              onPressed: _showDeleteConfirmationDialog,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Account'),
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
          _buildEditableField('height', _controllers['height']),
          _buildEditableField('weight', _controllers['weight']),
          _buildEditableField('bodyFat', _controllers['bodyFat']),
        ],
      ),
    );
  }

 Widget _buildProfilePicture() {
    return GestureDetector(
      onTap: _uploadProfilePicture,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          color: Colors.grey[800],
          image: _photoURL != null
            ? DecorationImage(
                image: NetworkImage(_photoURL!),
                fit: BoxFit.cover,
              )
            : null,
        ),
        child: _photoURL == null
          ? const Icon(Icons.person, size: 60, color: Colors.white)
          : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 20),
                child: _buildProfilePicture(),
              ),
              Text(
                _controllers['name']?.text ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.person), text: "Personal"),
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
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _tabController.dispose();
    _debouncer.dispose();
    super.dispose();
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}