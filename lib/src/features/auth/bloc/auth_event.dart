
part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

// Event saat pengguna berhasil login
class LoggedIn extends AuthEvent {
  final UserModel user;

  const LoggedIn({required this.user});

  @override
  List<Object> get props => [user];
}

// Event saat pengguna logout
class LoggedOut extends AuthEvent {}

// Event saat aplikasi dimulai
class AppStarted extends AuthEvent {}
