import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:kasir_app/src/features/users/bloc/user_bloc.dart';
import 'package:uuid/uuid.dart';

class AddEditUserDialog extends StatefulWidget {
  final UserModel? user; // Optional user for editing
  final Function(UserModel user, String? newPassword) onSave;

  const AddEditUserDialog({super.key, this.user, required this.onSave});

  @override
  State<AddEditUserDialog> createState() => _AddEditUserDialogState();
}

class _AddEditUserDialogState extends State<AddEditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.employee;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _usernameController.text = widget.user!.username;
      _selectedRole = widget.user!.role;
      // Password is not pre-filled for security reasons, user must re-enter for update
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Ubah Pengguna' : 'Tambah Pengguna Baru'),
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
                decoration: InputDecoration(
                  labelText: isEditing ? 'Password Baru (kosongkan jika tidak diubah)' : 'Password',
                ),
                obscureText: true,
                validator: (value) {
                  if (!isEditing && (value == null || value.isEmpty)) {
                    return 'Password tidak boleh kosong';
                  }
                  if (value != null && value.isNotEmpty && value.length < 4) {
                    return 'Password minimal 4 karakter';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<UserRole>(
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
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final String userId = isEditing ? widget.user!.id : const Uuid().v4();
              final String username = _usernameController.text;
              final UserRole role = _selectedRole;
              final String? newPassword = _passwordController.text.isNotEmpty ? _passwordController.text : null;

              final UserModel newUser = UserModel(
                id: userId,
                username: username,
                hashedPassword: isEditing ? widget.user!.hashedPassword : '', // Will be hashed in repo for new user
                role: role,
              );
              widget.onSave(newUser, newPassword);
              Navigator.pop(context);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
