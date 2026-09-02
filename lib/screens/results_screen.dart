import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';
import '../theme.dart';
import '../widgets/cli_block.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.session, required this.ui});

  final QuizSession session;
  final S ui;

  String _clock(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = session.length;
    final hits = session.correctCount;
    final misses = total - hits;
    final pct = total == 0 ? 0.0 : hits / total;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Cisco Quiz'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            ui.doneHeading(exam: session.isExam),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${ui.doneSub}\n${ui.certTitle(session.cert)} · ${session.examLang.toUpperCase()} · ${session.isExam ? ui.examMode : ui.practiceMode}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Metric(label: ui.points, value: '${(pct * 100).round()}%'),
              _Metric(label: ui.hits, value: '$hits'),
              _Metric(label: ui.misses, value: '$misses'),
              _Metric(label: ui.timeUsed, value: _clock(session.usedSeconds)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ui.scoreComment(pct),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(ui.redo),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(ui.home),
          ),
          const SizedBox(height: 24),
          Text(
            ui.summaryTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            ui.summaryHint,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < session.questions.length; i++)
            _QuestionReview(
              index: i,
              question: session.questions[i],
              answer: session.answers[i],
              ui: ui,
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ciscoBlue,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionReview extends StatelessWidget {
  const _QuestionReview({
    required this.index,
    required this.question,
    required this.answer,
    required this.ui,
  });

  final int index;
  final Question question;
  final int? answer;
  final S ui;

  @override
  Widget build(BuildContext context) {
    final ok = question.isCorrect(answer);
    final color = answer == null
        ? const Color(0xFF94A3B8)
        : ok
        ? const Color(0xFF34D399)
        : const Color(0xFFF87171);
    final status = answer == null
        ? ui.unanswered
        : ok
        ? ui.correct
        : ui.incorrect;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.18),
          foregroundColor: color,
          child: Text('${index + 1}', style: const TextStyle(fontSize: 13)),
        ),
        title: Text(
          question.question,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(status, style: TextStyle(color: color, fontSize: 12)),
        children: [
          if (question.hasCli) CliBlock(text: question.cli!),
          const SizedBox(height: 8),
          for (var i = 0; i < question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    i == question.correct
                        ? Icons.check_circle
                        : i == answer
                        ? Icons.cancel
                        : Icons.circle_outlined,
                    size: 18,
                    color: i == question.correct
                        ? const Color(0xFF34D399)
                        : i == answer
                        ? const Color(0xFFF87171)
                        : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${String.fromCharCode(65 + i)}. ${question.options[i]}',
                      style: TextStyle(
                        color: i == question.correct
                            ? const Color(0xFF34D399)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_wrongPick(question, answer)) ...[
            const SizedBox(height: 4),
            Text(
              '${ui.yourAnswer}: ${question.options[answer!]}',
              style: const TextStyle(color: Color(0xFFF87171)),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${ui.explanation}: ${question.explanation}',
            style: const TextStyle(height: 1.4, color: Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }
}

bool _wrongPick(Question question, int? answer) {
  if (answer == null) return false;
  if (answer == question.correct) return false;
  return answer >= 0 && answer < question.options.length;
}
