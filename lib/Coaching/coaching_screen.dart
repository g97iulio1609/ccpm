import 'package:alphanessone/providers/providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../user_autocomplete.dart';
import '../../models/user_model.dart';
import '../../services/coaching_service.dart';

final userListProvider = StateProvider<List<UserModel>>((ref) => []);
final filteredUserListProvider = StateProvider<List<UserModel>>((ref) => []);

class ProgramsScreen extends HookConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController typeAheadController = useTextEditingController();
    final FocusNode focusNode = useFocusNode();
    final filteredUserList = ref.watch(filteredUserListProvider);
    final usersService = ref.watch(usersServiceProvider);
    final coachingService = ref.watch(coachingServiceProvider);
    final currentUserRole = usersService.getCurrentUserRole();
    final currentUserId = usersService.getCurrentUserId();

    useEffect(() {
      Future<void> fetchUsers() async {
        List<UserModel> users = [];
        if (currentUserRole == 'admin') {
          final snapshot = await FirebaseFirestore.instance.collection('users').get();
          users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        } else if (currentUserRole == 'coach') {
          final associations = await coachingService.getUserAssociations(currentUserId).first;
          for (var association in associations) {
            if (association.status == 'accepted') {
              final athlete = await usersService.getUserById(association.athleteId);
              if (athlete != null) {
                users.add(athlete);
              }
            }
          }
        }
        ref.read(userListProvider.notifier).state = users;
        ref.read(filteredUserListProvider.notifier).state = users;
      }

      fetchUsers();
      return null;
    }, []);

    void filterUsers(String pattern) {
      final allUsers = ref.read(userListProvider);
      if (pattern.isEmpty) {
        ref.read(filteredUserListProvider.notifier).state = allUsers;
      } else {
        final filtered = allUsers
            .where((user) => user.name.toLowerCase().contains(pattern.toLowerCase()))
            .toList();
        ref.read(filteredUserListProvider.notifier).state = filtered;
      }
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: UserTypeAheadField(
              controller: typeAheadController,
              focusNode: focusNode,
              onSelected: (UserModel selectedUser) {},
              onChanged: filterUsers,
            ),
          ),
          Expanded(
            child: filteredUserList.isEmpty
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
                    itemCount: filteredUserList.length,
                    itemBuilder: (context, index) {
                      final user = filteredUserList[index];
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
