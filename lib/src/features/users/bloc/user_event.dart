
part of 'user_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
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
