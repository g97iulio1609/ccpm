import 'package:alphanessone/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../controller/training_program_controller.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AthleteSelectionDialog extends ConsumerWidget {
  final TrainingProgramController controller;

  const AthleteSelectionDialog({required this.controller, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersService = ref.watch(usersServiceProvider);
    final athleteNameController = TextEditingController();
    final focusNode = FocusNode();
    final suggestionsController = SuggestionsController<UserModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radii.xl),
          border: Border.all(
            color: colorScheme.outline.withAlpha(26),
          ),
          boxShadow: AppTheme.elevations.large,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(76),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radii.xl),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.sm,
                      vertical: AppTheme.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(76),
                      borderRadius: BorderRadius.circular(AppTheme.radii.full),
                    ),
                    child: Icon(
                      Icons.person_search,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  Text(
                    'Seleziona Atleta',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nome Atleta',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.surfaceContainerHighest,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.xs),
                  FutureBuilder<String>(
                    future: controller.athleteName,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        athleteNameController.text = snapshot.data ?? '';
                      }
                      return StreamBuilder<List<UserModel>>(
                        stream: usersService.getUsers(),
                        builder:
                            (context, AsyncSnapshot<List<UserModel>> snapshot) {
                          if (snapshot.hasData) {
                            final users = snapshot.data!;
                            return Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withAlpha(76),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radii.lg),
                                border: Border.all(
                                  color: colorScheme.outline.withAlpha(26),
                                ),
                              ),
                              child: TypeAheadField<UserModel>(
                                suggestionsController: suggestionsController,
                                suggestionsCallback: (pattern) {
                                  return users.where((user) {
                                    final nameLower = user.name.toLowerCase();
                                    final patternLower = pattern.toLowerCase();
                                    return nameLower.contains(patternLower);
                                  }).toList();
                                },
                                itemBuilder: (context, suggestion) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color:
                                              colorScheme.outline.withAlpha(26),
                                        ),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        padding:
                                            EdgeInsets.all(AppTheme.spacing.xs),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer
                                              .withAlpha(76),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        suggestion.name,
                                        style:
                                            theme.textTheme.bodyLarge?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                onSelected: (suggestion) {
                                  controller.athleteId = suggestion.id;
                                  athleteNameController.text = suggestion.name;
                                },
                                emptyBuilder: (context) => Padding(
                                  padding: EdgeInsets.all(AppTheme.spacing.lg),
                                  child: Text(
                                    'Nessun atleta trovato',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                    ),
                                  ),
                                ),
                                hideWithKeyboard: true,
                                hideOnSelect: true,
                                retainOnLoading: false,
                                decorationBuilder: (context, child) {
                                  return Material(
                                    color: Colors.transparent,
                                    child: child,
                                  );
                                },
                                controller: athleteNameController,
                                focusNode: focusNode,
                                builder: (context, suggestionsController,
                                    focusNode) {
                                  return TextFormField(
                                    controller: athleteNameController,
                                    focusNode: focusNode,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Cerca atleta...',
                                      hintStyle:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        color: colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.5),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: colorScheme.primary,
                                        size: 20,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          EdgeInsets.all(AppTheme.spacing.md),
                                    ),
                                  );
                                },
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Text(
                              'Errore: ${snapshot.error}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.error,
                              ),
                            );
                          } else {
                            return Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(76),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radii.xl),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.lg,
                        vertical: AppTheme.spacing.md,
                      ),
                    ),
                    child: Text(
                      'Annulla',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withAlpha(204),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.lg,
                            vertical: AppTheme.spacing.md,
                          ),
                          child: Text(
                            'Conferma',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
