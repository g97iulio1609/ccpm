// form_fields.dart
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
      decoration: const InputDecoration(
          labelText: 'Username', border: OutlineInputBorder()),
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
      decoration: const InputDecoration(
        labelText: 'Gender',
        border: OutlineInputBorder(),
      ),
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
      validator: (value) =>
          (value == null || value.isEmpty || !value.contains('@'))
              ? 'Please enter a valid email address'
              : null,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
          labelText: 'Email address', border: OutlineInputBorder()),
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
      decoration: const InputDecoration(
          labelText: 'Password', border: OutlineInputBorder()),
      obscureText: true,
      onSaved: (value) => userPassword.value = value ?? '',
    );
  }
}
