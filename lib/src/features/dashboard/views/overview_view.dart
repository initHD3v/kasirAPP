import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/data/repositories/transaction_repository.dart';
import 'package:kasir_app/src/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

class OverviewView extends StatelessWidget {
  const OverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(getIt<TransactionRepository>())..add(LoadDashboardData()),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: RefreshIndicator(
          onRefresh: () async {
             context.read<DashboardBloc>().add(LoadDashboardData());
          },
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading || state is DashboardInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is DashboardError) {
                return Center(child: Text('Error: ${state.message}'));
              }
              if (state is DashboardLoaded) {
                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // KPI Cards
                    Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            title: 'Total Pendapatan Hari Ini',
                            value: NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(state.totalRevenueToday),
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _KpiCard(
                            title: 'Transaksi Hari Ini',
                            value: state.transactionCountToday.toString(),
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Weekly Sales Chart
                    _WeeklySalesChart(weeklySales: state.weeklySales),
                    const SizedBox(height: 24),

                    // Top Selling Products
                    _TopProductsCard(topProducts: state.topProducts),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  ),
                ),
                Icon(icon, color: color, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
    final List<DashboardTopProduct> topProducts;
    const _TopProductsCard({required this.topProducts});

    @override
    Widget build(BuildContext context) {
        return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text(
                            'Produk Terlaris Hari Ini',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (topProducts.isEmpty)
                            const Center(child: Text('Belum ada produk terjual hari ini.'))
                        else
                            ...topProducts.map((product) => ListTile(
                                dense: true,
                                title: Text(product.name),
                                trailing: Text('${product.quantity} terjual'),
                            )).toList(),
                    ],
                ),
            ),
        );
    }
}

class _WeeklySalesChart extends StatelessWidget {
  final List<DashboardChartData> weeklySales;

  const _WeeklySalesChart({required this.weeklySales});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pendapatan 7 Hari Terakhir',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: weeklySales.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2, // Add 20% buffer
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${weeklySales[groupIndex].label}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(rod.toY),
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                           final index = value.toInt();
                           if (index < 0 || index >= weeklySales.length) {
                               return const SizedBox.shrink();
                           }
                           return Text(weeklySales[index].label);
                        },
                        reservedSize: 38,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == 0) return const SizedBox.shrink();
                          return Text(NumberFormat.compactSimpleCurrency(locale: 'id_ID').format(value), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklySales
                      .asMap()
                      .map((index, data) => MapEntry(
                            index,
                            BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: data.value,
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade300, Colors.blue.shade800],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  width: 20,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    topRight: Radius.circular(6),
                                  ),
                                )
                              ],
                              showingTooltipIndicators: [],
                            ),
                          ))
                      .values
                      .toList(),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
