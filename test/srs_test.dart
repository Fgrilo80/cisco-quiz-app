import 'package:cisco_quiz/models/question.dart';
import 'package:cisco_quiz/models/quiz_session.dart';
import 'package:cisco_quiz/models/quiz_stats.dart';
import 'package:cisco_quiz/services/progress_store.dart';
import 'package:cisco_quiz/services/srs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Question q(String text) => Question(
  question: text,
  options: const ['a', 'b', 'c', 'd'],
  correct: 1,
  explanation: 'e',
  difficulty: 'Fácil',
);

void main() {
  test('wrong answers are due immediately; right answers space out', () {
    const now = 1_000_000;
    var card = emptySrs('id', now);
    card = reviewSrs(card, correct: false, nowMs: now);
    expect(card.inMissedPile, isTrue);
    expect(card.isDue(now), isTrue);
    expect(card.lapses, 1);
    expect(card.intervalDays, 0);

    card = reviewSrs(card, correct: true, nowMs: now);
    expect(card.inMissedPile, isFalse);
    expect(card.intervalDays, 1);
    expect(card.isDue(now), isFalse);
    expect(card.isDue(now + dayMs), isTrue);

    card = reviewSrs(card, correct: true, nowMs: now);
    expect(card.intervalDays, 3);
    card = reviewSrs(card, correct: true, nowMs: now);
    expect(card.intervalDays, 7);
    card = reviewSrs(card, correct: true, nowMs: now);
    expect(card.intervalDays, 14);
  });

  test('progress store records missed ids and local stats', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.create();
    final session = QuizSession(
      cert: 'ccna',
      examLang: 'pt',
      questions: [q('OSPF 1'), q('VLAN 2')],
      answers: [1, 0],
      currentIndex: 1,
      timeLeftSeconds: 100,
      showingFeedback: false,
      startedAtMs: 1,
      durationSeconds: 200,
    );
    await store.recordSessionResults(session, nowMs: 50);
    expect(store.missedSrsIds(), contains(session.questions[1].id));
    expect(store.dueSrsIds(nowMs: 50), contains(session.questions[1].id));
    expect(
      store.dueSrsIds(nowMs: 50),
      isNot(contains(session.questions[0].id)),
    );
    final stats = store.loadStats();
    expect(stats.sessions, 1);
    expect(stats.correct, 1);
    expect(stats.answered, 2);
    expect(stats.lastCert, 'ccna');
    expect(stats.lastPct, 50);
    expect(stats.isEmpty, isFalse);
  });

  test('quiz stats stay local and accumulate', () {
    const empty = QuizStats();
    expect(empty.isEmpty, isTrue);
    final next = empty.record(cert: 'ccst', mode: 'exam', hits: 40, total: 50);
    expect(next.examSessions, 1);
    expect(next.practiceSessions, 0);
    expect(next.accuracy, 0.8);
    expect(next.lastPct, 80);
  });
}
