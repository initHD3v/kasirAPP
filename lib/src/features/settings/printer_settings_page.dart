import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/core/services/printing_service.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  final PrintingService _printingService = getIt<PrintingService>();
  List<BluetoothInfo> _devices = [];
  PrinterInfo? _savedPrinter;
  bool _isLoading = false;
  PrinterState _currentPrinterState = const PrinterState.initial();

  @override
  void initState() {
    super.initState();
    _loadSavedPrinter();
    _currentPrinterState = _printingService.state.value; // Initial state
    _printingService.state.addListener(_onPrinterStateChanged);
  }

  @override
  void dispose() {
    _printingService.state.removeListener(_onPrinterStateChanged);
    super.dispose();
  }

  void _onPrinterStateChanged() {
    if (!mounted) return;
    setState(() {
      _currentPrinterState = _printingService.state.value;
    });
  }

  void _loadSavedPrinter() async {
    final printer = await _printingService.getSavedPrinter();
    setState(() {
      _savedPrinter = printer;
    });
    // No need to set initial connection status here, it's handled by the listener
  }

  void _scanForDevices() async {
    setState(() {
      _isLoading = true;
      _devices = [];
    });
    try {
      final devices = await _printingService.getPairedDevices();
      setState(() {
        _devices = devices; // No cast needed, already BluetoothInfo
      });
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal memindai perangkat: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectPrinter(BluetoothInfo device) async {
    final printerToSave = PrinterInfo(name: device.name ?? 'Unknown', address: device.macAdress);
    await _printingService.savePrinter(printerToSave); // Save the printer info

    if (!mounted) return;
    // Attempt to connect to the printer immediately
    try {
      await _printingService.connect(printerToSave); // Connect to the printer
      // The PrintingService.connect method already shows snackbars for success/failure.
      // So, we don't need a separate success snackbar here.
    } catch (e) {
      // Catch any explicit errors from connect, though PrintingService should handle most internally
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghubungkan ke printer: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
    _loadSavedPrinter(); // Refresh saved printer info and status in UI
  }

  // ... (rest of the class)

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (_currentPrinterState.status) {
      case PrinterStatus.connected:
        statusText = 'Terhubung';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case PrinterStatus.connecting:
        statusText = 'Menghubungkan...';
        statusColor = Colors.orange;
        statusIcon = Icons.wifi_protected_setup;
        break;
      case PrinterStatus.error:
        statusText = _currentPrinterState.errorMessage ?? 'Error: Gagal terhubung';
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case PrinterStatus.disconnected:
      default:
        statusText = 'Tidak terhubung';
        statusColor = Colors.grey;
        statusIcon = Icons.link_off;
        break;
    }

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
                leading: Icon(Icons.print, color: statusColor),
                title: Text(_savedPrinter?.name ?? 'Belum ada printer dipilih'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_savedPrinter?.address ?? 'N/A'),
                    Text('Status: $statusText', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                  ],
                ),
                trailing: _currentPrinterState.status == PrinterStatus.connected
                    ? IconButton(
                        icon: const Icon(Icons.link_off, color: Colors.red),
                        onPressed: () async {
                          await _printingService.disconnect();
                        },
                      )
                    : (_savedPrinter != null && _currentPrinterState.status != PrinterStatus.connecting
                        ? IconButton(
                            icon: const Icon(Icons.link, color: Colors.green),
                            onPressed: () async {
                              await _printingService.connect(_savedPrinter!);
                            },
                          )
                        : null),
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
                          subtitle: Text(device.macAdress),
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
