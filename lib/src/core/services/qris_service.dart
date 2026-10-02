import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Layanan QRIS manual: simpan payload statis merchant + generate payload
/// dinamis (EMVCo) per transaksi dengan nominal.
///
/// Format EMVCo: TLV `ID(2) + len(2) + value`. CRC ada di field `58`
/// (`5802` + 4 hex). Untuk menyisipkan nominal: potong CRC lama, tambah
/// field `54` (amount), tambah `5802`, hitung ulang CRC16-CCITT (poly 0x1021,
/// init 0xFFFF) atas seluruh string, append hex uppercase.
class QrisService {
  static const _danaKey = 'qris_static_dana';
  static const _gopayKey = 'qris_static_gopay';

  Future<void> saveStaticQr({String? dana, String? gopay}) async {
    final prefs = await SharedPreferences.getInstance();
    if (dana != null) {
      if (dana.trim().isEmpty) {
        await prefs.remove(_danaKey);
      } else {
        await prefs.setString(_danaKey, dana.trim());
      }
    }
    if (gopay != null) {
      if (gopay.trim().isEmpty) {
        await prefs.remove(_gopayKey);
      } else {
        await prefs.setString(_gopayKey, gopay.trim());
      }
    }
  }

  Future<String?> getStaticQrDana() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_danaKey);
  }

  Future<String?> getStaticQrGopay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_gopayKey);
  }

  /// Ubah payload statis menjadi dinamis dengan nominal [amountRupiah].
  /// Return payload siap render sebagai QR. Throw [FormatException] jika
  /// payload statis tidak valid.
  String toDynamic(String staticPayload, double amountRupiah) {
    final clean = staticPayload.trim().replaceAll(RegExp(r'\s+'), '');
    if (clean.length < 8 ||
        !RegExp(r'[0-9A-Fa-f]{4}$').hasMatch(clean)) {
      throw const FormatException('Payload QRIS statis tidak valid.');
    }
    // Struktur akhir payload statis: ... + "5802" + 4 hex CRC (8 karakter).
    final trailer = clean.substring(clean.length - 8);
    if (!trailer.startsWith('5802')) {
      throw const FormatException('Payload QRIS statis tidak valid (CRC tidak ditemukan).');
    }
    final body = clean.substring(0, clean.length - 8);

    final amountStr = amountRupiah.toStringAsFixed(0);
    final amountField = '54${amountStr.length.toString().padLeft(2, '0')}$amountStr';

    final payloadForCrc = '$body$amountField'
        '5802';
    final crc = _crc16(payloadForCrc);
    return '$payloadForCrc${crc.toRadixString(16).toUpperCase().padLeft(4, '0')}';
  }

  /// Validasi CRC payload (statis maupun dinamis).
  bool isCrcValid(String payload) {
    final clean = payload.trim();
    if (clean.length < 8) return false;
    final data = clean.substring(0, clean.length - 4);
    final expected = clean.substring(clean.length - 4).toUpperCase();
    return _crc16(data).toRadixString(16).toUpperCase().padLeft(4, '0') == expected;
  }

  int _crc16(String input) {
    int crc = 0xFFFF;
    for (final code in input.codeUnits) {
      crc ^= code << 8;
      for (int i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) & 0xFFFF : (crc << 1) & 0xFFFF;
      }
    }
    return crc & 0xFFFF;
  }

  @visibleForTesting
  int crc16ForTest(String input) => _crc16(input);
}
