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
  String? _snackBarMessage, _password, _photoURL;
  Color? _snackBarColor;
  int? _selectedGender;
  DateTime? _birthdate;
  bool _isLoading = true;

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
        userProfileData.forEach((key, value) {
          if (!_excludedFields.contains(key)) {
            _controllers[key] = TextEditingController(text: value?.toString() ?? '');
          }
        });
        
        _selectedGender = userProfileData['gender'] as int?;
        _photoURL = userProfileData['photoURL'] as String?;
        _birthdate = userProfileData['birthdate'] != null ? (userProfileData['birthdate'] as Timestamp).toDate() : null;
      }
    } catch (e) {
      _updateSnackBar('Error fetching user profile: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile(String field, dynamic value) async {
    try {
      String uid = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
      await ref.read(usersServiceProvider).updateUser(uid, {field: value});
      _updateSnackBar('Profile saved successfully!', Colors.green);
    } catch (e) {
      _updateSnackBar('Error saving profile: $e', Colors.red);
    }
  }

  void _updateSnackBar(String message, Color color) {
    setState(() {
      _snackBarMessage = message;
      _snackBarColor = color;
    });
  }

  Future<void> _requestGalleryPermission() async {
    PermissionStatus status = await Permission.photos.request();
    if (status.isGranted) {
      await _uploadProfilePicture();
    } else {
      _updateSnackBar('Gallery access ${status.isDenied ? 'denied' : 'restricted'}', Colors.red);
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

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
          _updateSnackBar('Profile picture uploaded successfully!', Colors.green);
        } catch (e) {
          _updateSnackBar('Error uploading profile picture: $e', Colors.red);
        }
      } else {
        _updateSnackBar('Unsupported image format. Please choose a JPG, PNG, or JPEG file.', Colors.red);
      }
    } else {
      _updateSnackBar('No image selected.', Colors.red);
    }
  }

  Future<void> _deleteUser() async {
    try {
      String uid = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await ref.read(usersServiceProvider).deleteUser(uid);
        _updateSnackBar('User deleted successfully!', Colors.green);
        if (mounted) context.go('/');
      } else {
        throw Exception("User not authenticated.");
      }
    } catch (e) {
      _updateSnackBar('Error deleting user: $e', Colors.red);
    }
  }

  Future<void> _reauthenticateWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _updateSnackBar('Sign-in cancelled.', Colors.red);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(credential);
      await _deleteUser();
    } catch (e) {
      _updateSnackBar('Error during re-authentication: $e', Colors.red);
    }
  }

  Future<void> _reauthenticateWithPassword() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && _password != null) {
        AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: _password!);
        await user.reauthenticateWithCredential(credential);
        await _deleteUser();
      } else {
        throw Exception("User not authenticated or password not provided.");
      }
    } catch (e) {
      _updateSnackBar('Error during re-authentication: $e', Colors.red);
    }
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
              onPressed: () {
                _password = password;
                Navigator.of(context).pop();
                _reauthenticateWithPassword();
              },
            ),
          ],
        );
      },
    );
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
                if (_isGoogleUser(currentUser)) {
                  _reauthenticateWithGoogle();
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
        onChanged: (value) => _debouncer.run(() => _saveProfile(field, value)),
      ),
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
          decoration: InputDecoration(
            labelText: 'Birth date',
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
        decoration: InputDecoration(
          labelText: 'Gender',
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
        items: genderMap.entries.map((entry) {
          return DropdownMenuItem<int>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        hint: Text('Select gender', style: TextStyle(color: Colors.white.withOpacity(0.7))),
      ),
    );
  }

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

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text('User Profile'),
                    background: GestureDetector(
                      onTap: _requestGalleryPermission,
                      child: _photoURL != null
                          ? Image.network(_photoURL!, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.person, size: 100, color: Colors.white),
                            ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.person), text: "Personal"),
                        Tab(icon: Icon(Icons.settings), text: "Account"),
                        Tab(icon: Icon(Icons.fitness_center), text: "Fitness"),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
                SliverFillRemaining(
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}