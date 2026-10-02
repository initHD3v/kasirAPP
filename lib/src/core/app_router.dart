import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:kasir_app/src/features/auth/bloc/auth_bloc.dart';
import 'package:kasir_app/src/features/auth/login_page.dart';
import 'package:kasir_app/src/features/auth/splash_page.dart';
import 'package:kasir_app/src/features/products/products_page.dart';
import 'package:kasir_app/src/features/dashboard/dashboard_page.dart';
import 'package:kasir_app/src/features/settings/qris_settings_page.dart';
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
          // Dashboard (DashboardPage)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                builder: (context, state) => const DashboardPage(),
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
                  GoRoute(
                    path: 'qris', // '/settings/qris'
                    name: 'qris-settings',
                    builder: (context, state) => const QrisSettingsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final location = state.matchedLocation;

      final isAuth = authState is AuthenticationAuthenticated;
      final isLoggingIn = location == '/login';
      final isSplashing = location == '/splash';

      // Selama inisialisasi, tahan di splash; SplashPage yang navigasi via listener.
      if (authState is AuthenticationInitial) {
        return isSplashing ? null : '/splash';
      }

      // Jika authenticated, jangan ke splash/login.
      if (isAuth && (isLoggingIn || isSplashing)) {
        return '/';
      }

      // Jika belum auth, hanya login/splash yang boleh.
      if (!isAuth && !isLoggingIn && !isSplashing) {
        return '/login';
      }

      // Admin access rules
      final userRole = authState is AuthenticationAuthenticated ? authState.user.role : null;
      const adminRoutes = [
        '/products',
        '/dashboard',
        '/users',
        '/settings',
        '/settings/printer',
        '/settings/data',
      ];
      if (isAuth &&
          userRole == UserRole.employee &&
          adminRoutes.any((r) => location == r || location.startsWith('$r/'))) {
        return '/';
      }
      if (!isAuth && location == '/transaction_detail') {
        return '/login';
      }

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