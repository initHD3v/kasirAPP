import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:kasir_app/src/data/repositories/auth_repository.dart';
import 'package:kasir_app/src/features/auth/bloc/auth_bloc.dart';

// Mock AuthRepository
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthRepository authRepository;
  late AuthBloc authBloc;

  // Dummy UserModel for testing
  const testUser = UserModel(
    id: '123',
    username: 'testuser',
    hashedPassword: 'hashed_password_123',
    role: UserRole.admin, // Use a defined UserRole
  );

  setUp(() {
    authRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthenticationInitial', () {
      expect(authBloc.state, equals(AuthenticationInitial()));
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthenticationUnauthenticated] when AppStarted is added',
      build: () => authBloc,
      setUp: () {
        when(() => authRepository.initAdmin()).thenAnswer((_) async => Future.value());
      },
      act: (bloc) => bloc.add(AppStarted()),
      wait: const Duration(seconds: 3),
      expect: () => [AuthenticationUnauthenticated()],
      verify: (_) async {
        verify(() => authRepository.initAdmin()).called(1);
      }
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthenticationAuthenticated] when LoggedIn is added',
      build: () => authBloc,
      act: (bloc) => bloc.add(const LoggedIn(user: testUser)),
      expect: () => [AuthenticationAuthenticated(testUser)],
      verify: (_) async {
        verifyZeroInteractions(authRepository);
      }
    );

    blocTest<AuthBloc, AuthState>(
      'calls authRepository.logout and emits [AuthenticationUnauthenticated] when LoggedOut is added',
      build: () => authBloc,
      setUp: () {
        when(() => authRepository.logout()).thenAnswer((_) async => Future.value());
      },
      act: (bloc) => bloc.add(LoggedOut()),
      expect: () => [AuthenticationUnauthenticated()],
      verify: (_) async {
        verify(() => authRepository.logout()).called(1);
      }
    );
  });
}
