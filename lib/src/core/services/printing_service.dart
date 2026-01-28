import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:kasir_app/src/data/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

// --- Data Classes for State Management ---

enum PrinterStatus {
  disconnected,
  connecting,
  connected,
  error,
}

@immutable
class PrinterInfo {
  final String name;
  final String address;

  const PrinterInfo({required this.name, required this.address});

  Map<String, dynamic> toMap() => {'name': name, 'address': address};

  factory PrinterInfo.fromMap(Map<String, dynamic> map) {
    return PrinterInfo(
      name: map['name'] as String,
      address: map['address'] as String,
    );
  }
}

@immutable
class PrinterState {
  final PrinterStatus status;
  final PrinterInfo? device;
  final String? errorMessage;

  const PrinterState({
    this.status = PrinterStatus.disconnected,
    this.device,
    this.errorMessage,
  });

  const PrinterState.initial()
      : status = PrinterStatus.disconnected,
        device = null,
        errorMessage = null;

  PrinterState copyWith({
    PrinterStatus? status,
    PrinterInfo? device,
    String? errorMessage,
  }) {
    return PrinterState(
      status: status ?? this.status,
      device: device ?? this.device,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}


// --- Printing Service ---

class PrintingService {
  static const String _printerKey = 'saved_printer_v2';
  final ValueNotifier<PrinterState> state = ValueNotifier(const PrinterState.initial());

  Future<void> init() async {
    debugPrint('PrintingService: Initializing...');
    await _autoConnect();
    // The library does not provide a stream for connection status.
    // State is managed manually within this service.
  }

  Future<void> _autoConnect() async {
    final savedDevice = await getSavedPrinter();
    if (savedDevice != null) {
      debugPrint('PrintingService: Found saved printer. Connecting...');
      await connect(savedDevice);
    } else {
      debugPrint('PrintingService: No saved printer found.');
      state.value = const PrinterState.initial();
    }
  }

  Future<List<BluetoothInfo>> getPairedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  Future<void> savePrinter(PrinterInfo device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printerKey, jsonEncode(device.toMap()));
    debugPrint('PrintingService: Printer saved: ${device.name}');
  }

  Future<PrinterInfo?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrinterString = prefs.getString(_printerKey);
    if (savedPrinterString != null) {
      return PrinterInfo.fromMap(jsonDecode(savedPrinterString));
    }
    return null;
  }

  Future<void> connect(PrinterInfo device) async {
    if (state.value.status == PrinterStatus.connecting) return;

    state.value = PrinterState(status: PrinterStatus.connecting, device: device);
    debugPrint('PrintingService: Connecting to ${device.name}...');
    try {
      final bool connectResult = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.address,
      );

      if (connectResult) {
        state.value = PrinterState(status: PrinterStatus.connected, device: device);
        await savePrinter(device); // Save on successful connect
        debugPrint('PrintingService: Successfully connected to ${device.name}.');
      } else {
        state.value = PrinterState(
          status: PrinterStatus.error,
          device: device,
          errorMessage: 'Gagal terhubung. Pastikan printer menyala.',
        );
        debugPrint('PrintingService: Failed to connect to ${device.name}.');
      }
    } catch (e) {
      debugPrint('PrintingService: Exception during connect: $e');
      state.value = PrinterState(
        status: PrinterStatus.error,
        device: device,
        errorMessage: 'Error: ${e.toString()}',
      );
    }
  }

  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
    state.value = state.value.copyWith(status: PrinterStatus.disconnected);
    debugPrint('PrintingService: Disconnected.');
  }

  Future<void> printReceipt(TransactionModel transaction) async {
    debugPrint('PrintingService: printReceipt called. Status: ${state.value.status}');
    if (state.value.status != PrinterStatus.connected) {
      final errorMessage = 'Printer tidak terhubung.';
      debugPrint('PrintingService: $errorMessage');
      state.value = state.value.copyWith(status: PrinterStatus.error, errorMessage: errorMessage);
      throw Exception(errorMessage);
    }

    try {
      debugPrint('PrintingService: Generating and writing receipt bytes.');
      List<int> bytes = await _generateReceipt(transaction);
      final result = await PrintBluetoothThermal.writeBytes(bytes);
      debugPrint('PrintingService: Receipt bytes written, result: $result');
    } catch (e) {
      debugPrint('PrintingService: Exception during print: $e');
      state.value = state.value.copyWith(
        status: PrinterStatus.error,
        errorMessage: 'Gagal mencetak: ${e.toString()}',
      );
      throw Exception('Gagal mencetak struk.');
    }
  }

  // --- Private Helper for Receipt Generation (Unchanged) ---
  Future<List<int>> _generateReceipt(TransactionModel transaction) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    List<int> bytes = [];

    // Replace 'MD1' text with logo image
  final ByteData data = await rootBundle.load('assets/images/logo.png');
  final Uint8List bytesImage = data.buffer.asUint8List();
  final img.Image? image = img.decodeImage(bytesImage);

  if (image != null) {
    // Resize image to fit 58mm paper (approx 384 dots width for 8 dots/mm)
    // and maintain aspect ratio. Let's aim for a width that's less than max, e.g., 200-300px.
    final img.Image resizedImage = img.copyResize(image, width: 125); // Increased width from 100 to 125
    bytes += generator.image(resizedImage);
  } else {
    // Fallback if image fails to load
    bytes += generator.text('MD1', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
  }
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
      PosColumn(text: 'TOTAL', width: 6, styles: PosStyles(bold: true)), // Reverted to default size, added bold for emphasis
      PosColumn(text: 'Rp${transaction.totalAmount.toStringAsFixed(0)}', width: 6, styles: PosStyles(align: PosAlign.right, bold: true)), // Reverted to default size, added bold for emphasis
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
    bytes += generator.text('Terima Kasih!', styles: PosStyles(align: PosAlign.center)); // Reverted to default size
    bytes += generator.feed(0); // Attempt to feed 0mm (0 lines)
    bytes += generator.cut(mode: PosCutMode.partial);

    return bytes;
  }
}