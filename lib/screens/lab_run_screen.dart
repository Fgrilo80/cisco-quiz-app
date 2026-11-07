import 'package:flutter/material.dart';

import '../l10n.dart';
import '../labs/ios_cli.dart';
import '../labs/lab_catalog.dart';
import '../widgets/cli_terminal.dart';
import '../widgets/option_tile.dart';

class LabRunScreen extends StatefulWidget {
  const LabRunScreen({super.key, required this.lab, required this.ui});

  final LabDef lab;
  final S ui;

  @override
  State<LabRunScreen> createState() => _LabRunScreenState();
}

class _LabRunScreenState extends State<LabRunScreen> {
  final IosCli _cli = IosCli();
  int? _selected;
  bool _checked = false;

  S get ui => widget.ui;
  LabDef get lab => widget.lab;

  void _check() {
    if (_selected == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ui.selectFirst)));
      return;
    }
    setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    final ok = lab.isCorrect(_selected);
    return Scaffold(
      appBar: AppBar(title: Text(lab.title(ui))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              lab.task(ui),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${ui.labHint}: ${lab.hint}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            CliTerminal(cli: _cli),
            const SizedBox(height: 18),
            Text(
              ui.labAnswer,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < lab.options(ui).length; i++)
              OptionTile(
                index: i,
                label: lab.options(ui)[i],
                selected: _selected == i,
                revealed: _checked,
                isCorrect: i == lab.correct,
                onTap: () => setState(() => _selected = i),
              ),
            if (!_checked)
              FilledButton(onPressed: _check, child: Text(ui.labCheck))
            else ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ok ? const Color(0x1A34D399) : const Color(0x1AF87171),
                  borderRadius: BorderRadius.circular(16),
                  border: Border(
                    left: BorderSide(
                      color: ok
                          ? const Color(0xFF34D399)
                          : const Color(0xFFF87171),
                      width: 4,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ok ? ui.correct : ui.incorrect,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ok
                            ? const Color(0xFF34D399)
                            : const Color(0xFFF87171),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lab.explain(ui),
                      style: const TextStyle(
                        height: 1.35,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(ui.labBack),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
