
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:kasir_app/src/data/repositories/user_repository.dart';
import 'package:kasir_app/src/features/users/bloc/user_bloc.dart';
import 'package:kasir_app/src/features/users/widgets/add_edit_user_dialog.dart'; // New import
import 'package:kasir_app/src/features/auth/bloc/auth_bloc.dart'; // New import

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
            } else if (state is UsersLoaded) {
              // Ensure that if a user was updated/deleted, the snackbar is shown if needed.
              // For simplicity, we just reload the users after any operation in BLoC.
            }
          },
          builder: (context, state) {
            if (state is UsersLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is UsersLoaded) {
              final currentLoggedInUser = (context.read<AuthBloc>().state as AuthenticationAuthenticated).user;
              return ListView.separated(
                itemCount: state.users.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final user = state.users[index];
                  final bool isAdmin = currentLoggedInUser.role == UserRole.admin;
                  final bool isCurrentUser = currentLoggedInUser.id == user.id;

                  return ListTile(
                    leading: Icon(user.role == UserRole.admin ? Icons.admin_panel_settings : Icons.person_outline),
                    title: Text(user.username),
                    subtitle: Text(user.role.name),
                    trailing: isAdmin
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (dialogContext) {
                                      return AddEditUserDialog(
                                        user: user,
                                        onSave: (updatedUser, newPassword) {
                                          context.read<UserBloc>().add(UpdateUser(updatedUser, password: newPassword));
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: isCurrentUser ? Colors.grey : Colors.redAccent),
                                onPressed: isCurrentUser // Prevent admin from deleting themselves
                                    ? null
                                    : () => _showDeleteConfirmation(context, user.id, user.username),
                              ),
                            ],
                          )
                        : null,
                  );
                },
              );
            }
            return const Center(child: Text('Memuat data pengguna...'));
          },
        ),
        floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final bool isAdmin = authState is AuthenticationAuthenticated && authState.user.role == UserRole.admin;
            if (isAdmin) {
              return FloatingActionButton(
                heroTag: 'addUserFab',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return AddEditUserDialog(
                        onSave: (newUser, newPassword) {
                          context.read<UserBloc>().add(AddUser(
                                username: newUser.username,
                                password: newPassword ?? '', // AddUser expects a non-null password
                                role: newUser.role,
                              ));
                        },
                      );
                    },
                  );
                },
                child: const Icon(Icons.add),
              );
            }
            return const SizedBox.shrink(); // Hide FAB if not admin
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String userId, String username) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Pengguna'),
          content: Text('Apakah Anda yakin ingin menghapus pengguna $username?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () {
                context.read<UserBloc>().add(DeleteUser(userId));
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
