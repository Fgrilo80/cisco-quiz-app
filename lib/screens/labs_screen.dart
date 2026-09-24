import 'package:flutter/material.dart';

import '../l10n.dart';
import '../labs/lab_catalog.dart';
import '../theme.dart';
import 'lab_run_screen.dart';

class LabsScreen extends StatelessWidget {
  const LabsScreen({super.key, required this.ui});

  final S ui;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ui.labsTitle)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: labCatalog.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                ui.labsIntro,
                style: const TextStyle(color: Color(0xFF94A3B8), height: 1.4),
              ),
            );
          }
          final lab = labCatalog[index - 1];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              leading: CircleAvatar(
                backgroundColor: ciscoBlue.withValues(alpha: 0.2),
                foregroundColor: ciscoBlue,
                child: Text(
                  '$index',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              title: Text(
                lab.title(ui),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                lab.hint,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LabRunScreen(lab: lab, ui: ui),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
