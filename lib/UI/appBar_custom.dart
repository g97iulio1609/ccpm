import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../users_services.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.userRole,
    this.controller,
    required this.isLargeScreen,
    this.showBackButton = true,
    this.customActions = const [],
    this.title,
  });

  final String userRole;
  final TrainingProgramController? controller;
  final bool isLargeScreen;
  final bool showBackButton;
  final List<Widget> customActions;
  final String? title;

  String _getTitleForRoute(BuildContext context) {
    final String currentPath = GoRouterState.of(context).uri.toString();
    if (title != null) {
      return title!;
    }
    switch (currentPath) {
      case '/programs_screen':
        return 'I Miei Allenamenti';
      case '/exercises_list':
        return 'Esercizi';
      case '/maxrmdashboard':
        return 'Massimali';
      case '/user_profile':
        return 'Profilo Utente';
      case '/training_program':
        return 'Programma di Allenamento';
      case '/users_dashboard':
        return 'Gestione Utenti';
      case '/volume_dashboard':
        return 'Volume Allenamento';
      case '/user_programs':
        return 'Programmi Utente';
      case '/measurements':
        return 'Misurazioni Antropometriche';
      case '/tdee':
        return 'Fabbisogno Calorico';
      case '/macros_selector':
        return 'Calcolatore Macronutrienti';
      case '/training_gallery':
        return 'Galleria Allenamenti';
      case '/food_selector':
        return 'Selezione Alimento';
      default:
        break;
    }

    final pattern1 = RegExp(r'/programs_screen/user_programs/\w+/training_viewer/\w+/week_details/\w+$');
    if (pattern1.hasMatch(currentPath)) {
      return 'Dettagli Settimana';
    }

    final pattern2 = RegExp(r'/programs_screen/user_programs/\w+/training_viewer/\w+/week_details/\w+/workout_details/\w+$');
    if (pattern2.hasMatch(currentPath)) {
      return 'Dettagli Allenamento';
    }

    final pattern3 = RegExp(r'/programs_screen/user_programs/\w+/training_viewer/\w+/week_details/\w+/workout_details/\w+/exercise_details/\w+$');
    if (pattern3.hasMatch(currentPath)) {
      return 'Dettagli Esercizio';
    }

    final pattern4 = RegExp(r'/programs_screen/user_programs/\w+/training_viewer/\w+/week_details/\w+/workout_details/\w+/exercise_details/\w+/timer$');
    if (pattern4.hasMatch(currentPath)) {
      return 'Timer';
    }

    final weekPattern = RegExp(r'/programs_screen/user_programs/\w+/training_program/\w+/week/\d+$');
    if (weekPattern.hasMatch(currentPath)) {
      final weekIndex = int.parse(currentPath.split('/').last);
      return 'Settimana ${weekIndex + 1}';
    }

    return 'Alphaness One';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isBackButtonVisible = showBackButton && currentRoute.split('/').length > 2;

    return AppBar(
      title: Text(_getTitleForRoute(context)),
      backgroundColor: Colors.transparent,
      foregroundColor: Theme.of(context).colorScheme.onBackground,
      leading: isBackButtonVisible
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                final currentPath = GoRouterState.of(context).uri.toString();
                final trainingProgramWeekPattern = RegExp(r'/programs_screen/user_programs/\w+/training_program/\w+/week/\d+$');
                final trainingProgramPattern = RegExp(r'/programs_screen/user_programs/\w+/training_program/\w+$');

                if (trainingProgramWeekPattern.hasMatch(currentPath)) {
                  final programId = currentPath.split('/')[5];
                  final userId = currentPath.split('/')[3];
                  context.go('/programs_screen/user_programs/$userId/training_program/$programId');
                } else if (trainingProgramPattern.hasMatch(currentPath)) {
                  final userId = currentPath.split('/')[3];
                  context.go('/programs_screen/user_programs/$userId');
                } else {
                  context.pop();
                }
              },
            )
          : null,
      actions: [
        if (userRole == 'admin' && GoRouterState.of(context).uri.toString() == '/users_dashboard')
          IconButton(
            onPressed: () => _showAddUserDialog(context, ref),
            icon: const Icon(Icons.person_add),
          ),
        if (controller != null && currentRoute.startsWith('/programs_screen/user_programs/'))
          IconButton(
            onPressed: () => controller!.submitProgram(context),
            icon: const Icon(Icons.save),
          ),
        ...customActions,
      ],
    );
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final roleController = TextEditingController(text: 'client');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add User'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Role'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a role';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await ref.read(usersServiceProvider).createUser(
                        name: nameController.text,
                        email: emailController.text,
                        password: passwordController.text,
                        role: roleController.text,
                      );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
