import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense_model.dart';
import '../models/category.dart';

enum ChartPeriod { weekly, monthly, yearly }

class ChartsWidget extends StatefulWidget {
  final List<ExpenseModel> expenses;

  const ChartsWidget({super.key, required this.expenses});

  @override
  State<ChartsWidget> createState() => _ChartsWidgetState();
}

class _ChartsWidgetState extends State<ChartsWidget> {
  ChartPeriod _selectedPeriod = ChartPeriod.weekly;

  List<FlSpot> _buildSpots() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case ChartPeriod.weekly:
        return _weeklySpots(now);
      case ChartPeriod.monthly:
        return _monthlySpots(now);
      case ChartPeriod.yearly:
        return _yearlySpots(now);
    }
  }

  List<FlSpot> _weeklySpots(DateTime now) {
    final Map<int, double> totals = {};
    for (int i = 0; i < 7; i++) {
      totals[i] = 0;
    }
    for (final e in widget.expenses) {
      final diff = now.difference(e.timestamp).inDays;
      if (diff >= 0 && diff < 7) {
        totals[6 - diff] = (totals[6 - diff] ?? 0) + e.amount;
      }
    }
    return totals.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  List<FlSpot> _monthlySpots(DateTime now) {
    final Map<int, double> totals = {};
    for (int i = 0; i < 30; i++) {
      totals[i] = 0;
    }
    for (final e in widget.expenses) {
      final diff = now.difference(e.timestamp).inDays;
      if (diff >= 0 && diff < 30) {
        totals[29 - diff] = (totals[29 - diff] ?? 0) + e.amount;
      }
    }
    return totals.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  List<FlSpot> _yearlySpots(DateTime now) {
    final Map<int, double> totals = {};
    for (int i = 0; i < 12; i++) {
      totals[i] = 0;
    }
    for (final e in widget.expenses) {
      final monthsAgo = (now.year - e.timestamp.year) * 12 +
          (now.month - e.timestamp.month);
      if (monthsAgo >= 0 && monthsAgo < 12) {
        totals[11 - monthsAgo] = (totals[11 - monthsAgo] ?? 0) + e.amount;
      }
    }
    return totals.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  List<BarChartGroupData> _buildCategoryBars(List<String> nonZeroCategories) {
    final Map<String, double> totals = {};
    for (final e in widget.expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }

    return List.generate(nonZeroCategories.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: totals[nonZeroCategories[index]] ?? 0,
            color: Colors.deepPurple,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  List<String> _nonZeroCategories() {
    return ExpenseCategory.categories
        .where((cat) => widget.expenses.any((e) => e.category == cat))
        .toList();
  }

  String _getBottomLabel(double value) {
    final now = DateTime.now();
    final idx = value.toInt();
    switch (_selectedPeriod) {
      case ChartPeriod.weekly:
        final d = now.subtract(Duration(days: 6 - idx));
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
      case ChartPeriod.monthly:
        if (idx % 5 == 0) return '${idx + 1}';
        return '';
      case ChartPeriod.yearly:
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        // Safely calculate month index using modular arithmetic
        return months[((now.month - 1 + idx - 11) % 12 + 12) % 12];
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();
    final maxY = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);
    final nonZeroCategories = _nonZeroCategories();
    final categoryBars = _buildCategoryBars(nonZeroCategories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ChartPeriod.values.map((period) {
            final labels = {
              ChartPeriod.weekly: 'Weekly',
              ChartPeriod.monthly: 'Monthly',
              ChartPeriod.yearly: 'Yearly',
            };
            final isSelected = _selectedPeriod == period;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(labels[period]!),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedPeriod = period),
                selectedColor: Colors.deepPurple,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Line chart for expenses over time
        const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text(
            'Expenses Over Time',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: spots.isEmpty || maxY == 0
              ? const Center(
                  child: Text('No data for this period',
                      style: TextStyle(color: Colors.grey)),
                )
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Text(
                            _getBottomLabel(value),
                            style: const TextStyle(fontSize: 10),
                          ),
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.deepPurple,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.deepPurple.withOpacity(0.15),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: maxY * 1.2,
                  ),
                ),
        ),
        if (categoryBars.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'Expenses by Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= nonZeroCategories.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          ExpenseCategory.getEmoji(nonZeroCategories[idx]),
                          style: const TextStyle(fontSize: 14),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: categoryBars,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
