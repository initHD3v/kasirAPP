import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kasir_app/src/core/services/database_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart'; // New import

class DataSettingsPage extends StatefulWidget {
  const DataSettingsPage({super.key});

  @override
  State<DataSettingsPage> createState() => _DataSettingsPageState();
}

class _DataSettingsPageState extends State<DataSettingsPage> {
  final DatabaseService _databaseService = GetIt.instance<DatabaseService>();

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        // Android 11 (API 30) or above
        var status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          print('MANAGE_EXTERNAL_STORAGE permission granted');
          return true;
        } else if (status.isPermanentlyDenied) {
          print('MANAGE_EXTERNAL_STORAGE permission permanently denied, opening settings');
          _showSnackBar('Izin "Akses semua file" ditolak permanen. Mohon berikan izin di pengaturan.', isError: true);
          openAppSettings();
          return false;
        } else {
          print('MANAGE_EXTERNAL_STORAGE permission denied');
          _showSnackBar('Izin "Akses semua file" ditolak.', isError: true);
          return false;
        }
      } else {
        // Android 10 (API 29) or below
        var status = await Permission.storage.request();
        if (status.isGranted) {
          print('Storage permission granted');
          return true;
        } else if (status.isPermanentlyDenied) {
          print('Storage permission permanently denied, opening settings');
          _showSnackBar('Izin penyimpanan ditolak permanen. Mohon berikan izin di pengaturan.', isError: true);
          openAppSettings();
          return false;
        } else {
          print('Storage permission denied');
          _showSnackBar('Izin penyimpanan ditolak.', isError: true);
          return false;
        }
      }
    }
    // For other platforms or if not Android, assume granted or handle accordingly
    return true;
  }

  Future<void> _backupData() async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) return;

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        // Create a dedicated folder for backups if it doesn't exist within the selected directory
        final backupFolder = Directory('$selectedDirectory/KasirAppBackups');
        if (!await backupFolder.exists()) {
          await backupFolder.create(recursive: true);
        }

        final fileName = 'kasir_app_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db';
        final destinationPath = '${backupFolder.path}/$fileName';

        await _databaseService.backupDatabase(destinationPath);
        _showSnackBar('Backup data berhasil disimpan di: ${backupFolder.path}');
      } else {
        _showSnackBar('Tidak ada lokasi backup yang dipilih.', isError: false);
      }
    } catch (e) {
      print('Error during backup: $e');
      _showSnackBar('Gagal melakukan backup data: $e', isError: true);
    }
  }

  Future<void> _restoreData() async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Changed to FileType.any
      );

      if (result != null && result.files.single.path != null) {
        String backupFilePath = result.files.single.path!;
        // Manual check for .db extension
        if (!backupFilePath.toLowerCase().endsWith('.db')) {
          _showSnackBar('File yang dipilih bukan file database (.db).', isError: true);
          return;
        }
        await _databaseService.restoreDatabase(backupFilePath);
        _showSnackBar('Restore data berhasil. Aplikasi akan dimulai ulang.');

        // Optionally, restart the app or navigate to a fresh state
        // For simplicity, we just show a message. A full app restart
        // might be more robust depending on the app's state management.
      } else {
        _showSnackBar('Tidak ada file backup yang dipilih.', isError: false);
      }
    } catch (e) {
      print('Error during restore: $e');
      _showSnackBar('Gagal melakukan restore data: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return; // Check if the widget is still mounted
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Cadangkan Data'),
                subtitle: const Text('Buat salinan database aplikasi ke penyimpanan lokal.'),
                onTap: _backupData,
              ),
            ),
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Pulihkan Data'),
                subtitle: const Text('Pulihkan database aplikasi dari file backup lokal.'),
                onTap: _restoreData,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Catatan: Untuk Android 11 (API 30) ke atas, Anda perlu memberikan izin "Akses semua file" secara manual melalui pengaturan aplikasi.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
             Text(
              'Untuk Android 10 (API 29) ke bawah, Anda mungkin perlu mengizinkan akses penyimpanan secara manual melalui pengaturan aplikasi.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
