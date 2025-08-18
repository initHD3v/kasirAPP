
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:kasir_app/src/data/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PrinterInfo {
  final String name;
  final String address;
  const PrinterInfo({required this.name, required this.address});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
    };
  }

  factory PrinterInfo.fromMap(Map<String, dynamic> map) {
    return PrinterInfo(
      name: map['name'] as String,
      address: map['address'] as String,
    );
  }
}

class PrintingService {
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  static const String _printerKey = 'saved_printer_v2';

  // Mengambil daftar perangkat bluetooth yang sudah di-pairing
  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await _printer.getBondedDevices();
  }

  // Menyimpan informasi printer yang dipilih
  Future<void> savePrinter(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    final printerInfo = PrinterInfo(name: device.name ?? 'Unknown Device', address: device.address ?? '');
    await prefs.setString(_printerKey, jsonEncode(printerInfo.toMap()));
  }

  // Mengambil informasi printer yang tersimpan
  Future<PrinterInfo?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrinterString = prefs.getString(_printerKey);
    if (savedPrinterString != null) {
      return PrinterInfo.fromMap(jsonDecode(savedPrinterString));
    }
    return null;
  }

  // Method untuk format dan print struk
  Future<void> printReceipt(TransactionModel transaction) async {
    final printerInfo = await getSavedPrinter();
    if (printerInfo == null || printerInfo.address.isEmpty) {
      throw Exception('Printer belum dipilih. Silakan pilih di Pengaturan Printer.');
    }

    final isConnected = await _printer.isConnected;
    if (isConnected != true) {
      await _printer.connect(BluetoothDevice(printerInfo.name, printerInfo.address));
    }

    // ESC/POS commands to format the receipt
    _printer.printCustom("TOKO KITA", 3, 1); // Size 3 (large), Align center
    _printer.printCustom("Jalan Aplikasi No. 123", 1, 1); // Size 1 (normal), Align center
    _printer.printNewLine();
    _printer.printLeftRight(
      "No: ${transaction.id.substring(0, 8)}",
      DateFormat('dd/MM/yy HH:mm').format(transaction.createdAt),
      1,
    );
    _printer.printNewLine();

    // Items
    for (var item in transaction.items) {
      final itemName = item.product.name;
      final itemQty = item.quantity.toString();
      final itemTotal = (item.product.price * item.quantity).toStringAsFixed(0);
      _printer.printLeftRight("$itemName x$itemQty", "Rp$itemTotal", 1);
    }
    _printer.printNewLine();

    // Totals
    final subtotal = transaction.items.fold(0.0, (sum, item) => sum + item.subtotal);
    final tax = transaction.totalAmount - subtotal;

    _printer.printLeftRight("Subtotal", "Rp${subtotal.toStringAsFixed(0)}", 1);
    _printer.printLeftRight("Pajak (10%)", "Rp${tax.toStringAsFixed(0)}", 1);
    _printer.printCustom("--------------------------------", 1, 1);
    _printer.printLeftRight("TOTAL", "Rp${transaction.totalAmount.toStringAsFixed(0)}", 2);
    _printer.printNewLine();

    // Footer
    _printer.printCustom("Terima Kasih!", 2, 1); // Size 2, Align center
    _printer.printNewLine();
    _printer.paperCut();
  }
}
