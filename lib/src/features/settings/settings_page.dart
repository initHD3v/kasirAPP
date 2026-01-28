import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Pengaturan Printer'),
            onTap: () {
              context.go('/settings/printer');
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Pengaturan Data'),
            onTap: () {
              context.go('/settings/data');
            },
          ),
          // Add other settings options here in the future
        ],
      ),
    );
  }
}
