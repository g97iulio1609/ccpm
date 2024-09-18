import 'package:alphanessone/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../models/user_model.dart';

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

    return TypeAheadField<UserModel>(
      suggestionsCallback: (pattern) async {
        onChanged(pattern);
        return filteredUsers;
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
        ref.read(selectedUserIdProvider.notifier).state = suggestion.id;
        FocusScope.of(context).unfocus();
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
          borderRadius: BorderRadius.circular(12),
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
          decoration: InputDecoration(
            labelText: 'Search User',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        );
      },
    );
  }
}