import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/data/repositories/auth_repository.dart';
import 'package:kasir_app/src/features/auth/bloc/auth_bloc.dart';
import 'package:kasir_app/src/features/auth/login_bloc/login_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BlocProvider(
        create: (context) => LoginBloc(
          authRepository: getIt<AuthRepository>(),
          authBloc: context.read<AuthBloc>(),
        ),
        child: const LoginForm(),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(24.0),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sign in to continue',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter your username',
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.indigo),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.indigo, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.indigo),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.indigo, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      BlocBuilder<LoginBloc, LoginState>(
                        builder: (context, state) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            onPressed: state is LoginLoading ? null : _onLoginButtonPressed,
                            child: state is LoginLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'LOGIN',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          // TODO: Implement navigation to registration page
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Navigate to Registration Page')),
                          );
                        },
                        child: Text(
                          'Don\'t have an account? Register Now',
                          style: TextStyle(color: Colors.indigo[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onLoginButtonPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
            LoginButtonPressed(
              username: _usernameController.text,
              password: _passwordController.text,
            ),
          );
    }
  }
}