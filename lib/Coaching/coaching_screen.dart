import 'package:alphanessone/providers/providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../user_autocomplete.dart';
import '../../models/user_model.dart';
import '../UI/components/card.dart';

class CoachingScreen extends HookConsumerWidget {
  const CoachingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController typeAheadController = useTextEditingController();
    final FocusNode focusNode = useFocusNode();
    final usersService = ref.watch(usersServiceProvider);
    final coachingService = ref.watch(coachingServiceProvider);
    final currentUserRole = usersService.getCurrentUserRole();
    final currentUserId = usersService.getCurrentUserId();
    final theme = Theme.of(context);

    // Recupero degli utenti in base al ruolo
    final usersFuture = useMemoized(() async {
      if (currentUserRole == 'admin') {
        final snapshot = await FirebaseFirestore.instance.collection('users').get();
        return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      } else if (currentUserRole == 'coach') {
        final associations = await coachingService.getCoachAssociations(currentUserId).first;
        List<UserModel> users = [];
        for (var association in associations) {
          if (association.status == 'accepted') {
            final athlete = await usersService.getUserById(association.athleteId);
            if (athlete != null) {
              users.add(athlete);
            }
          }
        }
        return users;
      } else {
        return <UserModel>[];
      }
    }, [currentUserRole, currentUserId]);

    final snapshot = useFuture(usersFuture);

    // Aggiornamento della lista degli utenti dopo il caricamento
    useEffect(() {
      if (snapshot.hasData) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(userListProvider.notifier).state = snapshot.data!;
        });
      }
      return null;
    }, [snapshot.data, snapshot.error]);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.92),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Barra di ricerca
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: UserTypeAheadField(
                      controller: typeAheadController,
                      focusNode: focusNode,
                      onSelected: (UserModel selectedUser) {
                        context.go('/user_programs/${selectedUser.id}');
                      },
                      onChanged: (pattern) {
                        final allUsers = ref.read(userListProvider);
                        final filteredUsers = allUsers.where((user) =>
                          user.name.toLowerCase().contains(pattern.toLowerCase()) ||
                          user.email.toLowerCase().contains(pattern.toLowerCase())
                        ).toList();
                        ref.read(filteredUserListProvider.notifier).state = filteredUsers;
                      },
                    ),
                  ),
                ),
              ),
              // Lista degli utenti
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : snapshot.hasError
                        ? Center(
                            child: Text(
                              'Errore nel caricamento degli utenti: ${snapshot.error}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          )
                        : snapshot.data!.isEmpty
                            ? Center(
                                child: Text(
                                  currentUserRole == 'coach'
                                      ? 'Nessun atleta è stato associato'
                                      : 'Nessun utente trovato',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  // Determina il numero di colonne in base alla larghezza dello schermo
                                  final crossAxisCount = () {
                                    if (constraints.maxWidth > 1200) return 4; // Desktop large
                                    if (constraints.maxWidth > 900) return 3;  // Desktop
                                    if (constraints.maxWidth > 600) return 2;  // Tablet
                                    return 1; // Mobile
                                  }();

                                  final horizontalPadding = crossAxisCount == 1 ? 16.0 : 24.0;
                                  final spacing = 20.0;

                                  // Definire childAspectRatio dinamicamente in base al numero di colonne
                                  double childAspectRatio;
                                  switch (crossAxisCount) {
                                    case 1:
                                      childAspectRatio = 3.0; // Più largo, altezza minima per mobile
                                      break;
                                    case 2:
                                      childAspectRatio = 1.8;
                                      break;
                                    case 3:
                                      childAspectRatio = 1.6;
                                      break;
                                    default:
                                      childAspectRatio = 1.4;
                                  }

                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: horizontalPadding,
                                      vertical: spacing / 2,
                                    ),
                                    child: GridView.builder(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        mainAxisSpacing: spacing,
                                        crossAxisSpacing: spacing,
                                        childAspectRatio: childAspectRatio,
                                      ),
                                      itemCount: snapshot.data!.length,
                                      itemBuilder: (context, index) {
                                        final user = snapshot.data![index];
                                        return ActionCard(
                                          onTap: () => context.go('/user_programs/${user.id}'),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                          title: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  user.name,
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: -0.5,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  user.email,
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: theme.colorScheme.secondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            IconButtonWithBackground(
                                              icon: Icons.chevron_right,
                                              color: theme.colorScheme.primary,
                                              onPressed: () => context.go('/user_programs/${user.id}'),
                                            ),
                                          ],
                                          bottomContent: const [],
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}