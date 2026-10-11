import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'shell/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OcrExpenseApp());
}

class OcrExpenseApp extends StatelessWidget {
  const OcrExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const MainShell(),
    );
  }
}
