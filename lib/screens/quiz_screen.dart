import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';
import '../services/progress_store.dart';
import '../theme.dart';
import '../widgets/cli_block.dart';
import '../widgets/option_tile.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.session,
    required this.store,
    required this.ui,
    this.startPaused = false,
  });

  final QuizSession session;
  final ProgressStore store;
  final S ui;
  final bool startPaused;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  late QuizSession session;
  Timer? _timer;
  bool paused = false;
  int? selected;

  S get ui => widget.ui;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    session = widget.session;
    selected =
        session.answers[session.currentIndex] ?? session.pendingSelection;
    paused = widget.startPaused;
    _persist();
    if (!paused) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _persist();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || paused) return;
      if (session.timeLeftSeconds <= 0) {
        _timer?.cancel();
        _finish(fromTimeout: true);
        return;
      }
      setState(() => session.timeLeftSeconds--);
      if (session.timeLeftSeconds % 15 == 0) {
        _persist();
      }
    });
  }

  Future<void> _persist() {
    session.pendingSelection = selected;
    return widget.store.savePaused(session);
  }

  void _pause() {
    setState(() => paused = true);
    _timer?.cancel();
    _persist();
  }

  void _resume() {
    setState(() => paused = false);
    _startTimer();
  }

  Future<void> _goHomeKeepingProgress() async {
    await _persist();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _loadIndex(int index) {
    session.currentIndex = index;
    selected = session.answers[index];
    session.showingFeedback = session.revealsAfterAnswer && selected != null;
    session.pendingSelection = selected;
    setState(() {});
    _persist();
  }

  void _select(int index) {
    if (session.showingFeedback) return;
    setState(() => selected = index);
    session.pendingSelection = index;
    _persist();
  }

  void _needSelection() {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ui.selectFirst)));
  }

  void _onPrimary() {
    if (session.revealsAfterAnswer) {
      if (session.showingFeedback) {
        if (session.isLast) {
          _finish();
        } else {
          _loadIndex(session.currentIndex + 1);
        }
        return;
      }
      if (selected == null) {
        _needSelection();
        return;
      }
      session.answers[session.currentIndex] = selected;
      setState(() => session.showingFeedback = true);
      _persist();
      return;
    }
    if (selected == null) {
      _needSelection();
      return;
    }
    session.answers[session.currentIndex] = selected;
    session.showingFeedback = false;
    if (session.isLast) {
      _finish();
    } else {
      _loadIndex(session.currentIndex + 1);
    }
  }

  void _prev() {
    if (session.currentIndex == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ui.firstQ)));
      return;
    }
    _loadIndex(session.currentIndex - 1);
  }

  Future<void> _finish({bool fromTimeout = false}) async {
    _timer?.cancel();
    await widget.store.clearPaused();
    if (!mounted) return;
    if (fromTimeout) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(ui.timeUp),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(session: session, ui: ui),
      ),
    );
  }

  String _primaryLabel() {
    if (session.isExam) {
      return session.isLast ? ui.finish : ui.saveAndNext;
    }
    if (session.showingFeedback && session.isLast) return ui.finish;
    return ui.next;
  }

  String _clock(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final q = session.current;
    final lowTime = session.timeLeftSeconds <= 300;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pause();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _Header(
                    ui: ui,
                    cert: session.cert,
                    examLang: session.examLang,
                    modeLabel: session.isExam ? ui.examMode : ui.practiceMode,
                    clock: _clock(session.timeLeftSeconds),
                    lowTime: lowTime,
                    index: session.currentIndex,
                    total: session.length,
                    onHome: _pause,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (q.difficulty.isNotEmpty)
                              Chip(
                                label: Text(q.difficulty),
                                visualDensity: VisualDensity.compact,
                                side: const BorderSide(
                                  color: Color(0xFF334155),
                                ),
                              ),
                            Chip(
                              label: Text(
                                '${session.currentIndex + 1}/${session.length}',
                              ),
                              visualDensity: VisualDensity.compact,
                              side: const BorderSide(color: Color(0xFF334155)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.question,
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (q.hasCli) CliBlock(text: q.cli!),
                        const SizedBox(height: 16),
                        for (var i = 0; i < q.options.length; i++)
                          OptionTile(
                            index: i,
                            label: q.options[i],
                            selected: selected == i,
                            revealed: session.showingFeedback,
                            isCorrect: i == q.correct,
                            onTap: () => _select(i),
                          ),
                        if (session.showingFeedback) ...[
                          const SizedBox(height: 8),
                          _Feedback(ui: ui, question: q, selected: selected),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        OutlinedButton(onPressed: _prev, child: Text(ui.prev)),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _pause,
                          child: Text(ui.pause),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 52),
                            ),
                            onPressed: _onPrimary,
                            child: Text(
                              _primaryLabel(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (paused)
                _PauseOverlay(
                  ui: ui,
                  onResume: _resume,
                  onHome: _goHomeKeepingProgress,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.ui,
    required this.cert,
    required this.examLang,
    required this.modeLabel,
    required this.clock,
    required this.lowTime,
    required this.index,
    required this.total,
    required this.onHome,
  });

  final S ui;
  final String cert;
  final String examLang;
  final String modeLabel;
  final String clock;
  final bool lowTime;
  final int index;
  final int total;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          InkWell(
            onTap: onHome,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ciscoBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lan, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cisco Quiz',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${ui.certTitle(cert)} · ${examLang.toUpperCase()} · $modeLabel',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                clock,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: lowTime
                      ? const Color(0xFFF87171)
                      : const Color(0xFFFBBF24),
                ),
              ),
              Text(
                ui.remaining,
                style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${index + 1}/$total',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ui.questionLabel,
                style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.ui,
    required this.question,
    required this.selected,
  });

  final S ui;
  final Question question;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    final ok = question.isCorrect(selected);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ok ? const Color(0x1A34D399) : const Color(0x1AF87171),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: ok ? const Color(0xFF34D399) : const Color(0xFFF87171),
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
              color: ok ? const Color(0xFF34D399) : const Color(0xFFF87171),
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${ui.correctAnswer} ',
                  style: const TextStyle(color: Color(0xFF94A3B8)),
                ),
                TextSpan(
                  text: question.correctText,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${ui.explanation}: ${question.explanation}',
            style: const TextStyle(height: 1.35, color: Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.ui,
    required this.onResume,
    required this.onHome,
  });

  final S ui;
  final VoidCallback onResume;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xE0020617),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pause_circle_filled,
                  size: 64,
                  color: ciscoBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  ui.paused,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ui.pausedHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: onResume, child: Text(ui.resume)),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: onHome, child: Text(ui.home)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
