import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';
import '../models/quiz_stats.dart';
import '../services/bank_service.dart';
import '../services/progress_store.dart';
import '../services/quiz_filters.dart';
import '../services/quiz_picker.dart';
import '../theme.dart';
import '../widgets/cert_card.dart';
import 'labs_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.bank, required this.store});

  final BankService bank;
  final ProgressStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late S s;
  QuizSession? paused;
  QuizMode _mode = QuizMode.practice;
  String _difficulty = '';
  String _topic = '';

  @override
  void initState() {
    super.initState();
    s = S.of(widget.store.uiLang);
    paused = widget.store.loadPaused();
    _difficulty = widget.store.filterDifficulty;
    _topic = widget.store.filterTopic;
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

  List<Question> _pool(String cert, String lang) => applyFilters(
    widget.bank.questions(cert, lang),
    difficulty: _difficulty,
    topic: _topic,
  );

  int _unseen(String cert, String lang) {
    final pool = _pool(cert, lang);
    final seen = widget.store.loadSeen(cert, lang);
    return pool.where((q) => !seen.contains(q.id)).length;
  }

  List<Question> _dueQuestions() {
    final ids = widget.store.dueSrsIds();
    return applyFilters(
      widget.bank.questionsByIds(ids),
      difficulty: _difficulty,
      topic: _topic,
    );
  }

  Iterable<Question> get _allInLang sync* {
    for (final cert in const ['ccst', 'ccna', 'ccnp']) {
      yield* widget.bank.questions(cert, s.code);
      yield* widget.bank.questions(cert, s.code == 'pt' ? 'en' : 'pt');
    }
  }

  int get _filteredTotal {
    var n = 0;
    for (final cert in const ['ccst', 'ccna', 'ccnp']) {
      n += _pool(cert, 'pt').length;
      n += _pool(cert, 'en').length;
    }
    return n;
  }

  Future<void> _setDifficulty(String value) async {
    setState(() => _difficulty = value);
    await widget.store.setFilters(difficulty: value);
  }

  Future<void> _setTopic(String value) async {
    setState(() => _topic = value);
    await widget.store.setFilters(topic: value);
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

  (String, String) _locate(Question q) {
    for (final cert in const ['ccst', 'ccna', 'ccnp']) {
      for (final lang in const ['pt', 'en']) {
        if (widget.bank.questions(cert, lang).any((x) => x.id == q.id)) {
          return (cert, lang);
        }
      }
    }
    return ('ccna', s.code);
  }

  Future<void> _pushSession(QuizSession session) async {
    await widget.store.savePaused(session);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            QuizScreen(session: session, store: widget.store, ui: s),
      ),
    );
    if (!mounted) return;
    setState(() => paused = widget.store.loadPaused());
  }

  Future<void> _start(String cert, String lang) async {
    if (!await _confirmReplacePaused()) return;
    final pool = _pool(cert, lang);
    if (pool.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.noFilterMatch)));
      return;
    }
    final seen = widget.store.loadSeen(cert, lang);
    final n = filteredExamCount(pool.length);
    final picked = pickQuestions(pool: pool, seenIds: seen, count: n);
    await widget.store.addSeen(cert, lang, picked.map((q) => q.id));
    final duration = sessionSecondsFor(picked.length);
    final session = QuizSession(
      cert: cert,
      examLang: lang,
      questions: picked,
      answers: List<int?>.filled(picked.length, null),
      currentIndex: 0,
      timeLeftSeconds: duration,
      showingFeedback: false,
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
      mode: _mode,
      durationSeconds: duration,
    );
    await _pushSession(session);
  }

  Future<void> _startReview() async {
    if (!await _confirmReplacePaused()) return;
    final due = _dueQuestions();
    if (due.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.retryEmpty)));
      return;
    }
    final picked = due.take(quizLength).toList();
    final loc = _locate(picked.first);
    final duration = sessionSecondsFor(picked.length);
    final session = QuizSession(
      cert: loc.$1,
      examLang: loc.$2,
      questions: picked,
      answers: List<int?>.filled(picked.length, null),
      currentIndex: 0,
      timeLeftSeconds: duration,
      showingFeedback: false,
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
      mode: QuizMode.review,
      durationSeconds: duration,
    );
    await _pushSession(session);
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

  Future<void> _openLabs() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => LabsScreen(ui: s)));
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
    final stats = widget.store.loadStats();
    final dueCount = _dueQuestions().length;
    final topics = topicsPresentIn(_allInLang);
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
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
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
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 15,
                  ),
                ),
                if (bank.loadError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    s.loadFail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF87171),
                      fontSize: 14,
                    ),
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
                Center(
                  child: SegmentedButton<QuizMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: QuizMode.practice,
                        label: Text(s.practiceMode),
                      ),
                      ButtonSegment(
                        value: QuizMode.exam,
                        label: Text(s.examMode),
                      ),
                    ],
                    selected: {
                      _mode == QuizMode.review ? QuizMode.practice : _mode,
                    },
                    onSelectionChanged: (v) => setState(() => _mode = v.first),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _mode.isExam ? s.examHint : s.practiceHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                _FilterCard(
                  s: s,
                  difficulty: _difficulty,
                  topic: _topic,
                  topics: topics,
                  filteredTotal: _filteredTotal,
                  onDifficulty: _setDifficulty,
                  onTopic: _setTopic,
                ),
                const SizedBox(height: 12),
                _StatsCard(s: s, stats: stats),
                if (dueCount > 0) ...[
                  const SizedBox(height: 12),
                  _RetryCard(s: s, count: dueCount, onRetry: _startReview),
                ],
                const SizedBox(height: 16),
                Card(
                  child: InkWell(
                    onTap: _openLabs,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: ciscoBlue.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.terminal, color: ciscoBlue),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.labsTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.labsSubtitle,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final cert in const ['ccst', 'ccna', 'ccnp']) ...[
                  CertCard(
                    cert: cert,
                    s: s,
                    ptCount: _pool(cert, 'pt').length,
                    enCount: _pool(cert, 'en').length,
                    unseenPt: _unseen(cert, 'pt'),
                    unseenEn: _unseen(cert, 'en'),
                    exam: _mode.isExam,
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
                            const Icon(
                              Icons.cloud_download_outlined,
                              color: Color(0xFF34D399),
                            ),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.sync),
                          label: Text(
                            bank.refreshing ? s.refreshing : s.refreshNow,
                          ),
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
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.privacy,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.s,
    required this.difficulty,
    required this.topic,
    required this.topics,
    required this.filteredTotal,
    required this.onDifficulty,
    required this.onTopic,
  });

  final S s;
  final String difficulty;
  final String topic;
  final List<String> topics;
  final int filteredTotal;
  final ValueChanged<String> onDifficulty;
  final ValueChanged<String> onTopic;

  @override
  Widget build(BuildContext context) {
    final diffs = <(String, String)>[
      ('', s.filterAll),
      (kDifficultyEasy, s.difficultyEasy),
      (kDifficultyMedium, s.difficultyMedium),
      (kDifficultyHard, s.difficultyHard),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.filterTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              s.filterDifficulty,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in diffs)
                  ChoiceChip(
                    label: Text(d.$2),
                    selected: difficulty == d.$1,
                    onSelected: (_) => onDifficulty(d.$1),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              s.filterTopic,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: Text(s.filterAll),
                  selected: topic.isEmpty,
                  onSelected: (_) => onTopic(''),
                  visualDensity: VisualDensity.compact,
                ),
                for (final id in topics)
                  ChoiceChip(
                    label: Text(topicLabel(id, isPt: s.isPt)),
                    selected: topic == id,
                    onSelected: (_) => onTopic(id),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              s.filteredCount(filteredTotal),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.s, required this.stats});

  final S s;
  final QuizStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, color: ciscoBlue, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.statsTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (stats.isEmpty)
              Text(
                s.statsEmpty,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              )
            else ...[
              Text(
                s.statsLine(stats.sessions, (stats.accuracy * 100).round()),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                s.examsTaken(stats.examSessions),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              if (stats.lastPctByCert.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  s.lastByCertLine(
                    [
                      for (final cert in const ['ccst', 'ccna', 'ccnp'])
                        if (stats.lastPctByCert[cert] != null)
                          '${s.certTitle(cert)} ${stats.lastPctByCert[cert]}%',
                    ].join(' · '),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ],
              if (stats.lastFiveAvg != null) ...[
                const SizedBox(height: 4),
                Text(
                  s.lastFiveLine(stats.lastFiveAvg!),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 6),
            Text(
              s.statsLocal,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryCard extends StatelessWidget {
  const _RetryCard({
    required this.s,
    required this.count,
    required this.onRetry,
  });

  final S s;
  final int count;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF7C3AED).withValues(alpha: 0.16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.retryDue(count),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              s.retryHint,
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            ),
            const SizedBox(height: 10),
            FilledButton(onPressed: onRetry, child: Text(s.reviewWeak)),
          ],
        ),
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
              '${s.modeLabel(session.mode.name)} · '
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
