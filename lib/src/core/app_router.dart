import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:kasir_app/src/features/auth/bloc/auth_bloc.dart';
import 'package:kasir_app/src/features/auth/login_page.dart';
import 'package:kasir_app/src/features/auth/splash_page.dart';
import 'package:kasir_app/src/features/products/products_page.dart';
import 'package:kasir_app/src/features/reports/reports_page.dart';
import 'package:kasir_app/src/features/settings/printer_settings_page.dart';
import 'package:kasir_app/src/features/settings/data_settings_page.dart'; // New import
import 'package:kasir_app/src/features/settings/settings_page.dart'; // New import
import 'package:kasir_app/src/features/transaction/transaction_page.dart';
import 'package:kasir_app/src/features/users/user_management_page.dart';
import 'package:kasir_app/src/features/transaction/transaction_detail_page.dart';
import 'package:kasir_app/src/data/models/transaction_model.dart';

import 'package:kasir_app/src/features/main_wrapper.dart';

class AppRouter {
  final AuthBloc authBloc;
  GoRouter get router => _router;

  AppRouter(this.authBloc);

  late final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/transaction_detail',
        name: 'transaction_detail',
        builder: (context, state) {
          final transaction = state.extra as TransactionModel;
          return TransactionDetailPage(transaction: transaction);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainWrapper(navigationShell: navigationShell);
        },
        branches: [
          // Kasir (TransactionPage)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const TransactionPage(),
              ),
            ],
          ),
          // Produk (ProductsPage)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/products',
                name: 'products',
                builder: (context, state) => const ProductsPage(),
              ),
            ],
          ),
          // Laporan (ReportsPage)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                name: 'reports',
                builder: (context, state) => const ReportsPage(),
              ),
            ],
          ),
          // Pengguna (UserManagementPage)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/users',
                name: 'users',
                builder: (context, state) => const UserManagementPage(),
              ),
            ],
          ),
          // Pengaturan (SettingsPage, PrinterSettingsPage, DataSettingsPage)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'printer', // '/settings/printer'
                    name: 'printer-settings',
                    builder: (context, state) => const PrinterSettingsPage(),
                  ),
                  GoRoute(
                    path: 'data', // '/settings/data'
                    name: 'data-settings',
                    builder: (context, state) => const DataSettingsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authState = context.read<AuthBloc>().state;
      final location = state.matchedLocation;

      debugPrint('Redirecting...');
      debugPrint('  Auth State: ${authState.runtimeType}');
      debugPrint('  Current Location: $location');

      final isAuth = authState is AuthenticationAuthenticated;
      final isLoggingIn = location == '/login';
      final isSplashing = location == '/splash'; // Keep this for initialLocation check

      // If not authenticated, and not on login page, redirect to login
      if (!isAuth && !isLoggingIn) {
        debugPrint('  Redirecting to /login (Not Auth, Not Login)');
        return '/login';
      }

      // If authenticated, and trying to access splash or login, redirect to home
      if (isAuth && (isLoggingIn || isSplashing)) { // Use isSplashing here for initial redirect
        debugPrint('  Redirecting to / (Auth, Login or Splash)');
        return '/';
      }

      // Admin access rules (keep as is)
      final userRole = isAuth ? authState.user.role : null;
      final adminRoutes = ['/products', '/reports', '/users', '/settings/printer'];
      if (isAuth && userRole == UserRole.employee && adminRoutes.contains(location)) {
        debugPrint('  Redirecting to / (Employee trying to access admin route)');
        return '/';
      }

      // Allow navigation
      debugPrint('  Allowing navigation');
      return null;
    },
  );
}

// Helper class untuk membuat GoRouter mendengarkan stream BLoC
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.asBroadcastStream().listen((dynamic _) => notifyListeners());
  }
}