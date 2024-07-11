import 'package:alphanessone/services/users_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/coaching_service.dart';

// Providers
final userServiceProvider = Provider<UsersService>((ref) {
  return UsersService(ref, FirebaseFirestore.instance, FirebaseAuth.instance);
});

final filteredUsersStreamProvider = StreamProvider.autoDispose<List<UserModel>>((ref) async* {
  final userService = ref.watch(userServiceProvider);
  final coachingService = ref.watch(coachingServiceProvider);
  final currentUserRole = userService.getCurrentUserRole();
  final currentUserId = userService.getCurrentUserId();

  if (currentUserRole == 'admin') {
    yield* userService.getUsers();
  } else if (currentUserRole == 'coach') {
    final associations = await coachingService.getUserAssociations(currentUserId).first;
    final acceptedAthleteIds = associations
        .where((association) => association.status == 'accepted')
        .map((association) => association.athleteId)
        .toSet();

    yield* userService.getUsers().map((users) => 
      users.where((user) => acceptedAthleteIds.contains(user.id)).toList()
    );
  } else {
    yield [];
  }
});

class UserTypeAheadField extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(UserModel) onSelected;
  final void Function(String) onChanged;

  const UserTypeAheadField({
    required this.controller,
    required this.focusNode,
    required this.onSelected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredUsersAsyncValue = ref.watch(filteredUsersStreamProvider);

    return filteredUsersAsyncValue.when(
      data: (users) {
        return TypeAheadField<UserModel>(
          suggestionsCallback: (pattern) async {
            onChanged(pattern);
            return users.where((user) => 
              user.name.toLowerCase().contains(pattern.toLowerCase()) ||
              user.email.toLowerCase().contains(pattern.toLowerCase())
            ).toList();
          },
          itemBuilder: (context, UserModel suggestion) {
            return ListTile(
              title: Text(suggestion.name),
              subtitle: Text('Email: ${suggestion.email}'),
            );
          },
          onSelected: (UserModel suggestion) {
            controller.text = suggestion.name;
            onSelected(suggestion);
          },
          emptyBuilder: (context) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No users found'),
          ),
          hideWithKeyboard: true,
          hideOnSelect: true,
          retainOnLoading: false,
          decorationBuilder: (context, child) {
            return Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: child,
            );
          },
          offset: const Offset(0, 8),
          constraints: const BoxConstraints(maxHeight: 200),
          controller: controller,
          focusNode: focusNode,
          builder: (context, suggestionsController, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Search User',
              ),
            );
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}