import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../labs/ios_cli.dart';

/// Interactive IOS-like terminal. Large input for phones; Enter works on Windows.
class CliTerminal extends StatefulWidget {
  const CliTerminal({super.key, required this.cli, this.minHeight = 240});

  final IosCli cli;
  final double minHeight;

  @override
  State<CliTerminal> createState() => _CliTerminalState();
}

class _CliTerminalState extends State<CliTerminal> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _lines = <String>[];

  @override
  void initState() {
    super.initState();
    _lines.addAll(const [
      'Cisco IOS Software, Cisco Quiz Lab',
      'Compiled for study use — canned output, not a live device.',
      '',
    ]);
    _lines.add(widget.cli.prompt);
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _submit() {
    final cmd = _input.text;
    _input.clear();
    setState(() {
      final prompt = widget.cli.prompt;
      _lines.add('$prompt$cmd');
      final out = widget.cli.exec(cmd);
      if (out.isNotEmpty) {
        _lines.add(out);
      }
      _lines.add(widget.cli.prompt);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: widget.minHeight,
            maxHeight: widget.minHeight + 80,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF020617),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: GestureDetector(
            onTap: () => _focus.requestFocus(),
            child: Scrollbar(
              controller: _scroll,
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                children: [
                  SelectableText(
                    _lines.join('\n'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.35,
                      color: Color(0xFF86EFAC),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                focusNode: _focus,
                autocorrect: false,
                enableSuggestions: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.send,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  color: Color(0xFF86EFAC),
                ),
                decoration: InputDecoration(
                  hintText: '${widget.cli.prompt} ',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF020617),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[\u2018-\u201D]')),
                ],
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(56, 56),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Icon(Icons.keyboard_return, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
