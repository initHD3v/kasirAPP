import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_app/src/shared/widgets/printer_status_widget.dart';

class MainWrapper extends StatelessWidget {
  const MainWrapper({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('MainWrapper'));

  final StatefulNavigationShell navigationShell;

  // Function to get the title based on the current index
  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Kasir';
      case 1:
        return 'Manajemen Produk';
      case 2:
        return 'Laporan';
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
        title: Text(_getTitleForIndex(navigationShell.currentIndex)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: const [
          PrinterStatusWidget(),
          SizedBox(width: 8),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        selectedItemColor: Colors.blue, // Warna ikon yang dipilih
        unselectedItemColor: Colors.grey, // Warna ikon yang tidak dipilih
        onTap: (index) {
          navigationShell.goBranch(
            index,
            // A common pattern when using bottom navigation bars is to support
            // navigating to the initial location when tapping the item that is
            // already active. This is accomplished by setting
            // `initialLocation` to true in the `goBranch` call.
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Kasir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Pengguna',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan', // Group printer settings here or create a dedicated settings page
          ),
        ],
      ),
    );
  }
}
