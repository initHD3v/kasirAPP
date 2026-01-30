
import 'package:kasir_app/src/data/models/user_model.dart';
part of 'user_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsers extends UserEvent {}

class AddUser extends UserEvent {
  final String username;
  final String password;
  final UserRole role;

  const AddUser({
    required this.username,
    required this.password,
    required this.role,
  });

  @override
  List<Object> get props => [username, password, role];
}

class UpdateUser extends UserEvent {
  final UserModel user;
  final String? password; // Optional: new password if it's being updated

  const UpdateUser(this.user, {this.password});

  @override
  List<Object?> get props => [user, password];
}

class DeleteUser extends UserEvent {
  final String userId;

  const DeleteUser(this.userId);

  @override
  List<Object> get props => [userId];
}
