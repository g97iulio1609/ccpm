import 'package:alphanessone/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../controller/training_program_controller.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import 'package:alphanessone/common/app_search_field.dart';

class AthleteSelectionDialog extends ConsumerWidget {
  final TrainingProgramController controller;

  const AthleteSelectionDialog({required this.controller, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersService = ref.watch(usersServiceProvider);
    final athleteNameController = TextEditingController();
    // Rimosso: focusNode e suggestionsController non più necessari con componente unificato
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppDialog(
      title: Text(
        'Seleziona Atleta',
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.sm,
          vertical: AppTheme.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(76),
          borderRadius: BorderRadius.circular(AppTheme.radii.full),
        ),
        child: Icon(Icons.person_search, color: colorScheme.primary, size: 20),
      ),
      actions: [
        AppDialogHelpers.buildCancelButton(context: context),
        AppDialogHelpers.buildActionButton(
          context: context,
          label: 'Conferma',
          onPressed: () => Navigator.pop(context),
        ),
      ],
      child: FutureBuilder<String>(
        future: controller.athleteName,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            athleteNameController.text = snapshot.data ?? '';
          }
          return StreamBuilder<List<UserModel>>(
            stream: usersService.getUsers(),
            builder: (context, AsyncSnapshot<List<UserModel>> snap) {
              if (snap.hasData) {
                final users = snap.data!;
                return AppSearchField<UserModel>(
                  controller: athleteNameController,
                  hintText: 'Cerca atleta...',
                  prefixIcon: Icons.search,
                  suggestionsCallback: (pattern) async {
                    return users
                        .where(
                          (u) => u.name.toLowerCase().contains(
                            pattern.toLowerCase(),
                          ),
                        )
                        .toList();
                  },
                  itemBuilder: (context, user) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer.withAlpha(
                        76,
                      ),
                      child: Icon(Icons.person, color: colorScheme.primary),
                    ),
                    title: Text(user.name),
                  ),
                  onSelected: (user) {
                    controller.athleteId = user.id;
                    athleteNameController.text = user.name;
                  },
                );
              } else if (snap.hasError) {
                return Text(
                  'Errore: ${snap.error}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                );
              }
            },
          );
        },
      ),
    );
  }
}
