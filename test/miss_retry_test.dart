import 'package:cisco_quiz/models/question.dart';
import 'package:cisco_quiz/models/quiz_session.dart';
import 'package:cisco_quiz/models/quiz_stats.dart';
import 'package:cisco_quiz/services/progress_store.dart';
import 'package:cisco_quiz/services/quiz_filters.dart';
import 'package:cisco_quiz/services/quiz_picker.dart';
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

QuizSession sessionWith({
  required List<Question> questions,
  required List<int?> answers,
  QuizMode mode = QuizMode.practice,
  String cert = 'ccna',
}) {
  return QuizSession(
    cert: cert,
    examLang: 'pt',
    questions: questions,
    answers: answers,
    currentIndex: 0,
    timeLeftSeconds: quizSeconds,
    showingFeedback: false,
    startedAtMs: 1,
    mode: mode,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('missedQuestions are wrong or unanswered', () {
    final qs = [q('Q0'), q('Q1'), q('Q2')];
    final session = sessionWith(questions: qs, answers: [1, 0, null]);
    expect(session.missedQuestions.map((e) => e.question), ['Q1', 'Q2']);
    expect(session.hitQuestions.map((e) => e.question), ['Q0']);
    expect(session.scorePercent, 33);
  });

  test('wrong answers are due immediately; recency prefers latest miss', () {
    final older = reviewSrs(emptySrs('old', 0), correct: false, nowMs: 1000);
    final newer = reviewSrs(emptySrs('new', 0), correct: false, nowMs: 9000);
    final right = reviewSrs(emptySrs('ok', 0), correct: true, nowMs: 5000);
    expect(older.lastMissedMs, 1000);
    expect(newer.lastMissedMs, 9000);
    expect(right.lastMissedMs, 0);
    expect(older.isDue(9000), isTrue);
    expect(right.isDue(5000), isFalse);
    expect(preferRecentMisses([older, newer, right], 10000), ['new', 'old']);
  });

  test(
    'pickWeakQuestions prefers recently missed and stays within the pool',
    () {
      final pool = [q('Q0'), q('Q1'), q('Q2'), q('Q3')];
      final times = {pool[0].id: 10, pool[1].id: 50, pool[2].id: 30};
      final all = pickWeakQuestions(
        pool: pool,
        missTimes: times,
        count: 50,
        preferRecent: true,
      );
      expect(all.map((e) => e.question).toList(), ['Q1', 'Q2', 'Q0']);
      expect(all, hasLength(3));
    },
  );

  test(
    'store records miss timestamps and due ids prefer recent misses',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.create();
      final qs = [q('Alpha VLAN'), q('Beta OSPF'), q('Gamma OK')];
      final session = sessionWith(questions: qs, answers: [0, 0, 1]);
      await store.recordSessionResults(session, nowMs: 2000);
      final times = store.loadMissTimes();
      expect(times[qs[0].id], 2000);
      expect(times[qs[1].id], 2000);
      expect(times.containsKey(qs[2].id), isFalse);
      expect(store.dueSrsIds(nowMs: 2000), containsAll([qs[0].id, qs[1].id]));
      expect(store.dueSrsIds(nowMs: 2000), isNot(contains(qs[2].id)));

      final retry = sessionWith(
        questions: session.missedQuestions,
        answers: List<int?>.filled(session.missedQuestions.length, null),
        mode: QuizMode.review,
      );
      expect(retry.questions, hasLength(2));
      expect(retry.isReview, isTrue);
      expect(retry.revealsAfterAnswer, isTrue);
    },
  );

  test('exams taken, last score per cert, last-5 average stay local', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.create();
    Future<void> exam(String cert, int hits) {
      final qs = [for (var i = 0; i < 10; i++) q('$cert-$i')];
      final answers = <int?>[for (var i = 0; i < 10; i++) i < hits ? 1 : 0];
      return store.recordFinished(
        sessionWith(
          questions: qs,
          answers: answers,
          mode: QuizMode.exam,
          cert: cert,
        ),
        nowMs: 1,
      );
    }

    await exam('ccna', 8);
    await exam('ccna', 6);
    await exam('ccst', 9);
    final stats = store.loadStats();
    expect(stats.examSessions, 3);
    expect(stats.lastPctByCert['ccna'], 60);
    expect(stats.lastPctByCert['ccst'], 90);
    expect(stats.lastFiveAvg, 77); // (80+60+90)/3 = 76.66 → 77
    expect(stats.lastFiveExamPct, [80, 60, 90]);

    await store.recordFinished(
      sessionWith(
        questions: [q('practice only')],
        answers: [1],
        mode: QuizMode.practice,
        cert: 'ccnp',
      ),
      nowMs: 2,
    );
    final afterPractice = store.loadStats();
    expect(afterPractice.examSessions, 3);
    expect(afterPractice.lastFiveExamPct, [80, 60, 90]);
    expect(afterPractice.lastPctByCert['ccnp'], 100);
  });

  test('QuizStats last five keeps only the newest five exam scores', () {
    var stats = const QuizStats();
    for (var i = 1; i <= 6; i++) {
      stats = stats.record(cert: 'ccna', mode: 'exam', hits: i, total: 10);
    }
    expect(stats.examSessions, 6);
    expect(stats.lastFiveExamPct, [20, 30, 40, 50, 60]);
    expect(stats.lastFiveAvg, 40);
  });

  test('review session length follows the missed pool, never pads to 50', () {
    final missed = [q('A'), q('B')];
    expect(filteredExamCount(missed.length), 2);
    expect(sessionSecondsFor(2), 3 * 60);
  });
}
