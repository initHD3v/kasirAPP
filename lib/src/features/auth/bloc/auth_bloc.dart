import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:kasir_app/src/data/repositories/auth_repository.dart'; // Import AuthRepository

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository; // Declare the repository

  AuthBloc(this._authRepository) : super(AuthenticationUnauthenticated()) {
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
    on<AppStarted>(_onAppStarted);
  }

  void _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) {
    emit(AuthenticationAuthenticated(event.user));
  }

  void _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    await _authRepository.logout(); // Call the logout method
    emit(AuthenticationUnauthenticated());
  }

  void _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    await Future.delayed(const Duration(seconds: 2));
    await _authRepository.initAdmin(); // Initialize default admin
    emit(AuthenticationUnauthenticated());
  }
}