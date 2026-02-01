import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/data/repositories/transaction_repository.dart';
import 'package:kasir_app/src/features/dashboard/bloc/reports_bloc.dart'; // Updated import
import 'package:shimmer/shimmer.dart';
import 'package:kasir_app/src/features/dashboard/widgets/report_table_summary.dart'; // Updated import


enum ReportType { daily, weekly, monthly }

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  ReportType _selectedReportType = ReportType.daily;

  void _showDeleteAllConfirmation(BuildContext context) {
    final bloc = context.read<ReportsBloc>();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Semua Transaksi'),
          content: const Text('Apakah Anda yakin ingin menghapus semua riwayat transaksi? Tindakan ini tidak dapat diurungkan.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
            TextButton(
              child: const Text('Hapus Semua', style: TextStyle(color: Colors.red)),
              onPressed: () {
                bloc.add(DeleteAllTransactions());
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                  SegmentedButton<ReportType>(
                    segments: const [
                      ButtonSegment(value: ReportType.daily, label: Text('Harian')),
                      ButtonSegment(value: ReportType.weekly, label: Text('Mingguan')),
                      ButtonSegment(value: ReportType.monthly, label: Text('Bulanan')),
                    ],
                    selected: {_selectedReportType},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedReportType = newSelection.first;
                      });
                      final now = DateTime.now();
                      DateTime startTime;
                      final endTime = DateTime(now.year, now.month, now.day, 23, 59, 59);

                      switch (_selectedReportType) {
                        case ReportType.daily:
                          startTime = DateTime(now.year, now.month, now.day);
                          break;
                        case ReportType.weekly:
                          startTime = now.subtract(const Duration(days: 6));
                          break;
                        case ReportType.monthly:
                          startTime = DateTime(now.year, now.month, 1);
                          break;
                      }
                      context.read<ReportsBloc>().add(LoadReports(startTime: startTime, endTime: endTime, reportType: _selectedReportType));
                    },
                    style: SegmentedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: Colors.indigo,
                      side: const BorderSide(color: Colors.indigo),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                    tooltip: 'Hapus Semua Transaksi',
                    onPressed: () {
                      _showDeleteAllConfirmation(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ReportContent(reportType: _selectedReportType),
          ],
        ),
      ),
    );
  }
}

class ReportContent extends StatefulWidget {
  final ReportType reportType;

  const ReportContent({super.key, required this.reportType});

  @override
  State<ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends State<ReportContent> {
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void didUpdateWidget(covariant ReportContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reportType != oldWidget.reportType) {
      _loadReports();
    }
  }

  void _loadReports() {
    final now = DateTime.now();
    DateTime startTime;
    final endTime = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (widget.reportType) {
      case ReportType.daily:
        startTime = DateTime(now.year, now.month, now.day);
        break;
      case ReportType.weekly:
        startTime = now.subtract(const Duration(days: 6));
        break;
      case ReportType.monthly:
        startTime = DateTime(now.year, now.month, 1);
        break;
    }
    context.read<ReportsBloc>().add(LoadReports(startTime: startTime, endTime: endTime, reportType: widget.reportType));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (context, state) {
        if (state is ReportsLoading) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 24),
                // Placeholder for best selling products
                Container(
                  height: 20,
                  width: double.infinity,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 16),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3, // Show a few placeholder items
                  itemBuilder: (context, index) => Container(
                    height: 60,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is ReportsError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        if (state is ReportsLoaded) {
          debugPrint('ReportContent: Received ReportsLoaded state. Transactions count: ${state.transactions.length}');
          return Column(
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: 'Total Pendapatan',
                        value: NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(state.totalRevenue),
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        title: 'Jumlah Transaksi',
                        value: state.transactions.length.toString(),
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Chart
                if (state.chartData.isNotEmpty)
                  ExpansionTile(
                    initiallyExpanded: true, // Chart visible by default
                    title: const Text('Grafik Penjualan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    children: [
                      SizedBox(
                        height: 200,
                        child: ReportTableSummary(chartData: state.chartData, reportType: widget.reportType),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                // Best Selling Products
                const Text(
                  'Produk Terlaris',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Divider(height: 20, thickness: 1),
                if (state.bestSellingProducts.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_basket_outlined, size: 40, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'Belum ada produk terlaris.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.bestSellingProducts.length > 5 ? 5 : state.bestSellingProducts.length, // Tampilkan 5 teratas
                    itemBuilder: (context, index) {
                      final product = state.bestSellingProducts[index];
                      return Card(
                        elevation: 0.5,
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          title: Text(product.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Terjual: ${product.totalQuantitySold} unit'),
                          trailing: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(product.totalRevenueGenerated), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                // Transaction List Header
                const Text(
                  'Detail Transaksi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Divider(height: 20, thickness: 1),
                // Transaction List
                if (state.transactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 40, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'Belum ada detail transaksi.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true, // Crucial for embedding in SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Hand over scrolling to parent
                    itemCount: state.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = state.transactions[index];
                      return Card(
                        elevation: 0.5,
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: const Icon(Icons.receipt, color: Colors.indigo),
                          title: Text('ID: ${tx.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt)),
                          trailing: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(tx.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                          onTap: () {
                            context.push('/transaction_detail', extra: tx);
                          },
                        ),
                      );
                    },
                  ),
              ],
            );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4, // Increased elevation for more depth
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // More rounded corners
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Increased padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: Colors.grey[700], fontSize: 16), // Slightly darker grey, larger font
                  ),
                ),
                Icon(icon, color: color, size: 28), // Larger icon
              ],
            ),
            const SizedBox(height: 12), // Increased spacing
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87), // Larger, bolder text
            ),
          ],
        ),
      ),
    );
  }
}
