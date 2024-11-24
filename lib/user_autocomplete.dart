import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../common/generic_autocomplete.dart';
import '../providers/providers.dart';

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
    final filteredUsers = ref.watch(filteredUserListProvider);

    return GenericAutocompleteField<UserModel>(
      controller: controller,
      labelText: 'Search User',
      prefixIcon: Icons.person,
      suggestionsCallback: (pattern) async {
        onChanged(pattern);
        return filteredUsers;
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion.name),
          subtitle: Text('Email: ${suggestion.email}'),
        );
      },
      onSelected: (suggestion) {
        controller.text = suggestion.name;
        onSelected(suggestion);
        ref.read(selectedUserIdProvider.notifier).state = suggestion.id;
      },
      onChanged: onChanged,
      emptyBuilder: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No users found'),
      ),
    );
  }
}