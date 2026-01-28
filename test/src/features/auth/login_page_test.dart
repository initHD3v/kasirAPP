import 'dart:async'; // Import for StreamController
import 'package:bloc_test/bloc_test';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:kasir_app/src/data/repositories/auth_repository.dart';
import 'package:kasir_app/src/features/auth/bloc/auth_bloc.dart';
import 'package:kasir_app/src/features/auth/login_bloc/login_bloc.dart';
import 'package:kasir_app/src/features/auth/login_page.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockLoginBloc extends MockBloc<LoginEvent, LoginState> implements LoginBloc {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockAuthBloc mockAuthBloc;
  late MockLoginBloc mockLoginBloc;
  late StreamController<LoginState> loginStateController; // Use a StreamController

  // Dummy user for successful login
  const testUser = UserModel(
    id: '123',
    username: 'testuser',
    hashedPassword: 'hashed_password_123',
    role: UserRole.admin,
  );

  setUpAll(() {
    registerFallbackValue(AuthenticationInitial());
    registerFallbackValue(LoggedIn(user: testUser));
    registerFallbackValue(LoginButtonPressed(username: '', password: ''));
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockAuthBloc = MockAuthBloc();
    mockLoginBloc = MockLoginBloc();
    loginStateController = StreamController<LoginState>(); // Initialize StreamController

    // Stub mockLoginBloc.add to prevent "No matching calls" error if verify fails
    when(() => mockLoginBloc.add(any())).thenReturn(null);

    // Stub mockLoginBloc.state and stream
    when(() => mockLoginBloc.state).thenReturn(LoginInitial()); // Initial state
    when(() => mockLoginBloc.stream).thenAnswer((_) => loginStateController.stream); // Use the stream controller

    // Register mock AuthRepository with GetIt
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
    }
    getIt.registerLazySingleton<AuthRepository>(() => mockAuthRepository);
  });

  tearDown(() async {
    // Unregister mocks to clean up GetIt for each test
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
    }
    await loginStateController.close(); // Close the stream controller
  });

  // Helper widget to provide necessary Blocs and Material design context for LoginForm
  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<LoginBloc>.value(value: mockLoginBloc),
      ],
      child: const MaterialApp(
        home: Scaffold( // Add Scaffold to provide context for SnackBar
          body: LoginForm(),
        ),
      ),
    );
  }

  group('LoginPage Widget Tests', () {
    testWidgets('renders username and password fields and login button', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthenticationUnauthenticated()); // Initial state for AuthBloc
      // mockLoginBloc.state is already LoginInitial() from setUp()
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'LOGIN'), findsOneWidget);
    });

    testWidgets('shows validation errors when login button is pressed with empty fields', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthenticationUnauthenticated());
      // mockLoginBloc.state is already LoginInitial() from setUp()
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      await tester.pumpAndSettle(); // Allow SnackBar/validation messages to appear

      expect(find.text('Username cannot be empty'), findsOneWidget);
      expect(find.text('Password cannot be empty'), findsOneWidget);
    });

    testWidgets('adds LoginButtonPressed event and shows loading indicator on login attempt', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthenticationUnauthenticated());
      
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify button is enabled initially
      expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'LOGIN')).onPressed, isNotNull);

      // Enter text into fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'validuser');
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'validpass');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));

      // Verify LoginButtonPressed is added
      verify(() => mockLoginBloc.add(const LoginButtonPressed(
        username: 'validuser',
        password: 'validpass',
      ))).called(1);

      // Simulate LoginLoading state and pump
      loginStateController.add(LoginLoading());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Simulate LoginInitial state (after loading) and pump
      loginStateController.add(LoginInitial());
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });


    testWidgets('shows SnackBar with error message on LoginFailure', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthenticationUnauthenticated());
      const errorMessage = 'Invalid credentials';

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'invaliduser');
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'invalidpass');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      
      // Verify that LoginButtonPressed was added
      verify(() => mockLoginBloc.add(const LoginButtonPressed(
        username: 'invaliduser',
        password: 'invalidpass',
      ))).called(1);

      // Simulate LoginLoading state and pump
      loginStateController.add(LoginLoading());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget); // Expect loading indicator

      // Simulate LoginFailure state and pump
      loginStateController.add(const LoginFailure(error: errorMessage));
      await tester.pumpAndSettle(); // Pump until SnackBar appears and settles
      expect(find.byType(CircularProgressIndicator), findsNothing); // Ensure loading indicator is gone
      expect(find.text(errorMessage), findsOneWidget);
    });
  });
}