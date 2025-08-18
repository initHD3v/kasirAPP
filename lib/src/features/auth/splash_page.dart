
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_app/src/features/auth/bloc/auth_bloc.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticationAuthenticated) {
            context.go('/');
          } else if (state is AuthenticationUnauthenticated) {
            context.go('/login');
          }
        },
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
