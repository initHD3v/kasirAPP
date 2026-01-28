import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:kasir_app/src/data/repositories/user_repository.dart';
import 'package:kasir_app/src/features/users/bloc/user_bloc.dart';

// Mock UserRepository
class MockUserRepository extends Mock implements UserRepository {}

// Fakes for non-primitive types used with any()
class FakeUserModel extends Fake implements UserModel {}

void main() {
  late MockUserRepository mockUserRepository;
  late UserBloc userBloc;

  // Dummy Users for testing
  const dummyAdminUser = UserModel(
    id: 'user1',
    username: 'adminuser',
    hashedPassword: 'hashed_admin_password',
    role: UserRole.admin,
  );

  const dummyEmployeeUser = UserModel(
    id: 'user2',
    username: 'employeeuser',
    hashedPassword: 'hashed_employee_password',
    role: UserRole.employee,
  );

  final List<UserModel> dummyUsers = [dummyAdminUser, dummyEmployeeUser];

  setUpAll(() {
    registerFallbackValue(FakeUserModel());
    registerFallbackValue(UserRole.employee); // Register fallback for UserRole
  });

  setUp(() {
    mockUserRepository = MockUserRepository();
    userBloc = UserBloc(mockUserRepository);
  });

  tearDown(() {
    userBloc.close();
  });

  group('UserBloc', () {
    test('initial state is UsersInitial', () {
      expect(userBloc.state, equals(UsersInitial()));
    });

    blocTest<UserBloc, UserState>(
      'emits [UsersLoading, UsersLoaded] when LoadUsers is added and successful',
      build: () {
        when(() => mockUserRepository.getUsers())
            .thenAnswer((_) async => dummyUsers);
        return userBloc;
      },
      act: (bloc) => bloc.add(LoadUsers()),
      expect: () => [
        UsersLoading(),
        UsersLoaded(dummyUsers),
      ],
      verify: (_) {
        verify(() => mockUserRepository.getUsers()).called(1);
      },
    );

    blocTest<UserBloc, UserState>(
      'emits [UsersLoading, UserOperationFailure] when LoadUsers is added and fails',
      build: () {
        when(() => mockUserRepository.getUsers())
            .thenThrow(Exception('Failed to load users'));
        return userBloc;
      },
      act: (bloc) => bloc.add(LoadUsers()),
      expect: () => [
        UsersLoading(),
        const UserOperationFailure('Exception: Failed to load users'),
      ],
      verify: (_) {
        verify(() => mockUserRepository.getUsers()).called(1);
      },
    );

    blocTest<UserBloc, UserState>(
      'calls userRepository.addUser and then LoadUsers event on successful AddUser',
      build: () {
        when(() => mockUserRepository.addUser(any(), any(), any()))
            .thenAnswer((_) async => Future.value());
        when(() => mockUserRepository.getUsers())
            .thenAnswer((_) async => dummyUsers); // For the LoadUsers call after AddUser
        return userBloc;
      },
      act: (bloc) => bloc.add(const AddUser(
        username: 'newuser',
        password: 'password123',
        role: UserRole.employee,
      )),
      expect: () => [
        UsersLoading(), // From LoadUsers triggered after AddUser
        UsersLoaded(dummyUsers), // From LoadUsers triggered after AddUser
      ],
      verify: (_) {
        verify(() => mockUserRepository.addUser('newuser', 'password123', UserRole.employee)).called(1);
        verify(() => mockUserRepository.getUsers()).called(1);
      },
    );

    blocTest<UserBloc, UserState>(
      'emits [UserOperationFailure] and then LoadUsers event on failed AddUser',
      build: () {
        when(() => mockUserRepository.addUser(any(), any(), any()))
            .thenThrow(Exception('Username already exists'));
        when(() => mockUserRepository.getUsers())
            .thenAnswer((_) async => dummyUsers); // For the LoadUsers call after failure
        return userBloc;
      },
      act: (bloc) => bloc.add(const AddUser(
        username: 'existinguser',
        password: 'password123',
        role: UserRole.employee,
      )),
      expect: () => [
        const UserOperationFailure('Exception: Username already exists'),
        UsersLoading(), // From LoadUsers triggered after failure
        UsersLoaded(dummyUsers), // From LoadUsers triggered after failure
      ],
      verify: (_) {
        verify(() => mockUserRepository.addUser('existinguser', 'password123', UserRole.employee)).called(1);
        verify(() => mockUserRepository.getUsers()).called(1);
      },
    );
  });
}