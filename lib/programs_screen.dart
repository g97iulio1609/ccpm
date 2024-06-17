import 'package:alphanessone/providers/providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'user_type_ahead_field.dart'; // Assicurati di importare il file corretto
import '../models/user_model.dart'; // Assicurati di importare il modello UserModel

final userListProvider = StateProvider<List<QueryDocumentSnapshot>>((ref) => []);
final filteredUserListProvider = StateProvider<List<QueryDocumentSnapshot>>((ref) => []);

class ProgramsScreen extends HookConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);
    final TextEditingController typeAheadController = useTextEditingController();
    final FocusNode focusNode = useFocusNode();
    final userList = ref.watch(userListProvider);
    final filteredUserList = ref.watch(filteredUserListProvider);

    useEffect(() {
      // Inizializzare lo stato con la lista completa degli utenti quando il widget viene creato
      final subscription = FirebaseFirestore.instance.collection('users').snapshots().listen((snapshot) {
        ref.read(userListProvider.notifier).state = snapshot.docs;
        ref.read(filteredUserListProvider.notifier).state = snapshot.docs;
      });
      return subscription.cancel;
    }, []); // La lista vuota indica che questo effetto viene eseguito solo una volta

    void filterUsers(String pattern) {
      final allUsers = ref.read(userListProvider);
      if (pattern.isEmpty) {
        ref.read(filteredUserListProvider.notifier).state = allUsers;
      } else {
        ref.read(filteredUserListProvider.notifier).state = allUsers.where((user) {
          return user['name'].toLowerCase().contains(pattern.toLowerCase());
        }).toList();
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
              onSelected: (UserModel selectedUser) {
                // Non è necessario filtrare qui, poiché il filtro è gestito dal campo di testo
              },
              onChanged: filterUsers,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredUserList.length,
              itemBuilder: (context, index) {
                final user = filteredUserList[index];
                final userName = user['name'];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: InkWell(
                    onTap: () => context.go('/user_programs/${user.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        userName,
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
