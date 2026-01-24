import 'package:flutter/material.dart';
import 'package:moni/services/account_database.dart';
import 'package:provider/provider.dart';
import 'models/transaction.dart';
import 'models/account.dart';
import 'services/database.dart';
import 'screens/home_screen.dart';
import 'screens/import_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/accounts_screen.dart';  // Add this
import 'providers/transaction_provider.dart';
import 'providers/account_provider.dart';  // Add this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  await AccountDatabaseService.init();  // Initialize accounts database
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
      ],
      child: MaterialApp(
        title: 'Moni - Financial Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        routes: {
          '/import': (context) => const ImportScreen(),
          '/analysis': (context) => const AnalysisScreen(),
          '/accounts': (context) => const AccountsScreen(),  // Add this route
        },
      ),
    );
  }
}