
part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

// State saat aplikasi baru dimulai atau tidak ada sesi
class AuthenticationInitial extends AuthState {}

// State saat pengguna berhasil diautentikasi
class AuthenticationAuthenticated extends AuthState {
  final UserModel user;

  const AuthenticationAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

// State saat tidak ada pengguna yang login
class AuthenticationUnauthenticated extends AuthState {}
