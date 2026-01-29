import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async'; // New import for Timer
import 'package:intl/intl.dart'; // New import for DateFormat

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
        return 'MD 1 KASIR'; // Changed title for Kasir tab
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
        title: (widget.navigationShell.currentIndex == 0)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
                crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
                children: [
                  Text(
                    _getTitleForIndex(widget.navigationShell.currentIndex),
                    style: const TextStyle(
                      fontSize: 22, // Larger font size
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
          SizedBox(width: 8), // Keep a small spacing if desired, or remove entirely
        ],
      ),
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.navigationShell.currentIndex,
        selectedItemColor: Colors.blue, // Warna ikon yang dipilih
        unselectedItemColor: Colors.grey, // Warna ikon yang tidak dipilih
        onTap: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
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
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
