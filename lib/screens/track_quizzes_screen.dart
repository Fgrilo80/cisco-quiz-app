import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models/quiz_catalog.dart';
import '../theme.dart';

/// Counts for one quiz entry on the track screen.
class QuizEntryCounts {
  const QuizEntryCounts({
    required this.pt,
    required this.en,
    required this.unseenPt,
    required this.unseenEn,
  });

  final int pt;
  final int en;
  final int unseenPt;
  final int unseenEn;

  bool get isEmpty => pt == 0 && en == 0;
}

/// Lists the catalog quizzes of one track (by exam, by theme, …) plus the
/// whole track. Counting and starting are delegated to the home screen so
/// filters, seen-tracking and pause handling stay in one place.
class TrackQuizzesScreen extends StatefulWidget {
  const TrackQuizzesScreen({
    super.key,
    required this.ui,
    required this.track,
    required this.trackTitle,
    required this.quizzes,
    required this.countsFor,
    required this.onStart,
    required this.exam,
    this.catalogVersion = '',
  });

  final S ui;
  final String track;
  final String trackTitle;
  final List<CatalogQuiz> quizzes;

  /// null = the whole track.
  final QuizEntryCounts Function(CatalogQuiz? quiz) countsFor;
  final Future<void> Function(CatalogQuiz? quiz, String lang) onStart;
  final bool exam;
  final String catalogVersion;

  @override
  State<TrackQuizzesScreen> createState() => _TrackQuizzesScreenState();
}

class _TrackQuizzesScreenState extends State<TrackQuizzesScreen> {
  Future<void> _start(CatalogQuiz? quiz, String lang) async {
    await widget.onStart(quiz, lang);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.ui;
    final groups = <String, List<CatalogQuiz>>{};
    final sorted = [...widget.quizzes]
      ..sort((a, b) => quizKindRank(a.kind).compareTo(quizKindRank(b.kind)));
    for (final q in sorted) {
      groups.putIfAbsent(q.kind, () => []).add(q);
    }
    final trackPalette = CertPalette.of(widget.track);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.trackTitle} · ${s.quizzesTitle}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            s.quizzesHint,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 14),
          _QuizTile(
            key: const ValueKey('quiz-tile-all'),
            s: s,
            badge: s.isPt ? 'TODAS' : 'ALL',
            label: s.allOfTrack(widget.trackTitle),
            palette: trackPalette,
            counts: widget.countsFor(null),
            exam: widget.exam,
            onStart: (lang) => _start(null, lang),
          ),
          for (final entry in groups.entries) ...[
            const SizedBox(height: 18),
            Text(
              s.kindLabel(entry.key).toUpperCase(),
              key: ValueKey('quiz-section-${entry.key}'),
              style: const TextStyle(
                color: Color(0xFF60A5FA),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            for (final quiz in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _QuizTile(
                  key: ValueKey('quiz-tile-${quiz.id}'),
                  s: s,
                  badge: quiz.badge(isPt: s.isPt),
                  label: quiz.label(isPt: s.isPt),
                  palette: CertPalette.named(quiz.color),
                  counts: widget.countsFor(quiz),
                  exam: widget.exam,
                  onStart: (lang) => _start(quiz, lang),
                ),
              ),
          ],
          if (widget.catalogVersion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.catalogVersion,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizTile extends StatelessWidget {
  const _QuizTile({
    super.key,
    required this.s,
    required this.badge,
    required this.label,
    required this.palette,
    required this.counts,
    required this.exam,
    required this.onStart,
  });

  final S s;
  final String badge;
  final String label;
  final CertPalette palette;
  final QuizEntryCounts counts;
  final bool exam;
  final void Function(String lang) onStart;

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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: palette.badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  s.countsLine(counts.pt, counts.en),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 3),
            Text(
              '${s.unseenLine(counts.unseenPt)} (PT)  ·  ${s.unseenLine(counts.unseenEn)} (EN)',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.button,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: counts.pt == 0 ? null : () => onStart('pt'),
                    child: Text(
                      s.startPt(exam: exam),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: counts.en == 0 ? null : () => onStart('en'),
                    child: Text(
                      s.startEn(exam: exam),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
