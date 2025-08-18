
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kasir_app/src/data/repositories/auth_repository.dart';
import 'package:kasir_app/src/features/auth/bloc/auth_bloc.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;
  final AuthBloc authBloc;

  LoginBloc({required this.authRepository, required this.authBloc}) : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
  }

  void _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      final user = await authRepository.login(event.username, event.password);

      if (user != null) {
        authBloc.add(LoggedIn(user: user));
        // Tidak perlu emit success state, karena navigasi akan ditangani oleh AuthBloc listener
        emit(LoginInitial()); 
      } else {
        emit(const LoginFailure(error: 'Username atau password salah.'));
      }
    } catch (e) {
      emit(LoginFailure(error: 'Terjadi kesalahan: ${e.toString()}'));
    }
  }
}
