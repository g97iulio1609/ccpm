import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/services/users_services.dart';

class UsersDashboard extends ConsumerStatefulWidget {
  const UsersDashboard({super.key});

  @override
  ConsumerState<UsersDashboard> createState() => _UsersDashboardState();
}

class _UsersDashboardState extends ConsumerState<UsersDashboard> {
  late UsersService _usersService;

  @override
  void initState() {
    super.initState();
    _usersService = ref.read(usersServiceProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserSearchField(usersService: _usersService),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _usersService.getUsers(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ErrorView(error: snapshot.error.toString());
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = snapshot.data ?? [];
                  return users.isEmpty
                      ? const Center(child: Text('No users found'))
                      : UsersList(
                          users: users, onDeleteUser: _showDeleteConfirmation);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => CreateUserDialog(
        onUserCreated: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User created successfully')),
          );
        },
      ),
    );
  }

void _showDeleteConfirmation(UserModel user) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('Elimina Utente'),
      content: Text('Sei sicuro di voler eliminare ${user.name}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop(); // Chiudi il dialogo di conferma
            await _deleteUser(user); // Elimina l'utente
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );
}

Future<void> _deleteUser(UserModel user) async {
  try {
    await _usersService.deleteUser(user.id);
    if (mounted) {
      // Mostra un messaggio di successo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Utente ${user.name} eliminato con successo')),
      );
    }
  } catch (e) {
    if (mounted) {
      // Mostra un messaggio di errore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'eliminazione dell\'utente: $e')),
      );
    }
  }
}

}

class UserSearchField extends StatelessWidget {
  final UsersService usersService;

  const UserSearchField({super.key, required this.usersService});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search users',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: usersService.searchUsers,
    );
  }
}

class UsersList extends StatelessWidget {
  final List<UserModel> users;
  final Function(UserModel) onDeleteUser;

  const UsersList({super.key, required this.users, required this.onDeleteUser});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => UserCard(
        user: users[index],
        onTap: () => context.go('/user_profile/${users[index].id}'),
        onDelete: () => onDeleteUser(users[index]),
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              user.photoURL.isNotEmpty ? NetworkImage(user.photoURL) : null,
          child: user.photoURL.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(user.name),
        subtitle: Text('${user.email}\nRole: ${user.role}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}

class CreateUserDialog extends ConsumerStatefulWidget {
  final VoidCallback onUserCreated;

  const CreateUserDialog({super.key, required this.onUserCreated});

  @override
  ConsumerState<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'client';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create User'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter a name' : null,
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter an email' : null,
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) =>
                  value!.isEmpty ? 'Please enter a password' : null,
            ),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              onChanged: (value) => setState(() => _selectedRole = value!),
              items: ['admin', 'client', 'coach']
                  .map((role) =>
                      DropdownMenuItem(value: role, child: Text(role)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Role'),
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
          onPressed: _createUser,
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(usersServiceProvider).createUser(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              role: _selectedRole,
            );
        if (mounted) {
          widget.onUserCreated();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating user: $e')),
          );
        }
      }
    }
  }
}

class ErrorView extends StatelessWidget {
  final String error;

  const ErrorView({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
