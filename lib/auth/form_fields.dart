import 'package:flutter/material.dart';

class UsernameField extends StatelessWidget {
  const UsernameField({super.key, required this.userName});

  final ValueNotifier<String> userName;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const ValueKey('username'),
      validator: (value) => (value == null || value.isEmpty || value.length < 4)
          ? 'Please enter at least 4 characters'
          : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        labelText: 'Username',
        labelStyle: const TextStyle(
          color: Color(0xFFB3B3B3),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      onSaved: (value) => userName.value = value ?? '',
    );
  }
}

class GenderField extends StatelessWidget {
  const GenderField({super.key, required this.userGender});

  final ValueNotifier<String> userGender;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: const ValueKey('gender'),
      value: userGender.value,
      onChanged: (value) => userGender.value = value ?? '',
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        labelText: 'Gender',
        labelStyle: const TextStyle(
          color: Color(0xFFB3B3B3),
        ),
      ),
      dropdownColor: const Color(0xFF121212),
      style: const TextStyle(color: Colors.white),
      items: const [
        DropdownMenuItem(
          value: '',
          child: Text('Select Gender'),
        ),
        DropdownMenuItem(
          value: 'Male',
          child: Text('Male'),
        ),
        DropdownMenuItem(
          value: 'Female',
          child: Text('Female'),
        ),
        DropdownMenuItem(
          value: 'Other',
          child: Text('Other'),
        ),
      ],
    );
  }
}

class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.userEmail});

  final ValueNotifier<String> userEmail;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const ValueKey('email'),
      validator: (value) => (value == null || value.isEmpty || !value.contains('@'))
          ? 'Please enter a valid email address'
          : null,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        labelText: 'Email address',
        labelStyle: const TextStyle(
          color: Color(0xFFB3B3B3),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      onSaved: (value) => userEmail.value = value ?? '',
    );
  }
}

class PasswordField extends StatelessWidget {
  const PasswordField({super.key, required this.userPassword});

  final ValueNotifier<String> userPassword;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const ValueKey('password'),
      validator: (value) => (value == null || value.isEmpty || value.length < 7)
          ? 'Password must be at least 7 characters long'
          : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        labelText: 'Password',
        labelStyle: const TextStyle(
          color: Color(0xFFB3B3B3),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      obscureText: true,
      onSaved: (value) => userPassword.value = value ?? '',
    );
  }
}