import 'package:alphanessone/providers/providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../user_autocomplete.dart';
import '../../models/user_model.dart';

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

    useEffect(() {
      if (snapshot.hasData) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(userListProvider.notifier).state = snapshot.data!;
        });
      } 
      return null;
    }, [snapshot.data, snapshot.error]);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
          Expanded(
            child: snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : snapshot.hasError
                    ? Center(
                        child: Text(
                          'Errore nel caricamento degli utenti: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      )
                    : snapshot.data!.isEmpty
                        ? Center(
                            child: Text(
                              currentUserRole == 'coach'
                                  ? 'Nessun atleta è stato associato'
                                  : 'Nessun utente trovato',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final user = snapshot.data![index];
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: InkWell(
                                  onTap: () {
                                    context.go('/user_programs/${user.id}');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      user.name,
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}