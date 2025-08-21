import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../common/app_search_field.dart';
import '../../../providers/providers.dart';

class UserAutocompleteField extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(UserModel) onSelected;
  final void Function(String) onChanged;

  const UserAutocompleteField({
    required this.controller,
    required this.focusNode,
    required this.onSelected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppSearchField<UserModel>(
      controller: controller,
      hintText: 'Search User',
      prefixIcon: Icons.person,
      suggestionsCallback: (pattern) async {
        // Calcolo sempre dai dati sorgente per avere aggiornamenti coerenti
        final allUsers = ref.read(userListProvider);
        final q = pattern.toLowerCase();
        final matches = allUsers.where(
          (u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q),
        );
        onChanged(pattern);
        return matches.toList();
      },
      itemBuilder: (context, suggestion) {
        return ListTile(title: Text(suggestion.name), subtitle: Text('Email: ${suggestion.email}'));
      },
      onSelected: (suggestion) {
        controller.text = suggestion.name;
        onSelected(suggestion);
        ref.read(selectedUserIdProvider.notifier).state = suggestion.id;
      },
      onChanged: onChanged,
      emptyBuilder: const Padding(padding: EdgeInsets.all(8.0), child: Text('No users found')),
    );
  }
}
