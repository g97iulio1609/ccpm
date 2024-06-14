import 'package:alphanessone/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'controller/training_program_controller.dart';
import 'package:alphanessone/providers/providers.dart';

class AthleteSelectionDialog extends ConsumerWidget {
  final TrainingProgramController controller;

  const AthleteSelectionDialog({required this.controller, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersService = ref.watch(usersServiceProvider);
    final athleteNameController = TextEditingController();
    final focusNode = FocusNode();
    final suggestionsController = SuggestionsController<UserModel>();

    return AlertDialog(
      title: const Text('Select Athlete'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<String>(
          future: controller.athleteName,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              athleteNameController.text = snapshot.data ?? '';
            }
            return StreamBuilder<List<UserModel>>(
              stream: usersService.getUsers(),
              builder: (context, AsyncSnapshot<List<UserModel>> snapshot) {
                if (snapshot.hasData) {
                  final users = snapshot.data!;
                  return TypeAheadField<UserModel>(
                    suggestionsController: suggestionsController,
                    suggestionsCallback: (pattern) {
                      return users.where((user) {
                        final nameLower = user.name.toLowerCase();
                        final patternLower = pattern.toLowerCase();
                        return nameLower.contains(patternLower);
                      }).toList();
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion.name),
                      );
                    },
                    onSelected: (suggestion) {
                      controller.athleteId = suggestion.id;
                      athleteNameController.text = suggestion.name;
                    },
                    emptyBuilder: (context) => const SizedBox.shrink(),
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
                    controller: athleteNameController,
                    focusNode: focusNode,
                    builder: (context, suggestionsController, focusNode) {
                      return TextField(
                        controller: athleteNameController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Athlete Name',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return const CircularProgressIndicator();
                }
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}