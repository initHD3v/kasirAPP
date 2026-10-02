import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_app/src/core/services/qris_service.dart';

void main() {
  group('QrisService EMVCo', () {
    // Payload statis minimal yang valid: ... + 5802 + CRC atas "...5802".
    String buildStatic(String bodyWithoutCrcTrailer) {
      final svc = QrisService();
      final base = '${bodyWithoutCrcTrailer}5802';
      final crc = svc.crc16ForTest(base).toRadixString(16).toUpperCase().padLeft(4, '0');
      return '$base$crc';
    }

    test('toDynamic menyisipkan amount dan CRC valid', () {
      final svc = QrisService();
      final statis = buildStatic('000201010212');
      final dinamis = svc.toDynamic(statis, 25000);

      expect(dinamis.contains('540525000'), isTrue);
      expect(svc.isCrcValid(dinamis), isTrue);
      // Payload asli tanpa nominal tidak mengandung field 54
      expect(statis.contains('5405'), isFalse);
    });

    test('toDynamic throw untuk payload tidak valid', () {
      final svc = QrisService();
      expect(() => svc.toDynamic('tidak-valid', 1000), throwsFormatException);
      expect(() => svc.toDynamic('0002010102125802ZZZZ', 1000), throwsFormatException);
    });

    test('isCrcValid false untuk CRC rusak', () {
      final svc = QrisService();
      final statis = buildStatic('000201010212');
      final rusak = statis.substring(0, statis.length - 1) +
          (statis.endsWith('0') ? '1' : '0');
      expect(svc.isCrcValid(statis), isTrue);
      expect(svc.isCrcValid(rusak), isFalse);
    });
  });
}
