import 'package:flutter/material.dart';

import 'l10n.dart';
import 'screens/home_screen.dart';
import 'services/bank_service.dart';
import 'services/catalog_service.dart';
import 'services/progress_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await ProgressStore.create();
  final bank = BankService(store: store);
  final catalog = CatalogService();
  await Future.wait([bank.load(), catalog.load()]);
  runApp(CiscoQuizApp(bank: bank, store: store, catalog: catalog));
}

class CiscoQuizApp extends StatelessWidget {
  const CiscoQuizApp({
    super.key,
    required this.bank,
    required this.store,
    this.catalog,
  });

  final BankService bank;
  final ProgressStore store;
  final CatalogService? catalog;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.pt.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildCiscoTheme(),
      home: HomeScreen(bank: bank, store: store, catalog: catalog),
    );
  }
}
