import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kasir_app/src/features/reports/reports_page.dart';
import 'package:kasir_app/src/features/reports/bloc/reports_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class ReportLineChart extends StatefulWidget {
  final List<ChartData> chartData;
  final ReportType reportType;

  const ReportLineChart({
    super.key,
    required this.chartData,
    required this.reportType,
  });

  @override
  State<ReportLineChart> createState() => _ReportLineChartState();
}

class _ReportLineChartState extends State<ReportLineChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _chartRevealAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _chartRevealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ReportLineChart build: chartData = ${widget.chartData}');
    if (widget.chartData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'Belum ada data penjualan tersedia.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              'Lakukan beberapa transaksi untuk melihat grafik.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    if (widget.chartData.length == 1) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'Data tidak cukup untuk menampilkan grafik.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              'Dibutuhkan minimal 2 data untuk menampilkan grafik.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _chartRevealAnimation,
      builder: (context, child) {
        return LineChart(
          sampleData,
          duration: const Duration(milliseconds: 800),
        );
      },
    );
  }

  LineChartData get sampleData {
    double maxChartY = widget.chartData.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    double maxChartTransactions = widget.chartData.map((d) => d.numberOfTransactions.toDouble()).reduce((a, b) => a > b ? a : b);
    double maxY = (maxChartY > maxChartTransactions ? maxChartY : maxChartTransactions) * 1.2;
    if (maxY < 100 && maxChartY < 100 && maxChartTransactions < 100) {
      maxY = 100; // Ensure min 100 for small values if both are small
    }


    return LineChartData(
      lineTouchData: lineTouchData,
      gridData: gridData,
      titlesData: titlesData(maxY),
      borderData: borderData,
      lineBarsData: lineBarsData,
      minX: 0,
      maxX: (widget.chartData.length - 1).toDouble() * _chartRevealAnimation.value,
      maxY: maxY,
      minY: 0,
    );
  }

    LineTouchData get lineTouchData => LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final String label = widget.chartData[touchedSpot.spotIndex].label;
                if (touchedSpot.barIndex == 0) {
                  // Revenue line
                  final String revenue = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(touchedSpot.y);
                  final int transactionCount = widget.chartData[touchedSpot.spotIndex].numberOfTransactions;
                  return LineTooltipItem(
                    '$label\nPendapatan: $revenue\nTransaksi: $transactionCount',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                } else {
                  // Transactions line
                  final int transactionCount = touchedSpot.y.toInt();
                  return LineTooltipItem(
                    '$label\nTransaksi: $transactionCount',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
              }).toList();
            },
          ),
        );
  FlTitlesData titlesData(double maxY) => FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: bottomTitles,
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: leftTitles(maxY),
        ),
      );



  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    return SideTitleWidget(
      meta: meta,
      space: 10,
      child: Text(
        NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(value),
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }

  SideTitles leftTitles(double maxY) => SideTitles(
        getTitlesWidget: leftTitleWidgets,
        showTitles: true,
        interval: maxY / 5,
        reservedSize: 40,
      );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    final index = value.toInt();
    if (index >= 0 && index < widget.chartData.length) {
      return SideTitleWidget(
        meta: meta,
        space: 10,
        child: Text(widget.chartData[index].label, style: style),
      );
    }
    return const SizedBox.shrink();
  }

  SideTitles get bottomTitles {
    double interval;
    switch (widget.reportType) {
      case ReportType.daily:
        interval = widget.chartData.length > 4 ? (widget.chartData.length / 4).roundToDouble() : 1;
        break;
      case ReportType.weekly:
        interval = 1;
        break;
      case ReportType.monthly:
        interval = widget.chartData.length > 7 ? (widget.chartData.length / 7).roundToDouble() : 1;
        break;
    }
    return SideTitles(
      showTitles: true,
      reservedSize: 32,
      interval: interval,
      getTitlesWidget: bottomTitleWidgets,
    );
  }

  FlGridData get gridData => FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 0.5,
          );
        },
      );

  FlBorderData get borderData => FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
      );

  List<LineChartBarData> get lineBarsData => [
        lineChartBarDataRevenue,
        lineChartBarDataTransactions,
      ];

  LineChartBarData get lineChartBarDataRevenue => LineChartBarData(
        isCurved: true,
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.blue.shade400],
        ),
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 3,
            color: Colors.green,
            strokeColor: Colors.white,
            strokeWidth: 2,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              Colors.indigo.withOpacity(0.3),
              Colors.blue.withOpacity(0.1),
            ],
          ),
        ),
        spots: widget.chartData
            .asMap()
            .entries
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
            .toList(),
      );

  LineChartBarData get lineChartBarDataTransactions => LineChartBarData(
        isCurved: true,
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.red.shade400],
        ),
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 3,
            color: Colors.red,
            strokeColor: Colors.white,
            strokeWidth: 2,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.3),
              Colors.red.withOpacity(0.1),
            ],
          ),
        ),
        spots: widget.chartData
            .asMap()
            .entries
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value.numberOfTransactions.toDouble()))
            .toList(),
      );
}