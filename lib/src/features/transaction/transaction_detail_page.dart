import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kasir_app/src/data/models/transaction_model.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/core/services/printing_service.dart';
import 'package:kasir_app/src/data/repositories/user_repository.dart';
import 'package:kasir_app/src/data/models/user_model.dart';

class TransactionDetailPage extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  String _cashierUsername = 'Memuat...';
  final UserRepository _userRepository = getIt<UserRepository>();

  @override
  void initState() {
    super.initState();
    _loadCashierUsername();
  }

  void _loadCashierUsername() async {
    final UserModel? user = await _userRepository.getUserById(widget.transaction.cashierId);
    if (mounted) {
      setState(() {
        _cashierUsername = user?.username ?? 'Tidak Ditemukan';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [ // Added actions for print button
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Cetak Ulang Struk',
            onPressed: () async {
              final printingService = getIt<PrintingService>();
              final messenger = ScaffoldMessenger.of(context);
              try {
                await printingService.printReceipt(widget.transaction);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Struk dikirim ke printer.'), backgroundColor: Colors.green),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Gagal mencetak: ${e.toString()}'), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID Transaksi:', widget.transaction.id),
              _buildDetailRow('Tanggal:', DateFormat('dd MMM yyyy, HH:mm').format(widget.transaction.createdAt)),
              _buildDetailRow('Total Belanja:', NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(widget.transaction.totalAmount)),
              _buildDetailRow('Jumlah Bayar:', NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(widget.transaction.amountPaid)),
              _buildDetailRow('Kembalian:', NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(widget.transaction.change)),
              _buildDetailRow('Metode Pembayaran:', widget.transaction.paymentMethod),
              _buildDetailRow('Kasir:', _cashierUsername),
              
              const Divider(height: 32),
              const Text(
                'Item Transaksi:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.transaction.items.length,
                itemBuilder: (context, index) {
                  final item = widget.transaction.items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: Text(item.product.name),
                      subtitle: Text('${item.quantity} x ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(item.product.price)}'),
                      trailing: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(item.subtotal)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}