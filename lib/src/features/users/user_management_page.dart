
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:kasir_app/src/data/repositories/user_repository.dart';
import 'package:kasir_app/src/features/users/bloc/user_bloc.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserBloc(getIt<UserRepository>())..add(LoadUsers()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Pengguna'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => GoRouter.of(context).go('/'),
          ),
        ),
        body: BlocConsumer<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserOperationFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state is UsersLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is UsersLoaded) {
              return ListView.separated(
                itemCount: state.users.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final user = state.users[index];
                  return ListTile(
                    leading: Icon(user.role == UserRole.admin ? Icons.admin_panel_settings : Icons.person_outline),
                    title: Text(user.username),
                    subtitle: Text(user.role.name),
                  );
                },
              );
            }
            return const Center(child: Text('Memuat data pengguna...'));
          },
        ),
        floatingActionButton: Builder(builder: (context) {
          return FloatingActionButton(
            onPressed: () => _showAddUserDialog(context),
            child: const Icon(Icons.add),
          );
        }),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _usernameController = TextEditingController();
    final _passwordController = TextEditingController();
    UserRole _selectedRole = UserRole.employee;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Pengguna Baru'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Username tidak boleh kosong';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
                      if (value.length < 4) return 'Password minimal 4 karakter';
                      return null;
                    },
                  ),
                  StatefulBuilder(builder: (context, setState) {
                    return DropdownButtonFormField<UserRole>(
                      value: _selectedRole,
                      decoration: const InputDecoration(labelText: 'Peran'),
                      items: UserRole.values.map((UserRole role) {
                        return DropdownMenuItem<UserRole>(
                          value: role,
                          child: Text(role.name),
                        );
                      }).toList(),
                      onChanged: (UserRole? newValue) {
                        setState(() {
                          _selectedRole = newValue!;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<UserBloc>().add(AddUser(
                        username: _usernameController.text,
                        password: _passwordController.text,
                        role: _selectedRole,
                      ));
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
