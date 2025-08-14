import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/UI/components/glass.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/UI/components/user_autocomplete.dart';
import 'package:alphanessone/providers/providers.dart';

class MaxRMSearchBar extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const MaxRMSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassLite(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      child: UserTypeAheadField(
        controller: controller,
        focusNode: focusNode,
        onSelected: (UserModel user) {
          ref.read(selectedUserIdProvider.notifier).state = user.id;
        },
        onChanged: (String value) {
          final allUsers = ref.read(userListProvider);
          final filteredUsers = allUsers
              .where(
                (user) => user.name
                        .toLowerCase()
                        .contains(value.toLowerCase()) ||
                    user.email.toLowerCase().contains(value.toLowerCase()),
              )
              .toList();
          ref.read(filteredUserListProvider.notifier).state = filteredUsers;
        },
      ),
    );
  }
}


