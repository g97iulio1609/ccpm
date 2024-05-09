import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../users_services.dart';
import 'package:intl/intl.dart';

class TDEEScreen extends ConsumerStatefulWidget {
  final String userId;

  const TDEEScreen({super.key, required this.userId});

  @override
  _TDEEScreenState createState() => _TDEEScreenState();
}

class _TDEEScreenState extends ConsumerState<TDEEScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _birthDate;
  int _height = 0;
  int _weight = 0;
  String _gender = '';
  double _activityLevel = 1.2;
  double _tdee = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTDEEData();
  }

  void _loadTDEEData() async {
    final usersService = ref.read(usersServiceProvider);
    final tdeeData = await usersService.getTDEEData(widget.userId);

    if (tdeeData != null) {
      setState(() {
        _birthDate = DateTime.parse(tdeeData['birthDate']);
        _height = tdeeData['height'];
        _weight = tdeeData['weight'];
        _gender = tdeeData['gender'];
        _activityLevel = tdeeData['activityLevel'];
        _tdee = tdeeData['tdee'];
      });
    }
  }

  void _calculateTDEE() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final age = DateTime.now().year - _birthDate!.year;

      double bmr;
      if (_gender == 'male') {
        bmr = 88.362 + (13.397 * _weight) + (4.799 * _height) - (5.677 * age);
      } else {
        bmr = 447.593 + (9.247 * _weight) + (3.098 * _height) - (4.330 * age);
      }

      _tdee = bmr * _activityLevel;

      final usersService = ref.read(usersServiceProvider);
      await usersService.updateTDEEData(widget.userId, {
        'birthDate': _birthDate.toString(),
        'height': _height,
        'weight': _weight,
        'gender': _gender,
        'activityLevel': _activityLevel,
        'tdee': _tdee,
      });

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
     
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Calculate your TDEE',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Know your TDEE by entering basic details like age, weight, height, and activity level.',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  initialValue: _birthDate != null
                      ? (_calculateAge(_birthDate!)).toString()
                      : '',
                  readOnly: true,
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _birthDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _birthDate = pickedDate;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "Height",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        initialValue: _height.toString(),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your height';
                          }
                          return null;
                        },
                        onSaved: (value) => _height = int.parse(value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField(
                        decoration: InputDecoration(
                          labelText: 'Units',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: 'cms',
                        items: ['cms', 'ft/in'].map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "Weight",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        initialValue: _weight.toString(),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your weight';
                          }
                          return null;
                        },
                        onSaved: (value) => _weight = int.parse(value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField(
                        decoration: InputDecoration(
                          labelText: 'Units',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: 'kg',
                        items: ['kg', 'lbs'].map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField(
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: _gender,
                  items: ['male', 'female'].map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _gender = value as String;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField(
                  decoration: InputDecoration(
                    labelText: 'Activity Level',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: _activityLevel,
                  items: {
                    'Sedentary': 1.2,
                    'Lightly Active': 1.375,
                    'Moderately Active': 1.55,
                    'Very Active': 1.725,
                    'Extremely Active': 1.9,
                  }.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.value,
                      child: Text(entry.key),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your activity level';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _activityLevel = value as double;
                    });
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _calculateTDEE,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Calculate my TDEE',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Your TDEE is: ${_tdee.toStringAsFixed(2)}',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    int month1 = currentDate.month;
    int month2 = birthDate.month;
    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = currentDate.day;
      int day2 = birthDate.day;
      if (day2 > day1) {
        age--;
      }
    }
    return age;
  }
}