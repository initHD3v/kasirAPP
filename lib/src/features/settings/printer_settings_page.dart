
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/core/services/printing_service.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  final PrintingService _printingService = getIt<PrintingService>();
  List<BluetoothDevice> _devices = [];
  PrinterInfo? _savedPrinter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPrinter();
  }

  void _loadSavedPrinter() async {
    final printer = await _printingService.getSavedPrinter();
    setState(() {
      _savedPrinter = printer;
    });
  }

  void _scanForDevices() async {
    setState(() {
      _isLoading = true;
      _devices = [];
    });
    try {
      final devices = await _printingService.getPairedDevices();
      setState(() {
        _devices = devices;
      });
    } catch (e) {
      final messenger = ScaffoldMessenger.of(context); // Get messenger before await
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal memindai perangkat: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectPrinter(BluetoothDevice device) async {
    final messenger = ScaffoldMessenger.of(context); // Get messenger before await
    await _printingService.savePrinter(device);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('${device.name} disimpan sebagai printer utama.'), backgroundColor: Colors.green),
    );
    _loadSavedPrinter(); // Refresh saved printer info
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.print, color: Colors.indigo),
                title: const Text('Printer Tersimpan'),
                subtitle: Text(_savedPrinter?.name ?? 'Belum ada printer dipilih'),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _scanForDevices,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bluetooth_searching),
              label: Text(_isLoading ? 'Memindai...' : 'Pindai Perangkat Bluetooth'),
            ),
            const Divider(height: 32),
            const Text('Perangkat Terpairing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _devices.isEmpty
                  ? const Center(child: Text('Tidak ada perangkat ditemukan. Pastikan printer sudah di-pairing di pengaturan Bluetooth perangkat Anda.'))
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(device.name ?? 'Unknown Device'),
                          subtitle: Text(device.address ?? 'No address'),
                          onTap: () => _selectPrinter(device),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
