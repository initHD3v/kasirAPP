
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kasir_app/src/data/models/user_model.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // UserModel? currentUser;

  AuthBloc() : super(AuthenticationUnauthenticated()) {
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
    on<AppStarted>(_onAppStarted); // Add this line
  }

  void _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) {
    // this.currentUser = event.user;
    emit(AuthenticationAuthenticated(event.user));
  }

  void _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) {
    // this.currentUser = null;
    emit(AuthenticationUnauthenticated());
  }

  // Add this method
  void _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    // Simulate an authentication check
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    // For now, let's assume the user is unauthenticated by default
    // In a real app, you would check for a token, user session, etc.
    emit(AuthenticationUnauthenticated());
  }
}
