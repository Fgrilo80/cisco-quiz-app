import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models/quiz_session.dart';
import '../services/bank_service.dart';
import '../services/progress_store.dart';
import '../services/quiz_picker.dart';
import '../theme.dart';
import '../widgets/cert_card.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.bank,
    required this.store,
  });

  final BankService bank;
  final ProgressStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late S s;
  QuizSession? paused;

  @override
  void initState() {
    super.initState();
    s = S.of(widget.store.uiLang);
    paused = widget.store.loadPaused();
    widget.bank.addListener(_onBank);
  }

  @override
  void dispose() {
    widget.bank.removeListener(_onBank);
    super.dispose();
  }

  void _onBank() {
    if (mounted) setState(() {});
  }

  Future<void> _setLang(String code) async {
    await widget.store.setUiLang(code);
    setState(() => s = S.of(code));
  }

  int _unseen(String cert, String lang) {
    final pool = widget.bank.questions(cert, lang);
    final seen = widget.store.loadSeen(cert, lang);
    return pool.where((q) => !seen.contains(q.id)).length;
  }

  Future<bool> _confirmReplacePaused() async {
    if (paused == null) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.appTitle),
        content: Text(s.newExamReplaces),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _start(String cert, String lang) async {
    if (!await _confirmReplacePaused()) return;
    final pool = widget.bank.questions(cert, lang);
    if (pool.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.emptyBank)));
      return;
    }
    final seen = widget.store.loadSeen(cert, lang);
    final picked = pickQuestions(pool: pool, seenIds: seen, count: quizLength);
    await widget.store.addSeen(cert, lang, picked.map((q) => q.id));
    final session = QuizSession(
      cert: cert,
      examLang: lang,
      questions: picked,
      answers: List<int?>.filled(picked.length, null),
      currentIndex: 0,
      timeLeftSeconds: quizSeconds,
      showingFeedback: false,
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await widget.store.savePaused(session);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          session: session,
          store: widget.store,
          ui: s,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => paused = widget.store.loadPaused());
  }

  Future<void> _resume() async {
    final session = paused;
    if (session == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          session: session,
          store: widget.store,
          ui: s,
          startPaused: true,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => paused = widget.store.loadPaused());
  }

  Future<void> _discardPaused() async {
    await widget.store.clearPaused();
    setState(() => paused = null);
  }

  Future<void> _refresh() async {
    final ok = await widget.bank.refreshFromGithub();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? s.refreshOk(widget.bank.total) : s.refreshFail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bank = widget.bank;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ciscoBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lan, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Cisco Quiz',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pt', label: Text('PT')),
                ButtonSegment(value: 'en', label: Text('EN')),
              ],
              selected: {s.code},
              onSelectionChanged: (v) => _setLang(v.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: bank.loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(s.loading),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      s.versionBadge,
                      style: const TextStyle(
                        color: Color(0xFF60A5FA),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  s.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${s.subtitle}\n${s.questionsInBank(bank.total)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                ),
                if (bank.loadError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    s.loadFail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFF87171), fontSize: 14),
                  ),
                ],
                if (paused != null) ...[
                  const SizedBox(height: 16),
                  _PausedBanner(
                    s: s,
                    session: paused!,
                    onResume: _resume,
                    onDiscard: _discardPaused,
                  ),
                ],
                const SizedBox(height: 20),
                for (final cert in const ['ccst', 'ccna', 'ccnp']) ...[
                  CertCard(
                    cert: cert,
                    s: s,
                    ptCount: bank.count(cert, 'pt'),
                    enCount: bank.count(cert, 'en'),
                    unseenPt: _unseen(cert, 'pt'),
                    unseenEn: _unseen(cert, 'en'),
                    onStart: (lang) => _start(cert, lang),
                  ),
                  const SizedBox(height: 14),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cloud_download_outlined,
                                color: Color(0xFF34D399)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.refreshTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.refreshHint,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: bank.refreshing ? null : _refresh,
                          icon: bank.refreshing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync),
                          label: Text(bank.refreshing ? s.refreshing : s.refreshNow),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF020617),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${s.bankUrlLabel}: $bankRemoteUrl',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  s.footer,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  s.privacy,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                ),
              ],
            ),
    );
  }
}

class _PausedBanner extends StatelessWidget {
  const _PausedBanner({
    required this.s,
    required this.session,
    required this.onResume,
    required this.onDiscard,
  });

  final S s;
  final QuizSession session;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0A66C2).withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.resumeBanner,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${s.certTitle(session.cert)} · ${session.examLang.toUpperCase()} · '
              '${session.currentIndex + 1}/${session.length}',
              style: const TextStyle(color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onResume,
                    child: Text(s.resumeBannerAction),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: onDiscard, child: Text(s.discardPaused)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
