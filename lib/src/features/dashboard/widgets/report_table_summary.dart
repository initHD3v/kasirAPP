import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasir_app/src/features/dashboard/views/reports_view.dart';
import 'package:kasir_app/src/features/dashboard/bloc/reports_bloc.dart'; // Import ChartData

class ReportTableSummary extends StatelessWidget {
  final List<ChartData> chartData;
  final ReportType reportType;

  const ReportTableSummary({
    super.key,
    required this.chartData,
    required this.reportType,
  });

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'Belum ada data laporan tersedia.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: chartData.length,
      itemBuilder: (context, index) {
        final data = chartData[index];
        final formattedRevenue = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(data.value);
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periode: ${data.label}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pendapatan: $formattedRevenue',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Jumlah Transaksi: ${data.numberOfTransactions}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
