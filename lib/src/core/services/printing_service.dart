import 'package:intl/intl.dart';
import 'package:kasir_app/src/data/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

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
  // final PrintBluetoothThermal _printer = PrintBluetoothThermal.instance; // Removed, using static methods
  static const String _printerKey = 'saved_printer_v2';
  PrinterInfo? _currentPrinterInfo;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String? get savedPrinterName => _currentPrinterInfo?.name;

  Future<List<BluetoothInfo>> getPairedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  Future<void> savePrinter(BluetoothInfo device) async {
    final prefs = await SharedPreferences.getInstance();
    final printerInfo = PrinterInfo(name: device.name ?? 'Unknown', address: device.macAdress);
    await prefs.setString(_printerKey, jsonEncode(printerInfo.toMap()));
  }

  Future<PrinterInfo?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrinterString = prefs.getString(_printerKey);
    if (savedPrinterString != null) {
      return PrinterInfo.fromMap(jsonDecode(savedPrinterString));
    }
    return null;
  }

  Future<bool> autoConnectSavedPrinter() async {
    debugPrint('PrintingService: Attempting to auto-connect to saved printer.');
    final printerInfo = await getSavedPrinter();
    if (printerInfo == null || printerInfo.address.isEmpty) {
      _isConnected = false;
      _currentPrinterInfo = null;
      debugPrint('PrintingService: No saved printer found or address is empty.');
      return false;
    }

    _currentPrinterInfo = printerInfo;
    debugPrint('PrintingService: Found saved printer: ${printerInfo.name} (${printerInfo.address}). Attempting connection...');
    final bool connectResult = await PrintBluetoothThermal.connect(
      macPrinterAddress: printerInfo.address,
    );
    _isConnected = connectResult;
    if (_isConnected) {
      debugPrint('PrintingService: Successfully connected to ${printerInfo.name}.');
    } else {
      debugPrint('PrintingService: Failed to connect to ${printerInfo.name}.');
    }
    return _isConnected;
  }

  Future<void> printReceipt(TransactionModel transaction) async {
    debugPrint('PrintingService: printReceipt called. Current _isConnected: $_isConnected');
    if (!_isConnected) {
      debugPrint('PrintingService: Printer not connected. Attempting auto-connection...');
      final bool connected = await autoConnectSavedPrinter();
      if (!connected) {
        debugPrint('PrintingService: Auto-connection failed. Throwing exception.');
        throw Exception('Printer belum terhubung. Silakan periksa pengaturan atau coba lagi.');
      }
    }
    debugPrint('PrintingService: Printer is connected. Generating and writing receipt bytes.');
    List<int> bytes = await _generateReceipt(transaction);
    await PrintBluetoothThermal.writeBytes(bytes);
    debugPrint('PrintingService: Receipt bytes written.');
  }

  Future<List<int>> _generateReceipt(TransactionModel transaction) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    List<int> bytes = [];

    bytes += generator.text('MD1', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text('Jl.kartini Saribudolok', styles: PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);

    bytes += generator.row([
      PosColumn(text: 'No: ${(transaction.createdAt.millisecondsSinceEpoch % 10000000).toString()}', width: 6),
      PosColumn(text: DateFormat('dd/MM/yy HH:mm').format(transaction.createdAt), width: 6, styles: PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.feed(1);

    for (var item in transaction.items) {
      final itemName = item.product.name;
      final itemQty = item.quantity.toString();
      final itemTotal = (item.product.price * item.quantity).toStringAsFixed(0);
      bytes += generator.row([
        PosColumn(text: '$itemName x$itemQty', width: 8),
        PosColumn(text: 'Rp$itemTotal', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.feed(1);

    final subtotal = transaction.items.fold(0.0, (sum, item) => sum + item.subtotal);
    final tax = transaction.totalAmount - subtotal;

    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 6),
      PosColumn(text: 'Rp${subtotal.toStringAsFixed(0)}', width: 6, styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: PosStyles(height: PosTextSize.size2, width: PosTextSize.size2)),
      PosColumn(text: 'Rp${transaction.totalAmount.toStringAsFixed(0)}', width: 6, styles: PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.feed(1);
    bytes += generator.row([
      PosColumn(text: 'TUNAI', width: 6), // Assuming cash payment, or could use transaction.paymentMethod
      PosColumn(text: currencyFormatter.format(transaction.amountPaid), width: 6, styles: PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'KEMBALI', width: 6),
      PosColumn(text: currencyFormatter.format(transaction.change), width: 6, styles: PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.feed(2);

    bytes += generator.text('Terima Kasih!', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size2));
    bytes += generator.feed(1);
    bytes += generator.cut();

    return bytes;
  }
}
