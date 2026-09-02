import 'package:cisco_quiz/models/question.dart';
import 'package:cisco_quiz/models/quiz_session.dart';
import 'package:flutter_test/flutter_test.dart';

Question q(String text) => Question(
  question: text,
  options: const ['a', 'b', 'c', 'd'],
  correct: 1,
  explanation: 'e',
  difficulty: 'Fácil',
);

void main() {
  test('score counts only matching confirmed answers', () {
    final session = QuizSession(
      cert: 'ccna',
      examLang: 'pt',
      questions: [q('Q0'), q('Q1'), q('Q2')],
      answers: [1, 0, null],
      currentIndex: 2,
      timeLeftSeconds: quizSeconds - 30,
      showingFeedback: false,
      startedAtMs: 1,
    );
    expect(session.correctCount, 1);
    expect(session.answeredCount, 2);
    expect(session.usedSeconds, 30);
    expect(session.mode, QuizMode.practice);
    expect(session.revealsAfterAnswer, isTrue);
  });

  test('practice mode reveals after each answer; exam does not', () {
    final practice = QuizSession(
      cert: 'ccna',
      examLang: 'pt',
      questions: [q('Q0')],
      answers: [null],
      currentIndex: 0,
      timeLeftSeconds: quizSeconds,
      showingFeedback: false,
      startedAtMs: 1,
      mode: QuizMode.practice,
    );
    final exam = QuizSession(
      cert: 'ccna',
      examLang: 'pt',
      questions: [q('Q0')],
      answers: [null],
      currentIndex: 0,
      timeLeftSeconds: quizSeconds,
      showingFeedback: false,
      startedAtMs: 1,
      mode: QuizMode.exam,
    );
    expect(practice.isPractice, isTrue);
    expect(practice.isExam, isFalse);
    expect(practice.revealsAfterAnswer, isTrue);
    expect(exam.isExam, isTrue);
    expect(exam.isPractice, isFalse);
    expect(exam.revealsAfterAnswer, isFalse);
  });

  test('fromJson keeps exam mode flag and clamps answers', () {
    final session = QuizSession.fromJson({
      'cert': 'ccst',
      'examLang': 'en',
      'mode': 'exam',
      'questions': [q('Q0').toJson(), q('Q1').toJson()],
      'answers': [1, 99],
      'currentIndex': 80,
      'timeLeftSeconds': -5,
      'showingFeedback': true,
      'startedAtMs': 10,
      'pendingSelection': 2,
    });
    expect(session.currentIndex, 1);
    expect(session.timeLeftSeconds, 0);
    expect(session.answers, [1, null]);
    expect(session.pendingSelection, 2);
    expect(session.correctCount, 1);
    expect(session.mode, QuizMode.exam);
    expect(session.revealsAfterAnswer, isFalse);
  });

  test('missing mode in json defaults to practice', () {
    final session = QuizSession.fromJson({
      'cert': 'ccna',
      'examLang': 'pt',
      'questions': [q('Hello').toJson()],
      'answers': [null],
      'currentIndex': 0,
      'timeLeftSeconds': 100,
      'showingFeedback': false,
      'startedAtMs': 5,
    });
    expect(session.mode, QuizMode.practice);
    expect(session.revealsAfterAnswer, isTrue);
  });

  test('round-trip keeps pending selection and exam mode for pause/resume', () {
    final original = QuizSession(
      cert: 'ccnp',
      examLang: 'pt',
      questions: [q('Hello')],
      answers: [null],
      currentIndex: 0,
      timeLeftSeconds: 100,
      showingFeedback: false,
      startedAtMs: 5,
      pendingSelection: 3,
      mode: QuizMode.exam,
    );
    final loaded = QuizSession.fromJson(original.toJson());
    expect(loaded.pendingSelection, 3);
    expect(loaded.questions.single.question, 'Hello');
    expect(loaded.timeLeftSeconds, 100);
    expect(loaded.mode, QuizMode.exam);
    expect(loaded.revealsAfterAnswer, isFalse);
  });
}
