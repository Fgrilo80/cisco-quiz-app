import 'package:flutter/material.dart';

import 'l10n.dart';
import 'screens/home_screen.dart';
import 'services/bank_service.dart';
import 'services/progress_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await ProgressStore.create();
  final bank = BankService();
  await bank.load();
  runApp(CiscoQuizApp(bank: bank, store: store));
}

class CiscoQuizApp extends StatelessWidget {
  const CiscoQuizApp({
    super.key,
    required this.bank,
    required this.store,
  });

  final BankService bank;
  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.pt.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildCiscoTheme(),
      home: HomeScreen(bank: bank, store: store),
    );
  }
}
