import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // New import
import 'package:kasir_app/src/features/auth/bloc/auth_bloc.dart'; // New import
import 'package:kasir_app/src/data/models/user_model.dart'; // New import

class MainWrapper extends StatefulWidget {
  const MainWrapper({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('MainWrapper'));

  final StatefulNavigationShell navigationShell;

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  late DateTime _currentDateTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _currentDateTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentDateTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Function to get the title based on the current index
  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'MD 1 KASIR';
      case 1:
        return 'Manajemen Produk';
      case 2:
        return 'Dashboard';
      case 3:
        return 'Manajemen Pengguna';
      case 4:
        return 'Pengaturan';
      default:
        return 'Aplikasi Kasir';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (widget.navigationShell.currentIndex == 0)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _getTitleForIndex(widget.navigationShell.currentIndex),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, dd MMMM yyyy, HH:mm:ss', 'id_ID').format(_currentDateTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )
            : Text(_getTitleForIndex(widget.navigationShell.currentIndex)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: widget.navigationShell,
      bottomNavigationBar: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final bool isAdmin = state is AuthenticationAuthenticated && state.user.role == UserRole.admin;

          List<BottomNavigationBarItem> items = [
            const BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale),
              label: 'Kasir',
            ),
          ];

          List<int> visibleBranchIndexes = [0]; // Always show Kasir

          if (isAdmin) {
            items.addAll([
              const BottomNavigationBarItem(
                icon: Icon(Icons.inventory),
                label: 'Produk',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'Pengguna',
              ),
            ]);
            visibleBranchIndexes.addAll([1, 2, 3]); // Produk, Laporan, Pengguna
          }

          items.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Pengaturan',
            ),
          );
          visibleBranchIndexes.add(4); // Pengaturan

          // Map the current shell index to the index within the visible items
          int selectedIndex = visibleBranchIndexes.indexOf(widget.navigationShell.currentIndex);
          if (selectedIndex == -1) {
            // If the current branch index is hidden, default to the first visible item (Kasir)
            selectedIndex = 0;
            // Also, redirect the navigation shell to the first visible branch to prevent being stuck on a hidden route
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.navigationShell.goBranch(
                visibleBranchIndexes.first,
                initialLocation: true,
              );
            });
          }


          return BottomNavigationBar(
            currentIndex: selectedIndex,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              // Map the tapped index back to the actual branch index
              widget.navigationShell.goBranch(
                visibleBranchIndexes[index],
                initialLocation: index == selectedIndex,
              );
            },
            items: items,
          );
        },
      ),
    );
  }
}
