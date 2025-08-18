import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kasir_app/src/features/reports/bloc/reports_bloc.dart';
import 'package:intl/intl.dart';

class ReportBarChart extends StatelessWidget {
  final List<ChartData> chartData;
  const ReportBarChart({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.5),
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < chartData.length) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 4.0,
                    child: Text(chartData[index].label, style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: chartData
                .asMap()
                .entries
                .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
                .toList(),
            isCurved: true,
            color: Colors.indigo,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.indigo.withOpacity(0.3),
            ),
          ),
        ],
        minX: 0,
        maxX: chartData.length.toDouble() - 1,
        minY: 0,
        maxY: chartData.map((d) => d.value).reduce((a, b) => a > b ? a : b) * 1.2,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(touchedSpot.y),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}