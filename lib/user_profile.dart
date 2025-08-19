// user_profile.dart

import 'dart:async';
import 'dart:io';
import 'package:alphanessone/Store/subscriptions_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/providers/ui_settings_provider.dart';
import 'package:alphanessone/UI/components/app_card.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import 'package:alphanessone/Main/app_theme.dart';

const Map<int, String> genderMap = {0: 'Altro', 1: 'Maschio', 2: 'Femmina'};

class UserProfile extends ConsumerStatefulWidget {
  final String? userId;

  const UserProfile({super.key, this.userId});

  @override
  UserProfileState createState() => UserProfileState();
}

class UserProfileState extends ConsumerState<UserProfile>
    with SingleTickerProviderStateMixin {
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _excludedFields = [
    'currentProgram',
    'role',
    'socialLinks',
    'id',
    'photoURL',
    'gender',
  ];
  final _debouncer = Debouncer(milliseconds: 1000);
  late TabController _tabController;
  String? _photoURL;
  int? _selectedGender;
  DateTime? _birthdate;
  bool _isLoading = true;
  String? _role;
  bool _twoFactorEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchUserProfile();
  }

  @override
  void didUpdateWidget(covariant UserProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _fetchUserProfile();
    }
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    try {
      String uid = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final userProfileData = userData.data() as Map<String, dynamic>?;

      if (userProfileData != null) {
        _updateControllers(userProfileData);
        _selectedGender = userProfileData['gender'] as int?;
        _photoURL = userProfileData['photoURL'] as String?;
        _birthdate = userProfileData['birthdate'] != null
            ? (userProfileData['birthdate'] as Timestamp).toDate()
            : null;
        _role = (userProfileData['role'] as String?)?.toUpperCase();
      }
    } catch (e) {
      _showSnackBar('Errore nel caricamento del profilo: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateControllers(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (!_excludedFields.contains(key)) {
        _controllers[key] = TextEditingController(
          text: value?.toString() ?? '',
        );
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
      _showSnackBar('Profilo salvato con successo!', Colors.green);
    } catch (e) {
      _showSnackBar('Errore nel salvare il profilo: $e', Colors.red);
    }
  }

  Future<void> _updateWeight(String uid, String weightValue) async {
    final measurementsService = ref.read(measurementsServiceProvider);
    final weight = double.parse(weightValue);
    try {
      await measurementsService.addMeasurement(
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
      // Measurement saved successfully
    } catch (e) {
      _showSnackBar('Errore nel salvare il peso: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    XFile? pickedFile;

    if (Platform.isAndroid) {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    } else {
      final status = await Permission.photos.request();
      if (status.isGranted) {
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
      } else {
        _showSnackBar('Accesso alla galleria negato', Colors.red);
        return;
      }
    }

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String uid = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
      String fileExtension = file.path.split('.').last.toLowerCase();

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('$uid.$fileExtension');

        await storageRef.putFile(file);
        final downloadURL = await storageRef.getDownloadURL();

        await ref.read(usersServiceProvider).updateUser(uid, {
          'photoURL': downloadURL,
        });

        setState(() {
          _photoURL = downloadURL;
        });

        _showSnackBar('Immagine del profilo aggiornata!', Colors.green);
      } catch (e) {
        _showSnackBar('Errore nel caricamento dell\'immagine: $e', Colors.red);
      }
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
            _showSnackBar(
              'Il tuo account è stato eliminato con successo.',
              Colors.green,
            );
            context.go('/');
          }
        } else {
          if (mounted) {
            _showSnackBar('Utente eliminato con successo!', Colors.green);
            context.pop();
          }
        }
      } else {
        throw Exception("Utente non autenticato.");
      }
    } catch (e) {
      _showSnackBar('Errore nell\'eliminazione dell\'utente: $e', Colors.red);
    }
  }

  Future<void> _reauthenticateAndDelete(bool isGoogleUser) async {
    try {
      User user = FirebaseAuth.instance.currentUser!;

      if (isGoogleUser) {
        final GoogleSignIn googleSignIn = GoogleSignIn.instance;
        await googleSignIn.initialize();
        final GoogleSignInAccount googleUser = await googleSignIn.authenticate(
          scopeHint: ['email', 'profile'],
        );

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        await user.reauthenticateWithCredential(credential);
      }

      await _deleteUser();
    } catch (e) {
      _showSnackBar('Errore nella riautenticazione: $e', Colors.red);
    }
  }

  void _showDeleteConfirmationDialog() {
    showAppDialog(
      context: context,
      title: const Text('Conferma eliminazione'),
      child: const Text('Sei sicuro di voler eliminare questo utente?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            final currentUser = FirebaseAuth.instance.currentUser!;
            _reauthenticateAndDelete(_isGoogleUser(currentUser));
          },
          child: const Text('Elimina'),
        ),
      ],
    );
  }

  bool _isGoogleUser(User user) {
    return user.providerData.any(
      (userInfo) => userInfo.providerId == 'google.com',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final glassEnabled = ref.watch(uiGlassEnabledProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  // final isWide = constraints.maxWidth >= 1000;
                  // final columnGap = AppTheme.spacing.xl;
                  final glass = glassEnabled;

                  final tabBar = AppCard(
                    glass: glass,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      indicatorColor: colorScheme.primary,
                      tabs: const [
                        Tab(text: 'Info'),
                        Tab(text: 'Account'),
                        Tab(text: 'Fitness'),
                        Tab(text: 'Abbonamenti'),
                      ],
                    ),
                  );

                  return Padding(
                    padding: EdgeInsets.all(AppTheme.spacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(theme),
                        SizedBox(height: AppTheme.spacing.lg),
                        tabBar,
                        SizedBox(height: AppTheme.spacing.lg),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              SingleChildScrollView(
                                child: _buildPersonalInfoCard(glass),
                              ),
                              SingleChildScrollView(
                                child: _buildAccountSettingsCard(glass),
                              ),
                              SingleChildScrollView(
                                child: _buildFitnessDataCard(glass),
                              ),
                              SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildSubscriptionsCard(),
                                    SizedBox(height: AppTheme.spacing.xl),
                                    _buildSecurityCard(glass),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final glassEnabled = ref.watch(uiGlassEnabledProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: AppCard(
        glass: glassEnabled,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            children: [
              _buildProfilePicture(),
              const SizedBox(height: 16),
              Text(
                _controllers['name']?.text ?? 'Utente',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (_role != null && _role!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing.md,
                    vertical: AppTheme.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(76),
                    borderRadius: BorderRadius.circular(AppTheme.radii.full),
                  ),
                  child: Text(
                    _role!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (_controllers['email']?.text != null &&
                  _controllers['email']!.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _controllers['email']!.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppTheme.spacing.md,
                runSpacing: AppTheme.spacing.sm,
                children: [
                  FilledButton.icon(
                    onPressed: _uploadProfilePicture,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Cambia foto'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _copyEmailToClipboard,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copia email'),
                  ),
                  TextButton.icon(
                    onPressed: () => _tabController.animateTo(3),
                    icon: const Icon(Icons.subscriptions_outlined),
                    label: const Text('Abbonamenti'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _uploadProfilePicture,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary.withAlpha(26),
            width: 3,
          ),
          color: theme.colorScheme.surfaceContainerHighest,
          image: _photoURL != null
              ? DecorationImage(
                  image: NetworkImage(_photoURL!),
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withAlpha(51),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _photoURL == null
            ? Icon(
                Icons.person,
                size: 60,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
      ),
    );
  }

  Widget _buildPersonalInfoCard(bool glass) {
    return AppCard(
      glass: glass,
      title: 'Informazioni personali',
      leadingIcon: Icons.person_outline,
      child: Column(
        children: [
          _buildEditableField('nome', _controllers['name']),
          _buildEditableField('cognome', _controllers['surname']),
          _buildBirthdayField(),
          _buildGenderDropdown(),
          _buildEditableField('email', _controllers['email']),
          _buildEditableField('telefono', _controllers['phone']),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsCard(bool glass) {
    return AppCard(
      glass: glass,
      title: 'Impostazioni account',
      leadingIcon: Icons.settings_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditableField('username', _controllers['username']),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _sendPasswordResetEmail,
            child: const Text('Reset password via email'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Switch(
                value: _twoFactorEnabled,
                onChanged: (v) {
                  setState(() => _twoFactorEnabled = v);
                  // Hook 2FA: qui potresti aprire un AppDialog per QR/OTP
                },
              ),
              const SizedBox(width: 8),
              const Text('Abilita 2FA (placeholder)'),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _logoutAllDevices,
            icon: const Icon(Icons.logout),
            label: const Text('Logout da tutti i dispositivi'),
          ),
          const SizedBox(height: 12),
          if (ref.read(usersServiceProvider).getCurrentUserRole() == 'admin' ||
              widget.userId != null)
            ElevatedButton(
              onPressed: _showDeleteConfirmationDialog,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Elimina Account'),
            ),
        ],
      ),
    );
  }

  Widget _buildFitnessDataCard(bool glass) {
    return AppCard(
      glass: glass,
      title: 'Dati fitness',
      leadingIcon: Icons.fitness_center_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditableField('altezza', _controllers['height']),
          _buildEditableField('peso', _controllers['weight']),
          _buildEditableField('grassoCorpo', _controllers['bodyFat']),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsCard() {
    return AppCard(
      glass: ref.watch(uiGlassEnabledProvider),
      title: 'Abbonamenti',
      leadingIcon: Icons.subscriptions_outlined,
      child: SubscriptionsScreen(
        userId: widget.userId ?? FirebaseAuth.instance.currentUser!.uid,
      ),
    );
  }

  Widget _buildSecurityCard(bool glass) {
    return AppCard(
      glass: glass,
      title: 'Sicurezza',
      leadingIcon: Icons.security_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              const Text('Stato 2FA: placeholder'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Consiglio: abilita la verifica in due passaggi per proteggere il tuo account.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String field, TextEditingController? controller) {
    if (controller == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    String label = field[0].toUpperCase() + field.substring(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: theme.colorScheme.onSurface),
        decoration: _getInputDecoration(label),
        onChanged: (value) => _debouncer.run(() => _saveProfile(field, value)),
      ),
    );
  }

  InputDecoration _getInputDecoration(String label) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(51)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
    );
  }

  Widget _buildBirthdayField() {
    final theme = Theme.of(context);
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
          decoration: _getInputDecoration('Data di nascita'),
          child: Text(
            _birthdate != null
                ? '${_calculateAge(_birthdate!)} anni (${_birthdate!.day}/${_birthdate!.month}/${_birthdate!.year})'
                : 'Seleziona data di nascita',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }

  int _calculateAge(DateTime birthdate) {
    DateTime today = DateTime.now();
    int age = today.year - birthdate.year;
    if (today.month < birthdate.month ||
        (today.month == birthdate.month && today.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  void _copyEmailToClipboard() {
    final email = _controllers['email']?.text ?? '';
    if (email.isEmpty) return;
    Clipboard.setData(ClipboardData(text: email));
    _showSnackBar('Email copiata negli appunti', Colors.green);
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _controllers['email']?.text ?? '';
    if (email.isEmpty) {
      _showSnackBar('Nessuna email in profilo', Colors.red);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnackBar('Email di reset inviata a $email', Colors.green);
    } catch (e) {
      _showSnackBar('Errore invio reset password: $e', Colors.red);
    }
  }

  Future<void> _logoutAllDevices() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        _showSnackBar(
          'Logout effettuato da questo dispositivo. (Placeholder multi-device)',
          Colors.green,
        );
        context.go('/');
      }
    } catch (e) {
      _showSnackBar('Errore logout: $e', Colors.red);
    }
  }

  Widget _buildGenderDropdown() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        initialValue: _selectedGender,
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
            if (value != null) _saveProfile('gender', value);
          });
        },
        decoration: _getInputDecoration('Genere'),
        dropdownColor: theme.colorScheme.surfaceContainerHighest,
        style: TextStyle(color: theme.colorScheme.onSurface),
        items: genderMap.entries.map((entry) {
          return DropdownMenuItem<int>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        hint: Text(
          'Seleziona genere',
          style: TextStyle(color: Colors.white.withAlpha(179)),
        ),
      ),
    );
  }
}

// Widget placeholder per i contenuti delle tab
class UserProfileTabContent extends StatelessWidget {
  const UserProfileTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Contenuto della scheda'));
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
