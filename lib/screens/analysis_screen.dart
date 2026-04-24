// lib/screens/analysis_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Шинжилгээ'),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final transactions = provider.transactions;
          
          if (transactions.isEmpty) {
            return const Center(
              child: Text('Шинжилгээ хийх өгөгдөл байхгүй'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadTransactions(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cash Flow Summary Cards
                  _buildCashFlowSummary(provider),
                  const SizedBox(height: 24),
                  
                  // Monthly Spending Trends
                  _buildSectionTitle('Сарын зарлагын тренд'),
                  const SizedBox(height: 12),
                  _buildMonthlyTrendChart(transactions),
                  const SizedBox(height: 24),
                  
                  // Category Breakdown
                  _buildSectionTitle('Категорийн хуваарилалт'),
                  const SizedBox(height: 12),
                  _buildCategoryPieChart(transactions),
                  const SizedBox(height: 24),
                  
                  // Top Spending Categories
                  _buildSectionTitle('Топ зарлагын категориуд'),
                  const SizedBox(height: 12),
                  _buildTopCategoriesBarChart(transactions),
                  const SizedBox(height: 24),
                  
                  // Average Spending
                  _buildSectionTitle('Дундаж зарлага'),
                  const SizedBox(height: 12),
                  _buildAverageSpendingCards(transactions),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCashFlowSummary(TransactionProvider provider) {
    final totalIncome = provider.getTotalIncome();
    final totalExpenses = provider.getTotalExpenses();
    final netIncome = totalIncome - totalExpenses;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Орлого',
            totalIncome,
            Colors.green,
            Icons.arrow_downward_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Зарлага',
            totalExpenses,
            Colors.red,
            Icons.arrow_upward_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Цэвэр орлого',
            netIncome,
            netIncome >= 0 ? Colors.blue : Colors.orange,
            Icons.trending_up_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(locale: 'mn_MN', symbol: '₮', decimalDigits: 0).format(amount),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendChart(List<Transaction> transactions) {
    // Group transactions by month
    Map<String, double> monthlyExpenses = {};
    Map<String, double> monthlyIncome = {};
    
    for (var t in transactions) {
      final monthKey = DateFormat('yyyy-MM').format(t.date);
      monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0) + t.expense;
      monthlyIncome[monthKey] = (monthlyIncome[monthKey] ?? 0) + t.income;
    }

    // Sort by month and get last 6 months
    final sortedMonths = monthlyExpenses.keys.toList()..sort();
    final recentMonths = sortedMonths.length > 6 
        ? sortedMonths.sublist(sortedMonths.length - 6) 
        : sortedMonths;

    if (recentMonths.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Өгөгдөл байхгүй')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _calculateGridInterval(monthlyExpenses.values.toList()),
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[700],
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('');
                      return Text(
                        _formatCompactNumber(value),
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= recentMonths.length) return const Text('');
                      final month = recentMonths[index];
                      final parts = month.split('-');
                      return Text(
                        '${parts[1]}-${parts[0].substring(2)}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (recentMonths.length - 1).toDouble(),
              minY: 0,
              maxY: monthlyExpenses.values.reduce((a, b) => a > b ? a : b) * 1.2,
              lineBarsData: [
                LineChartBarData(
                  spots: recentMonths.asMap().entries.map((e) {
                    return FlSpot(
                      e.key.toDouble(),
                      monthlyExpenses[e.value] ?? 0,
                    );
                  }).toList(),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.3),
                        Colors.red.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                LineChartBarData(
                  spots: recentMonths.asMap().entries.map((e) {
                    return FlSpot(
                      e.key.toDouble(),
                      monthlyIncome[e.value] ?? 0,
                    );
                  }).toList(),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.3),
                        Colors.green.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(List<Transaction> transactions) {
    // Group expenses by category
    Map<String, double> categoryExpenses = {};
    
    for (var t in transactions) {
      final category = t.category ?? 'Тодорхойгүй';
      categoryExpenses[category] = (categoryExpenses[category] ?? 0) + t.expense;
    }

    if (categoryExpenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Өгөгдөл байхгүй')),
        ),
      );
    }

    final total = categoryExpenses.values.reduce((a, b) => a + b);
    final colors = [
      Colors.red, Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.pink, Colors.cyan, Colors.amber,
      Colors.teal, Colors.indigo, Colors.brown, Colors.grey,
    ];

    final sortedCategories = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: sortedCategories.asMap().entries.map((e) {
                      final index = e.key % colors.length;
                      final category = e.value;
                      final percentage = (category.value / total * 100);
                      return PieChartSectionData(
                        color: colors[index],
                        value: category.value,
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sortedCategories.take(5).map((category) {
                  final index = sortedCategories.indexOf(category) % colors.length;
                  final percentage = (category.value / total * 100);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[index],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category.key,
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategoriesBarChart(List<Transaction> transactions) {
    // Group expenses by category
    Map<String, double> categoryExpenses = {};
    
    for (var t in transactions) {
      final category = t.category ?? 'Тодорхойгүй';
      categoryExpenses[category] = (categoryExpenses[category] ?? 0) + t.expense;
    }

    if (categoryExpenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Өгөгдөл байхгүй')),
        ),
      );
    }

    // Sort and get top 5
    final sortedCategories = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(5).toList();

    final maxValue = topCategories.first.value;
    final colors = [
      Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 180.0,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      NumberFormat.currency(locale: 'mn_MN', symbol: '₮', decimalDigits: 0).format(rod.toY),
                      const TextStyle(color: Colors.white),
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
                      if (index >= topCategories.length) return const Text('');
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8,
                        child: Transform.rotate(
                          angle: -0.3,
                          child: SizedBox(
                            width: 80,
                            child: Text(
                              topCategories[index].key,
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    },
                    interval: 1,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('');
                      return Text(
                        _formatCompactNumber(value),
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _calculateGridInterval(topCategories.map((e) => e.value).toList()),
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[700],
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: topCategories.asMap().entries.map((e) {
                final index = e.key;
                final category = e.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: category.value,
                      color: colors[index % colors.length],
                      width: 30,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAverageSpendingCards(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate date range
    final dates = transactions.map((t) => t.date).toList();
    final minDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    
    final totalDays = maxDate.difference(minDate).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();
    final totalMonths = ((totalDays / 30).ceil()).clamp(1, 100);

    final totalExpenses = transactions.fold<double>(0, (sum, t) => sum + t.expense);
    
    final avgDaily = totalExpenses / totalDays;
    final avgWeekly = totalExpenses / totalWeeks;
    final avgMonthly = totalExpenses / totalMonths;

    return Row(
      children: [
        Expanded(
          child: _buildAverageCard('Өдөр', avgDaily),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAverageCard('7 хоног', avgWeekly),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAverageCard('Сар', avgMonthly),
        ),
      ],
    );
  }

  Widget _buildAverageCard(String period, double amount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              period,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(locale: 'mn_MN', symbol: '₮', decimalDigits: 0).format(amount),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateGridInterval(List<double> values) {
    if (values.isEmpty) return 1000;
    final max = values.reduce((a, b) => a > b ? a : b);
    if (max == 0) return 1000;
    
    // Round to nearest nice number
    final magnitude = (math.log(max) / math.ln10).floor();
    final normalized = max / math.pow(10, magnitude);
    
    if (normalized <= 1) return math.pow(10, magnitude).toDouble();
    if (normalized <= 2) return (2 * math.pow(10, magnitude)).toDouble();
    if (normalized <= 5) return (5 * math.pow(10, magnitude)).toDouble();
    return math.pow(10, magnitude + 1).toDouble();
  }

  String _formatCompactNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      final formatted = NumberFormat.currency(locale: 'mn_MN', symbol: '', decimalDigits: 0).format(value / 1000);
      return formatted;
    }
    final formatted = NumberFormat.currency(locale: 'mn_MN', symbol: '', decimalDigits: 0).format(value);
    return formatted;
  }
}
