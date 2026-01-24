import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final accountProvider = context.watch<AccountProvider>();
    
    final spendingByAccount = transactionProvider.getSpendingByAccount();
    final transactions = transactionProvider.transactions;

    if (transactions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Spending Analysis')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                'No data available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 10),
              Text('Import bank statements first'),
            ],
          ),
        ),
      );
    }

    // Prepare chart data
    List<PieData> pieData = [];
    double totalSpending = 0;

    for (var entry in spendingByAccount.entries) {
      final category = accountProvider.getCategoryForAccount(entry.key);
      totalSpending += entry.value;
      
      pieData.add(PieData(
        category!.name,
        entry.value,
        category.color,
      ));
    }

    // Sort by value
    pieData.sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Total Spending',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      '₮${totalSpending.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      'Across ${spendingByAccount.length} accounts',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Spending by Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 10),
            
            // Pie Chart
            SizedBox(
              height: 300,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  overflowMode: LegendItemOverflowMode.wrap,
                  position: LegendPosition.bottom,
                ),
                series: <CircularSeries>[
                  PieSeries<PieData, String>(
                    dataSource: pieData,
                    xValueMapper: (PieData data, _) => data.x,
                    yValueMapper: (PieData data, _) => data.value,
                    pointColorMapper: (PieData data, _) => data.color,
                    dataLabelMapper: (PieData data, _) => '${data.x}\n₮${data.value.toStringAsFixed(0)}',
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      textStyle: TextStyle(fontSize: 12),
                    ),
                    explode: true,
                    explodeIndex: 0,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Account Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 10),
            
            // Account Breakdown List
            ...pieData.map((data) {
              final percentage = (data.value / totalSpending * 100).toStringAsFixed(1);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: data.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        data.x.substring(0, 1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: data.color,
                        ),
                      ),
                    ),
                  ),
                  title: Text(data.x),
                  subtitle: Text('$percentage% of total'),
                  trailing: Text(
                    '₮${data.value.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 20),
            
            // Top Spending Accounts
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top Spending Accounts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...spendingByAccount.entries
                        .toList()
                        .sorted((a, b) => b.value.compareTo(a.value))
                        .take(5)
                        .map((entry) {
                      final category = accountProvider.getCategoryForAccount(entry.key);
                      return ListTile(
                        leading: Icon(
                          Icons.attach_money,
                          color: category?.color,
                        ),
                        title: Text(category!.name),
                        subtitle: Text('Account: ${entry.key}'),
                        trailing: Text(
                          '₮${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension ListExtension<E> on List<E> {
  List<E> sorted(int Function(E, E) compare) {
    List<E> newList = List.from(this);
    newList.sort(compare);
    return newList;
  }
}

class PieData {
  PieData(this.x, this.value, this.color);
  final String x;
  final double value;
  final Color color;
}