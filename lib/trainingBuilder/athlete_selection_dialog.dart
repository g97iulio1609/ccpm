import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_program_controller.dart';
import '../users_services.dart';

class AthleteSelectionDialog extends ConsumerWidget {
  final TrainingProgramController controller;

  const AthleteSelectionDialog({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersService = ref.watch(usersServiceProvider);

    return AlertDialog(
      title: const Text('Select Athlete'),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<List<UserModel>>(
          stream: usersService.getUsers(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final users = snapshot.data!;
              return Autocomplete<UserModel>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<UserModel>.empty();
                  }
                  return users.where((user) => user.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                displayStringForOption: (user) => user.name,
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onChanged: (value) {},
                    decoration: const InputDecoration(
                      labelText: 'Athlete Name',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
                onSelected: (user) {
                  controller.athleteIdController.text = user.id;
                },
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return const CircularProgressIndicator();
            }
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