import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'controller/training_program_controller.dart';
import '../users_services.dart';

class AthleteSelectionDialog extends ConsumerWidget {
  final TrainingProgramController controller;

  const AthleteSelectionDialog({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersService = ref.watch(usersServiceProvider);
    final athleteNameController = TextEditingController(text: '');

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
                    suggestionsCallback: (search) async {
                      return users
                          .where((user) => user.name.toLowerCase().contains(search.toLowerCase()))
                          .toList();
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
                    offset: const Offset(0, 8),
                    decorationBuilder: (context, suggestionsBox) {
                      return Material(
                        elevation: 4,
                        color: Theme.of(context).colorScheme.surface,
                        child: suggestionsBox,
                      );
                    },
                    builder: (context, controller, focusNode) {
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