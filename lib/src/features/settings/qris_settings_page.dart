import 'package:flutter/material.dart';
import 'package:kasir_app/src/core/services/qris_service.dart';

/// Pengaturan QRIS manual: tempel payload statis dari stiker QRIS
/// Dana dan/atau GoPay. Payload disimpan di HP ini saja.
class QrisSettingsPage extends StatefulWidget {
  const QrisSettingsPage({super.key});

  @override
  State<QrisSettingsPage> createState() => _QrisSettingsPageState();
}

class _QrisSettingsPageState extends State<QrisSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _danaController = TextEditingController();
  final _gopayController = TextEditingController();
  final _qris = QrisService();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dana = await _qris.getStaticQrDana();
    final gopay = await _qris.getStaticQrGopay();
    if (!mounted) return;
    setState(() {
      _danaController.text = dana ?? '';
      _gopayController.text = gopay ?? '';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _danaController.dispose();
    _gopayController.dispose();
    super.dispose();
  }

  String? _validatePayload(String? value) {
    if (value == null || value.trim().isEmpty) return null; // opsional
    try {
      _qris.toDynamic(value, 1000);
    } on FormatException {
      return 'Payload QRIS tidak valid';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await _qris.saveStaticQr(
        dana: _danaController.text,
        gopay: _gopayController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QRIS tersimpan.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan QRIS')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Tempel isi QR statis dari stiker QRIS Dana / GoPay (buka aplikasi kamera/QR scanner, salin teksnya, tempel di sini). Cukup isi salah satu.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _danaController,
                      decoration: const InputDecoration(
                        labelText: 'QRIS Statis Dana',
                        hintText: '000201010212...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: _validatePayload,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _gopayController,
                      decoration: const InputDecoration(
                        labelText: 'QRIS Statis GoPay',
                        hintText: '000201010212...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: _validatePayload,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
