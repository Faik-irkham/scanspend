import 'package:flutter/material.dart';
import 'screens/expense_screen.dart';

void main() {
  runApp(const ScanSpendApp());
}

class ScanSpendApp extends StatelessWidget {
  const ScanSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ScanSpend',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ExpenseScreen(),
    );
  }
}
