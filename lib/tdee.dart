import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'users_services.dart';

class TDEEScreen extends ConsumerStatefulWidget {
  final String userId;

  const TDEEScreen({super.key, required this.userId});

  @override
  _TDEEScreenState createState() => _TDEEScreenState();
}

class _TDEEScreenState extends ConsumerState<TDEEScreen> {
  final _formKey = GlobalKey<FormState>();

  int _age = 0;
  int _height = 0;
  int _weight = 0;
  String _gender = '';
  double _activityLevel = 1.2;

  void _calculateTDEE() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      double bmr;
      if (_gender == 'male') {
        bmr = 88.362 + (13.397 * _weight) + (4.799 * _height) - (5.677 * _age);
      } else {
        bmr = 447.593 + (9.247 * _weight) + (3.098 * _height) - (4.330 * _age);
      }

      double tdee = bmr * _activityLevel;

      final usersService = ref.read(usersServiceProvider);
      await usersService.updateUser(widget.userId, {
        'age': _age,
        'height': _height,
        'weight': _weight,
        'gender': _gender,
        'activityLevel': _activityLevel,
        'tdee': tdee,
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculate TDEE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _calculateTDEE,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  return null;
                },
                onSaved: (value) => _age = int.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your height';
                  }
                  return null;
                },
                onSaved: (value) => _height = int.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  return null;
                },
                onSaved: (value) => _weight = int.parse(value!),
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['male', 'female'].map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
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
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Activity Level'),
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
            ],
          ),
        ),
      ),
    );
  }
}